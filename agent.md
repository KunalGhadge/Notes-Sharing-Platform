# Developer Guide & System Architecture Manual: Serious Study

> **Target Platform**: Android (Flutter 3.24+ / Dart 3.5+, Android SDK 36, Java 17)
> **Backend Architecture**: Supabase Serverless BaaS (PostgreSQL 15+, Supabase Auth, Storage, Realtime)
> **Application Identifier**: `com.divinevisionary.notehub`
> **Brand & App Name**: Serious Study (formerly NoteHub)
> **Audience**: Mumbai University Academic & Student Community

---

## 1. Executive Summary & Architecture Overview

Serious Study is an enterprise-grade academic networking and educational content distribution platform tailored for university students. Originally conceived as a standard mobile client backed by a legacy monolithic stack (Django & MongoDB), the application has undergone a full architectural modernization into a reactive, cloud-native Flutter application powered by a serverless Supabase (PostgreSQL) backend.

### 1.1 High-Level Architecture Diagram
```
┌────────────────────────────────────────────────────────────────────────┐
│                        Flutter UI Presentation Layer                    │
│   (Material 3, Glassmorphism, Theme Tokens, Shimmer, Lottie Animation) │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Observables / Reactive GetX
┌───────────────────────────────────▼────────────────────────────────────┐
│                       Controller & Business Logic                      │
│   AuthController, DocumentController, HomeController, UploadController │
│   ProfileController, CommentController, NotificationController, etc.    │
└──────────────┬────────────────────┬────────────────────┬───────────────┘
               │                    │                    │
┌──────────────▼─────┐  ┌───────────▼───────┐  ┌─────────▼──────────────┐
│  Hive Local Cache  │  │  File Caching &   │  │   Supabase Client      │
│ (UserBox, Downloads│  │  Download Service │  │  • Supabase Auth (JWT) │
│  Instant Boot UI)  │  │   (Dio, PathProv) │  │  • Postgres RPC / RLS  │
└────────────────────┘  └───────────────────┘  │  • Realtime WebSocket  │
                                               │  • Object Storage      │
                                               └────────────────────────┘
```

### 1.2 Technology Stack
- **Frontend Framework**: Flutter (Channel Stable / Master compatible, Target SDK 36, Min SDK 21).
- **Programming Language**: Dart 3.5+.
- **State Management & Routing**: GetX (`GetxController`, `GetMaterialApp`, `Obx`, `GetX`).
- **Local Persistence & Offline Cache**: Hive NoSQL (`hive_flutter`, `userBox`, `downloadsBox`).
- **Networking & API**: `supabase_flutter` SDK (PostgREST, GoTrue, Realtime Client, Storage Client) and `dio` for advanced byte-stream downloads and HTTP caching.
- **Media Optimization**: `flutter_image_compress` (70% quality, max 1024x1024), `cached_network_image`.
- **System Services & Platform Channels**: `flutter_local_notifications`, `open_file`, `share_plus`, `url_launcher`.
- **Database & Storage Engine**: PostgreSQL with Row-Level Security (RLS), PL/pgSQL Atomic Functions, Supabase Storage buckets.

---

## 2. Deep-Dive Performance Analysis

Performance in Serious Study is engineered across five critical dimensions: UI rendering thread responsiveness, network payload minimization, persistent local caching, database query optimization, and memory efficiency.

### 2.1 Reactive State Management & UI Thread Isolation
- **GetX Architecture**: The app uses targeted reactivity. Instead of triggering full-tree `setState()` rebuilds, UI sub-trees subscribe to specific observable variables (`Rx<T>`, `RxList`, `RxBool`) via `Obx` or `GetX<Controller>` builders.
- **Micro-Task Batching**: Controllers decouple long-running asynchronous network calls from synchronous UI interactions. When liking or disliking documents in `DocumentController`, UI counters update immediately (optimistic UI), preventing touch latency or frame drops.
- **Controller Lifecycle Management**: Controllers are registered selectively in `main.dart` (global singletons like `NotificationController`, `BottomNavigationController`) and within `Layout` (`_LayoutState.initState`), preventing redundant instantiations and memory leaks.

