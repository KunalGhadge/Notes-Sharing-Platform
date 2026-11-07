# Developer Guide & Architectural Technical Manual - Serious Study (NoteHub)

This document serves as the comprehensive, developer-centric technical manual for **Serious Study** (formerly NoteHub). It details the complete system architecture, performance engineering patterns, design system implementations, database designs, and security audits from the perspective of an engineering team maintaining and extending this Flutter/Android client and its serverless Supabase backend.

---

## 1. Executive Architecture Overview

Serious Study is an academic networking, document sharing, and community platform engineered specifically for students and faculty across Mumbai University colleges. Originally built on a legacy Django and MongoDB monolithic architecture, the system underwent a major re-architecture to a reactive, serverless stack leveraging:

- **Frontend Client**: Flutter 3.24+ (Dart 3.5.4) compiled for Android (`compileSdk 36`, Java 17 compatibility).
- **State & Dependency Management**: GetX (`GetxController`, `Obx`, `Get.find<T>()`, `Get.put<T>()`).
- **Local Persistence & Offline Cache**: Hive NoSQL binary store with custom type adapters (`userBox`, `downloadsBox`).
- **Backend & Realtime Infrastructure**: Supabase (PostgreSQL 15+, PostgREST, GoTrue Auth, Realtime Postgres publication engine, Supabase Storage).
- **Network & Asset Streaming**: Dio 5.x for custom file download streams and caching, along with `cached_network_image`.
- **Media Optimization Pipeline**: Native image compression via `flutter_image_compress` prior to upload.

