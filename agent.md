# Developer Technical Manual & System Architecture Analysis - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-centric technical analysis and maintenance manual for **Serious Study** (formerly NoteHub). It details the system architecture, performance optimizations, UI design paradigms, security posture, file-by-file component mappings, and QA protocols following the migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

---

## 1. Executive Summary & Architecture Overview

**Serious Study** is a cross-platform mobile application built with **Flutter 3.24+ (Dart SDK ^3.5.4)** and powered by a serverless **Supabase (PostgreSQL)** backend. It serves the Mumbai University student community by enabling seamless notes sharing, peer-to-peer interactions, academic announcements, and resource discovery.

```
+-------------------------------------------------------------------------+
|                        FLUTTER CLIENT APPLICATION                       |
|                                                                         |
|   +-----------------------+   +-------------------+   +-------------+   |
|   |   GetX Controllers    |   |   Hive Storage    |   |  UI Views   |   |
|   | (State & Logic Layer) |<->| (Local User/Docs) |<->| (M3/Glass)  |   |
|   +-----------------------+   +-------------------+   +-------------+   |
+-------------------------------------------------------------------------+
                                    |
                            HTTPS / WSS (JWT)
                                    v
+-------------------------------------------------------------------------+
|                            SUPABASE BACKEND                             |
|                                                                         |
|   +-----------------------+   +-------------------+   +-------------+   |
|   |     Supabase Auth     |   | PostgreSQL DB     |   | Object      |   |
|   |    (JWT / Argon2)     |   | (RLS / RPCs)      |   | Storage     |   |
|   +-----------------------+   +-------------------+   +-------------+   |
+-------------------------------------------------------------------------+
```

---

## 2. File-by-File & Directory Component Mappings

### 2.1 Logic & Controllers (`notehub/lib/controller/`)
- **`auth_controller.dart`**: Manages user session lifecycle, login, registration, email validation, default institute fallback ("Mumbai University"), and profile syncing into `HiveBoxes`.
- **`document_controller.dart`**: Handles note fetching, optimistic UI updates for likes/dislikes/bookmarks, RPC atomic counter invocations (`increment_likes`, `decrement_likes`, etc.), document deletions, and external URL launching. Synchronizes state with `HomeController`.
- **`home_controller.dart`**: Implements real-time feed updates via Postgres Realtime subscriptions (`supabase.channel('public:documents')`), document batching (limit: 50), and official feed queries (top 20 documents).
- **`upload_controller.dart`**: Enforces content validation, file size checks (10MB maximum), image compression integration, external links parsing, and admin-restricted "Official Content" toggling.
- **`profile_controller.dart` & `profile_user_controller.dart`**: Fetches user metadata, handles follower/following relationships, and manages user showcase data.
- **`comment_controller.dart`**: Manages nested hierarchical comment trees, replies (`parent_id`), and comment deletion permissions.
- **`notification_controller.dart`**: Fetches unread notifications, marks alerts as read, and syncs notification items.
- **`download_controller.dart` & `file_controller.dart`**: Oversees offline document downloads and local filesystem caching metadata in Hive.
- **`search_controller.dart`**: Filters documents and user profiles by query terms, academic topics, or categories.
- **`bottom_navigation_controller.dart`**: Handles root tab navigation across Home, Official, Search, Upload, and Profile.

### 2.2 Core Infrastructure (`notehub/lib/core/`)
- **`config/color.dart`**: Primary design tokens including Premium Deep Blue (`#0D47A1`), glassmorphism linear gradients (`AppGradients.glassGradient`), and color helper utilities updated to `.withValues(alpha: ...)`.
- **`config/typography.dart`**: Standardized Material 3 text styles (`AppTypography`).
- **`helper/hive_boxes.dart`**: Manages local NoSQL storage boxes (`userBox`, `downloadsBox`) for persistent session metadata and offline file tracking.
- **`helper/image_helper.dart`**: Provides JPEG image compression (quality: 70%, max dimensions: 1024x1024) via `flutter_image_compress`.
- **`meta/app_meta.dart`**: Application branding constants, version numbers, and Supabase client credentials.

### 2.3 Data Models (`notehub/lib/model/`)
- **`user_model.dart`**: Entity model representing user profiles, counts (documents, followers, following), and `is_admin` flags.
- **`document_model.dart`**: Primary model for notes and tweets, capturing metadata, interaction flags (`isLiked`, `isDisliked`, `isBookmarked`), content URLs, and official status.
- **`post_model.dart` & `mini_user_model.dart`**: Compact data representations for feeds and commenter summaries.

### 2.4 Service Layer (`notehub/lib/service/`)
- **`file_caching.dart`**: Manages filesystem caching for media assets using Dio and path provider utilities.
- **`file_download.dart`**: Downloads files locally with `Dio` and emits device notifications via `flutter_local_notifications`.
- **`notification_service.dart`**: Configures local push channels for download progress and platform interactions.

### 2.5 Presentation Layer (`notehub/lib/view/`)
- **`auth_screen/`**: `login.dart` and login/signup form widgets with input validation.
- **`home_screen/`**: Main document feed displaying `HomeHeader` and document cards.
- **`document_screen/`**: Detailed view for notes featuring `CommentSection` and `CommentTile` hierarchy.
- **`upload_screen/`**: File and link sharing form featuring `UploadForm` with administrative official toggles (`activeThumbColor`).
- **`profile_screen/`**: User profiles with `ProfileHeader`, `FollowerWidget`, and `ProfileShowcase`.
- **`official_screen/`**: Verified university updates feed for official announcements.
- **`notification_screen/`**: User interaction feed displaying activity logs.
- **`widgets/`**: Reusable components (`AdminBadge`, `DocumentCard`, `PostCard`, `PrimaryButton`, `RefresherWidget`).

