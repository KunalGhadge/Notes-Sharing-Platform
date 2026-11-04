# Serious Study (formerly NoteHub) - Developer Guide & Technical Manual

This manual provides an in-depth, developer-centric analysis of the Serious Study Android application. It covers system architecture, performance optimizations, design implementation, security controls, database schema with Row Level Security (RLS), and maintenance procedures following the migration from the legacy Django/MongoDB stack to a modern serverless Flutter + Supabase architecture.

---

## 1. System Architecture & High-Level Overview

Serious Study is an academic resource and networking mobile platform designed for Mumbai University students. The application enables students to share lecture notes, syllabi, study materials, and micro-posts ("tweets"), as well as engage via comments, likes/dislikes, downloads, and bookmarks.

### 1.1 Architecture Stack
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **Architecture Pattern**: Decoupled MVC / Controller-Service Pattern powered by **GetX**.
- **Backend-as-a-Service**: **Supabase** (PostgreSQL, Supabase Auth, Supabase Storage, and Realtime Engine).
- **Local Persistence**: **Hive** (Key-Value NoSQL) for instant session hydration and offline tracking.
- **Networking & Caching**: Supabase Flutter SDK client combined with **Dio** and **flutter_cache_manager** for document and media caching.
- **Android Platform Target**: Android API Level 36 (`compileSdk 36`, `targetSdk 36`), Kotlin 2.1.0, Java 17, AGP 8.9.1.

### 1.2 Repository Structure & File Mapping
```
notehub/
├── android/                   # Native Android configuration (API 36, desugaring, multiDex)
├── assets/                    # Static assets (SVG icons, Lottie animations, raster graphics)
├── lib/
│   ├── main.dart              # Application entrypoint, Supabase & Hive initialization, GetX setup
│   ├── layout.dart            # Root scaffold managing bottom navigation and dynamic page switching
│   ├── core/
│   │   ├── config/
│   │   │   ├── color.dart     # Color palettes (Premium Deep Blue, secondary, grayscale)
│   │   │   └── typography.dart# Google Fonts (Plus Jakarta Sans) typographic scales
│   │   ├── helper/
│   │   │   ├── custom_icon.dart # SVG asset wrapper
│   │   │   ├── hive_boxes.dart  # Hive box interfaces ('userBox', 'downloadsBox')
│   │   │   └── image_helper.dart# Compression utility using flutter_image_compress
│   │   └── meta/
│   │       └── app_meta.dart  # Metadata, API endpoints, Supabase credentials, avatar CDN
│   ├── controller/            # Reactive state management controllers
│   │   ├── auth_controller.dart              # Session lifecycle, login, registration, Hive sync
│   │   ├── bottom_navigation_controller.dart # Active navigation tab state
│   │   ├── comment_controller.dart           # Threaded comment fetching, creation, deletion
│   │   ├── connection_controller.dart        # Followers/following relationship queries
│   │   ├── document_controller.dart          # Document lifecycle, optimistic likes/bookmarks
│   │   ├── download_controller.dart          # Download progress state
│   │   ├── home_controller.dart              # Feed fetching, sticky sort, Supabase Realtime
│   │   ├── notification_controller.dart      # User notifications and badge status
│   │   ├── profile_controller.dart           # User profile updates and bookmark listing
│   │   ├── profile_user_controller.dart      # Third-party profile inspections
│   │   ├── remote_config_controller.dart     # Dynamic feature flags via Supabase
│   │   ├── search_controller.dart            # Debounced queries across notes and authors
│   │   ├── showcase_controller.dart          # Featured document carousels
│   │   └── upload_controller.dart            # Multi-part upload pipeline (docs, covers, tweets)
│   ├── model/                 # Data transfer and domain models
│   │   ├── document_model.dart# Document and tweet metadata model
│   │   ├── mini_user_model.dart # Minimal user representation for lists
│   │   ├── post_model.dart    # Micro-post representation
│   │   └── user_model.dart    # Hive-annotated user profile model
│   ├── service/               # Native and device background services
│   │   ├── file_caching.dart  # Local cache-checking and temporary file opening
│   │   ├── file_download.dart # Dio download manager with background notification progress
│   │   └── notification_service.dart # Local notification channels and handlers
│   └── view/                  # Presentation layer and modular widgets
│       ├── auth_screen/       # Login and registration views
│       ├── bottom_footer/     # Custom Glassmorphic navigation bar
│       ├── connection_screen/ # Followers / Following lists
│       ├── document_screen/   # Note preview, description, comments thread
│       ├── home_screen/       # Main community feed with sticky official notices
│       ├── notification_screen/# User activity notifications
│       ├── official_screen/   # University announcements and official circulars
│       ├── profile_screen/    # Current and external profile views
│       ├── search_screen/     # Dynamic search page with filter chips
│       ├── settings_screen/   # About page and drawer settings
│       ├── splash_screen/     # Animated startup loader and session check
│       ├── upload_screen/     # Multi-part form for notes, links, and tweets
│       └── widgets/           # Shared reusable components (DocumentCard, PostCard, Toasts)
```