### 2.2 Offline-First Storage & Hive Local Caching
- **Instant Boot Execution**: User identity and profile metadata are cached in Hive (`userBox`). During app boot (`main.dart` and `Splash`), session recovery is evaluated locally without blocking on remote auth handshakes.
- **Binary Serialization**: Models such as `UserModel` are serialized using compiled Hive type adapters (`UserModelAdapter` with `@HiveType(typeId: 0)`), providing sub-millisecond read times compared to JSON decoding.
- **Downloads Metadata Persistence**: The `downloadsBox` keeps an index of downloaded documents, file paths, and local hashes, allowing instant access to notes when offline.

### 2.3 Media & Bandwidth Optimization Pipeline
- **Client-Side Image Compression**: Direct high-resolution camera or gallery uploads are intercepted by `ImageHelper.compressImage()` (`lib/core/helper/image_helper.dart`). Images are re-encoded to JPEG at 70% quality with a bounding constraint of 1024x1024 pixels, slashing upload payload sizes by 80–90% before hitting Supabase Storage.
- **File Upload Limits & Offloading**: Direct document uploads are enforced with a strict 10MB ceiling (`UploadController.validateAndUpload`). To mitigate bandwidth costs and storage consumption, the application natively supports external document links (Google Drive, Mega, OneDrive) flagged via `is_external = true`.
- **Intelligent Byte Caching**: `FileCachingService` (`lib/service/file_caching.dart`) checks the temporary file cache using file checksums or filenames before initiating duplicate network transfers. Remote network images rely on `CachedNetworkImage` with custom disk cache stores.

### 2.4 Database Optimization & Atomic Counter Operations
- **Atomic Stored Procedures (RPCs)**: Client-side counter increments (likes, dislikes, bookmarks) are vulnerable to race conditions and inconsistent state under high concurrency. All counter mutations are executed via database-level RPC functions:
  - `increment_likes(doc_id BIGINT)`
  - `decrement_likes(doc_id BIGINT)`
  - `increment_dislikes(doc_id BIGINT)`
  - `decrement_dislikes(doc_id BIGINT)`
- **Query Batching & Pagination**: In `HomeController` and `SearchController`, queries are constrained with `.limit()` (e.g., official updates limited to 20, feed paginated in batches) to prevent memory ballooning and excessive ingress/egress.
- **Realtime Channel Filtering**: Postgres Realtime subscriptions (`supabase.channel('public:documents')`) only listen to specific event deltas, keeping WebSocket serialization overhead negligible.

---

## 3. UI/UX Design System & Architectural Patterns

Serious Study pairs Google's **Material 3 (M3)** specification with contemporary **Glassmorphism** to produce a distinctive, modern visual identity.

### 3.1 Design Language & Theming Tokens
- **Primary Color Palette**:
  - `AppColors.primaryColor`: Premium Deep Blue (`0xFF0D47A1`), conveying institutional authority and focus.
  - `AppColors.accentColor`: Radiant Royal Blue (`0xFF1976D2`) for interactive call-to-actions.
  - `AppColors.darkColor`: Charcoal Navy (`0xFF0A192F`) providing deep contrast in dark surfaces.
  - `AppColors.cardBackground`: Semi-translucent layered surface (`0xFFF8FAFC`).
- **Glassmorphic Surface Design**:
  - Implemented in `BottomFooter`, `HomeHeader`, `AdminBadge`, and dialog overlays.
  - Utilizes blur filters (`BackdropFilter`) combined with subtle border strokes (`Border.all(color: Colors.white.withValues(alpha: 0.2))`) and alpha-blended fills (`Colors.white.withValues(alpha: 0.15)`).
- **Typography**: Managed centrally in `AppTypography` (`lib/core/config/typography.dart`), with strict hierarchy across Headings (`headlineLarge`, `headlineMedium`), Titles (`titleMedium`), and Body typography, paired with Google Fonts.

### 3.2 Visual Feedback & Perceived Latency Reduction
- **Shimmer Placeholders**: `HomeDocumentSection` and `ProfileShowcase` render animated gradient shimmers during asynchronous queries, eliminating jarring layout shifts.
- **State Illustrations & Empty States**: Integrated vector graphics (`flutter_svg`) and `Lottie` animations render context-aware illustrations when searches yield no results or notification feeds are empty.
- **Adaptive Toast Notifications**: Custom `Toasts` utility built on `toastification`, delivering uniform success, warning, and error banners.

