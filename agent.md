# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides an exhaustive, developer-centric analysis of the **Serious Study** Android application. It serves as the primary technical blueprint and system manual, covering architecture, file-by-file component mappings, performance optimizations, design systems, security paradigms, and developer QA procedures following its complete migration from a legacy Django/MongoDB backend to a serverless **Supabase** infrastructure.

---

## 1. Executive Summary & System Stack

**Serious Study** is a premium notes-sharing and academic networking platform tailored for the Mumbai University student community. The application bridges peer-to-peer resource sharing, official university announcements, and short academic updates ("tweets").

### Core System Stack
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management**: `GetX` (Reactive dependency injection, controller lifecycle, and observable bindings).
- **Local Persistent Storage**: `Hive` (High-performance NoSQL key-value store for session persistence and offline caching).
- **Backend & Serverless Infrastructure**: `Supabase` (PostgreSQL relational database with Row Level Security, Managed JWT Auth, Realtime Postgres Changes, and S3-compatible Object Storage).
- **Networking & Transfers**: `Supabase Flutter SDK` for database/auth operations & `Dio` for low-level file downloading and chunk caching.
- **Media Compression**: `flutter_image_compress` for client-side asset optimization before cloud transmission.

---

## 2. Architecture & File-by-File Component Mapping

Serious Study follows a decoupled, reactive **Model-View-Controller (MVC)** architectural pattern. Business logic and network calls are encapsulated within GetX Controllers, keeping UI Views purely declarative.

```
                  ┌─────────────────────────────────────────┐
                  │                UI Layer                 │
                  │   (lib/view/ - Screens & Widgets)       │
                  └────────────────────┬────────────────────┘
                                       │ (Listens via Obx/GetBuilder)
                                       ▼
                  ┌─────────────────────────────────────────┐
                  │            Controller Layer             │
                  │      (lib/controller/ - GetxController) │
                  └──────┬───────────────────────────┬──────┘
                         │                           │
          (API Calls)    │                           │ (Cache Read/Write)
                         ▼                           ▼
      ┌──────────────────────────────┐    ┌──────────────────────────┐
      │       Supabase Backend       │    │     Hive Storage Box     │
      │ (PostgreSQL, Auth, Storage)  │    │ (lib/core/helper/hive)   │
      └──────────────────────────────┘    └──────────────────────────┘
```

---

### File-by-File Technical Directory Breakdown

#### Core Configurations & Helpers (`lib/core/`)
- **`lib/main.dart`**: Entry point of the Flutter application. Initializes Supabase client with URL and Anon key from `AppMetaData`, initializes Hive boxes (`userBox`, `downloadsBox`), and registers top-level GetX controllers (`AuthController`, `ProfileController`).
- **`lib/layout.dart`**: Root navigation shell wrapping bottom footer tabs. Houses the global reactive tab switching logic using `BottomNavigationController`.
- **`lib/core/config/color.dart`**: Centralized color palette. Defines `PrimaryColor.shade500` ("Premium Deep Blue" `#0D47A1`), danger colors, grayscale tokens, and modern `AppGradients` (glassmorphism gradient and primary theme gradient).
- **`lib/core/config/typography.dart`**: Text design tokens (`AppTypography`) for heading, subhead, and body hierarchy across the app.
- **`lib/core/meta/app_meta.dart`**: Centralized metadata holding application name ("Serious Study"), Supabase connection endpoints, API keys, and default fallback URLs.
- **`lib/core/helper/hive_boxes.dart`**: High-performance NoSQL access wrapper. Manages `userBox` (storing `UserModel` data) and `downloadsBox` (storing downloaded file metadata). Provides static accessors for `userId`, `username`, and `user`.
- **`lib/core/helper/image_helper.dart`**: Image processing pipeline. Uses `FlutterImageCompress` to compress uploaded cover images to JPEG at 70% quality, reducing payload size by up to 80%.
- **`lib/core/helper/custom_icon.dart`**: Custom SVG icon renderer (`CustomIcon`) and circle avatar fallback renderer (`CustomAvatar`).

---

