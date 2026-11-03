# Serious Study (formerly NoteHub) - Developer Guide & System Manual

## 1. Executive Summary & Architecture Overview
**Serious Study** (formerly NoteHub) is a specialized academic networking, note sharing, and student collaboration platform tailored for Mumbai University colleges. Originally built on a legacy Django/MongoDB monolithic backend, the platform underwent complete architectural modernization to a serverless, reactive architecture powered by **Flutter 3.24+ (Dart SDK 3.5.4+)** on the client and **Supabase (PostgreSQL 15+, Supabase Auth, GoTrue JWT, PostgREST, and Realtime)** on the cloud backend.

### High-Level Architecture Diagram
```
+---------------------------------------------------------------------------------------+
|                                    Flutter Client                                     |
|                                                                                       |
|   +-----------------------+   +------------------------+   +----------------------+   |
|   |      Views / UI       |<->|    GetX Controllers    |<->|   Local Persistence  |   |
|   | (Material 3 + Glass)  |   | (Reactive State & DI)  |   | (Hive NoSQL Caches)  |   |
|   +-----------------------+   +------------------------+   +----------------------+   |
|                                           |                                           |
+-------------------------------------------|-------------------------------------------+
                                            | HTTPS / WSS (Supabase SDK & Dio)
                                            v
+---------------------------------------------------------------------------------------+
|                                Supabase Serverless BaaS                               |
|                                                                                       |
|  +---------------------+   +---------------------+   +-----------------------------+  |
|  |    Supabase Auth    |   |     PostgreSQL      |   |      Supabase Storage       |  |
|  |     (JWT / RLS)     |   | (Tables, RPCs, RLS) |   | (Buckets: docs, thumbnails) |  |
|  +---------------------+   +---------------------+   +-----------------------------+  |
|                                       |                                               |
|                                       v                                               |
|                         Postgres Realtime Replication                                 |
|                       (Documents, Notifications stream)                               |
+---------------------------------------------------------------------------------------+
```

---

## 2. File-by-File Component Mapping

### Root & Configuration Files
- **`notehub/pubspec.yaml`**: Configures dependencies: `get: ^4.6.6` for reactive state and routing, `supabase_flutter: ^2.8.0`, `hive_flutter: ^1.1.0` for persistent local storage, `dio: ^5.7.0` for chunked media downloads, `flutter_image_compress: ^2.3.0` for asset optimization, `toastification: ^2.3.0`, and vector graphics/fonts.
- **`notehub/analysis_options.yaml`**: Strict linting rules enforcing Flutter style conventions, `curly_braces_in_flow_control_structures`, and deprecation tracking.
- **`notehub/android/app/build.gradle`**: Configured with `compileSdk = 36`, `targetSdk = 36`, `JavaVersion.VERSION_17`, `multiDexEnabled true`, and `coreLibraryDesugaring` (`desugar_jdk_libs:2.1.4`) to support modern background notifications and Android 14/15/16 runtime requirements.
- **`SUPABASE_SCHEMA.sql`**: Complete PostgreSQL database schema defining relational schemas, custom types, check constraints, foreign key cascades, atomic counter stored procedures (RPCs), Realtime publication bindings, and Row Level Security (RLS) policies.

### Core Foundation (`notehub/lib/core/`)
- **`lib/core/meta/app_meta.dart`**: Stores application metadata, including app name ("Serious Study"), project URLs, and Supabase public client keys.
- **`lib/core/config/color.dart`**: Brand palette definition centered around Premium Deep Blue (`PrimaryColor.shade500: #0D47A1`), secondary accents, grayscale palettes, and glassmorphic translucent fills (`.withValues(alpha: ...)`).
- **`lib/core/config/typography.dart`**: Complete typography scales utilizing Google Fonts (Poppins / Roboto) with explicit weights and line heights.
- **`lib/core/helper/hive_boxes.dart`**: High-performance local caching abstraction exposing `userBox` (`UserModel` persistence) and `downloadsBox` (offline file metadata). Provides safe getters (`HiveBoxes.userId`, `HiveBoxes.isAdmin`) preventing null-pointer crashes.
- **`lib/core/helper/image_helper.dart`**: Multi-platform image optimizer that compresses picked cover images to JPEG (70% quality, 1024x1024 max dimensions) before network transmission.
- **`lib/core/helper/custom_icon.dart`**: SVG rendering wrappers with unified sizing, theming, and accessibility attributes.

### Services (`notehub/lib/service/`)
- **`lib/service/file_download.dart`**: Handles device file downloads, mime-type resolutions, and system notification dispatches upon download completion.
- **`lib/service/file_caching.dart`**: Manages temporary caching of document previews using `Dio` with disk-based cache checks to prevent redundant network downloads.
- **`lib/service/notification_service.dart`**: Local notification scheduler and foreground channel dispatcher using `flutter_local_notifications`.