---

## 4. Comprehensive Security Posture & Vulnerability Analysis

The migration from legacy Django/MongoDB to Supabase fundamentally elevates the application's defense-in-depth security model.

### 4.1 Authentication & Credential Management
- **Token-Based Auth**: Authentication is handled via Supabase Auth (GoTrue), issuing cryptographically signed JSON Web Tokens (JWT). Client secrets and user passwords never touch custom server code; passwords are encrypted with bcrypt/Argon2 inside the auth microservice.
- **Session Auto-Refresh**: The Supabase Flutter client automatically persists and refreshes session tokens in secure client-side storage, eliminating replay attacks from expired access tokens.
- **Deep Link Callback Security**: Magic links and OAuth redirections are scoped strictly to the custom URI scheme `io.supabase.flutternotehub://login-callback` registered in `AndroidManifest.xml`.

### 4.2 Row Level Security (RLS) & Access Control
PostgreSQL Row Level Security is explicitly activated across all public tables (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).

```sql
-- Profiles: Public read, owner update
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Documents: Public read, owner insert & mutation
CREATE POLICY "Documents are viewable by everyone" ON public.documents FOR SELECT USING (true);
CREATE POLICY "Users can insert their own documents" ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update/delete their own documents" ON public.documents FOR ALL USING (auth.uid() = user_id);

-- Admin privilege protection
CREATE POLICY "Admins can update documents" ON public.documents
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
```

### 4.3 Privilege Escalation Countermeasures
- **Admin Verification Trigger**: To prevent malicious users from mutating `is_admin = true` on their own profile or creating fraudulent official university notes (`is_official = true`), database triggers and RLS policies restrict administrative flags strictly to users verified against admin records.
- **Search-Path Hijacking Protection**: All database functions and triggers are configured with explicit search path isolation (`SET search_path = public`) to neutralize PostgreSQL search-path hijacking attacks.

### 4.4 Android Security Configuration
- **Android Manifest Audit (`AndroidManifest.xml`)**:
  - `android:exported="true"` is restricted to `MainActivity` with explicit intent filters for the launcher and deep-link schemes.
  - Text selection querying (`<queries>`) specifies explicit system intents (`ACTION_PROCESS_TEXT`).
  - Network requests are governed by standard TLS encryption over HTTPS; no cleartext HTTP traffic is permitted.
- **Platform Permissions**:
  - `INTERNET`: Required for backend communication.
  - `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`: Handled dynamically for downloading study documents and PDFs to user-accessible device directories.

---

## 5. File-by-File Developer Reference

### 5.1 Project Entry & Navigation Architecture
- **`lib/main.dart`**:
  - The application entrypoint.
  - Initializes Flutter bindings, Supabase Client (`url`, `anonKey`), local notifications plugin, and Hive storage boxes.
  - Registers global state singletons (`BottomNavigationController`, `ShowcaseController`, `NotificationController`).
  - Bootstraps `MyApp` wrapped in `ToastificationWrapper` with Material 3 deep blue theme.
- **`lib/layout.dart`**:
  - The root shell widget for authenticated navigation.
  - Houses the persistent `BottomFooter` and dynamic page swapper indexed by `BottomNavigationController`.
  - Instantiates screen-scoped controllers (`ProfileController`, `DocumentController`, `RemoteConfigController`, etc.).
- **`lib/view/bottom_footer/bottom_footer.dart`**:
  - Custom glassmorphic navigation bar displaying 5 primary tabs: Home, Search, Upload, Official, and Profile.

### 5.2 Core Infrastructure & Configuration
- **`lib/core/meta/app_meta.dart`**:
  - Central metadata file holding constants: `appName`, `appIcon`, `supabaseUrl`, `supabaseAnonKey`, and fallback `avatarUrl`.
- **`lib/core/config/color.dart`**:
  - Defines the color palette (`primaryColor`, `accentColor`, `darkColor`, `cardBackground`, glass tints).
- **`lib/core/config/typography.dart`**:
  - Typography system adhering to Material 3 scale.
