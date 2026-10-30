# Developer Guide & System Architecture Manual - Serious Study (formerly NoteHub)

This manual provides an exhaustive, developer-centric analysis of the **Serious Study** Android application. It covers system architecture, component file mappings, performance strategies, design/UI paradigms, security audits, and developer QA workflows.

---

## 1. System Overview & Technological Migration

**Serious Study** is a high-performance notes-sharing and academic networking platform tailored for the Mumbai University student community. The application was completely migrated from a legacy Django/MongoDB stack to a modern serverless **Supabase (PostgreSQL)** backend and a **Flutter 3.24+ (Dart SDK ^3.5.4)** reactive frontend.

```
+-----------------------------------------------------------------------------------+
|                                  FLUTTER FRONTEND                                 |
|                                                                                   |
|  +-------------------+     +-----------------------+     +---------------------+  |
|  |     UI Views      | <-> |   GetX Controllers    | <-> |  Hive Local Caching |  |
|  |  (Material 3 &    |     |  (State Management &  |     |  (User & Download   |  |
|  |   Glassmorphism)  |     |    Business Logic)    |     |     Boxes)          |  |
|  +-------------------+     +-----------------------+     +---------------------+  |
|                                        |                                          |
+----------------------------------------|------------------------------------------+
                                         | Supabase SDK / Dio
                                         v
+-----------------------------------------------------------------------------------+
|                             SUPABASE BACKEND (PostgreSQL)                         |
|                                                                                   |
|  +-------------------+     +-----------------------+     +---------------------+  |
|  |   Supabase Auth   |     |   Row Level Security  |     |  PostgreSQL RPCs    |  |
|  |    (JWT / OAuth)  |     |   (RLS Table Policies)|     | (Atomic Functions)  |  |
|  +-------------------+     +-----------------------+     +---------------------+  |
|  +-------------------+     +-----------------------+     +---------------------+  |
|  | Postgres Realtime |     |   Supabase Storage    |     | Triggers & Security |  |
|  |  (Live Pub/Sub)   |     | (Buckets & Thumbnails)|     | (Definer Functions) |  |
|  +-------------------+     +-----------------------+     +---------------------+  |
+-----------------------------------------------------------------------------------+
```

---

## 2. Architecture & File Component Mapping

The codebase enforces a decoupled Model-View-Controller (MVC) architecture with GetX state management. Below is the file-by-file mapping of the codebase components:

### 2.1 State Controllers (`notehub/lib/controller/`)
- **`auth_controller.dart`**: Manages user authentication via Supabase Auth (email/password login, registration with custom user metadata, profile creation, session sync with Hive `userBox`).
- **`document_controller.dart`**: Manages note and tweet document lifecycles, optimistic interaction state updates (likes, dislikes, bookmarks), atomic PostgreSQL RPC calls (`increment_likes`, `decrement_likes`), document downloading, and local feed syncing.
- **`home_controller.dart`**: Oversees the primary content feed. Implements batching (50 documents per query), sticky sorting (official notices pinned first), real-time Postgres changes via `supabase.channel('public:documents').onPostgresChanges`, and fetching top 20 official updates via `fetchOfficialUpdates()`.
- **`upload_controller.dart`**: Manages document uploads (direct file uploads or external Google Drive/Mega URLs). Enforces a 10MB size limit on direct uploads and compresses thumbnail images via `ImageHelper`.
- **`profile_controller.dart` & `profile_user_controller.dart`**: Handles user profile details, tabbed document feeds (Uploaded, Liked, Bookmarked), and follower/following metrics.
- **`comment_controller.dart`**: Controls multi-threaded comment discussions on documents, parent-child nested replies, and automated activity notifications.
- **`notification_controller.dart`**: Manages user-specific notifications and system-wide announcements with live unread indicators.
- **`search_controller.dart`**: Handles reactive search query execution across document titles, topics, and institute filters.
- **`file_controller.dart` & `download_controller.dart`**: Coordinates offline document opening, file caching progress, and Dio download streams.
- **`bottom_navigation_controller.dart`**, **`showcase_controller.dart`**, **`remote_config_controller.dart`**: Tab switching, feature discovery tooltips, and dynamic remote configuration overrides.

