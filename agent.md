# Developer Guide & Tech Stack Analysis - Serious Study (formerly NoteHub)

This document serves as the definitive developer guide, system manual, and maintenance log for the **Serious Study** (formerly NoteHub) mobile application. It provides an exhaustive deep-dive from a developer's perspective on the application's performance, design, and security architecture.

---

## 1. Project Architecture Overview

Serious Study is an academic notes-sharing and student networking platform designed for the Mumbai University student community. The application utilizes a decoupled MVC-like architectural paradigm:

```
                  ┌─────────────────────────────────┐
                  │          Flutter UI             │
                  │   (Material 3 / Glassmorphic)   │
                  └────────────────┬────────────────┘
                                   │  (Reactive UI via Obx)
                                   ▼
                  ┌─────────────────────────────────┐
                  │         GetxControllers         │
                  │ (Home, Upload, Profile, etc.)   │
                  └──────┬────────────────────┬─────┘
                         │                    │
                         │ (Supabase queries) │ (Local Store updates)
                         ▼                    ▼
        ┌──────────────────────────────────┐┌───────────────────┐
        │        Supabase Client           ││    Hive Cache     │
        │  (Auth, Database RPC, Storage)   ││ (User & Downloads)│
        └──────────────────────────────────┘└───────────────────┘
```

The system interacts with a serverless PostgreSQL instance hosted on **Supabase** via real-time WebSockets and JSON Web Token (JWT) authenticated PostgreSQL queries/RPC calls.

---

## 2. File Directory & Codebase Breakdown

Below is a detailed analysis of the directory structure under `notehub/lib/`:

*   **`main.dart`**: Entrypoint. Initializes the Flutter binding, Supabase client using credentials from `AppMetaData`, local notifications via `FlutterLocalNotificationsPlugin`, and NoSQL caching via `Hive`. It registers the Hive `UserModelAdapter` and bootstraps global GetX dependencies like `BottomNavigationController`, `ShowcaseController`, and `NotificationController`.
*   **`layout.dart`**: Manages top-level layout, containing the global footer and scaffolding for tab switching.
*   **`core/`**:
    *   `config/color.dart`: Theme configuration. Rebranded with a "Premium Deep Blue" (`#0D47A1`) palette.
    *   `config/typography.dart`: Custom Google Fonts configuration using "Plus Jakarta Sans" for primary and display text.
    *   `helper/hive_boxes.dart`: Centralized access to Hive storage (`user` and `downloads` boxes). Exposes helper getters for current user state (`userId`, `username`, `displayName`, `profileUrl`).
    *   `helper/image_helper.dart`: Optimizes image assets by compressing files to JPEG at 70% quality with a 1024x1024 constraint using `flutter_image_compress`.
    *   `meta/app_meta.dart`: Houses static application metadata and Supabase configuration variables (API URL & Anonymous Key).
*   **`controller/`**:
    *   `auth_controller.dart`: Handles validation, sign-up, email confirmations, password-based authentication, and profile caching in Hive upon successful login.
    *   `home_controller.dart`: Listens to PostgreSQL real-time replication via Supabase WebSockets (`supabase.channel('public:documents')`). Fetches modern updates and handles "Sticky Sort" logic where official documents are pinned at the top.
    *   `document_controller.dart`: Controls note interactions (Likes, Dislikes, Bookmarks) using optimistic UI patterns and RPC triggers. Manages direct file deletion and storage cleanup.
    *   `upload_controller.dart`: Form validation, file picker extraction, cover image compression, and file uploading to Supabase Storage. Supports "Tweet" (social post format) vs. "Note" (classic PDF/Document sharing format) with a 10MB direct file size ceiling.
    *   `profile_controller.dart` & `profile_user_controller.dart`: Fetches user profiles and counts of followers/following/documents. Handles profile modifications and local cache sync.
    *   `comment_controller.dart`: Manages comments and nested thread interactions.
*   **`service/`**:
    *   `file_caching.dart`: Downloads and caches documents using `Dio` and `path_provider` to allow offline reading. Checks local directories for existing resources prior to executing HTTP requests.
    *   `notification_service.dart`: Integrates local system notifications.
*   **`model/`**:
    *   `user_model.dart`: Represents the user profile structure. Generated with `hive_generator` (`user_model.g.dart`) for NoSQL local database serialization.
    *   `document_model.dart`: Strongly-typed schema representing note posts, social tweets, and metadata.
    *   `comment_model.dart` & `post_model.dart`: Standard representations of interaction resources.