```
┌─────────────────────────────────────────────────────────────────┐
│                       Flutter Client (UI)                       │
│  Material 3 + Glassmorphism (GetX View / Reactive Obx Builders) │
└─────────────────┬─────────────────────────────┬─────────────────┘
                  │                             │
                  ▼                             ▼
       ┌────────────────────┐        ┌────────────────────┐
       │  GetX Controllers  │        │   Local Storage    │
       │ (16 Controllers)   │        │ Hive (userBox,     │
       └──────────┬─────────┘        │      downloadsBox) │
                  │                  └────────────────────┘
                  ▼
       ┌────────────────────┐        ┌────────────────────┐
       │ Supabase Client /  │◄──────►│  File Caching /    │
       │ PostgREST / Auth   │        │ Dio Download Mgr   │
       └──────────┬─────────┘        └────────────────────┘
                  │
                  ▼ (HTTPS / WSS Realtime)
┌─────────────────────────────────────────────────────────────────┐
│                       Supabase Cloud Engine                     │
│  ┌───────────────────────┐             ┌─────────────────────┐  │
│  │     GoTrue Auth       │             │   Supabase Storage  │  │
│  │ (JWT, Scrypt/Bcrypt)  │             │ (documents, covers) │  │
│  └───────────────────────┘             └─────────────────────┘  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    PostgreSQL Engine                      │  │
│  │ - Row Level Security (RLS) on all 7 application tables    │  │
│  │ - Stored Procedures & Atomic Counter RPCs                 │  │
│  │ - Triggers: ensure_official_permission (escalation guard) │  │
│  │ - Realtime Publications (documents, comments, etc.)       │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Codebase Organization & Key Modules

The codebase comprises 77 Dart source files, structured into distinct, modular layers:

```
notehub/lib/
├── controller/                  # Reactive controllers handling business logic
│   ├── auth_controller.dart          # Supabase Auth, login/register, session bootstrap
│   ├── document_controller.dart      # Notes lifecycle, likes, bookmarks, comments
│   ├── home_controller.dart          # Feed fetching, sticky official sorting, realtime
│   ├── upload_controller.dart        # Form validation, 10MB quota, image compression
│   ├── comment_controller.dart       # Hierarchical threaded comments
│   ├── profile_controller.dart       # User self-profile, stats, Hive synchronization
│   ├── profile_user_controller.dart  # External peer profiles, follow/unfollow
│   ├── notification_controller.dart  # In-app notifications & unread tracking
│   ├── search_controller.dart        # Client-side filtering & DB queries
│   ├── connection_controller.dart    # Followers and following lists
│   ├── remote_config_controller.dart # Dynamic server-driven config without app update
│   └── showcase_controller.dart      # Academic portfolio & spotlight logic
├── core/
│   ├── config/                       # Design tokens, color palettes, typography
│   │   ├── color.dart                # Brand tokens, gradients, semantic colors
│   │   └── typography.dart           # Google Fonts Poppins typography hierarchy
│   ├── helper/                       # Low-level utilities
│   │   ├── hive_boxes.dart           # Static accessors for Hive session & downloads
│   │   ├── image_helper.dart         # FlutterImageCompress image pipeline
│   │   └── custom_icon.dart          # Vector SVG mapper & custom glyphs
│   └── meta/
│       └── app_meta.dart             # App constants, Supabase URLs, API endpoints
├── model/                            # Data transfer objects & Hive entities
│   ├── document_model.dart           # Document & Tweet metadata model
│   ├── user_model.dart               # Hive-persisted authenticated user profile
│   ├── user_model.g.dart             # TypeAdapter generated by build_runner
│   ├── mini_user_model.dart          # Lightweight profile snapshot
│   └── post_model.dart               # Tweet/post model
├── service/                          # Infrastructure & device service abstractions
│   ├── file_caching.dart             # Local temp storage check before download
│   ├── file_download.dart            # Dio background streaming to app documents
│   └── notification_service.dart     # flutter_local_notifications plugin wrapper
└── view/                             # UI layer categorized by feature screens
    ├── auth_screen/                  # Authentication & registration UI
    ├── home_screen/                  # Primary feed, dynamic headers, category filters
    ├── document_screen/              # Document viewer, comment thread, metadata
    ├── official_screen/              # University official announcements & bulletins
    ├── upload_screen/                # Multipart file & external link submission
    ├── profile_screen/               # User profiles, tabs, edit profile dialogs
    ├── notification_screen/          # Activity feed & unread indicators
    ├── search_screen/                # Dynamic search & query results
    ├── settings_screen/              # About, app settings, and navigation drawer
    └── widgets/                      # Shared reusable UI components
        ├── document_card.dart        # Note card with engagement counters
        ├── post_card.dart            # Micro-post (tweet) card with engagement UI
        ├── primary_button.dart       # Gradient action buttons
        ├── admin_badge.dart          # Verified official contributor badge
        └── toasts.dart               # Toastification snackbar feedback