### 2.2 UI Views (`notehub/lib/view/`)
- **`splash_screen/splash.dart`**: Handles initial session checks and displays animated brand logos.
- **`auth_screen/login.dart`**: Form interface for registration and authentication with real-time input validation.
- **`home_screen/home.dart` & `widget/`**: Main dashboard containing `HomeHeader`, institute selector, category filters, and document list feeds.
- **`document_screen/document.dart` & `widget/`**: Full document view displaying PDF preview triggers, author info, action bars (like, bookmark, download), and `CommentSection`.
- **`upload_screen/upload_screen.dart` & `widget/`**: Upload form for publishing notes and micro-posts ('tweet'), supporting cover image picking and external URL input.
- **`profile_screen/profile.dart` & `profile_user.dart`**: Personal profile management and public user profile viewing.
- **`official_screen/official_screen.dart`**: Official Mumbai University notices feed.
- **`notification_screen/notifications.dart`**: Central activity feed listing interactions, comments, and global alerts.
- **`settings_screen/about.dart` & `settings_drawer.dart`**: App metadata, developer credits, and account logout options.
- **`widgets/`**: Reusable modular UI components:
  - `document_card.dart` & `post_card.dart`: Rich media post cards with interaction buttons.
  - `admin_badge.dart`: Official/Admin verification badges.
  - `loader.dart`, `toasts.dart`, `refresher_widget.dart`: Visual feedback, liquid pull-to-refresh, and Toastification alerts.

### 2.3 Core System Helpers (`notehub/lib/core/`)
- **`config/color.dart`**: Rebranded Material 3 palette featuring Premium Deep Blue (`#0D47A1`), glassmorphism overlays (`.withValues(alpha: ...)`), and linear gradients.
- **`config/typography.dart`**: Modern typography rules leveraging Google Fonts (Poppins and Roboto).
- **`helper/hive_boxes.dart`**: Centralized Hive storage utility for `userBox` (user session) and `downloadsBox` (downloaded document metadata).
- **`helper/image_helper.dart`**: Image compression logic using `flutter_image_compress` (70% JPEG quality, target resolution 1024x1024).
- **`meta/app_meta.dart`**: Application branding constants and Supabase API credentials.

### 2.4 Data Models (`notehub/lib/model/`)
- **`user_model.dart` & `user_model.g.dart`**: Hive type-adapter annotated entity representing user profile data.
- **`document_model.dart`**: Data model representing notes and tweets (`post_type` = 'note' | 'tweet').
- **`post_model.dart` & `mini_user_model.dart`**: Lightweight representations for social feeds and search user previews.

### 2.5 Services (`notehub/lib/service/`)
- **`file_caching.dart`**: Disk-based file caching manager using `Dio` and `path_provider` to prevent duplicate network downloads.
- **`file_download.dart`**: Asynchronous file downloader providing real-time progress callbacks.
- **`notification_service.dart`**: Android local push notification wrapper powered by `flutter_local_notifications`.

### 2.6 Backend Schema (`SUPABASE_SCHEMA.sql`)
- **Tables**: `profiles`, `documents`, `comments`, `interactions`, `bookmarks`, `notifications`, `followers`, `remote_config`.
- **Realtime Subscriptions**: Enabled for `documents`, `notifications`, `interactions`, `comments`.

---

## 3. In-Depth Performance Analysis

### 3.1 Reactive State & Memory Management
- **GetX State Management**: Controllers utilize reactive variables (`RxBool`, `RxList`, `obs`) to update only specific UI nodes without invalidating the widget tree.
- **Local Hive Caching**: User session metadata and downloaded file lists are stored in local binary NoSQL boxes (`userBox` and `downloadsBox`). App launch profile loading is virtually instant ($0\text{ ms}$ blocking latency).