#### Business Logic Controllers (`lib/controller/`)
- **`lib/controller/auth_controller.dart`**: Manages email/password authentication, registration with Mumbai University metadata, session initialization, and sync with `userBox`. Includes automated profile row upsert upon registration.
- **`lib/controller/home_controller.dart`**: Handles main feed generation, infinite scrolling batch loads (limit 50), category filtering (Notes vs. Tweets), sticky sort options, and official update feeds (`fetchOfficialUpdates`). Integrates Supabase Realtime changes for post stream updates.
- **`lib/controller/document_controller.dart`**: Manages single note/tweet operations: optimistic like/dislike toggling, bookmarking, file launcher execution, and document deletion with storage cleanup. Synchronizes state back to `HomeController` via `_syncWithHome()`.
- **`lib/controller/upload_controller.dart`**: Multi-part upload workflow manager. Validates inputs, blocks files exceeding 10MB, compresses image covers, uploads binaries to Supabase Storage `documents` bucket, and inserts database records.
- **`lib/controller/profile_controller.dart`**: Controls current logged-in user profile view, document showcase tabs, saved bookmarks, and profile editing (avatar update, display name, bio, institute).
- **`lib/controller/profile_user_controller.dart`**: Handles peer user profiles (`ProfileUser`), follow/unfollow interactions, and follower count updates.
- **`lib/controller/comment_controller.dart`**: Manages flat and nested comment threads under documents (`fetchComments`, `postComment`, `deleteComment`). Supports nested comment replies via `parent_id`.
- **`lib/controller/notification_controller.dart`**: Real-time activity feed controller (`fetchNotifications`, `markAsRead`). Filters notifications by recipient ID or global announcements.
- **`lib/controller/search_controller.dart`**: Reactive search query engine querying `documents` by title, topic, or description.
- **`lib/controller/showcase_controller.dart`**: Tabbed post renderer for user profile screens (Uploaded Notes, Short Updates, Bookmarked Resources).
- **`lib/controller/connection_controller.dart`**: Handles follower/following list views and social connection discovery.
- **`lib/controller/download_controller.dart`**: Offline downloaded resources manager querying `downloadsBox` metadata.
- **`lib/controller/remote_config_controller.dart`**: Fetches dynamic key-value parameters from Supabase `remote_config` table for feature flags without requiring app rebuilds.
- **`lib/controller/bottom_navigation_controller.dart`**: Observable reactive index holder for bottom navigation tabs.
- **`lib/controller/file_controller.dart` & `post_controller.dart`**: Specialized helpers for direct file viewing and post creation handling.

---

#### Models (`lib/model/`)
- **`lib/model/user_model.dart` & `user_model.g.dart`**: Reactive user entity with Hive TypeAdapter `@HiveType(typeId: 0)` for local storage binary serialization.
- **`lib/model/document_model.dart`**: Document/post entity mapping fields from Supabase relational queries (`id`, `name`, `topic`, `likes_count`, `is_official`, `post_type`, `is_external`, `document_url`).
- **`lib/model/mini_user_model.dart`**: Compact user representation for follower/following lists and comment attribution.
- **`lib/model/post_model.dart`**: Model for tweet-style academic announcements.

---

#### Services (`lib/service/`)
- **`lib/service/file_caching.dart`**: Dio-powered file caching engine. Checks local temporary directory for pre-existing files before initiating network transfers.
- **`lib/service/file_download.dart`**: File downloader with progress notification integration (`FlutterLocalNotificationsPlugin`). Opens downloaded PDF/Doc files upon completion via `open_file`.
- **`lib/service/notification_service.dart`**: Android local push notification service wrapper.

---