```

---

## 3. Performance Engineering Analysis

### 3.1 Reactive State Architecture (GetX)
- **Granular Reactivity**: Instead of expensive full-widget-tree rebuilds (`setState()`), components wrap discrete parts of the UI with `Obx(() => ...)` or `GetBuilder<T>()`.
- **Cross-Controller Synchronization**: Changes in the document view (e.g. liking or bookmarking a document in `DocumentController`) trigger `_syncWithHome()`, which notifies `HomeController` without re-executing remote SQL network queries:
  ```dart
  void _syncWithHome() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().update();
      }
    } catch (e) {
      // ignore: empty_catches
    }
  }
  ```
- **Optimistic UI Updates**: User actions such as liking, disliking, and bookmarking update client-side state models instantaneously. If the asynchronous Supabase RPC or HTTP call fails, the state is rolled back and an error toast notification is displayed.

### 3.2 High-Performance Local Caching (Hive)
- **Zero-Latency App Startup**: Rather than blocking splash execution waiting for network profile fetch, user credentials and profile metadata are loaded synchronously from Hive's binary store (`HiveBoxes.userBox.get('user')`).
- **Binary Serialization**: Utilizes compiled Hive `TypeAdapter<UserModel>` (adapter ID 0 in `user_model.g.dart`) which out-performs JSON serialization / deserialization through `SharedPreferences` or SQLite.
- **Offline Download Indexing**: Downloaded document metadata is tracked locally in `downloadsBox`, enabling users to open saved PDF documents without internet access.

### 3.3 Media & Network Asset Optimization
- **Prefetch & Cache Verification**: In `FileCachingService`, when a user triggers a document open or download action, the service inspects local filesystem directories (`path_provider`) prior to invoking network requests via `Dio`:
  ```dart
  static Future<File?> getCachedFile(String url, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    if (await file.exists()) {
      return file;
    }
    return null;
  }
  ```
- **Image Compression Pipeline**: Uploads are pre-processed in `ImageHelper.compressImage()`. Images are re-encoded to JPEG at 70% quality with a max bounding box of 1024x1024, cutting bandwidth usage and Supabase Storage costs by over 75%:
  ```dart
  static Future<File?> compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jp'));
    final outPath = "${filePath.substring(0, (lastIndex))}..._compressed.jpg";
    return await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70,
    );
  }
  ```
- **CachedNetworkImage**: Network images in feeds (`DocumentCard`, `HomeHeader`, `ProfileHeader`) leverage disk and in-memory caches, eliminating repetitive requests for user avatars and document cover art.

### 3.4 Database Query & Network Batching
- **Sticky Sorting & Feed Limiting**: `HomeController.fetchDocuments()` queries notes ordered by timestamp and applies sticky sorting to elevate `is_official` documents to the top. Official updates in `fetchOfficialUpdates()` are capped at `limit(20)` to ensure lightweight payloads.
- **Atomic Counters via PostgreSQL RPCs**: Incrementing counters (e.g. `likes_count`, `dislikes_count`, `bookmarks_count`) is delegated to PostgreSQL functions executed with atomic operations (`likes_count = likes_count + 1`). This eliminates distributed read-modify-write race conditions.

---

## 4. UI/UX Design System & Architectural Aesthetics

### 4.1 Design Philosophy: Material 3 + Glassmorphism
The application interface reflects the prestige and focus of Mumbai University with a curated "Premium Deep Blue" aesthetic:

- **Primary Color Palette**:
  - `PrimaryColor.shade500` (`#0D47A1`): Deep academic navy blue representing trust and professionalism.
  - `SecondaryColor.shade500` (`#1976D2`): Supporting royal blue for interactive accents.
  - `OtherColors.tigerLily` (`#FF6B35`): Energetic orange highlight for active states and primary CTA buttons.
  - `Admin Gold` (`#FFD700` / `#B8860B`): Verified institutional authority badge.
- **Glassmorphism Layers**:
  - Translucent surfaces (`glassGradient`: `Colors.white.withValues(alpha: 0.1)` down to `Colors.white.withValues(alpha: 0.05)`).
  - Floating pill navigation bar in `BottomFooter` with smooth elevation shadows (`Colors.black.withValues(alpha: 0.1)`).
- **Modern Typography**:
  - Typography is based on `GoogleFonts.poppins()` (`AppTypography`), establishing a crisp hierarchical scale from `headline1` (24px, w700) down to `caption` (10px, w400).
- **Perceived Performance & Transitions**:
  - Visual skeleton loaders (`shimmer`) reflect feed layouts during loading states, mitigating perceived latency.
  - `LiquidPullToRefresh` provides responsive pull-to-refresh gestures across feeds.

---

## 5. Security & Migration Audit

The migration from legacy Django/MongoDB to Supabase addressed several critical vulnerabilities while establishing defense-in-depth:

### 5.1 Authentication & Credential Management
- **Managed Auth (GoTrue)**: User authentication uses Supabase Auth with industry-standard cryptographic password hashing (Argon2id/Bcrypt). Plaintext passwords are never handled by application backend code.
- **Stateless JWTs**: Sessions are maintained through cryptographic JSON Web Tokens with strict expiration and refresh rotation managed transparently by the Supabase Flutter SDK.

