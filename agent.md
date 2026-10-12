# Developer Technical Manual & Architectural Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive, developer-centric technical analysis and maintenance manual for the **Serious Study** Android application. Serious Study is a premium notes-sharing and academic networking platform tailored for the Mumbai University student community, migrated from a legacy Django/MongoDB stack to a modern serverless **Supabase** architecture with a Flutter frontend.

---

## 1. System Architecture & Tech Stack

### Tech Stack Overview
- **Frontend Framework**: Flutter 3.24+ / Dart SDK ^3.5.4
- **Backend & Database**: Supabase (PostgreSQL 15+, Supabase Auth JWT, Supabase Storage, Realtime Engine)
- **State Management**: GetX (Reactive `Rx` variables, `Obx`, `GetX`, `GetBuilder`, `Get.put`, `Get.find`)
- **Local Storage & Persistence**: Hive NoSQL (`userBox`, `downloadsBox`)
- **Network & File Processing**:
  - `supabase_flutter` for API & Realtime subscriptions
  - `dio` (5.x) for chunked file streaming & download management
  - `cached_network_image` for optimized web asset rendering
  - `flutter_image_compress` for client-side image compression
  - `open_file` and `url_launcher` for document/external resource viewing
  - `flutter_local_notifications` for file download progress and background status

```
+-----------------------------------------------------------------------------------+
|                                 Serious Study App                                 |
|                                (Flutter Frontend)                                 |
+-----------------------------------------------------------------------------------+
       |                        |                          |               |
       | Auth & REST            | Realtime                 | Local Cache   | Storage
       v                        v                          v               v
+------------------+  +-------------------+        +---------------+ +--------------+
| Supabase Auth    |  | Postgres Realtime |        | Hive Local    | | Supabase     |
| (JWT Sessions)   |  | (public:documents)|        | NoSQL Boxes   | | Storage      |
+------------------+  +-------------------+        +---------------+ +--------------+
       |                        |                                          |
       +------------------------+------------------------------------------+
                                |
                                v
                +-------------------------------+
                | PostgreSQL Database (Supabase)|
                | - RLS Authorization           |
                | - RPC Functions (Atomic Ops)  |
                | - Triggers (Admin Guard)      |
                +-------------------------------+
```

---

## 2. Codebase Component Mapping & Directory Structure

```
notehub/
├── android/                   # Android native configuration (compileSdk 36, Java 17, multidex)
├── assets/                    # Vector graphics, icons, and Lottie animations
├── lib/
│   ├── controller/            # Business logic & reactive state management (GetX)
│   ├── core/                  # Configurations, theme constants, helpers, and metadata
│   ├── model/                 # Data models & JSON serialization helpers
│   ├── service/               # External service integrations (Supabase, Dio caching)
│   ├── view/                  # UI screens, widgets, and layout structures
│   ├── layout.dart            # Root navigation shell & bottom bar wrapper
│   └── main.dart              # App entry point & initialization sequence
├── test/                      # Test suite (e.g. dummy_test.dart for CI/CD)
├── pubspec.yaml               # Dependency declarations and asset mappings
└── SUPABASE_SCHEMA.sql        # Database tables, RLS policies, functions & triggers
```

### File-by-File Technical Breakdown

#### Core Application Entry
- `lib/main.dart`: Initializes Flutter binding, Hive local storage (`Hive.initFlutter()`), Supabase Flutter client (`Supabase.initialize(...)`), and boots `Splash`.
- `lib/layout.dart`: Primary shell widget holding `BottomFooter` and managing reactive tab navigation across Home, Official, Search, Upload, and Profile pages via `BottomNavigationController`.
- `lib/view/splash_screen/splash.dart`: Startup screen displaying Lottie animation (`notes.json`) and directing users to `Layout` if `HiveBoxes.userId` is present, or `Login` if unauthenticated.

#### Controllers (`lib/controller/`)
- `auth_controller.dart`: Manages user authentication (email sign-in, email sign-up with emailRedirectTo deep-linking, profile fetching, local session sync with Hive, and sign-out).
- `document_controller.dart`: Core feed and document state controller. Implements optimistic updates with error rollback for likes, dislikes, and bookmarks; document deletion with linked storage cleanup; external link opening via `url_launcher`; and PDF/image opening via `saveAndOpenFile`.
- `home_controller.dart`: Feed fetch controller supporting standard feed queries, official feed batch queries (top 20), and Postgres Realtime listener setup on `public:documents`.
- `profile_controller.dart`: Current user's reactive profile state sync with Hive `userBox`.
- `profile_user_controller.dart`: Profile state management for public user profile views, including follow/unfollow operations.
- `comment_controller.dart`: Handles nested discussion threads (fetching root and reply comments, posting comments with optional `parentId`, and deleting comments).
- `upload_controller.dart`: Document upload pipeline managing file selection, 10MB file size checks, image compression, post type ('note' vs 'tweet'), direct file upload vs external link toggles, and administrative official content flagging.
- `search_controller.dart`: Real-time debounced query execution for searching documents and student profiles.
- `notification_controller.dart`: Notification fetching and bulk mark-as-read updates.
- `bottom_navigation_controller.dart`: Navigation index reactive state (`currentPage`).

