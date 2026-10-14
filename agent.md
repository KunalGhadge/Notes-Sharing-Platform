# Developer Guide & System Technical Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-centric technical analysis and maintenance manual for the **Serious Study** Android application. It details the system architecture, performance optimizations, UI/UX design paradigm, security implementation, database schema, and QA procedures following the migration from legacy Django/MongoDB to a serverless **Supabase** backend.

---

## 1. System Architecture & Tech Stack

Serious Study is an academic notes-sharing and social networking mobile app tailored for the Mumbai University student community.

### Stack Summary
- **Frontend**: Flutter (3.24+) / Dart SDK (^3.5.4)
- **State Management**: GetX (`get: ^4.6.6`) for reactive controller-based state management, dependency injection, and route navigation.
- **Local Cache & Storage**: Hive (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`) for synchronous NoSQL key-value caching.
- **Backend & Database**: Supabase (PostgreSQL with Row Level Security, Realtime, Supabase Auth JWT, and Supabase Storage).
- **Networking & Downloading**: Dio (`dio: ^5.9.1`), `path_provider`, and `open_file`.
- **UI Libraries**: Glassmorphism (`glassmorphism: ^3.0.0`), Google Fonts (`google_fonts`), Shimmer, Toastification, Lottie, and Vector Graphics (`flutter_svg`).

### Directory & File Structure
```
notehub/
├── lib/
│   ├── main.dart                      # App entry point, Supabase & Hive initialization
│   ├── layout.dart                    # Bottom navigation scaffold & screen routing
│   ├── controller/                    # GetX reactive business logic controllers
│   │   ├── auth_controller.dart       # Supabase Auth, login/register, session sync
│   │   ├── document_controller.dart   # Feed, document state, RPC counter invocation
│   │   ├── home_controller.dart       # Home feed, Realtime subscription, official feed
│   │   ├── upload_controller.dart     # File upload pipeline, compression, metadata
│   │   ├── profile_controller.dart    # User profile management, edit profile, posts
│   │   ├── download_controller.dart   # Background file downloading & local file handling
│   │   ├── comment_controller.dart    # Post comments and replies
│   │   ├── search_controller.dart     # Global search for notes and users
│   │   ├── notification_controller.dart # User notifications & global announcements
│   │   └── connection_controller.dart   # Followers/Following management
│   ├── model/                         # Data models (UserModel, DocumentModel, PostModel, etc.)
│   ├── service/                       # Infrastructure services
│   │   ├── file_caching.dart          # Local file caching via Dio & path_provider
│   │   ├── file_download.dart         # Download management
│   │   └── notification_service.dart  # Local notification handling
│   ├── core/                          # App metadata, theme, and local boxes
│   │   ├── config/color.dart          # AppColors, AppGradients, Glassmorphic styling
│   │   ├── config/typography.dart     # AppTypography styling
│   │   ├── helper/hive_boxes.dart     # Hive boxes wrapper (userBox, downloadsBox)
│   │   ├── helper/image_helper.dart   # Compression pipeline (70% quality, 1024x1024 max)
│   │   └── meta/app_meta.dart         # App metadata (version, branding)
│   └── view/                          # Modular UI components and screens
│       ├── auth_screen/               # Login & Register views
│       ├── home_screen/               # Main document feed with Realtime updates
│       ├── document_screen/           # Document details, comments, and action bar
│       ├── upload_screen/             # File upload and external link form
│       ├── profile_screen/            # Profile showcase, documents, edit modal
│       ├── search_screen/             # Multi-tab search interface
│       ├── official_screen/           # MU Official announcements & verified notes
│       ├── notification_screen/       # Notification feed
│       └── widgets/                   # Reusable components (DocumentCard, PostCard, Buttons, Toasts)
```

---

## 2. Deep Technical Performance Analysis

### A. Reactive State Management & Memory Management
- **GetX Controller Isolation**: Business logic is strictly separated from UI rendering. Views use `Obx` or `GetBuilder` to bind directly to reactive properties (e.g., `RxList`, `RxBool`).
- **Optimistic UI Updates**: Operations such as liking, disliking, or bookmarking notes in `DocumentController` update the local state immediately before invoking remote backend calls, ensuring zero input latency for users.
- **Batching & Pagination**: Feed queries in `HomeController` limit results (e.g., batch limit of 50 for main feeds, 20 for official updates) to reduce initial JSON payload sizes and optimize widget tree construction.

### B. Storage & Local Caching Strategy
- **Synchronous Session Access with Hive**: User session details are persisted in Hive (`userBox`). On application startup, user profile data is instantly retrieved without requiring an asynchronous network call, preventing screen flashing.
- **Media & File Caching**:
  - Image assets are rendered via `cached_network_image`, storing thumbnails locally to eliminate redundant network requests.
  - Document downloads are managed by `FileCachingService` which uses `Dio` to check local temporary directories (`path_provider`) before initiating external network requests.
- **Image Compression Pipeline**: `ImageHelper.compressImage` compresses uploaded images to JPEG at 70% quality with a maximum dimension of 1024x1024 pixels before sending them to Supabase Storage, saving up to 80% bandwidth during upload and download.

### C. Backend Database Scalability
- **PostgreSQL Atomic Functions (RPCs)**: Counter increments/decrements (likes, dislikes, bookmarks) are executed directly on the PostgreSQL database via stored procedures (`increment_likes`, `decrement_likes`, etc.). This guarantees atomic transaction isolation and eliminates race conditions under heavy concurrent use.
- **Postgres Realtime Integration**: `HomeController` subscribes to `public:documents` changes using `supabase.channel('public:documents').onPostgresChanges(...)`, enabling instant feed updates across connected clients without client-side polling.

---

## 3. Design & UI/UX Paradigm

### A. Material 3 & Premium Deep Blue Branding
- **Color Palette**: Rebranded around "Premium Deep Blue" (`#0D47A1` primary, `#1976D2` secondary, `#002171` dark surface).
- **Glassmorphism Aesthetic**: Custom semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`) combined with subtle backdrop blurs and linear gradients (`AppGradients.premiumGradient`) create a tactile, layered visual hierarchy.
- **Modern Color API Compliance**: The app uses Dart 3.5.4+ `.withValues(alpha: ...)` for color opacities, avoiding deprecated `.withOpacity()` methods.
- **Form Controls**: Switch controls in administrative settings (e.g., `UploadForm`) use `activeThumbColor: const Color(0xFFB8860B)` to adhere to modern Flutter specifications.

### B. Component Hierarchy & UX Design
- **Visual Feedback & Shimmer**: Data-loading states utilize custom `Shimmer` placeholders matching card geometry, maintaining visual consistency while fetching backend data.
- **Feedback & Toasting**: Reusable notifications (`Toasts.showTostSuccess`, `Toasts.showTostWarning`, `Toasts.showTostError`) powered by `toastification` offer clear user state feedback.

---

## 4. Security Architecture & Audit

### A. Authentication & Session Security
- **Supabase Auth (JWT)**: User authentication utilizes standard JWT tokens managed securely by `supabase_flutter`. Passwords are never stored or transmitted in plain text, leveraging Argon2/Bcrypt hashing inside Supabase Auth.
- **Session Verification**: `AuthController` verifies session validity after login/registration before populating local Hive storage.

### B. Row Level Security (RLS) Policies
Row Level Security is enabled across all tables in `SUPABASE_SCHEMA.sql`:

1. **`profiles`**:
   - `SELECT`: Publicly viewable by all authenticated users.
   - `INSERT`: Restricted to `auth.uid() = id`.
   - `UPDATE`: Enforces `auth.uid() = id` with a `WITH CHECK` clause ensuring users cannot elevate their own `is_admin` status:
     ```sql
     CREATE POLICY "Users can update own profile" ON public.profiles
       FOR UPDATE USING (auth.uid() = id)
       WITH CHECK (
         is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
       );
     ```
2. **`documents`**:
   - `SELECT`: Publicly viewable.
   - `INSERT`: Restricted to `auth.uid() = user_id`.
   - `UPDATE / DELETE`: Only allowed if `auth.uid() = user_id` or if user has `is_admin = true`.
3. **`comments` / `interactions` / `bookmarks` / `notifications` / `followers`**:
   - Explicit RLS policies protect user data privacy, ensuring notifications and bookmarks are readable solely by their owner (`auth.uid() = receiver_id` / `auth.uid() = user_id`).

### C. Database RPC & Trigger Security
- **Search Path Hijacking Prevention**: PostgreSQL functions (e.g., `check_official_permission`) are declared with `SET search_path = public` to prevent search path hijacking attacks.
- **Privilege Escalation Controls**: Setting `is_official = true` on documents is protected by the `ensure_official_permission` database trigger, verifying `is_admin` status in `public.profiles` prior to table writes.

---

## 5. Database Schema Reference (`SUPABASE_SCHEMA.sql`)

### Key Tables & Constraints
- **`profiles`**: Primary key `id` (UUID references `auth.users`). Columns: `username`, `display_name`, `profile_url`, `institute`, `academic_interests`, `bio`, `is_admin`, `followers`, `following`, `documents`.
- **`documents`**: Primary key `id` (BIGINT Identity). Foreign key `user_id` references `profiles(id)`. Columns: `name`, `topic`, `description`, `document_url` (nullable for tweets), `document_name`, `cover_url`, `icon_name`, `likes_count`, `dislikes_count`, `is_external`, `is_official`, `post_type` ('note' or 'tweet').
- **`comments`**: Primary key `id` (UUID). Includes `parent_id` for nested reply threads.
- **`interactions`**: Tracks likes/dislikes with unique constraint `(document_id, user_id)`.
- **`bookmarks`**: Tracks saved posts with unique constraint `(document_id, user_id)`.
- **`notifications`**: Private and global platform notifications.
- **`followers`**: Social graph relation with unique constraint `(follower_id, following_id)`.

---

## 6. Developer Maintenance & QA Guidelines

### Prerequisites
- Flutter SDK: `^3.24.0`
- Dart SDK: `^3.5.4`
- Android `compileSdk`: `36`, Java 17 compatibility.

### Static Analysis & Code Quality Rules ("Zero Warnings")
To maintain the repository's strict "Zero Warnings" standard:
1. Run static analysis:
   ```bash
   cd notehub
   flutter analyze
   ```
2. Ensure flow control statements use explicit curly braces (`curly_braces_in_flow_control_structures`).
3. Use `.withValues(alpha: ...)` for color opacities instead of `.withOpacity(...)`.
4. Use `activeThumbColor` for Flutter `Switch` widgets.
5. Place `// ignore: empty_catches` annotations on their own line inside the catch block to avoid commenting out closing braces or `finally` blocks.

### Test Execution
Run the unit test suite:
```bash
cd notehub
flutter test
```

---
*Maintained by Jules, Senior AI Software Engineer.*