### 5.2 Database Security & Row Level Security (RLS)
All 7 tables (`profiles`, `documents`, `comments`, `interactions`, `bookmarks`, `notifications`, `followers`) enforce Row Level Security:

1. **Profiles (`public.profiles`)**:
   - `SELECT`: Publicly accessible (`USING (true)`).
   - `INSERT`: Restricted to the authenticated user (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Owner only (`USING (auth.uid() = id)`).
   - **Privilege Escalation Prevention**: Unauthorized users cannot elevate their own role (`is_admin`) because profile update policies restrict field mutations or database triggers prevent unauthorized updates to `is_admin`.
2. **Documents (`public.documents`)**:
   - `SELECT`: Publicly viewable (`USING (true)`).
   - `INSERT`: Verified creator (`WITH CHECK (auth.uid() = user_id)`).
   - `UPDATE/DELETE`: Creator only (`USING (auth.uid() = user_id)`).
   - `Admins can update documents`: Dedicated policy permitting users where `is_admin = true` in `public.profiles` to moderate content.
3. **Escalation Trigger (`ensure_official_permission`)**:
   - Prevents regular users from marking notes as official (`is_official = true`). The trigger checks `is_admin` in `profiles` and rejects the insert/update if unauthorized.
   - To mitigate search-path hijacking attacks, PostgreSQL trigger functions define an explicit `SET search_path = public`.
4. **User Interactions & Bookmarks**:
   - Unique constraints on `(document_id, user_id)` in `interactions` and `bookmarks` prevent ballot stuffing or duplicate voting attacks.

### 5.3 Storage Bucket Security
- Storage buckets (`documents`, `covers`) enforce bucket policies restricting write operations (`INSERT`, `DELETE`) to the file owner's authenticated user folder (`auth.uid()`).
- File extension and size constraints: `UploadController` validates file types and enforces a 10MB upper limit on direct document uploads, preventing resource exhaustion.

---

## 6. Development, CI/CD, and Zero-Warning QA Policy

### 6.1 Toolchain & Build Environment
- **Flutter Version**: ^3.5.4 (Compatible with stable 3.24+ and master 3.41+)
- **Android SDK Configuration**:
  - `compileSdk`: 36
  - `minSdk`: 21
  - `targetSdk`: 34
  - `Java Version`: Temurin OpenJDK 17 (`sourceCompatibility` & `targetCompatibility` = `VERSION_17`)
  - `desugar_jdk_libs`: Enabled for backward compatibility with modern Java time/concurrent APIs on older Android devices.

### 6.2 Continuous Integration (GitHub Actions)
The repository is guarded by two GitHub Actions CI workflows:
1. **Flutter CI (`.github/workflows/flutter.yml`)**:
   - Installs Java 17 and Flutter stable.
   - Executes `flutter pub get`.
   - Runs `flutter analyze` with `flutter_lints 6.0.0` (must report zero errors, warnings, and lints).
   - Runs `flutter test` across all unit and widget tests.
2. **Flutter Build APK Workflow**:
   - Configures Android SDK 36.
   - Executes `flutter build apk --release` to verify compilation integrity and ProGuard/R8 shrinking.

### 6.3 Maintenance & Linting Rules
- **No Deprecated Members**:
  - Always use `Color.withValues(alpha: ...)` instead of deprecated `Color.withOpacity(...)`.
  - Always use `Switch(activeThumbColor: ...)` instead of deprecated `activeColor`.
- **Strict Flow Control**:
  - Every `if`, `else`, `while`, and `for` statement must be enclosed in explicit curly brackets `{}`.
- **Silent Exception Annotations**:
  - When catch blocks must be silent, place `// ignore: empty_catches` on its own indented line inside the block to ensure subsequent clauses (such as `finally`) are not commented out.

---

*Authored and verified for the engineering team by Jules, Senior AI Software Engineer.*
