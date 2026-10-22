# Developer Technical Guide & System Manual - Serious Study (formerly NoteHub)

This document serves as the primary system manual, developer guide, and architectural reference for the **Serious Study** Android application. It provides an in-depth, developer-centric analysis across **Performance**, **Design & Architecture**, and **Security**, alongside a complete file-by-file mapping, backend database policies, and Quality Assurance guidelines.

---

## 1. Executive Overview & System Architecture

**Serious Study** is a high-performance academic networking and study notes-sharing platform designed for the Mumbai University student community. The application was migrated from a legacy Django/MongoDB backend to a modern serverless **Supabase** (PostgreSQL) architecture with a Flutter client frontend.

### Tech Stack Overview
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management & Routing**: GetX (Reactive state management & dependency injection)
- **Local Storage / Caching**: Hive (NoSQL local key-value store for session and downloads caching)
- **HTTP & File Operations**: Dio & Supabase Flutter SDK
- **Backend Architecture**: Supabase (PostgreSQL, Auth JWT, Storage, Realtime, RPC Functions)
- **UI Paradigm**: Material 3 with Glassmorphism overlays and Premium Deep Blue (`#0D47A1`) aesthetics.

```
+-----------------------------------------------------------------------+
|                            FLUTTER CLIENT                             |
|  +---------------------+  +---------------------+  +---------------+  |
|  | Views & Glass UI    |  | GetX Controllers    |  | Hive Local    |  |
|  | (Material 3)        |  | (State & Logic)     |  | Storage       |  |
|  +----------+----------+  +----------+----------+  +-------+-------+  |
+-------------|------------------------|---------------------|----------+
              |                        |                     |
              v                        v                     v
+-----------------------------------------------------------------------+
|                           SUPABASE BACKEND                            |
|  +---------------------+  +---------------------+  +---------------+  |
|  | PostgREST API / JWT |  | PostgreSQL DB & RLS |  | Storage & RPC |  |
|  | Authentication      |  | Row Level Security  |  | Functions     |  |
|  +---------------------+  +---------------------+  +---------------+  |
+-----------------------------------------------------------------------+
```

---

## 2. Performance Analysis

### 2.1 Reactive State Management (GetX)
- Business logic is strictly decoupled from UI rendering using GetX controllers (`DocumentController`, `HomeController`, `AuthController`, etc.).
- UI widgets listen to granular observable fields (`.obs`), ensuring re-renders are isolated to affected widgets rather than rebuilding entire screen trees.
- `DocumentController` incorporates optimistic UI updates for likes, dislikes, and bookmarks, syncing changes locally before backend confirmation and calling `_syncWithHome()` to keep the main feed coherent.

### 2.2 Local Storage & Caching Architecture
- **Hive NoSQL Storage**: Session data and profile details are persisted in `userBox` (`lib/core/helper/hive_boxes.dart`), providing instant UI startup and profile loading without waiting for network roundtrips.
- **Downloaded Metadata**: Cached document metadata and download history are stored in `downloadsBox`.
- **Media & File Caching**:
  - `cached_network_image`: Efficiently handles profile avatars and document thumbnails, storing cached files in local cache directories to prevent repetitive bandwidth usage.
  - `FileCachingService` (`lib/service/file_caching.dart`): Leverages `Dio` and `path_provider` to check local disk cache before initiating remote network transfers.

### 2.3 Media & Network Optimization
- **On-Device Compression**: `ImageHelper.compressImage()` (`lib/core/helper/image_helper.dart`) compresses user cover images and avatars to JPEG format (70% quality, max dimensions 1024x1024) using `flutter_image_compress` prior to uploading.
- **Direct File Size Safeguards**: File uploads over 10MB are blocked at the controller layer (`UploadController.dart`), encouraging external cloud links (e.g., Google Drive, Mega) for heavy files to save storage and bandwidth.
- **Lazy Fetching & Pagination**: The home feed fetches documents in constrained batches (limit 50) with sticky sorting, reducing initial payload size and query execution time.