- **`lib/core/helper/hive_boxes.dart`**:
  - Centralized interface for reading and writing to Hive boxes (`userBox` and `downloadsBox`).
  - Exposes convenient getters: `userId`, `username`, `displayName`, `institute`, `userModel`, as well as `setUser()` and `resetUser()`.
- **`lib/core/helper/image_helper.dart`**:
  - Image compression utility wrapping `flutter_image_compress`. Reduces payload size while maintaining readability of text-dense documents.
- **`lib/core/helper/custom_icon.dart`**:
  - Type-safe SVG and asset path resolver for custom UI glyphs.

### 5.3 Data Models
- **`lib/model/user_model.dart` & `user_model.g.dart`**:
  - Primary user entity stored in Hive (`typeId: 0`). Fields: `id`, `displayName`, `username`, `institute`, `profile`, `documents`, `followers`, `following`.
- **`lib/model/document_model.dart`**:
  - Encapsulates academic document records including title, topic, description, download URL, cover image URL, author info, interaction counters (`likesCount`, `dislikesCount`), `isExternal`, `isOfficial`, `postType` ('note' or 'tweet'), and timestamps.
- **`lib/model/mini_user_model.dart`**:
  - Lightweight user summary for rendering followers and following user lists.
- **`lib/model/post_model.dart`**:
  - Compact presentation model for profile grid renderings.

### 5.4 State Controllers (`lib/controller/`)
- **`auth_controller.dart`**:
  - Manages authentication state, form validation, email/password registration, login, and user profile provisioning upon auth creation.
- **`home_controller.dart`**:
  - Fetches and caches the global document feed.
  - Subscribes to Supabase Postgres Realtime changes (`supabase.channel('public:documents')`) to update the feed on remote changes.
  - Fetches the latest 20 official university updates via `fetchOfficialUpdates()`.
- **`document_controller.dart`**:
  - Handles the document detail lifecycle: bookmarking, sharing, downloading, and optimistic liking/disliking via atomic RPC invocations (`increment_likes`, `decrement_likes`, etc.).
  - Synchronizes updated state back to `HomeController` through `_syncWithHome()`.
  - Manages document deletion, including cascade deletion of remote storage files.
- **`upload_controller.dart`**:
  - Orchestrates multi-step document uploads: file picking, thumbnail selection, 10MB size validation, image compression, uploading to Supabase Storage buckets (`documents`, `covers`), and inserting records into the database.
- **`comment_controller.dart`**:
  - Powers the document discussion thread. Fetches flat and hierarchical comment trees, adds root comments, and handles nested replies linked via `parent_id`.
- **`profile_controller.dart`**:
  - Manages the active user's profile view, academic interests, bio updates, and profile picture replacement.
- **`profile_user_controller.dart`**:
  - Manages third-party user profile views and handles follow/unfollow toggle actions.
- **`notification_controller.dart`**:
  - Ingests real-time notifications for user interactions (likes, comments, follows) and system-wide announcements.
- **`search_controller.dart`**:
  - Implements client-side and remote keyword search across subjects, document names, and topics.
- **`showcase_controller.dart`**:
  - Manages trending content lists, high-engagement notes, and spotlight carousels.
- **`remote_config_controller.dart`**:
  - Dynamically synchronizes application settings and feature flags stored in the `remote_config` table without requiring APK redeployment.
- **`connection_controller.dart`**:
  - Fetches lists of followers and following connections for any target user.
- **`download_controller.dart` & `file_controller.dart`**:
  - Facilitate local file system operations, download status indexing, and device file picking.

### 5.5 Platform Services (`lib/service/`)
- **`file_caching.dart`**:
  - Implements disk-cache lookup for remote assets using `dio` and `path_provider`, checking if files exist locally in temporary directories before initiating network downloads.
- **`file_download.dart`**:
  - Robust foreground and background file download service displaying download progress notifications via `flutter_local_notifications`.
- **`notification_service.dart`**:
  - Initializes Android notification channels, notification priorities, and alert sounds.

### 5.6 View Components (`lib/view/`)
- **`auth_screen/`**:
  - `login.dart`, `login_form.dart`, `login_fields.dart`, `login_header.dart`. Smooth transitions between Sign In and Sign Up forms.