#### Core Configurations & Helpers (`lib/core/`)
- `config/color.dart`: Color definitions including `PrimaryColor.shade500` (#0D47A1 Premium Deep Blue), `Grayscale`, `DangerColors`, `OtherColors`, and `AppGradients`. Modernized with `.withValues(alpha: ...)` for Dart SDK ^3.5.4 compatibility.
- `config/gradients.dart`: Centralized `LinearGradient` definitions for glassmorphism and background overlays.
- `config/typography.dart`: `AppTypography` scale defining font sizes, line heights, and letter spacing.
- `helper/hive_boxes.dart`: Hive box accessor (`userBox`, `downloadsBox`) providing immediate synchronous access to `userId`, `username`, and cached profile attributes.
- `helper/image_helper.dart`: Wraps `image_picker` and `flutter_image_compress` to compress images to 70% quality JPEG with maximum 1024x1024 resolution.
- `helper/custom_icon.dart`: SVG icon renderer and `CustomAvatar` network/fallback avatar widget.
- `meta/app_meta.dart`: App-wide metadata constants (App name "Serious Study", default DiceBear avatar URL base, community links).

#### Services (`lib/service/`)
- `supabase_service.dart`: Client singleton reference wrapper and database query execution helpers.
- `file_caching.dart` & `file_download.dart`: Network download manager utilizing `Dio` for chunked streaming, path resolution via `path_provider`, duplicate checking in temp directory, and system notification updates.

#### Models (`lib/model/`)
- `user_model.dart`: Models user profiles including `displayName`, `username`, `institute`, `profile` URL, document/follower/following counts, and `isAdmin` flag.
- `document_model.dart`: Comprehensive document/post model covering likes, dislikes, `isLiked`, `isDisliked`, `isBookmarked`, `isOfficial`, `isExternal`, and `postType` ('note' or 'tweet').
- `comment_model.dart`: Nested comment model holding `parentId`, content, author details, and `isAdmin` flag.
- `notification_model.dart`: Event model for notifications ('like', 'comment', 'follow', 'new_post').

#### UI Views & Widgets (`lib/view/`)
- `auth_screen/`: `Login` and `LoginForm`, `LoginHeader`.
- `home_screen/`: Main feed view, `HomeHeader` (greeting, MU tag, search & notification buttons), and `HomeDocumentSection` with shimmer loading states.
- `document_screen/`: Detailed document viewer screen and `CommentSection`/`CommentTile` nested comments UI.
- `upload_screen/`: Upload screen and `UploadForm` (Post type toggle, file upload/link picker, cover image preview, and Admin Official toggle switch using `activeThumbColor`).
- `profile_screen/`: Current user and external profile screens (`ProfileUser`, `ProfileShowcase`, `FollowerWidget`).
- `notification_screen/`: Notifications listing view with unread highlight indicators.
- `search_screen/`: Tabbed search UI (Notes, Tweets, Users).
- `settings_screen/`: Settings view and `about.dart` (Developer credits, vision statement).
- `widgets/`: Modular, reusable UI components (`AdminBadge`, `DocumentCard`, `PostCard`, `PrimaryButton`, `SecondaryButton`, `Loader`, `RefresherWidget`, `Toasts`).

---

## 3. Performance Analysis

1. **Reactive Micro-Rebuilds (GetX)**
   - UI updates are bounded to granular reactive widgets (`Obx`, `GetX`, `GetBuilder`). Controller logic is fully detached from presentation code, preventing unnecessary full-screen re-renders during state mutations.
2. **Synchronous Local Caching (Hive)**
   - User profile metadata and active session details are stored locally in Hive (`userBox`). On application launch, `HiveBoxes.userId` is checked synchronously, allowing instant routing to `Layout` without asynchronous network authentication delays.
3. **Media Pipeline Optimization**
   - **Image Compression**: Client-side compression via `flutter_image_compress` converts images to 70% quality JPEGs with a 1024x1024 bounding box before uploading to Supabase Storage, reducing average file payload from ~4MB to <300KB.
   - **Upload File Size Limits**: Enforces a strict 10MB limit in `UploadController` for direct document uploads.
   - **Network Caching**: `cached_network_image` caches remote document covers and avatars on disk.
4. **Atomic Counter RPCs & Database Performance**
   - Increments and decrements for document counters (`likes_count`, `dislikes_count`) execute atomic PostgreSQL RPC functions (`increment_likes`, `decrement_likes`, etc.) defined in `SUPABASE_SCHEMA.sql`. This eliminates race conditions, row lock contention, and client-side data mismatch.
5. **Optimistic UI with Fallback Rollback**
   - User interactions (like, dislike, bookmark) update reactive local state immediately in `DocumentController`. If the backend RPC or network request fails, the state cleanly reverts to its original value and displays an error toast.
6. **Query Optimization & Batching**
   - Home official feed uses batch limits (`fetchOfficialUpdates` capped at top 20 records) to ensure quick response times on mobile data connections.

---

## 4. Design System & UI/UX Paradigm

- **UI Language**: Modern **Material 3** combined with **Glassmorphism**.
- **Visual Aesthetic**:
  - Semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`).
  - Glassmorphic card overlays using `GlassmorphicContainer` and `AppGradients.glassGradient`.
  - Rebranded with "Premium Deep Blue" theme (`#0D47A1`).
  - Verified Admin badges and Official MU Content tags styled with Premium Gold accents (`#FFD700` / `#B8860B`).
- **Modern Color API Compliance**:
  - Migrated all legacy `.withOpacity()` references to `.withValues(alpha: ...)` to align with Dart SDK ^3.5.4 precision standards.
  - Switch widgets utilize `activeThumbColor` (e.g. in `UploadForm`) to replace deprecated `activeColor`.
- **User Feedback**:
  - Shimmer placeholder animations (`Shimmer.fromColors`) during asynchronous data loading.
  - Lottie vector animations for splash screen and empty search/notification states.
  - Toast notifications (`Toasts`) for user action feedback.

---

## 5. Security Architecture & Audit

### Authentication & Session Management
- Migrated to **Supabase Auth (JWT)**. Sessions are managed securely by the Supabase Flutter client SDK. Passwords are handled via Supabase's secure password hashing algorithms (Argon2/Bcrypt) and are never exposed in plaintext or stored in application state.

### Row Level Security (RLS) Policies (`SUPABASE_SCHEMA.sql`)
Every PostgreSQL table enforces strict RLS policies:
- **`profiles`**:
  - `SELECT`: Public access allowed.
  - `UPDATE`: Restricted to profile owner (`auth.uid() = id`).
  - **Privilege Escalation Guard**: The `FOR UPDATE` policy includes a strict `WITH CHECK` clause:
    ```sql
    WITH CHECK (
      is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
    );
    ```
    This prevents standard users from crafting direct API requests to update their own `is_admin` status to `true`.

- **`documents`**:
  - `SELECT`: Public access allowed.
  - `INSERT / UPDATE / DELETE`: Restricted to post author (`auth.uid() = user_id`).
  - **Official Content Guard**: Enforced via a database trigger function (`ensure_official_permission`):
    ```sql
    CREATE OR REPLACE FUNCTION check_official_permission()
    RETURNS TRIGGER AS $$
    BEGIN
      IF NEW.is_official = true AND OLD.is_official IS DISTINCT FROM NEW.is_official THEN
        IF NOT EXISTS (
          SELECT 1 FROM public.profiles
          WHERE id = auth.uid() AND is_admin = true
        ) THEN
          RAISE EXCEPTION 'Only admin users can mark content as official.';
        END IF;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
    ```

- **`interactions` & `bookmarks`**:
  - `SELECT / INSERT / DELETE`: Isolated strictly to the authenticated user (`auth.uid() = user_id`).

- **`comments` & `notifications`**:
  - `SELECT / INSERT / DELETE`: Owner and recipient isolation enforced via RLS.

### RPC Function Hardening
- All PostgreSQL RPC counter functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`) are defined with `SECURITY DEFINER` and explicitly set `SET search_path = public` to prevent search-path hijacking attacks.

---

## 6. Developer Guidelines & QA Procedures

### Prerequisites
- Flutter SDK ^3.24.0
- Dart SDK ^3.5.4

### QA & Static Analysis Enforcements ("Zero Warnings Policy")
Before submitting any code changes, developer must verify that the codebase compiles with zero linter warnings and passes all tests.

1. **Run Static Analysis**:
   ```bash
   cd notehub
   flutter analyze
   ```
   *Expected result*: `No issues found!`

2. **Run Unit & Integration Tests**:
   ```bash
   cd notehub
   flutter test
   ```
   *Expected result*: `All tests passed!`

3. **Coding Standards & Linting Rules**:
   - **Color Opacities**: Always use `.withValues(alpha: doubleValue)` instead of `.withOpacity(doubleValue)`.
   - **Switch Controls**: Always use `activeThumbColor` instead of `activeColor`.
   - **Flow Control**: Enforce `curly_braces_in_flow_control_structures` for all `if`, `else`, `for`, and `while` statements.
   - **Catch Annotations**: When handling silent exceptions, place `// ignore: empty_catches` on its own line inside the `catch` block.

---
*Maintained and documented by Jules, Software Engineer.*