### 2.4 Database Atomic Operations (RPCs)
To eliminate race conditions and avoid client-side calculation errors during concurrent user interactions:
- Counter mutations (likes, dislikes, bookmarks) are executed as PostgreSQL RPC functions (`increment_likes`, `decrement_likes`, etc.) defined in `SUPABASE_SCHEMA.sql`.
- These functions execute atomically inside PostgreSQL transactions, guaranteeing accuracy across high user concurrency.

---

## 3. Design System & UI Architecture

### 3.1 Visual Aesthetics & Rebranding
- **Theme Paradigm**: Material 3 combined with **Glassmorphism** depth effects.
- **Color Palette**: Rebranded to "Premium Deep Blue" (`#0D47A1`), representing academic credibility.
  - Primary Accent: Deep Blue (`#0D47A1`)
  - Secondary Accents: Light Ice Blue (`#E3F2FD`), Card Surface Overlays (`Colors.white.withValues(alpha: 0.15)`).
- **Typography**: Custom typography configured in `lib/core/config/typography.dart`, ensuring consistent font hierarchies across screen sizes.

### 3.2 Flutter Deprecation & Modern API Standards
The codebase strictly adheres to Dart SDK ^3.5.4 standards:
- **Color Opacity**: Legacy `.withOpacity(x)` calls have been replaced with the precision-safe `.withValues(alpha: x)` method across all widgets.
- **Switch Controls**: `Switch` widgets utilize `activeThumbColor` instead of the deprecated `activeColor` parameter.
- **Flow Control**: All flow control blocks (`if`, `else`, `for`) enforce curly braces (`curly_braces_in_flow_control_structures`).

### 3.3 Visual Feedback & State Transitions
- **Shimmer Placeholders**: Used in `HomeDocumentSection` and search views to render elegant skeleton loaders while asynchronous queries resolve.
- **Lottie Animations**: Deployed for empty state indicators (e.g., empty search results, no notifications) and upload completion feedback.
- **Toast Notifications**: Reusable toast feedback (`Toasts.showTostSuccess`, `Toasts.showTostError`) provides immediate visual confirmation for user actions.

---

## 4. Security Architecture & Threat Analysis

### 4.1 Authentication & Token Handling
- Migrated from legacy session-less authentication to **Supabase Auth** (JWT-based).
- User credentials are encrypted at rest; password hashing is managed securely by Supabase Auth (Bcrypt/Argon2).
- Session tokens are stored securely on device and validated on subsequent API requests.

### 4.2 Row Level Security (RLS) Policies
Every table in PostgreSQL has Row Level Security enabled. Standard policies include:
- **`profiles`**: Public `SELECT` allowed. `INSERT` and `UPDATE` are strictly restricted to `auth.uid() = id`.
- **`documents`**: Public `SELECT` allowed. `INSERT` restricted to `auth.uid() = user_id`. `UPDATE`/`DELETE` restricted to document owners or global admins.
- **`notifications` & `bookmarks`**: Restricted exclusively to the owning user (`auth.uid() = receiver_id` / `user_id`).

