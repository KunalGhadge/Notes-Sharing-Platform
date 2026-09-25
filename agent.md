# Technical Architecture & Developer Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive developer-centric analysis of the **Serious Study** Android application, detailing its architecture, component mappings across all codebase files, performance strategies, design system, security implementations, and developer QA procedures.

---

## 1. Executive Summary & System Architecture

**Serious Study** is a modernized community notes-sharing and academic networking platform tailored for students and faculty at Mumbai University. The platform supports notes and study resource sharing (PDFs, images, external links), short academic updates ("tweets"), peer networking, and administrative official announcements.

### Key Architectural Stack
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **Backend Stack**: Serverless Supabase (PostgreSQL DB, Row Level Security, Supabase Auth with JWT, Supabase Storage, and Realtime Engine).
- **State Management**: GetX reactive architecture (`GetxController`, `Rx`, `Obx`, `GetBuilder`).
- **Local Persistence**: Hive NoSQL key-value caching (`HiveBoxes`).
- **Networking & I/O**: Supabase Flutter SDK, Dio, `path_provider`, and `flutter_local_notifications`.

---

## 2. File-by-File & Component Mapping

### 2.1 Core Utilities (`notehub/lib/core/`)
- `main.dart`: Main application entrypoint. Initializes Supabase client, Hive local boxes, and GetX global bindings.
- `layout.dart`: Main bottom navigation screen holder displaying active tabs with `BottomFooter`.
- `core/meta/app_meta.dart`: Configuration constants containing app metadata, branding names, Supabase endpoint, and public anonymous API key.
- `core/config/color.dart`: Centralized color definitions featuring Premium Deep Blue (`#0D47A1`), Gold (`#FFD700`), grayscale palettes, and modern `.withValues(alpha: ...)` opacity rules.
- `core/config/typography.dart`: Typography scale using Google Fonts Inter for standard text styling.
- `core/helper/hive_boxes.dart`: Hive local storage manager (`userBox`, `downloadsBox`, `userId`, `username`, `setUser`, `resetUser`).
- `core/helper/image_helper.dart`: Media compression utility utilizing `FlutterImageCompress` (quality: 70%, 1024x1024 max dimensions).
- `core/helper/custom_icon.dart`: SVG rendering component using `flutter_svg`.

### 2.2 Business Logic Controllers (`notehub/lib/controller/`)
- `auth_controller.dart`: Manages user authentication (email login, registration with metadata, profile creation/syncing via Hive, and sign-out).
- `document_controller.dart`: Controls note lifecycle. Implements optimistic UI updates for likes/dislikes/bookmarks, calls atomic PostgreSQL RPCs, handles document deletion, and manages external URL opening or local file launching.
- `upload_controller.dart`: Handles multi-part resource uploads and tweet posts. Supports direct file uploads (up to 10MB) or external link submissions (Google Drive/Mega), automatic image compression, and admin official content toggling.
- `home_controller.dart`: Main feed controller. Fetches documents in batches (limit 50), subscribes to `public:documents` Postgres Realtime channel for live updates, and provides filtered official news (`fetchOfficialUpdates`).
- `profile_controller.dart` & `profile_user_controller.dart`: Profile controllers managing user statistics (followers, following, uploaded documents) and peer follow/unfollow toggle actions.
- `comment_controller.dart`: Handles nested commenting threads, reply hierarchies (`parent_id`), comment posting, and administrative comment deletion.
- `connection_controller.dart`: Peer discovery controller providing user searches and connection recommendations.
- `download_controller.dart`: Manages saved offline files and integrates with `downloadsBox` in Hive.
- `notification_controller.dart`: Retrieves personal and global system notifications, providing mark-as-read functionality.
- `search_controller.dart`: Full-text search controller filtering documents and user profiles by query terms.
- `showcase_controller.dart`: Tab filtering controller for profile content ("Uploaded Notes" vs "Saved/Bookmarked").
- `bottom_navigation_controller.dart`: Maintains bottom navigation active index.
- `remote_config_controller.dart`: Fetches dynamic runtime configurations without forcing app re-installs.

### 2.3 Data Models (`notehub/lib/model/`)
- `document_model.dart`: Primary document entity (`documentId`, `username`, `displayName`, `profile`, `name`, `topic`, `description`, `likes`, `dislikes`, `dateOfUpload`, `documentName`, `document`, `isLiked`, `isDisliked`, `isBookmarked`, `isExternal`, `isOfficial`, `postType`).
- `user_model.dart` & `user_model.g.dart`: Hive-serializable model for persistent user profile caching.
- `mini_user_model.dart`: Compact profile entity for lists and connection cards.
- `post_model.dart`: Specialized post data representation.

### 2.4 Services (`notehub/lib/service/`)
- `file_caching.dart`: Local file caching service using Dio and path resolution to prevent duplicate downloads.
- `file_download.dart`: Download manager handling background file downloads and triggering local device notifications via `flutter_local_notifications`.
- `notification_service.dart`: Device notification setup and background channel registration.

