# Developer & Technical Architecture Manual — Serious Study (formerly NoteHub)

This document serves as the comprehensive, developer-perspective technical reference manual for the **Serious Study** repository. It details the system architecture, performance engineering, UI/UX design system, security audit, file-by-file component mapping, and quality assurance protocols following the app's migration to a serverless **Supabase** backend.

---

## 1. System Architecture & High-Level Design

Serious Study is an academic notes-sharing and peer networking platform built specifically for the Mumbai University student community. The application uses a decoupled frontend-backend architecture designed for scale, real-time interactivity, and cross-platform compatibility.

```
+-------------------------------------------------------------------+
|                        FLUTTER FRONTEND                           |
|  +---------------------+  +-------------------+  +-------------+  |
|  |   GetX Controllers  |  |  Material 3 Views |  |  Hive Storage| |
|  | (Document, Auth, etc)|  | & Glassmorphism   |  | (User Session)| |
|  +----------+----------+  +---------+---------+  +------+------+  |
+-------------|-----------------------|-------------------|---------+
              |                       |                   |
              | Supabase SDK (JWT)    | HTTP / Dio        | Local Sync
              v                       v                   v
+-------------------------------------------------------------------+
|                        SUPABASE BACKEND                           |
|  +---------------------+  +-------------------+  +-------------+  |
|  |   Supabase Auth     |  | Supabase Storage  |  | PostgreSQL  |  |
|  |   (Bcrypt / Argon2) |  | (Docs & Covers)   |  | (RLS & RPCs)|  |
|  +---------------------+  +-------------------+  +-------------+  |
+-------------------------------------------------------------------+
```

### Tech Stack Breakdown
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management**: **GetX** (`get`) providing reactive variable bindings (`Rx`), dependency injection (`Get.put`, `Get.find`), and declarative routing.
- **Local Persistence**: **Hive** (`hive`, `hive_flutter`) for instant NoSQL local session caching (`userBox`) and downloaded file metadata (`downloadsBox`).
- **Networking & Storage**:
  - **Supabase Flutter SDK** (`supabase_flutter`): Handles authentication, PostgREST queries, PostgreSQL Realtime streams, and RPC calls.
  - **Dio** (`dio`) & **Path Provider** (`path_provider`): Manages background file downloading, HTTP streaming, and local disk caching.
- **Backend Infrastructure**:
  - **Database**: PostgreSQL 15+ hosted on Supabase with Row Level Security (RLS).
  - **Authentication**: Supabase Auth utilizing JWTs (JSON Web Tokens) and secure session refreshes.
  - **Storage**: Supabase Storage Buckets (`documents`) for direct PDF uploads and cover images.

---

## 2. Performance Engineering & Optimizations

### 2.1 Optimistic UI Updates
To eliminate network latency perception during user interactions, controllers implement optimistic state manipulation:
- **Likes & Dislikes**: `DocumentController.toggleLike()` immediately mutates local model fields (`doc.isLiked`, `doc.likes`) and triggers UI re-render (`update()`). It then asynchronously calls the Supabase RPC (`increment_likes` / `decrement_likes`). In case of network failure, state is automatically rolled back and an error toast is displayed.
- **Bookmarks**: `DocumentController.toggleBookmark()` updates local bookmark status instantly before persisting changes to the `bookmarks` table.

### 2.2 Atomic Backend Operations (PostgreSQL RPCs)
Client-side counter mutations in concurrent environments lead to race conditions. Serious Study delegates counter calculations to atomic database RPC functions defined in `SUPABASE_SCHEMA.sql`:
- `increment_likes(doc_id)` / `decrement_likes(doc_id)`
- `increment_dislikes(doc_id)` / `decrement_dislikes(doc_id)`

These functions execute as isolated atomic transactions directly on PostgreSQL.

### 2.3 Data Batching & Sticky Sorting
- **Batching**: `HomeController` fetches posts in batches of 50 (`.range(0, 49)`) to limit initial payload size and reduce network overhead.
- **Sticky Sorting**: The main document feed prioritizes official posts and recent uploads while maintaining scroll position during background updates via `_syncWithHome()`.

### 2.4 Media Compression & Caching
- **Image Compression**: Before uploading cover images, `ImageHelper.compressImage()` uses `flutter_image_compress` to re-encode images to JPEG at 70% quality with a max target resolution of 1024x1024.
- **Network Image Caching**: All feed thumbnails and user avatars utilize `cached_network_image`, storing cached images on local storage to prevent unnecessary HTTP re-downloads.
- **File Caching Service**: `FileCachingService` checks the local temporary directory before triggering network downloads with Dio, eliminating duplicate bandwidth usage.
- **Upload File Limits**: `UploadController` enforces a strict 10MB file limit for direct PDF/document uploads.

---

## 3. UI/UX Design System & Aesthetics

### 3.1 Color System & Theme
The application adopts a **Premium Deep Blue** palette reflecting academic authority and elegance:
- **Primary Color**: `#0D47A1` (`PrimaryColor.shade500` / `shade900`).
- **Accent Gold**: `#FFD700` (`OtherColors.premiumGold`) used for Admin badges and Official verification toggles.
- **Danger Red**: `#FF3728` (`DangerColors.shade500`) for destructive actions (deletions).
- **Gradients**: `AppGradients.premiumGradient` (Deep Blue to Royal Blue) and `AppGradients.glassGradient` for semi-transparent card overlays.

