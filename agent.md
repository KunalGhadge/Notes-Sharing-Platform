# Developer Guide & Architectural Manual - Serious Study (NoteHub)

This document provides an exhaustive, developer-centric technical analysis of the **Serious Study** (formerly NoteHub) mobile application. It covers architecture, performance engineering, UI/UX design systems, backend schemas, and security audits across all application files and modules.

---

## 1. Executive Summary & System Overview

Serious Study is an academic social network and collaborative resource platform built primarily for the Mumbai University student community. The application bridges academic peer-to-peer resource sharing (lecture notes, past papers, syllabus guides, reference material) and community discourse (tweets/short updates, nested comment discussions, follow networks).

### Architectural Philosophy
- **Client Frontend**: Flutter (SDK ^3.5.4, targeting Android 14+ / SDK 36 and modern multiplatform targets).
- **Backend Architecture**: Fully serverless using **Supabase** (PostgreSQL, Supabase Auth with JWT, Storage Buckets, and Postgres Realtime).
- **State Management & DI**: **GetX** (`GetxController`, `Rx` observables, dependency injection via `Get.put()` / `Get.find()`, reactive routing).
- **Local Persistence**: **Hive** NoSQL storage with type adapters for lightning-fast zero-latency offline boot and user session persistence.
- **Networking**: `supabase_flutter` for relational queries, authentication, and realtime subscriptions; `Dio` with `path_provider` for cached media streaming and file downloads.

---

## 2. Codebase Organization & Module Directory

```
notehub/
├── android/                   # Native Android host configuration (SDK 36, Gradle 8.12, Java 17)
├── assets/                    # Static vector graphics (SVG), animations (Lottie), raster images
├── lib/
│   ├── main.dart              # Application entrypoint & global dependency container
│   ├── layout.dart            # Root scaffold binding BottomNavigationController
│   ├── core/                  # Design tokens, theme config, helpers, and app constants
│   │   ├── config/            # Color palettes (`color.dart`), Typography (`typography.dart`)
│   │   ├── helper/            # Hive box wrappers (`hive_boxes.dart`), Image compression (`image_helper.dart`), SVG helpers
│   │   └── meta/              # Supabase API keys, base endpoints, branding constants
│   ├── controller/            # GetX business logic, state machines, and API interfaces
│   │   ├── auth_controller.dart          # Sign up, sign in, profile bootstrap, session lifecycle
│   │   ├── home_controller.dart          # Realtime document feeds, batching, official notes
│   │   ├── document_controller.dart      # Optimistic like/dislike/bookmark, storage cleanup
│   │   ├── upload_controller.dart        # Multi-part upload pipeline, file compression, validation
│   │   ├── profile_controller.dart       # User stats, bio updates, user uploads
│   │   ├── profile_user_controller.dart  # Peer user view, follow/unfollow graph
│   │   ├── comment_controller.dart       # Nested thread comments & real-time additions
│   │   ├── notification_controller.dart  # User activity notifications & Postgres change listener
│   │   ├── connection_controller.dart    # Followers/following directory
│   │   ├── search_controller.dart        # Text and tag search
│   │   └── remote_config_controller.dart # Dynamic database-driven configurations
│   ├── model/                 # Data transfer objects and Hive entity adapters
│   │   ├── document_model.dart           # Document & tweet entity representation
│   │   ├── user_model.dart & .g.dart     # Hive-persisted authenticated user profile
│   │   ├── post_model.dart               # Social post model
│   │   └── mini_user_model.dart          # Lightweight user badge representation
│   ├── service/               # Native integrations and I/O services
│   │   ├── file_caching.dart             # Local temp caching via Dio & PathProvider
│   │   ├── file_download.dart            # Document downloads with notification feedback
│   │   └── notification_service.dart     # Android Local Notification channels
│   └── view/                  # Screen views and modular UI components
│       ├── splash_screen/     # Cold start routing and session verification
│       ├── auth_screen/       # Login and registration forms with validation
│       ├── home_screen/       # Main feed, header profile icon, shimmer states
│       ├── document_screen/   # Note viewer, comment thread, author meta
│       ├── upload_screen/     # Note & Tweet upload flow with switch toggles
│       ├── profile_screen/    # Current and external profile screens with post renderers
│       ├── notification_screen/# Notification timeline
│       ├── connection_screen/ # Following/Followers tabs
│       └── widgets/           # Document cards, admin badges, toasts, buttons
├── SUPABASE_SCHEMA.sql        # Database tables, RLS policies, triggers, and RPC functions
└── test/                      # Unit and integration test suites
```