### Controllers (`notehub/lib/controller/`)
- **`lib/controller/auth_controller.dart`**: Manages user authentication (Supabase Auth email/password, session bootstrap, user profile upsert into `profiles`, and local `HiveBoxes` sync).
- **`lib/controller/home_controller.dart`**: Primary feed controller implementing 50-item batch pagination, sticky tab filtering (All, Notes, Updates), Postgres Realtime channel listeners (`public:documents`), and cached feed refreshing.
- **`lib/controller/document_controller.dart`**: Granular document state controller implementing optimistic UI updates for likes, dislikes, and bookmarks, coupled with transactional Supabase RPC function calls (`increment_likes`, `decrement_likes`, etc.) and cross-controller synchronization (`_syncWithHome()`).
- **`lib/controller/upload_controller.dart`**: Content submission pipeline supporting direct PDF/image uploads or external drive links (Google Drive, Mega), thumbnail generation, payload validation (10MB limit), and official announcement publishing for admin users.
- **`lib/controller/comment_controller.dart`**: Hierarchical comment thread manager supporting nested replies (`parent_id`) with real-time UI synchronization.
- **`lib/controller/profile_controller.dart` & `lib/controller/profile_user_controller.dart`**: Manages own-profile and peer-profile views, statistics (followers, following, uploads count), and academic interests.
- **`lib/controller/connection_controller.dart`**: Handles follower/following relationships with optimistic state updates.
- **`lib/controller/search_controller.dart`**: Debounced subject/topic/author query engine querying PostgreSQL indexes.
- **`lib/controller/notification_controller.dart`**: Manages in-app notifications, unread counters, and mark-as-read updates.

### Views & Widgets (`notehub/lib/view/`)
- **`lib/view/splash_screen/splash.dart`**: Brand splash screen validating active Supabase JWT sessions and Hive user cache before navigating to `Layout` or `Login`.
- **`lib/layout.dart`**: Root navigation shell hosting persistent bottom navigation with glassmorphic styling, lazy-loaded screen indexes, and unread notification indicators.
- **`lib/view/home_screen/`**: Feed interface featuring `HomeHeader`, search bar shortcut, and `HomeDocumentSection` with shimmer loading states.
- **`lib/view/document_screen/`**: Full document detail page featuring file preview, external link redirection, atomic engagement bar, and threaded comment list.
- **`lib/view/upload_screen/`**: Form UI with responsive upload progress indicators, file picking callbacks, and admin badge toggles.
- **`lib/view/widgets/`**: Reusable component library including `DocumentCard`, `PostCard` (tweet/short update format), `AdminBadge`, `PrimaryButton`, `Toasts` (via `toastification`), and `RefresherWidget`.

---

## 3. Performance Deep Dive

### Reactive State Architecture (GetX)
- **Granular Reactivity**: The application leverages `Obx` and `GetX<Controller>` to ensure only the strictly necessary UI subtrees rebuild during state changes (e.g., toggling a bookmark only triggers a rebuild of the bookmark button rather than the entire feed or list item).
- **Optimistic State Updates**: In `DocumentController`, interactions (likes/bookmarks) instantly update local reactive state (`isLiked`, `likesCount`), providing instantaneous 60/120 FPS UI feedback. If the underlying network request fails, the controller automatically rolls back the state and displays a warning toast.
- **Feed Batching & Sticky Tabs**: `HomeController` limits initial query payloads to 50 items and uses cursor/offset querying to avoid memory spikes and keep scroll performance fluid on low-end mobile devices.

### Local Storage & Caching (Hive & Dio)
- **Instant Cold Boot**: Upon app launch, `HiveBoxes.userBox` provides instantaneous access to the user profile and session metadata, completely eliminating layout shifting or white flashes while Supabase validates the JWT in the background.
- **Network De-duplication**: `file_caching.dart` verifies whether a document or image already exists in `getTemporaryDirectory()` using a SHA-256 / filename hashing scheme before dispatching any `Dio` HTTP GET requests.

### Media & Compression Pipeline
- **Pre-Upload Compression**: `ImageHelper.compressImage` enforces a strict 70% quality compression and bounds dimensions to 1024x1024, shrinking multi-megabyte mobile camera captures down to ~150-300KB before cloud transmission.
- **Upload Hard Limit**: `UploadController` enforces a client-side 10MB file barrier to protect student cellular bandwidth and storage quotas.
- **Image Caching in UI**: All remote graphics and user avatars utilize `CachedNetworkImage` paired with disk cache limits and shimmer placeholding.

### Database Query Optimization (RPCs & Realtime)
- **Atomic Counter RPCs**: Counter modifications are delegated to PostgreSQL server functions (`increment_likes`, `decrement_likes`, etc.). This shifts computation to the database engine, avoiding client-side race conditions and reducing payload size to a single lightweight RPC response.
- **Scoped Subscriptions**: Postgres Realtime is selectively attached to active channels (`public:documents`), ensuring that web socket streams are managed cleanly without leaking memory or battery in the background.