---

## 2. Performance Analysis & Optimization

### 2.1 Reactive State Management (GetX)
- **Granular Updates**: The app avoids monolithic rebuilds by separating business logic into specialized GetX controllers (`DocumentController`, `HomeController`, `UploadController`).
- **Targeted Notifications**: Using `update()` with optional IDs or reactive observables (`.obs`) ensures that only components listening to changed data re-render.
- **Cross-Controller Synchronization**: Changes in document state (such as liking or bookmarking in `DocumentController`) trigger `_syncWithHome()`, keeping `HomeController` lists in sync without requiring a network refresh.

### 2.2 Local Storage & Persistent Caching (Hive)
- **Zero-Latency App Startup**: User session and profile metadata are persisted in the Hive `userBox` (`lib/core/helper/hive_boxes.dart`). On cold launch, the UI renders the active user's credentials, avatar, and counts immediately before the network profile call completes.
- **Offline Download Registry**: Completed document downloads are logged in `downloadsBox`, allowing instantaneous checks via `ifFileExists()` before redundant network transfer.

### 2.3 Media & Asset Optimization
- **Image Compression Pipeline**: `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) automatically compresses cover images using `flutter_image_compress` before transmission to Supabase Storage:
  - Format: JPEG (`.jpg`).
  - Compression Quality: 70%.
  - Max Dimension: 1024x1024 px.
  - Significantly reduces bandwidth consumption and accelerates load times on 3G/4G mobile connections.
- **Network Image Caching**: Network assets are loaded through `cached_network_image`, maintaining a local disk cache with fallback placeholders and preventing re-downloads on list scrolls.

### 2.4 Scalable Database Operations & Perceived Performance
- **Atomic Operations via Remote Procedure Calls (RPCs)**: Counters (`likes_count`, `dislikes_count`) are incremented and decremented directly on PostgreSQL via database functions (`increment_likes`, `decrement_likes`). This prevents concurrency race conditions inherent in client-side read-modify-write patterns.
- **Optimistic UI Updates**: In `DocumentController.toggleLike()` and `toggleDislike()`, the local observable model state (`doc.isLiked`, `doc.likes`) updates immediately before the asynchronous RPC call. If the request encounters a network error, the state reverts automatically and displays a feedback toast.
- **Feed Batching & Sticky Sort**: `HomeController.fetchUpdates()` batches feed queries to 50 documents and limits official announcements to 20 documents. The feed employs an in-memory sticky sort placing official university announcements (`is_official: true`) at the top, followed chronologically by recent uploads.
- **Shimmer Placeholders**: During asynchronous data loads, skeleton layouts (`shimmer` package) maintain visual rhythm and prevent abrupt layout shifts (Cumulative Layout Shift mitigation).

---

## 3. Design System & UI/UX Architecture

### 3.1 Design Paradigm: Material 3 & Glassmorphism
The application adopts **Material 3** guidelines combined with a contemporary **Glassmorphism** aesthetic tailored for Mumbai University students:
- **Color Identity ("Premium Deep Blue")**:
  - Primary Base: `#0D47A1` (`PrimaryColor.shade500`).
  - Gradient Accent: `AppGradients.premiumGradient` blending `#0D47A1` into `#1976D2`.
  - Contrast Highlights: Subtle amber/gold accents (`#FFD700`, `#B8860B`) designating verified official posts and administrative badges.