### 2.5 User Interface & Components (`notehub/lib/view/`)
- `splash_screen/splash.dart`: Animated Lottie startup splash routing based on Hive session state.
- `auth_screen/login.dart`: Authentication screen supporting login and user sign-up.
- `home_screen/home.dart`: Main dashboard displaying header, official update slider, search bar, and post feed.
- `document_screen/document.dart`: Resource detail view displaying preview, metadata, interaction buttons, and comment section.
- `upload_screen/upload_screen.dart`: Upload interface for note documents and short updates.
- `profile_screen/profile.dart` & `profile_user.dart`: User profile views with stats, showcase tabs, and admin badges.
- `official_screen/official_screen.dart`: Dedicated official announcement feed for verified administrative posts.
- `widgets/`: Reusable UI components (`document_card.dart`, `post_card.dart`, `admin_badge.dart`, `loader.dart`, `refresher_widget.dart`, `toasts.dart`, `primary_button.dart`).

### 2.6 Backend Database Schema (`SUPABASE_SCHEMA.sql`)
- **Tables**: `profiles`, `documents`, `comments`, `interactions`, `bookmarks`, `notifications`, `followers`, `remote_config`.
- **Row Level Security (RLS)**: Enforced policies across all tables restricting update/delete operations to resource owners.
- **PostgreSQL Functions (RPCs)**: `increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`.
- **Security Definer Triggers**: `ensure_official_permission` trigger preventing non-admin users from marking documents as official.

---

## 3. Performance Analysis

1. **Reactive State Management**: GetX controllers separate UI presentation from business logic. Reactive observables (`.obs`, `Obx`, `GetBuilder`) target specific UI widgets during updates, avoiding unnecessary subtree rebuilds.
2. **Hive Local Persistence**: Hive NoSQL key-value storage (`userBox`) ensures immediate session restoration and profile loading upon app launch without blocking on network queries.
3. **Media & File Optimization**:
   - `cached_network_image` caches remote thumbnails to conserve bandwidth and reduce GPU memory usage.
   - `FlutterImageCompress` compresses cover images before uploading to Supabase Storage.
   - Upload limit of 10MB prevents client-side memory overhead during direct file transfers.
4. **Database & Query Efficiency**:
   - Atomic RPC functions perform counter modifications (`likes_count`) directly inside PostgreSQL, eliminating client-side concurrency race conditions.
   - Pagination (limit 50 per batch) prevents fetching massive datasets over mobile networks.
   - Supabase Realtime subscriptions listen to `public:documents` changes, eliminating heavy polling routines.

---

## 4. Design System & UX Analysis

1. **Material 3 & Glassmorphism Paradigm**: Combines clean Material 3 component guidelines with translucent glassmorphic card overlays (`glassmorphism`), soft shadows, and rounded corners (12-24px).
2. **Rebranded Color Palette**:
   - **Primary**: Premium Deep Blue (`#0D47A1`).
   - **Accent**: Gold (`#FFD700`) for official content and administrator badges (`AdminBadge`).
   - **Neutral**: Crisp white and structured dark/light grayscale hierarchy.
3. **Typography**: Google Fonts Inter hierarchy (`AppTypography`) providing structured font weights (300 to 700) and scalable line heights.
4. **Micro-Interactions**:
   - Shimmer loading placeholders (`shimmer`) during network fetches.
   - Spring scale animation (`LikesWithHeart` widget using `AnimationController` and `TweenSequence`) on liking notes.
   - Liquid pull-to-refresh (`liquid_pull_to_refresh`) on feeds.
   - Lottie vector animations for empty search states and onboarding.

---

## 5. Security Audit

1. **Authentication & Session Handling**:
   - Managed JWT authentication via Supabase Auth. Passwords hashed using Argon2/Bcrypt by Supabase Auth engine.
   - Tokens stored securely and refreshed automatically by the Supabase Flutter SDK.
2. **Row Level Security (RLS)**:
   - `profiles`: Public SELECT, INSERT/UPDATE strictly guarded by `auth.uid() = id`. `profiles` UPDATE policy includes a `WITH CHECK` clause ensuring users cannot self-elevate `is_admin`.
   - `documents`: Public SELECT, INSERT/UPDATE/DELETE limited to `auth.uid() = user_id`. Admin policy allows verified admins to manage official flags.
   - `comments`, `interactions`, `bookmarks`, `notifications`, `followers`: Strict user owner checks.
3. **Database Safeguards**:
   - RPC functions defined with explicit `SET search_path = public` to mitigate search-path hijacking.
   - Trigger `ensure_official_permission` verifies `is_admin` status before allowing `is_official = true` on document inserts/updates.
4. **Storage Security**: Supabase Storage bucket policies restrict update and delete actions to the original uploader.

---

## 6. Development, Building & QA Manual

### 6.1 Requirements
- Flutter SDK: 3.24+
- Dart SDK: ^3.5.4
- Android Configuration: `compileSdk 36`, `coreLibraryDesugaring` enabled, Java 17 compatibility (`notehub/android/app/build.gradle`).

### 6.2 Code Quality Standards
- Strict adherence to "Zero Warnings" under `flutter analyze`.
- Flow control statements enclosed with curly braces (`curly_braces_in_flow_control_structures`).
- Modern color opacity usage using `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
- Switch widgets configured with `activeThumbColor`.

### 6.3 QA Commands
```bash
# Verify static code analysis
cd notehub && flutter analyze

# Run unit and widget test suite
cd notehub && flutter test

# Build production Android APK
cd notehub && flutter build apk --release
```

---
*Analyzed and Documented by Jules, AI Software Engineer.*