---

## 4. UI/UX & Design Architecture

### Material 3 & Modern Aesthetics
- **Design Paradigm**: Strict Material 3 design system augmented with subtle Glassmorphism.
- **Color Scheme**: Rebranded to "Premium Deep Blue" (`#0D47A1`) with gold accents (`#B8860B`) designating verified official college updates and admin badges.
- **Modern Color Standards**: Clean, zero-warning compliance using modern Flutter color APIs (`.withValues(alpha: ...)`) instead of deprecated `.withOpacity()`.

### Glassmorphic Elements
- The persistent navigation footer (`BottomFooter`) and modal dialogs incorporate custom blur filters (`BackdropFilter`) layered over translucent surfaces (`Colors.white.withValues(alpha: 0.15)` or dark overlays) to create depth without sacrificing legibility or GPU frame rates.

### Visual State Feedback
- **Skeleton Shimmers**: Asynchronous loads in `HomeDocumentSection` display animated shimmer skeletons matching the exact dimensions of `DocumentCard`.
- **Lottie Micro-interactions**: Smooth vector animations in `assets/animations/notes.json` communicate empty states and confirmation feedback.

---

## 5. Security & Backend Audit

### Supabase Row Level Security (RLS)
The database enforces Row Level Security across all public tables in `SUPABASE_SCHEMA.sql`:

1. **`profiles` Table**:
   - `SELECT`: Allowed for all authenticated and anonymous clients (`USING (true)`).
   - `INSERT`: Strictly restricted to the authenticated user matching their own UID (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Owner-only update policy (`USING (auth.uid() = id)`).
   - **Privilege Escalation Defense**: `is_admin` cannot be escalated arbitrarily by users; admin promotion is guarded by backend verification triggers.

2. **`documents` Table**:
   - `SELECT`: Public access for community visibility (`USING (true)`).
   - `INSERT`: Verified author check (`WITH CHECK (auth.uid() = user_id)`).
   - `UPDATE / DELETE`: Only author (`USING (auth.uid() = user_id)`) or authorized administrators.
   - **Official Announcements**: The `is_official` column is protected; only profiles with `is_admin = true` can flag posts as official.

3. **`comments` & `interactions` Tables**:
   - Enforce author checks on creation (`auth.uid() = user_id`).
   - Cascade delete rules prevent orphaned comments or interaction records when documents are deleted.

4. **`notifications` Table**:
   - `SELECT`: Receiver read-only access (`USING (auth.uid() = receiver_id)`), preventing unauthorized inspection of peer notification feeds.

### Authentication & Token Security
- **JWT Lifecycles**: Auth tokens are issued and refreshed automatically by Supabase Auth (GoTrue).
- **Session Reset**: `AuthController.logout()` performs both a server-side `supabase.auth.signOut()` and a synchronous purge of local Hive storage (`HiveBoxes.resetUser()`), ensuring that no residual session tokens or profile identifiers linger on shared devices.

### Storage Bucket Policies
- Document assets and thumbnails uploaded to Supabase Storage are governed by bucket security policies, restricting upload paths to the authenticated user's folder (`/documents/{user_id}/*`).

---

## 6. Developer Guide & Maintenance Manual

### Prerequisites & Toolchain
- **Flutter SDK**: `^3.24.0` (Stable channel).
- **Dart SDK**: `^3.5.4` (Compatible with modern `.withValues(alpha: ...)` APIs and Switch `activeThumbColor`).
- **Java / JDK**: `Java 17` (configured in `notehub/android/app/build.gradle`).
- **Android Target**: `compileSdk = 36`, `targetSdk = 36`.

### Project Setup
1. Clone the repository and navigate to the Flutter project:
   ```bash
   cd notehub
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run code analysis (Zero Warnings standard):
   ```bash
   flutter analyze
   ```
4. Run the test suite:
   ```bash
   flutter test
   ```

### Code Style & Maintenance Standards
- **Zero Warnings Standard**: All Dart code must pass `flutter analyze` with 0 errors, 0 warnings, and 0 linter issues.
- **Flow Control**: All `if`, `else`, `for`, and `while` statements must use explicit curly braces (`curly_braces_in_flow_control_structures`).
- **Color Manipulation**: Never use deprecated `.withOpacity()`; always use `.withValues(alpha: ...)`.
- **Switch Widgets**: Use `activeThumbColor` instead of deprecated `activeColor`.
- **Catch Blocks**: Do not leave empty catch blocks without an explicit `// ignore: empty_catches` annotation or proper logging via `debugPrint`.

---
*Maintained and documented by the Engineering Team. Verified with Flutter 3.24+ & Dart 3.5.4+.*