---

## 3. Deep Dive: Performance Engineering Analysis

### 3.1 Network Optimization & Media Pipeline
1. **Intelligent Image Compression**:
   - High-resolution camera captures and raw PNG cover art are compressed before upload using `flutter_image_compress` in `ImageHelper.compressImage`.
   - Compresses images to JPEG format at 70% quality, capping dimensions to 1024x1024. This drastically reduces upload times, cuts bandwidth consumption, and prevents storage bloat.
2. **Two-Tier Image & Document Caching**:
   - `cached_network_image` is utilized across document list views (`DocumentCard`, `PostCard`) and profile headers (`HomeHeader`, `ProfileHeader`). Images are cached on disk using an LRU cache eviction policy.
   - `FileCaching` checks the local application cache directory (`getTemporaryDirectory()`) before dispatching network GET requests via `Dio`. If the file exists, it immediately loads from local storage.
3. **Bandwidth Preservation (External Links)**:
   - For massive PDFs or reference archives (>10MB), `UploadController` supports external cloud links (Google Drive, Mega, GitHub). This keeps app storage low while supporting arbitrary file sizes.

### 3.2 State Management & Reactive UI Performance
1. **Fine-Grained Reactivity (GetX)**:
   - Controllers isolate reactive state into `Rx` primitives (`RxBool`, `RxList`, `Rxn`). UI components wrap only the reactive segments with `Obx` or `GetX<Controller>`, eliminating full-widget subtree rebuilds.
2. **Optimistic Updates**:
   - `DocumentController.toggleLike()`, `toggleDislike()`, and `toggleBookmark()` update local state and notify UI subscribers immediately before the Supabase RPC call resolves. If the network call fails, the mutation is seamlessly rolled back, delivering a zero-latency tactile experience to the student.
3. **Cross-Controller State Synchronization**:
   - `DocumentController` triggers `_syncWithHome()` on interaction mutations, keeping the feed in `HomeController` synchronized with detail screens without reloading the full list.
4. **Local Persistent Cache (Hive)**:
   - User profile metadata and session information are kept in binary-serialized Hive boxes (`userBox`). During cold starts (`Splash`), user state is resolved synchronously without blocking on network roundtrips.

### 3.3 Database & Query Performance
1. **Atomic Server-Side RPCs**:
   - Instead of reading counts, modifying them in Dart, and writing them back (which causes race conditions and multi-trip latency), counter mutations are handled via Postgres functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`).
2. **Targeted Relation Projection**:
   - Feeds use Supabase foreign key joins (`select('*, profiles:user_id(...), interactions:interactions(...), bookmarks:bookmarks(...)')`), fetching documents, author profiles, and user interaction states in a single database round-trip.
3. **Result Set Limiting**:
   - Official updates (`HomeController.fetchOfficialUpdates()`) query only the top 20 records (`.limit(20)`), preventing high memory pressure and excessive deserialization overhead on mobile clients.

---

## 4. Deep Dive: UI/UX & Design System Analysis

### 4.1 Visual Identity & Theming
- **Palette**: Shifted from generic aesthetics to the **"Serious Study" Academic Deep Blue** theme (`#0D47A1`), reinforcing academic professionalism and institutional identity.
- **Glassmorphism**: Layered glass cards (`glassmorphism` package) with semi-transparent white fills (`withValues(alpha: 0.15)`), subtle borders, and background blurs (`sigmaX: 10`, `sigmaY: 10`) provide high visual hierarchy in navigation bars and floating overlays.
- **Material 3 Alignment**: Full adherence to Material 3 specifications (`useMaterial3: true`), incorporating dynamic color seeds, tonal elevation, and modern tactile feedback.

### 4.2 Perceived Performance & Motion
- **Shimmer Placeholders**: `shimmer` provides animated skeleton screens in `HomeDocumentSection` and search lists while asynchronous payloads load, preventing layout pop-in.
- **Lottie Micro-Interactions**: Vector animations (`assets/animations/notes.json`) provide friendly feedback during empty feed states, search results, or upload completions.
- **Toastification Feedback**: Toast notifications are centralized in `Toasts` (`showTostSuccess`, `showTostError`, `showTostWarning`), giving users unambiguous, non-blocking visual feedback on operations.