*   **`view/`**: Modular presentation tier separated into semantic directories (e.g., `auth_screen`, `home_screen`, `document_screen`, `profile_screen`, `upload_screen`, etc.) styled with premium layouts, Glassmorphic overlays, and Shimmer placeholders.

---

## 3. Comprehensive Performance Analysis

### A. State Management & Perceived Performance
*   **GetX Reactive Architecture**: State updates are completely reactive and trigger UI changes via `Obx` and `GetX` builder wrappers. This eliminates unnecessary rebuilds common in monolithic state widgets.
*   **Optimistic UI Updates**: Inside `DocumentController.dart`, actions like `toggleLike`, `toggleDislike`, and `toggleBookmark` execute *optimistic updates* immediately on local variables before making remote Supabase API requests. If the database update fails, the UI instantly reverts to the original state and triggers a localized error Toast. This prevents visible latency for user interactions.
*   **Asynchronous Shimmer Effects**: Shimmer widgets (e.g. `HomeDocumentSection`) are integrated to display a premium mock-up loader during REST requests. It eliminates layout jumps and offers high visual responsiveness.

### B. Persistent Local Storage & Caching
*   **NoSQL Local Storage (Hive)**: User metadata and cached session details are stored inside Hive's `userBox` (binary format), allowing instant loading of the "My Profile" tab on app launch.
*   **Offloading Database with Hive**: The metadata of downloaded files is cached in `downloadsBox`. This allows offline access to downloaded notes without querying the Supabase backend.
*   **Efficient Download Management (`file_caching.dart`)**: Before initiating a high-overhead download via `Dio` for PDF files, the service checks the temporary/documents directory on local storage using `path_provider`. If the file exists, it immediately opens the cached version, saving network bandwidth.
*   **Image Caching**: UI elements use `CachedNetworkImage` with custom memory cache parameters to prevent reloading remote user avatars and note cover images.

### C. Backend Database Scalability
*   **Database Atomic Functions (RPC)**: Critical counter increments and decrements (likes, bookmarks, and dislikes) are not performed via direct client-side overwrites (which are vulnerable to race conditions). Instead, they are handled atomically inside PostgreSQL functions on Supabase via Remote Procedure Calls:
    *   `increment_likes(doc_id)`
    *   `decrement_likes(doc_id)`
    *   `increment_dislikes(doc_id)`
    *   `decrement_dislikes(doc_id)`
*   **Batching & Pagination**: `HomeController.dart` caps initial feeds to `limit(50)` documents, and `fetchOfficialUpdates` caps to `limit(20)` documents to optimize database read performance and response payload size.
*   **Compression Pipelines**: The `UploadController` integrates image compression using `flutter_image_compress` (70% quality, JPEG encoding) on cover files before uploading to the `documents` storage bucket, preserving Supabase bandwidth and database load.

---

## 4. Design & UX Guidelines

The Serious Study platform maintains a premium, cohesive aesthetic styled for academic environments:

*   **Theme Specifications**: Uses **Material 3** guidelines with a primary color theme of **Premium Deep Blue** (`#0D47A1`).
*   **Glassmorphism Effects**: Implemented in components like `BottomFooter` and profile cards, utilising translucent blurs and borders (`BackdropFilter` combined with light, semi-transparent white fills such as `Colors.white.withValues(alpha: 0.15)` and thin borders).
*   **Typography**: Defined modularly using **Plus Jakarta Sans** via `google_fonts`, enforcing standardized typographic sizes and weights across the application.
*   **Interactive Visual Feedback**: Features high-quality vector icons (`flutter_svg`) and `Lottie` animations for empty feed states and successful uploads.

---

## 5. Security Architecture & Threat Vector Mitigations