#### User Interface Screens & Widgets (`lib/view/`)
- **`lib/view/splash_screen/splash.dart`**: Lottie-animated splash screen checking session validity in Hive to route to `Layout` or `Login`.
- **`lib/view/auth_screen/`**: Authentication screen (`login.dart`), custom form validation (`login_form.dart`), header typography (`login_header.dart`).
- **`lib/view/home_screen/`**: Main feed view (`home.dart`), search/header widget (`home_header.dart`), document feed list (`home_document_section.dart`).
- **`lib/view/official_screen/official_screen.dart`**: Filtered feed dedicated strictly to official Mumbai University circulars (`is_official = true`).
- **`lib/view/document_screen/`**: Detailed note viewer (`document.dart`), nested comment section (`comment_section.dart`), individual comment tile (`comment_tile.dart`), cover viewer (`icon_viewer.dart`).
- **`lib/view/profile_screen/`**: Own profile (`profile.dart`), peer profile (`profile_user.dart`), follower metrics (`follower_widget.dart`), edit profile modal (`edit_profile_dialog.dart`), post grid renderer (`post_renderer.dart`).
- **`lib/view/upload_screen/`**: Resource uploader (`upload_screen.dart`), upload input fields (`upload_form.dart`), official toggle switch (`activeThumbColor: const Color(0xFFB8860B)`).
- **`lib/view/widgets/`**: Reusable Material 3 components:
  - `document_card.dart`: Primary card for notes and direct file downloads.
  - `post_card.dart`: Rich media post card with glassmorphic bottom bar.
  - `admin_badge.dart`: Premium gold gradient badge (`#FFD700` to `#FFA500`) rendered for administrative users.
  - `primary_button.dart`, `secondary_button.dart`, `normal_button.dart`, `option_button.dart`: Standardized button hierarchy.
  - `refresher_widget.dart`: Pull-to-refresh container.
  - `toasts.dart`: Global Toastification feedback alerts.

---

#### Android Engine Configuration (`android/`)
- **`android/app/build.gradle`**: Configured for `compileSdk 36`, `Java 17` compatibility, `multiDexEnabled true`, and `coreLibraryDesugaring` enabled for local notification plugin compatibility.
- **`android/app/src/main/AndroidManifest.xml`**: Configured with internet, storage read/write, and notification permissions. Defines deep-linking URL schemes (`io.supabase.flutternotehub://login-callback`).

---

#### Database Engine Schema & RPC Functions (`SUPABASE_SCHEMA.sql`)
- **`profiles`**: Stores student profiles, university credentials, admin flag (`is_admin`), followers/following counts.
- **`documents`**: Primary content storage for notes and tweets (`post_type IN ('note', 'tweet')`), with support for direct uploads or external links (`is_external`), and official status (`is_official`).
- **`comments`**: Comment threads supporting nested replies via `parent_id REFERENCES comments(id)`.
- **`interactions`**: Tracks user likes/dislikes with unique constraint `UNIQUE(document_id, user_id)`.
- **`bookmarks`**: User saved resources with unique constraint `UNIQUE(document_id, user_id)`.
- **`notifications`**: Activity feed items (`like`, `comment`, `follow`, `reply`, `announcement`).
- **`followers`**: Social graph links with constraint `UNIQUE(follower_id, following_id)`.
- **PostgreSQL Atomic RPC Functions**:
  - `increment_likes(doc_id)`, `decrement_likes(doc_id)`
  - `increment_dislikes(doc_id)`, `decrement_dislikes(doc_id)`
  - `increment_bookmarks(doc_id)`, `decrement_bookmarks(doc_id)`
  Functions execute with `SECURITY DEFINER` and explicit `SET search_path = public` to guarantee concurrency safety and avoid race conditions.

---

## 3. Performance Analysis

From a developer's perspective, the application is engineered for maximum responsiveness and minimal memory usage on mobile devices:

1. **GetX State Efficiency**: UI widgets utilize targeted rebuilds through `Obx` and `GetBuilder`. Unnecessary global widget tree re-renders are completely avoided.
2. **Instant App Launch via Hive Caching**: User session data and profile info are loaded directly from memory via `HiveBoxes.userBox` at startup. The app presents user data instantly without blocking on a network fetch.
3. **Media Compression & Asset Caching**:
   - `cached_network_image` prevents re-downloading document thumbnails across feed scrolls.
   - `flutter_image_compress` reduces uploaded covers to JPEG format with 70% quality, preventing unnecessary bandwidth consumption.