### 4.3 Privilege Escalation & Defenses
- **`is_admin` Security Fix**: A `WITH CHECK` clause on the `profiles` table update policy prevents regular users from elevating their own privileges:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (
      auth.uid() = id AND
      is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
    );
  ```
- **`is_official` Protection**: Document verification (`is_official = true`) is restricted to administrative profiles via database trigger policies (`ensure_official_permission`).
- **Search Path Hijacking Safeguard**: RPC functions explicit define `SET search_path = public` to protect against search path injection vulnerabilities in `SECURITY DEFINER` functions.

---

## 5. File & Directory Mapping

```
notehub/lib/
├── controller/                      # GetX Reactive Business Logic
│   ├── auth_controller.dart          # Auth, registration, session persistence, profile fetch
│   ├── bottom_navigation_controller.dart # App navigation index management
│   ├── comment_controller.dart       # Post comments & nested replies management
│   ├── connection_controller.dart    # User connections & follower interactions
│   ├── document_controller.dart      # Document interactions (likes, bookmarks, sync)
│   ├── download_controller.dart      # Local document download manager & status
│   ├── file_controller.dart          # File preview & external link handling
│   ├── home_controller.dart          # Feed fetching, pagination, real-time channel setup
│   ├── notification_controller.dart  # User notifications & activity feed
│   ├── post_controller.dart          # Micro-post / tweet creation & interactions
│   ├── profile_controller.dart       # Active user profile editing & statistics
│   ├── profile_user_controller.dart  # Other user profile viewing
│   ├── remote_config_controller.dart # Dynamic server configuration loader
│   ├── search_controller.dart        # Real-time search query execution
│   ├── showcase_controller.dart      # Feature walkthrough onboarding state
│   └── upload_controller.dart        # File upload, validation, compression, Supabase Storage
│
├── core/                            # App Configurations & Utilities
│   ├── config/
│   │   ├── color.dart               # Rebranded color constants (Deep Blue `#0D47A1`)
│   │   └── typography.dart          # Material 3 typography specifications
│   ├── helper/
│   │   ├── custom_icon.dart         # SVG & Icon mapping helpers
│   │   ├── hive_boxes.dart          # Hive local key-value box definitions
│   │   └── image_helper.dart        # Image compression utility (70% JPEG quality)
│   └── meta/
│       └── app_meta.dart            # App metadata & Supabase configuration credentials
│
├── model/                           # Data Models & Serialization
│   ├── document_model.dart          # Document entity model
│   ├── mini_user_model.dart         # Compact user reference model
│   ├── post_model.dart              # Tweet / micro-post model
│   ├── user_model.dart              # User profile entity model
│   └── user_model.g.dart            # Hive adapter generator mapping
│
├── service/                         # Low-Level Network & Native Services
│   ├── file_caching.dart            # Dio-based local file caching service
│   ├── file_download.dart           # File download & path resolution engine
│   └── notification_service.dart    # Flutter local notifications setup
│
├── view/                            # Modular UI Screens & Components
│   ├── auth_screen/                 # Login & Registration screens
│   ├── bottom_footer/               # Glassmorphism bottom navigation bar
│   ├── connection_screen/           # Network & followers management screen
│   ├── document_screen/             # Detailed document view, PDF viewer, comments
│   ├── home_screen/                 # Primary feed view & category filtering
│   ├── notification_screen/         # Real-time activity notifications list
│   ├── official_screen/             # Verified university updates screen
│   ├── onboarding_screen/           # Application onboarding walkthrough
│   ├── profile_screen/              # User profile, uploads, saved bookmarks
│   ├── search_screen/               # Instant document & user search view
│   ├── settings_screen/             # Application settings & about dialog
│   ├── splash_screen/               # Animated startup splash screen
│   ├── upload_screen/               # File upload & link creation screen
│   └── widgets/                     # Reusable UI widgets (cards, buttons, badges)
│
├── layout.dart                      # Primary root shell widget with dynamic tab views
└── main.dart                        # Application entry point, Supabase & Hive initialization
```

---

## 6. Development, Testing & Quality Assurance

### Prerequisites
- Flutter SDK v3.24+ (Dart SDK ^3.5.4)
- Android SDK (targeting `compileSdk 36`, source compatibility Java 17)

### Verification Commands
To ensure 'Zero Warnings' compliance and pass CI checks, run the following commands inside `notehub/`:

```bash
# 1. Check static analysis and linting compliance
flutter analyze

# 2. Run unit and integration test suite
flutter test
```

### Code Quality Rules
1. **Zero Warnings Policy**: All code modifications must produce 0 lint errors or warnings under `flutter analyze`.
2. **Modern Color API**: Always use `.withValues(alpha: ...)` for transparency calculations. Avoid deprecated `.withOpacity()`.
3. **Switch Controls**: Always use `activeThumbColor` for active Switch styling.
4. **Flow Control Braces**: Enforce explicit curly braces `{}` on all `if`/`else` control structures.
5. **Empty Catches**: Annotate empty catch blocks with `// ignore: empty_catches` on its own line inside the block to avoid commenting out subsequent `finally` blocks.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