Moving from legacy architectures to a modern Supabase backend resolved several major vulnerabilities:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 SUPABASE SECURITY MATRIX                               │
├─────────────────────────────┬──────────────────────────────────────────────────────────┤
│ Auth Layer                  │ JWT-based session tokens with industry-standard hashing  │
├─────────────────────────────┼──────────────────────────────────────────────────────────┤
│ Row Level Security (RLS)    │ Database policies verifying `auth.uid() = user_id`       │
├─────────────────────────────┼──────────────────────────────────────────────────────────┤
│ privilege Escalation Guard  │ `WITH CHECK` clauses preventing unauthorized updates     │
├─────────────────────────────┼──────────────────────────────────────────────────────────┤
│ Storage Access Security     │ Owner-only write rights on documents & covers            │
└─────────────────────────────┴──────────────────────────────────────────────────────────┘
```

### 1. Robust Row Level Security (RLS)
The database enforces strict Row Level Security (RLS) policies defined in `SUPABASE_SCHEMA.sql`:
*   **Profiles**: Public profiles are read-only to all users. Update operations are constrained to the owner:
    ```sql
    CREATE POLICY "Users can update own profile" ON public.profiles
      FOR UPDATE USING (auth.uid() = id) WITH CHECK (
        -- Privilege Escalation Guard: Ensure is_admin cannot be toggled by the user
        is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
      );
    ```
*   **Documents**: Insert and Delete operations verify that the authenticated user ID matches the record's user ID (`auth.uid() = user_id`).
*   **Notifications & Bookmarks**: Access is strictly private. Only the receiver can read notifications (`auth.uid() = receiver_id`).

### 2. Privilege Escalation Prevention
*   **Admin Status Guard**: Users cannot update their own profile to set `is_admin = true`. The `profiles` `UPDATE` policy enforces that `is_admin` must match the value already in the database for the current `auth.uid()`.
*   **Official Document Toggle Protection**: The database table `documents` includes an `is_official` column. Privilege escalation is prevented via backend constraint triggers:
    ```sql
    -- Enforce official verification permissions via trigger
    CREATE OR REPLACE FUNCTION public.check_official_permission()
    RETURNS TRIGGER AS $$
    BEGIN
      IF NEW.is_official = true AND (SELECT is_admin FROM public.profiles WHERE id = auth.uid()) IS NOT TRUE THEN
        RAISE EXCEPTION 'Only platform administrators can mark documents as official.';
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
    ```
    This function utilizes `SECURITY DEFINER` with an explicit `SET search_path = public` configuration to prevent **Search Path Hijacking / Privilege Escalation** vectors.

### 3. Core Credentials & Tokens
*   **Managed JWT Tokens**: Authentication uses short-lived JSON Web Tokens (JWT) issued and validated securely by Supabase Auth, preventing session hijacking.
*   **Password Security**: Managed on Supabase's identity manager utilizing state-of-the-art password hashing (Bcrypt/Argon2). No raw passwords ever touch application logs or custom databases.

---

## 6. Developer Operations & Maintenance Checklist

### A. Environment Prerequisites
- **Flutter SDK**: `v3.24+` (stable channel).
- **Dart SDK**: `^3.5.4` (ensuring compatibility with modernized APIs such as `.withValues()` and `activeThumbColor` properties in `Switch` widgets).

### B. Command Execution Reference

Always run commands from inside the `notehub/` subdirectory:

```bash
# 1. Navigate to the app folder
cd notehub

# 2. Get dependencies
flutter pub get

# 3. Code Generation (Generates local NoSQL Hive Adapters)
dart run build_runner build --delete-conflicting-outputs

# 4. Run Linter / Static Analysis
flutter analyze

# 5. Run Local Tests
flutter test
```

### C. Modern Code Quality Rules (Zero Warnings Policy)
To maintain the repository's strict **Zero Warnings** standard, all developers must adhere to:
1.  **Deprecated Colors**: Avoid `.withOpacity()`. Always use `.withValues(alpha: ...)` to prevent precision loss.
2.  **Modern Switch Widgets**: When styling `Switch` widgets (e.g. in `UploadForm`), avoid the deprecated `activeColor` property. Utilize `activeThumbColor` instead.
3.  **Control Flow**: All conditional structures and loops must utilize curly braces (`curly_braces_in_flow_control_structures`), even for single-line statements:
    ```dart
    // Correct Style
    if (condition) {
      action();
    }
    ```
4.  **Error Handling**: Silent catch blocks in controllers must be properly documented. If a catch block is left intentionally empty, use the `// ignore: empty_catches` annotation placed on its own line inside the block to satisfy the linter:
    ```dart
    try {
      // code
    } catch (e) {
      // ignore: empty_catches
    }
    ```

---
*Maintained and documented by the Engineering Team.*