### 3.2 Visual Paradigms
- **Material 3 Integration**: Rounded shapes, modern dialogs (`Get.defaultDialog`), and dynamic switch components (`activeThumbColor`).
- **Glassmorphism**: Bottom Navigation Bar (`BottomFooter`) and feed cards (`PostCard`) utilize semi-transparent white overlays (`.withValues(alpha: ...)`) with blur effects (`glassmorphism` package).
- **Feedback & Loaders**:
  - **Shimmer Effect**: `Shimmer.fromColors()` renders skeleton placeholders in `HomeDocumentSection` during feed loading.
  - **Lottie Vector Animations**: `LottieBuilder.asset` renders vector animations (e.g., `assets/animations/notes.json` on Splash Screen).

---

## 4. Security Architecture & Migration Audit

The migration from legacy Django/MongoDB to Supabase serverless eliminated severe security vulnerabilities:

| Architectural Component | Legacy Implementation | Modern Supabase Architecture |
| :--- | :--- | :--- |
| **Authentication** | Session-less plain text checks | **JWT (JSON Web Tokens)** managed by Supabase Auth |
| **Password Storage** | Insecure / Plain text risk | **Argon2 / Bcrypt** key derivation in database core |
| **Database Access Control** | Unprotected custom REST endpoints | **Row Level Security (RLS)** enforced at engine level |
| **Role Escalation Protection** | Vulnerable client updates | PostgreSQL triggers (`ensure_official_permission`) & RLS `WITH CHECK` clauses |
| **File Storage Permissions** | Publicly accessible links | Managed bucket policies with signed URL support |

### 4.1 Row Level Security (RLS) Deep-Dive
Every table in `SUPABASE_SCHEMA.sql` enforces RLS policies:
1. **`profiles` Table**:
   - `SELECT`: Publicly readable (`FOR SELECT USING (true)`).
   - `UPDATE`: Only the profile owner can update (`FOR UPDATE USING (auth.uid() = id)`).
   - **Privilege Escalation Defense**: RLS `WITH CHECK` clause ensures users cannot self-assign `is_admin = true`.
2. **`documents` Table**:
   - `SELECT`: Publicly readable.
   - `INSERT / UPDATE / DELETE`: Restricted to document owner (`auth.uid() = user_id`).
   - **Admin Trigger Guard**: Setting `is_official = true` requires admin verification enforced by `ensure_official_permission` trigger.
3. **`notifications` Table**:
   - `SELECT`: Strictly scoped to receiver (`auth.uid() = receiver_id`).
4. **RPC Function Security**:
   - Counter RPC functions use `SECURITY DEFINER` with explicit `SET search_path = public` to prevent search-path hijacking attacks.

---

## 5. Codebase Component Mapping

### 5.1 System Entry & Core (`lib/core/` & Root)
- `lib/main.dart`: App entrypoint initializing Supabase, Hive, and GetX controllers.
- `lib/layout.dart`: Shell layout hosting top bars and bottom bar navigation.
- `lib/core/config/color.dart`: Color palette, primary shades, and gradient definitions.
- `lib/core/config/typography.dart`: Text styling scale (`AppTypography`).
- `lib/core/meta/app_meta.dart`: App metadata, brand names, and Supabase credentials.
- `lib/core/helper/hive_boxes.dart`: Hive box interface for `userBox` and `downloadsBox`.
- `lib/core/helper/image_helper.dart`: Image compression utility.

### 5.2 Reactive Controllers (`lib/controller/`)
- `auth_controller.dart`: Authentication lifecycle (Login, Register, Logout, Session sync).
- `document_controller.dart`: Notes CRUD, optimistic likes/dislikes/bookmarks, link opening.
- `home_controller.dart`: Feed loading, pagination, realtime Postgres subscriptions.
- `upload_controller.dart`: Document upload flow, 10MB limit enforcement, link validation.
- `profile_controller.dart` / `profile_user_controller.dart`: Local user and peer profile state.
- `comment_controller.dart`: Hierarchical comment tree handling and deletion.
- `notification_controller.dart`: User activity notification sync.
- `download_controller.dart`: Local PDF downloads with progress notifications.

### 5.3 Services (`lib/service/`)
- `file_caching.dart`: Caching layer for network documents using Dio.
- `file_download.dart`: Download manager supporting local notification updates.
- `notification_service.dart`: Native notification helper (`flutter_local_notifications`).

### 5.4 UI Views & Widgets (`lib/view/`)
- `view/splash_screen/`: Animated splash view.
- `view/auth_screen/`: Login and Registration forms.
- `view/home_screen/`: Feed widgets, header, shimmer placeholders.
- `view/official_screen/`: Curated feed for verified university content.
- `view/upload_screen/`: Resource sharing form with Note/Tweet toggles and admin options.
- `view/document_screen/`: Detailed note view, comment thread section.
- `view/profile_screen/`: Profile view, follower stats, user showcase posts.
- `view/notification_screen/`: Real-time notification feed.
- `view/widgets/`: Modular UI buttons, badges (`AdminBadge`), post cards (`PostCard`, `DocumentCard`).

---

## 6. Development, Maintenance & QA Guidelines

### 6.1 Prerequisites & Setup
- **Flutter SDK**: `v3.24+`
- **Dart SDK**: `^3.5.4`
- **Setup Commands**:
  ```bash
  cd notehub
  flutter pub get
  flutter analyze
  flutter test
  ```

### 6.2 Zero Warnings Linting Policy
The repository strictly enforces a zero-warning requirement under `flutter analyze`:
- **Color Opacity**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
- **Switch Controls**: Use `activeThumbColor` instead of deprecated `activeColor`.
- **Flow Control**: Enforce explicit curly braces `{}` on all `if` statements.
- **Empty Catch Blocks**: Must contain explicit comments (e.g., `// ignore: empty_catches`).

---
*Maintained by Jules, AI Software Engineer.*