4. **Database Counter Operations (RPCs)**: Atomic counters for likes and dislikes run inside PostgreSQL stored functions (`increment_likes`), eliminating client-side fetch-then-write race conditions and minimizing payload sizes.
5. **Optimistic UI Updates**: Interactions like liking, disliking, and bookmarking update UI state immediately on tap, reverting smoothly only if the background Supabase network call fails.
6. **Batched Feed Querying**: `HomeController` limits document feed fetches to 50 items per query batch, keeping payload sizes manageable over cellular data.

---

## 4. Design & Aesthetic Systems

The application implements a modern **Material 3** baseline combined with custom **Glassmorphism** depth styling:

- **Rebranded Color System**: Replaced generic legacy colors with **Premium Deep Blue** (`#0D47A1` primary) to reflect academic authority. Admin content and badges feature a **Premium Gold** gradient (`#FFD700` to `#FFA500`).
- **Glassmorphic Overlays**: Bottom navigation bars and rich post cards utilize semi-transparent white fills (`Colors.white.withValues(alpha: 0.15)`) with backdrop blur filters (`GlassmorphicContainer`) for modern visual layering.
- **Micro-Interactions & State Feedback**:
  - Heart icon scale animations (`ScaleTransition` with `AnimationController`) trigger upon liking.
  - Shimmer placeholder containers (`shimmer`) mask asynchronous data fetching states.
  - Lottie vector animations (`lottie`) handle empty search states and upload confirmation feedback.

---

## 5. Security Analysis & Mitigation Audit

The serverless migration resolved all legacy vulnerabilities present in the old Django stack:

```
+--------------------------+------------------------------------+---------------------------------------+
| Security Domain          | Legacy Django Stack                | Modern Supabase Stack                 |
+--------------------------+------------------------------------+---------------------------------------+
| Password Storage         | Plaintext / Weak Hashing           | Argon2 / Bcrypt via Supabase Auth     |
| Session Management       | Custom Session Strings             | Managed JWT (JSON Web Tokens)         |
| Database Access          | Open REST Endpoints                | PostgreSQL Row Level Security (RLS)  |
| Privilege Escalation     | Client-side role flag mutation     | PostgreSQL Trigger & RLS WITH CHECK   |
| Function Execution       | Direct DB Updates                  | SECURITY DEFINER Functions with Path |
| Object Storage Access    | Unrestricted Direct File Links     | Storage RLS & Signed Access Policies  |
+--------------------------+------------------------------------+---------------------------------------+
```

### Critical Security Implementation Details
1. **Row Level Security (RLS)**: Strictly enforced across every database table:
   - `profiles`: SELECT is public; UPDATE requires `auth.uid() = id` with a `WITH CHECK` clause verifying `is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())` to prevent self-promotion to admin status.
   - `documents`: SELECT is public; INSERT requires `auth.uid() = user_id`; UPDATE/DELETE restricted to owner.
   - `notifications` & `bookmarks`: Restricted exclusively to receiver or owner (`auth.uid() = receiver_id`).
2. **Preventing Official Verification Spoofing**: Setting `is_official = true` on documents is protected at the database level by a trigger (`check_official_permission`) that verifies the calling user's profile has `is_admin = true`.
3. **RPC Function Path Isolation**: All PostgreSQL RPC functions specify `SET search_path = public` to protect against search-path hijacking exploits.

---

## 6. Developer QA & Maintenance Standards

To maintain code health and CI/CD compliance, developers must adhere to the following standards:

### Prerequisites
- **Flutter SDK**: ^3.24.0
- **Dart SDK**: ^3.5.4

### "Zero Warnings" Code Quality Enforcement
All code must pass `flutter analyze` without warnings or deprecations:
1. **Modern Color Opacities**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
2. **Switch Controls**: Use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Structures**: Always enclose `if` / `else` statements in curly braces `{}`.
4. **Silent Exception Handling**: Annotations like `// ignore: empty_catches` must be placed on their own line inside the catch block to prevent syntax corruption.

### Verification Commands
```bash
# Run static code analysis (Must report "No issues found!")
cd notehub && flutter analyze

# Run unit and widget test suite
cd notehub && flutter test
```

---
*Maintained and Verified by Jules, AI Software Engineer.*