### 2.6 Database Backend (`SUPABASE_SCHEMA.sql`)
- **Tables**: `profiles`, `documents`, `comments`, `interactions`, `bookmarks`, `notifications`, `followers`, `remote_config`.
- **Row Level Security (RLS)**: Enforces access restrictions across all database tables.
- **RPCs**: Atomic functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`) with explicit `SET search_path = public`.

### 2.7 Android Build Settings (`notehub/android/app/build.gradle`)
- Target/Compile SDK: `36`
- JDK Version: `Java 17` compatibility
- Support features: `multiDexEnabled true` and `coreLibraryDesugaring` (`com.android.tools:desugar_jdk_libs:2.1.4`) for notification plugin compatibility.

---

## 3. Performance Analysis

| Area | Implementation Details | Performance Gain |
| :--- | :--- | :--- |
| **State Management** | **GetX Reactive Observables (`.obs`)** | Eliminates full widget tree re-renders by binding updates strictly to modified reactive nodes. |
| **Local Persistent Caching** | **Hive NoSQL Key-Value Store** (`userBox`) | Provides instant application startup without waiting for network profile fetches. |
| **Media Compression** | **`flutter_image_compress`** (JPEG, quality: 70%, 1024x1024) | Reduces uploaded cover image payloads by up to 80%, saving user bandwidth. |
| **Image Caching** | **`cached_network_image`** | Caches network thumbnails on disk, eliminating redundant image downloads in feed scrolls. |
| **Atomic Database Counters** | **PostgreSQL Stored Functions (`RPCs`)** | Prevents race conditions during concurrent likes/bookmarks and minimizes payload size. |
| **Data Batching** | **PostgreSQL Query Limits** (50 per batch) | Reduces initial API payload size and speeds up feed rendering. |

---

## 4. Design & UI/UX Analysis

- **Visual Paradigm**: Implements **Material 3** coupled with **Glassmorphism** overlays (`AppGradients.glassGradient`).
- **Color Palette**: Rebranded to **Premium Deep Blue** (`#0D47A1`) with gold accents (`#FFD700`) for official and administrative components.
- **Color API Modernization**: All visual alpha channels utilize the Flutter 3.24+ `.withValues(alpha: ...)` API to ensure precision.
- **Perceived Latency Control**: Integrated shimmer placeholders (`shimmer` package) deliver immediate layout feedback during asynchronous queries.
- **Administrative Aesthetics**: Distinct `AdminBadge` widgets with gold linear gradients (`Color(0xFFFFD700)` to `Color(0xFFFFA500)`).

---

## 5. Security Analysis & Vulnerability Audit

```
+--------------------------------------------------------------------------+
|                          SUPABASE SECURITY LAYER                         |
|                                                                          |
|   [ User Request ] -> [ JWT Auth Header ] -> [ RLS Policy Engine ]       |
|                                                      |                   |
|                                       +--------------+--------------+    |
|                                       |                             |    |
|                                  (Authorized)                 (Unauthorized)
|                                       v                             v    |
|                              [ SQL / RPC Execution ]         [ HTTP 403 ]|
+--------------------------------------------------------------------------+
```

### 5.1 Authentication & Password Hashing
- Replaced custom session handling with **Supabase Auth (JWT)**.
- Passwords are encrypted using industry-standard hashing algorithms (**Argon2 / Bcrypt**).

### 5.2 Row Level Security (RLS) Audit
Every table in `SUPABASE_SCHEMA.sql` enforces active RLS policies:
- **`profiles`**: Public read access; `UPDATE` allowed only when `auth.uid() = id`.
- **`documents`**: Public read access; `INSERT` allowed with `auth.uid() = user_id`. Admin update policies verify `is_admin = true` from `public.profiles`.
- **`notifications` & `bookmarks`**: Restricted strictly to the owner (`auth.uid() = receiver_id` / `user_id`).

### 5.3 Privilege Escalation Safeguards
- **Admin Verification**: The `profiles` update policy prevents users from escalating their own `is_admin` privileges by validating changes against current profile claims.
- **Official Status Control**: Setting `is_official = true` in the `documents` table is restricted via database checks and triggers (`ensure_official_permission`) ensuring only verified administrators can flag content as official.
- **Search Path Isolation**: All PostgreSQL RPC functions specify `SET search_path = public` to protect against search-path hijacking.

---

## 6. Development, Maintenance & QA Manual

### 6.1 Prerequisites
- **Flutter SDK**: `>= 3.24.0`
- **Dart SDK**: `>= 3.5.4`
- **Java Development Kit**: `Java 17`
- **Android SDK**: Target/Compile SDK `36`

### 6.2 Code Quality & Static Analysis Guidelines
The repository strictly enforces a **Zero Warnings** static analysis standard.

To verify compliance:
```bash
cd notehub
flutter analyze
```

### 6.3 Automated Testing Protocol
Run the test suite prior to committing code:
```bash
cd notehub
flutter test
```

---
*Maintained and documented by Jules, AI Software Engineer.*