- **Glassmorphism Overlays**:
  - Custom glass containers with frosted background blur, semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`), and thin borders (`Colors.white.withValues(alpha: 0.2)`).
  - Applied to the floating bottom navigation bar (`BottomFooter`) and profile statistics cards.
- **Modern Color Alpha API**: Codebase adopts modern Flutter color handling using `.withValues(alpha: ...)` rather than deprecated `.withOpacity()`.

### 3.2 Typography & Asset Integration
- **Typography**: Powered by `GoogleFonts.plusJakartaSansTextTheme()`, offering high legibility across diverse Android screen densities.
- **Vector Graphics**: Resolution-independent SVG icons (`flutter_svg`) are used for action buttons, navigation icons, and bookmarks.
- **State Feedback**: Integrated `Lottie` animations provide clear visual communication during empty searches, pull-to-refresh triggers, and upload completions.

### 3.3 Component Hierarchy & Modularity
- **Atomic Widgets**: Reusable UI primitives (`DocumentCard`, `PostCard`, `AdminBadge`, `PrimaryButton`, `UploadTextField`) reside in `lib/view/widgets/`.
- **Responsive Layout**: Screen layouts use dynamic constraints and `SingleChildScrollView` with `RefreshIndicator` or `LiquidPullToRefresh` for smooth mobile scrolling.

---

## 4. Security Architecture & Threat Audit

### 4.1 Authentication & Credential Protection
- **JWT-Based Authentication**: Custom legacy credentials have been completely replaced with Supabase Auth (GoTrue). User sessions are cryptographically signed with short-lived JWT access tokens and secure refresh tokens handled by the client SDK.
- **Password Safety**: Passwords are never transmitted in raw form to application databases. Passwords are salted and hashed using industry-standard algorithms (Argon2id/Bcrypt) within Supabase Auth.

### 4.2 Database Security & Row Level Security (RLS)
Every table defined in `SUPABASE_SCHEMA.sql` has `ROW LEVEL SECURITY` enabled with granular policies:

1. **`profiles` Table**:
   - `SELECT`: Public access (`USING (true)`).
   - `INSERT`: Restricted to the authenticated user (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Restricted to profile owner (`USING (auth.uid() = id)`).
   - *Privilege Escalation Protection*: Users cannot grant themselves administrative privileges (`is_admin`); modifications to `is_admin` are restricted by backend constraints and trigger protections.

2. **`documents` Table**:
   - `SELECT`: Public access (`USING (true)`).
   - `INSERT`: Enforces that the `user_id` matches the calling session (`WITH CHECK (auth.uid() = user_id)`).
   - `UPDATE` / `DELETE`: Restricted to the document author (`USING (auth.uid() = user_id)`), or administrators (`USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true))`).
   - *Content Integrity*: Setting `is_official = true` is restricted to verified administrators via PostgreSQL trigger (`ensure_official_permission`).

3. **`comments`, `interactions`, & `bookmarks` Tables**:
   - Row-level access ensures users can only write or remove records attached to their own `auth.uid()`.
   - Interactions table enforces a unique constraint `UNIQUE(document_id, user_id)` to prevent duplicate votes.

4. **`notifications` Table**:
   - `SELECT`: Strictly limited to the notification recipient (`auth.uid() = receiver_id`).

### 4.3 Storage Security & Upload Constraints
- **File Size Enforcements**: Direct document uploads are enforced with a 10MB limit in `UploadController`. Files exceeding this threshold prompt the user to use cloud link references (Google Drive, OneDrive).
- **Public/Private Storage Policies**: Supabase Storage buckets enforce authenticated upload paths scoped to `$userId/...`, mitigating unauthorized asset overwrites.

### 4.4 PostgreSQL Functions & Search Path Protection
- Stored procedures and RPC functions utilize `SECURITY DEFINER` and define an explicit `SET search_path = public` to prevent search path hijacking vulnerabilities.

---

## 5. Android Platform Configuration & Build Engine

The native Android layer inside `notehub/android` is optimized for modern Android releases:
- **Target & Compile SDK**: Android 36 (`compileSdk = 36`, `targetSdk = 36`).
- **Java & Kotlin Toolchain**: Source and target compatibility set to **Java 17** (`JavaVersion.VERSION_17`), jvmTarget = "17", Kotlin 2.1.0.
- **Core Library Desugaring**: Configured with `coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'` and `coreLibraryDesugaringEnabled true` to support modern Java APIs on older Android OS levels.
- **MultiDex Enabled**: `multiDexEnabled true` configured to prevent 64K method threshold errors arising from complex plugins (`flutter_local_notifications`, `supabase_flutter`).
- **Background Notifications**: Android notification channels configured for downloads (`download_channel`) with custom importance and priority levels.

---

## 6. Developer Guidelines & Maintenance Procedures

### 6.1 Prerequisites
- **Flutter SDK**: 3.24+ (Channel Stable).
- **Dart SDK**: ^3.5.4.
- **Java Development Kit**: JDK 17 (Temurin recommended).
- **Android SDK Platform**: API Level 36 (`build-tools;36.0.0`).

### 6.2 Code Quality Standards
- **Zero Warnings Policy**: All code merged into `main` must produce zero errors and zero warnings under `flutter analyze`.
- **Modern API Conventions**:
  - Always use `Color.withValues(alpha: ...)` instead of `Color.withOpacity(...)`.
  - In `Switch` widgets, use `activeThumbColor` instead of deprecated `activeColor`.
  - Flow control constructs (`if`, `else`, `for`, `while`) must always use explicit curly braces `{}`.
  - Silent/intentional catch blocks must contain an explicit comment (`/* silent */` or `// ignore: empty_catches`) on its own line.
- **Observability**: Avoid raw `print()` statements. Use `debugPrint()` or structured logging for development diagnostic traces.

### 6.3 Verification Commands
Inside `notehub/`:
```bash
# Get dependencies
flutter pub get

# Run static analysis
flutter analyze

# Execute test suite
flutter test

# Build release APK
flutter build apk --release
```

---
*Maintained and documented for Serious Study development team.*