### 3.2 Network & Database Optimizations
- **Paginated Lazy Loading**: `HomeController` fetches documents in batches of 50 items per network request, minimizing payload size and GPU memory footprint during fast scrolls.
- **Atomic Database Counter RPCs**: Counter operations (`likes_count`, `dislikes_count`) execute atomically inside PostgreSQL via RPC functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`). This eliminates race conditions and avoids transferring entire row payloads across the network.
- **Optimistic UI Updates**: `DocumentController` updates client-side interaction states immediately upon user touch, background-syncing with Supabase to deliver a seamless user experience.

### 3.3 Media & Network Asset Pipeline
- **Image Compression**: `ImageHelper.compressImage()` compresses selected thumbnail images to 70% quality JPEG format with a maximum resolution of 1024x1024 prior to upload.
- **Thumbnail Caching**: Image renders use `CachedNetworkImage` to cache network assets locally, eliminating duplicate HTTP GET requests.
- **Smart File Caching**: `FileCachingService` checks the local temporary directory before downloading document PDFs via Dio.

---

## 4. Design & UX Paradigm

### 4.1 Rebranded Aesthetic
- **Color Scheme**: Modern **Premium Deep Blue** palette (`#0D47A1`), representing academic trust and authority.
- **Glassmorphism**: Semi-transparent UI overlays utilizing modern Dart color opacity (`.withValues(alpha: 0.15)`) coupled with blurred backgrounds in the navigation bar, headers, and floating widgets.
- **Material 3 UI**: Full Material 3 alignment using rounded surfaces, custom elevation, dynamic cards, and custom typography.

### 4.2 Micro-Interactions & Visual Feedback
- **Shimmer Placeholders**: `shimmer` loaders provide visual skeleton feedback while async network calls complete.
- **Lottie Vector Animations**: Custom Lottie animations (`assets/animations/notes.json`) provide feedback for empty search views and zero-state notifications.
- **Custom Toasts**: High-visibility non-blocking feedback messages powered by `toastification`.

---

## 5. Security Audit & Vulnerability Mitigations

### 5.1 Authentication & Password Safety
- **JWT Authentication**: Replaced legacy session-less Auth with Supabase Auth standard JSON Web Tokens (JWT).
- **Secure Password Hashing**: Passwords are managed securely by Supabase using industry-standard Bcrypt/Argon2 hashing. Plaintext passwords are never stored or transmitted.

### 5.2 Row Level Security (RLS)
Row Level Security is strictly enabled across all PostgreSQL tables in `SUPABASE_SCHEMA.sql`:
- **`profiles`**: Public `SELECT`; `INSERT` and `UPDATE` restricted strictly to `auth.uid() = id`.
- **`documents`**: Public `SELECT`; `INSERT` restricted to `auth.uid() = user_id`; `UPDATE`/`DELETE` restricted to the document owner or an authenticated admin.
- **`notifications` & `bookmarks`**: Restricted so users can only `SELECT` or modify their own private records (`auth.uid() = receiver_id` or `auth.uid() = user_id`).

### 5.3 Privilege Escalation & Defenses
- **Profile Escalation Defense**: RLS `UPDATE` policies prevent users from modifying their own `is_admin` column:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (
      auth.uid() = id AND
      is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
    );
  ```
- **Official Status Escalation Defense**: Setting `is_official = true` on documents is protected by the `ensure_official_permission` database trigger, which verifies that `(SELECT is_admin FROM public.profiles WHERE id = auth.uid())` is `true`.
- **Search-Path Hijacking Defense**: Database RPC functions specify an explicit `SET search_path = public` to prevent search-path hijacking.

---

## 6. Developer Setup, Build Specifications & Maintenance QA

### 6.1 Requirements & Prerequisites
- **Flutter SDK**: `^3.24.0`
- **Dart SDK**: `^3.5.4`

### 6.2 Android Platform Build Configuration (`notehub/android/app/build.gradle`)
- **`compileSdk`**: `36`
- **`targetSdk`**: `36`
- **Java Compatibility**: `Java 17` (`sourceCompatibility` and `targetCompatibility`)
- **MultiDex**: `multiDexEnabled true`
- **Core Library Desugaring**: Enabled to support `flutter_local_notifications` on older Android API levels.

### 6.3 Zero Warnings Quality Assurance Standard
The project strictly enforces a **Zero Warnings** policy under `flutter analyze`:
- **Modern Color APIs**: All deprecated `.withOpacity(x)` calls are replaced with `.withValues(alpha: x)`.
- **Switch Controls**: Switch components use `activeThumbColor` instead of deprecated `activeColor`.
- **Flow Control Braces**: All `if/else` statements use explicit curly braces (`curly_braces_in_flow_control_structures`).
- **Silent Catch Blocks**: Any intended silent error catches use `// ignore: empty_catches` on its own line inside the block to preserve syntax integrity.

### 6.4 Verification Commands
Developers must verify code quality using the following commands inside `notehub/`:

```bash
# Execute static lint analysis
flutter analyze

# Execute test suite
flutter test
```

---
*Maintained and verified by Jules, AI Software Engineer.*