---

## 5. Deep Dive: Security, Privacy & Backend Audits

### 5.1 Authentication & Session Management
- **Modern JWT Authentication**: Authenticates via Supabase Auth (Argon2 / Bcrypt server-side password hashing). No plain-text passwords or vulnerable legacy session tokens are stored on the device.
- **Secure Token Storage**: Handled under the hood by `supabase_flutter` using native secure storage where available.
- **Email Redirection & Deep Links**: Registration sets `emailRedirectTo: 'io.supabase.flutternotehub://login-callback'`, integrated with Android deep linking filters.

### 5.2 Row Level Security (RLS) Policy Audit
Every database table in `SUPABASE_SCHEMA.sql` has Row Level Security strictly enabled:

| Table | Policy Name | Permitted Roles / Checks | Security Implication |
| :--- | :--- | :--- | :--- |
| `profiles` | Public profiles are viewable by everyone | `SELECT (true)` | Open directory for user networking |
| `profiles` | Users can insert their own profile | `INSERT WITH CHECK (auth.uid() = id)` | Prevents impersonation on registration |
| `profiles` | Users can update own profile | `UPDATE USING (auth.uid() = id)` | Prevents profile tampering by third parties |
| `documents` | Documents are viewable by everyone | `SELECT (true)` | Public academic repository |
| `documents` | Users can insert their own documents | `INSERT WITH CHECK (auth.uid() = user_id)` | Documents must match authenticated UID |
| `documents` | Users can update/delete their own documents | `ALL USING (auth.uid() = user_id)` | Prevents deletion or modification of other students' notes |
| `documents` | Admins can update documents | `USING (auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true))` | Role-based moderation for verified institutional notes |
| `comments` | Comments viewable / insert | `SELECT (true)`, `INSERT WITH CHECK (auth.uid() = user_id)` | Verified comment ownership |
| `notifications` | Users can view their own notifications | `SELECT (auth.uid() = receiver_id)` | Private notification inbox |

### 5.3 Storage Bucket Security & File Integrity
- Files in the `documents` storage bucket are mapped to user IDs.
- Direct uploads enforce a 10MB limit in `UploadController` before network transmission.
- Deletions in `DocumentController.deleteDocument()` verify ownership (`doc.username == HiveBoxes.username`) and remove both the physical file in Supabase Storage and the relational row in PostgreSQL.

### 5.4 Android Native Security & Permissions
In `android/app/src/main/AndroidManifest.xml`:
- `INTERNET`: Required for Supabase client and Dio downloads.
- Storage Permissions (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`): Configured for downloading and saving educational PDFs.
- Intent Filter: `io.supabase.flutternotehub://login-callback` for secure OAuth/Magic Link callbacks.

---

## 6. Android Build & Native Platform Configuration

- **Target SDK**: Configured for `compileSdk 36` and `targetSdk 36` in `android/app/build.gradle`.
- **Java Compatibility**: Source and target set to `JavaVersion.VERSION_17`.
- **Desugaring**: `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'` enabled to support modern Java APIs required by `flutter_local_notifications`.
- **MultiDex**: `multiDexEnabled true` enabled to prevent method limit crashes with large third-party native libraries.
- **CI Reliability**: Gradle wrapper configured to fetch from stable mirrors (`gradle-8.12-bin.zip`), preventing CI network timeouts.

---

## 7. Developer & QA Procedures

### Static Analysis & Lints
All code in `notehub/lib` adheres to standard Flutter lint rules:
- **Zero Warnings Standard**: Run `flutter analyze` inside the `notehub` directory to ensure clean code.
- **Color Standards**: Modern Dart color definitions must use `Color.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
- **Widget Standards**: Use `activeThumbColor` for Switch widgets instead of deprecated `activeColor`.
- **Control Flow**: Explicit block braces `{}` are strictly enforced on control statements.

### Automated Testing
- Tests are located in `notehub/test/`.
- Run `flutter test` inside `notehub/` before pushing commits to verify passing suites.

---
*Maintained and documented for the Serious Study Engineering Team.*