- **`home_screen/`**:
  - `home.dart`, `home_header.dart`, `home_document_section.dart`. Profile greeting, dynamic quick-search bar, categorized horizontal and vertical document feeds with pull-to-refresh.
- **`document_screen/`**:
  - `document.dart`, `doc_description.dart`, `comment_section.dart`, `comment_tile.dart`, `follow_button.dart`, `icon_viewer.dart`. Detail view showing document preview, file statistics, interaction toolbar, author info, and threaded comments.
- **`upload_screen/`**:
  - `upload_screen.dart`, `upload_form.dart`, `upload_button.dart`. Intuitive upload forms supporting both binary files and external URLs, subject tag pickers, cover previewers, and admin official switches.
- **`profile_screen/`**:
  - `profile.dart`, `profile_user.dart`, `profile_header.dart`, `profile_showcase.dart`, `edit_profile_dialog.dart`, `post_renderer.dart`. Comprehensive profile views with academic details, document counts, follower metrics, and editable biographies.
- **`official_screen/`**:
  - Dedicated feed for university administration circulars and verified official syllabus notes.
- **`notification_screen/`**:
  - Activity feed with read/unread statuses and direct document navigation.
- **`settings_screen/`**:
  - Application information, open-source attributions, and account sign-out.
- **`widgets/`**:
  - Reusable presentation components: `DocumentCard`, `PostCard`, `AdminBadge`, `PrimaryButton`, `SecondaryButton`, `NormalButton`, `OptionButton`, `UploadTextField`, `Loader`, `RefresherWidget`, and `Toasts`.

---

## 6. Build, Tooling & CI/CD Pipeline

### 6.1 Android Gradle Setup
- **Android Target**: Android SDK 36 (`compileSdk = 36`, `targetSdk = 36`).
- **Java Compatibility**: Configured for Java 17 toolchain (`sourceCompatibility = JavaVersion.VERSION_17`, `targetCompatibility = JavaVersion.VERSION_17`, `jvmTarget = "17"`).
- **Core Library Desugaring**: Enabled (`coreLibraryDesugaringEnabled true`) with `com.android.tools:desugar_jdk_libs:2.1.4` to support modern Java APIs on older Android devices.
- **MultiDex**: Explicitly enabled (`multiDexEnabled true`) to support external native plugins.
- **Network Resiliency in CI**: Gradle wrapper (`gradle-wrapper.properties`) is configured to fetch distributions via JetBrains cache redirector (`https://cache-redirector.jetbrains.com/services.gradle.org/distributions/gradle-8.12-bin.zip`) to eliminate HTTP 504 timeouts on continuous integration runners.

### 6.2 GitHub Actions Workflows
1. **Flutter CI (`.github/workflows/dart.yml`)**:
   - Triggers on push and pull requests to `main`.
   - Sets up Java 17 and stable Flutter SDK.
   - Executes `flutter pub get`, `flutter analyze`, and `flutter test` within the `notehub` directory.
2. **Flutter Build APK (`.github/workflows/flutter-build.yml`)**:
   - Compiles release Android APK artifacts (`flutter build apk --release`).
   - Installs Android SDK 36 build tools.
   - Uploads compiled APK artifacts (`app-release.apk`) to GitHub Actions artifacts.

---

## 7. Developer Workflow & Quality Assurance Guide

### 7.1 Local Environment Setup
1. **Flutter SDK**: Ensure Flutter 3.24+ is installed (`flutter --version`).
2. **Dependencies**:
   ```bash
   cd notehub
   flutter pub get
   ```
3. **Run Code Generation (if modifying Hive models)**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### 7.2 Static Analysis & Code Hygiene
To maintain code quality and avoid breaking CI pipelines:
- **Linting & Code Style**:
  ```bash
  flutter analyze
  ```
- **Modern Flutter/Dart Conventions**:
  - Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
  - Use `activeThumbColor` instead of deprecated `activeColor` on `Switch` widgets.
  - Enclose control flow statements in explicit blocks (`{ ... }`).
  - Annotate intended empty catch blocks with `// ignore: empty_catches` on their own line.
- **Automated Tests**:
  ```bash
  flutter test
  ```

---
*Authored by Jules (AI Software Engineer) — Comprehensive Architecture & Security Manual for Serious Study.*
