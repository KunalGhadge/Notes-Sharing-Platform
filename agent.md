# Serious Study (formerly NoteHub) - Developer Technical Analysis & System Manual

## Executive Summary
**Serious Study** is a high-performance academic community and document-sharing mobile platform tailored for the Mumbai University student ecosystem. The platform enables students and faculty to publish notes, engage in peer discussions, bookmark study materials, and build academic networks.

This document serves as the primary system manual and developer reference guide. It provides an exhaustive analysis of the application's architecture, file structure, state management, performance optimizations, design patterns, security parameters, and database schemas following its full migration from a legacy Django/MongoDB stack to a serverless **Supabase** backend with a **Flutter** client.

---

## 1. System Architecture & Tech Stack

```
+-----------------------------------------------------------------------------------+
|                                  FLUTTER CLIENT                                   |
|  +-----------------------+  +------------------------+  +----------------------+  |
|  |     GetX UI Layer     |  | GetX Controllers (16)  |  | Hive NoSQL Cache     |  |
|  | Material 3 / Glass UI | <-> Business & Async Logic | <-> User Session/Boxes  |  |
|  +-----------------------+  +------------------------+  +----------------------+  |
+------------------------------------------^----------------------------------------+
                                           |
                                  Supabase SDK & Dio
                                           |
+------------------------------------------v----------------------------------------+
|                            SUPABASE SERVERLESS BACKEND                            |
|  +-------------------+  +--------------------+  +------------------------------+  |
|  | Supabase Auth     |  | PostgreSQL DB      |  | Supabase Storage             |  |
|  | JWT Session Mgmt  |  | RLS & RPC Functions|  | Document & Cover Buckets     |  |
|  +-------------------+  +--------------------+  +------------------------------+  |
+-----------------------------------------------------------------------------------+
```

### Core Tech Stack
- **Frontend Framework**: Flutter 3.24+ / Dart SDK ^3.5.4 (Cross-platform Android target).
- **State Management & Routing**: `GetX` (`5.0.0-release-candidate-5`) for reactive state management, route injection, and dependency lifecycle control.
- **Local Storage**: `Hive` (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`) for fast NoSQL disk caching of session data and user profiles.
- **Backend Infrastructure**: `Supabase` (`supabase_flutter: ^2.12.0`) providing PostgreSQL database, Auth JWT, Realtime websockets, and Object Storage.
- **Networking & Caching**: `Dio` (`^5.9.1`) for chunked file downloads; `cached_network_image` (`^3.4.1`) for network asset caching.
- **Media Processing**: `flutter_image_compress` (`^2.4.0`) for client-side asset optimization.

---

## 2. Codebase Directory & File Mapping

The repository is structured around a clean MVC-like architecture separated into controllers, views, models, services, and core utilities.

### Root Directory Structure
- `agent.md`: Primary system manual and developer reference guide.
- `ANALYSIS.md`: High-level executive overview and migration summary.
- `SUPABASE_SCHEMA.sql`: Production PostgreSQL database definitions, triggers, RPCs, and RLS policies.
- `SUPABASE_GUIDE.md`: Backend setup and environment configuration instructions.
- `CONFLICT_RESOLUTION_GUIDE.md`: Architectural guidelines for resolving code conflicts.
- `notehub/`: Core Flutter project directory.

### Flutter Application (`notehub/lib/`)

#### Top-Level Core
- `lib/main.dart`: Application entry point. Initializes `Supabase`, registers global GetX controllers (`AuthController`, `ConnectionController`, `RemoteConfigController`), and bootstraps `Hive`.
- `lib/layout.dart`: Main shell widget hosting the dynamic bottom navigation bar and page index switching (`Obx`).

#### Controllers (`lib/controller/`)
1. `auth_controller.dart`: Handles login, registration, password validation, profile initial sync, and Hive session persistence.
2. `document_controller.dart`: Manages notes lifecycle, likes/dislikes, bookmarks, views, and syncs updates with `HomeController`.
3. `upload_controller.dart`: Manages document/tweet creation, image picking, client-side compression, file size checking (10MB ceiling), and Supabase Storage uploads.
4. `home_controller.dart`: Fetches dynamic home feed, handles official posts feed (limit 20), implements Realtime WebSocket subscriptions (`public:documents`), and pull-to-refresh logic.
5. `profile_controller.dart`: Manages active user profile state, user document lists, bookmarks tab, and profile updates.
6. `profile_user_controller.dart`: Fetches and displays public profiles of other users, follow/unfollow actions, and follow counts.
7. `comment_controller.dart`: Controls comment creation, nested comment replies, comment count increments, and real-time comment fetching.
8. `notification_controller.dart`: Manages user notification feeds (likes, comments, follows, announcements) and unread notification indicators.
9. `search_controller.dart`: Implements real-time debounced search across note titles, topics, and author names.
10. `download_controller.dart`: Oversees file downloading, local device storage paths, and Hive download history tracking.
11. `connection_controller.dart`: Monitors network connectivity states and displays connectivity warnings.
12. `file_controller.dart`: Utilities for file pickers and MIME-type handling.
13. `post_controller.dart`: Manages short-form "tweet" content creations and feed representations.
14. `remote_config_controller.dart`: Fetches runtime configurations from PostgreSQL `remote_config` table for dynamic app flags without APK rebuilds.
15. `showcase_controller.dart`: Controls first-time user tutorial overlay tooltips.
16. `bottom_navigation_controller.dart`: Controls the active index state of the bottom navigation bar.

#### Data Models (`lib/model/`)
- `document_model.dart`: Data model representing notes and tweets (fields: `id`, `name`, `topic`, `documentUrl`, `likesCount`, `isOfficial`, `postType`, etc.).
- `user_model.dart` & `user_model.g.dart`: TypeAdapter-annotated Hive model storing user profile metadata (`id`, `displayName`, `username`, `institute`, `followers`, `following`).
- `post_model.dart`: Data structure for short-form academic post updates.
- `mini_user_model.dart`: Lightweight user reference model for author attribution tiles.

#### Core Services (`lib/service/`)
- `file_caching.dart`: High-performance disk caching service checking existing local paths prior to downloading external documents.
- `file_download.dart`: Dio-powered background file downloader handling progress callbacks and saving files to system directories.
- `notification_service.dart`: Local notification system wrapping `flutter_local_notifications` for background alerts.

#### Core Utilities (`lib/core/`)
- `core/config/color.dart`: Color palette definitions featuring "Premium Deep Blue" (`#0D47A1`), glassmorphic background colors, and accent gradients.
- `core/helper/hive_boxes.dart`: Centralized Hive interface for `userBox` and `downloadsBox`.
- `core/helper/image_helper.dart`: Static utility wrapping `flutter_image_compress` for JPEG compression (70% quality, 1024x1024 resolution target).
- `core/meta/app_meta.dart`: Metadata store holding app branding strings and Supabase API credentials.

#### UI Views & Components (`lib/view/`)
- `view/auth_screen/`: Login and Registration UI screens (`login.dart`, `register.dart`).
- `view/home_screen/`: Primary community feed (`home.dart`, `home_header.dart`, `home_document_section.dart`).
- `view/document_screen/`: Detailed note viewing page, PDF previewer, comment section (`document_detail.dart`, `comment_section.dart`, `comment_tile.dart`).
- `view/upload_screen/`: Upload form for notes and tweets with image picking and official toggle (`upload_screen.dart`, `upload_form.dart`).
- `view/profile_screen/`: Current user profile and peer profile view (`profile.dart`, `profile_user.dart`).
- `view/notification_screen/`: Dynamic notification feed (`notifications.dart`).
- `view/search_screen/`: Dynamic search bar and filtering UI (`search_page.dart`).
- `view/settings_screen/`: App settings, about page, theme options (`about.dart`, `settings.dart`).
- `view/splash_screen/`: Animated splash screen checking active user session (`splash.dart`).
- `view/widgets/`: Reusable widgets (`document_card.dart`, `post_card.dart`, `admin_badge.dart`, `toasts.dart`, `custom_shimmer.dart`).

---

## 3. Performance Analysis & Engineering

### 3.1 State Management & Reactive Memory Optimization
- **GetX Architecture**: The app utilizes GetX controllers to separate business logic from the view layer. Reactive variables (`RxString`, `RxBool`, `RxList`, `.obs`) ensure granular widget updates via `Obx()` without full widget tree rebuilds.
- **Controller Lifecycle**: Controllers are bound using lazy initialization (`Get.lazyPut()`) or permanent registration at startup (`Get.put()`), ensuring unused controllers are garbage collected when routes close.

### 3.2 Offline Caching & Local Storage
- **Hive NoSQL Storage**: Session data and profile details are persisted in Hive boxes (`userBox` and `downloadsBox`). Reading from Hive occurs synchronously in memory, enabling instant application launch without waiting for backend network requests.
- **Asset Network Caching**: Images and cover thumbnails utilize `cached_network_image`, which automatically caches HTTP image assets to local disk storage, reducing network overhead on repeated feed scrolls.

### 3.3 Media & Bandwidth Optimization
- **Client-Side Image Compression**: Cover images selected for uploads pass through `ImageHelper.compressImage()`. This compresses images to 70% JPEG quality and restricts dimensions to 1024x1024 before network transmission.
- **Upload Payload Guard**: Direct document uploads are enforced with a strict **10MB ceiling** in `UploadController`. For larger assets, the app supports `is_external = true`, allowing users to share Google Drive or Mega URLs without straining backend storage resources.

### 3.4 Database Performance & RPC Atomic Operations
- **Atomic Counter RPCs**: To prevent race conditions and excessive multi-step HTTP requests during high-concurrency user interactions (likes, dislikes, bookmarks), operations are executed via server-side PostgreSQL Remote Procedure Calls:
  - `increment_likes(p_document_id, p_user_id)`
  - `decrement_likes(p_document_id, p_user_id)`
  - `increment_dislikes(p_document_id, p_user_id)`
  - `decrement_dislikes(p_document_id, p_user_id)`
- **Query Pagination**: The home feed query in `HomeController` limits document batch fetching to 50 items per call, keeping initial JSON payload sizes minimal.

---

## 4. Design & UI/UX Paradigms

```
+--------------------------------------------------------------------+
|  THEME: Premium Deep Blue (#0D47A1) + Material 3 Glassmorphism     |
|                                                                    |
|  [ Custom Dynamic Header / Glass Overlays (.withValues(alpha: x)) ]|
|  [ Material 3 Cards | Custom Shimmer Loaders | Lottie Feedback ]  |
+--------------------------------------------------------------------+
```

### 4.1 Visual Identity & Color Palette
- **Branding**: Rebranded from NoteHub to **Serious Study**, shifting to a "Premium Deep Blue" (`#0D47A1`) primary palette that reflects the academic identity of Mumbai University.
- **Color System (`lib/core/config/color.dart`)**:
  - Primary Accent: `#0D47A1` (Deep Blue)
  - Secondary Accent: `#1976D2` (Light Blue)
  - Official Accent: `#B8860B` (Dark Goldenrod for administrative badges)
  - Surface Glass: Translucent white overlay (`Colors.white.withValues(alpha: 0.15)`)

### 4.2 Material 3 & Glassmorphism Aesthetics
- The UI combines **Material 3** component structures with **Glassmorphism** backdrops on headers, top bars, bottom navigation, and profile cards.
- Modernized color opacity methods are enforced across all UI components using `.withValues(alpha: ...)` to align with Dart 3.5.4+ standards and avoid deprecated `.withOpacity()` precision loss warnings.

### 4.3 Visual Feedback & State Representation
- **Shimmer Placeholders**: `Shimmer` loaders (`custom_shimmer.dart`) are presented during asynchronous data fetching on the home feed, search tab, and profile document lists.
- **Vector & Lottie Animations**: Uses `flutter_svg` for crisp scale-independent icons and `Lottie` animations for contextual feedback on empty search states or successful document uploads.

---

## 5. Security Architecture & Threat Audit

The security architecture relies on a multi-layered defense model enforced at both the client SDK level and the PostgreSQL database engine.

```
+-------------------------------------------------------------------+
|                         SECURITY LAYERS                           |
|  1. Auth Engine: Supabase JWT + Argon2/Bcrypt Hashing             |
|  2. API Enforcement: Row Level Security (RLS) on all 7 Tables     |
|  3. Role Protection: Admin WITH CHECK Clause & Verification Trigger|
|  4. RPC Isolation: SECURITY DEFINER with SET search_path = public |
+-------------------------------------------------------------------+
```

### 5.1 Authentication & Token Handling
- **JWT Session Management**: User authentications are issued and validated by Supabase Auth using JSON Web Tokens (JWT). Sessions are securely stored on disk and automatically refreshed by `Supabase.instance.client`.
- **Password Security**: Client passwords are never handled in plain text or stored in local application state; hashing is managed server-side by Supabase Auth (Argon2 / Bcrypt).

### 5.2 Row Level Security (RLS) Audit
Row Level Security is explicitly enabled on all public tables in `SUPABASE_SCHEMA.sql`:

1. **`profiles` Table**:
   - `SELECT`: Publicly viewable by all authenticated users (`USING (true)`).
   - `INSERT`: Users can only insert their own profile (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Users can only update their own profile (`USING (auth.uid() = id)`). Privilege escalation is mitigated by validating `is_admin` immutability via `WITH CHECK`.
2. **`documents` Table**:
   - `SELECT`: Publicly viewable by all users.
   - `INSERT`: Users can only insert documents where `user_id = auth.uid()`.
   - `UPDATE` / `DELETE`: Restricted to document owners (`auth.uid() = user_id`) or administrative profiles (`is_admin = true`).
3. **`comments`, `interactions`, `bookmarks`, `notifications`, `followers` Tables**:
   - All write and read operations are bound strictly to `auth.uid()` checks matching the record's user or receiver foreign key.

### 5.3 Privilege Escalation Prevention
- **Admin Flag Guard**: Prevents non-admin users from altering their `is_admin` status during profile updates:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (
      auth.uid() = id
      AND is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
    );
  ```
- **Official Verification Trigger**: Restricts setting `is_official = true` on notes to administrative users via a PostgreSQL trigger:
  ```sql
  CREATE OR REPLACE FUNCTION public.check_official_permission()
  RETURNS TRIGGER AS $$
  BEGIN
    IF NEW.is_official = true THEN
      IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND is_admin = true
      ) THEN
        RAISE EXCEPTION 'Only administrators can mark content as official.';
      END IF;
    END IF;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
  ```
- **Search Path Hijacking Protection**: All database functions created with `SECURITY DEFINER` explicitly include `SET search_path = public` to prevent search-path injection vulnerabilities.

---

## 6. PostgreSQL Database Schema & Serverless Backend

### 6.1 Database ERD & Schema Summary

#### `profiles` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | Primary Key, FK -> `auth.users` | Unique user auth identifier |
| `username` | `TEXT` | UNIQUE, NOT NULL | Account handle |
| `display_name` | `TEXT` | - | User full display name |
| `profile_url` | `TEXT` | - | Supabase Storage avatar URL |
| `institute` | `TEXT` | Default: 'Mumbai University' | Academic institution |
| `academic_interests`| `TEXT[]` | - | Array of study topics |
| `is_admin` | `BOOLEAN` | Default: `false` | Administrative privilege flag |
| `followers` | `INT` | Default: `0` | Cached follower counter |
| `following` | `INT` | Default: `0` | Cached following counter |
| `documents` | `INT` | Default: `0` | Cached document counter |

#### `documents` Table
| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `BIGINT` | Primary Key, Identity | Unique note/tweet ID |
| `user_id` | `UUID` | FK -> `profiles.id` | Note author ID |
| `name` | `TEXT` | NOT NULL | Title of note or tweet |
| `topic` | `TEXT` | - | Subject/course tag |
| `description` | `TEXT` | - | Detailed description |
| `document_url` | `TEXT` | Nullable | Supabase Storage file URL or external link |
| `cover_url` | `TEXT` | - | Supabase Storage thumbnail URL |
| `likes_count` | `INT` | Default: `0` | Atomic like counter |
| `dislikes_count`| `INT` | Default: `0` | Atomic dislike counter |
| `is_external` | `BOOLEAN` | Default: `false` | External drive link indicator |
| `is_official` | `BOOLEAN` | Default: `false` | Official MU verification badge |
| `post_type` | `TEXT` | CHECK (`'note'`, `'tweet'`) | Content format indicator |

#### Additional Tables
- **`comments`**: ID (`UUID`), `document_id`, `user_id`, `parent_id` (for nested replies), `content`.
- **`interactions`**: ID (`BIGINT`), `document_id`, `user_id`, `type` (`'like'`/`'dislike'`), UNIQUE(`document_id`, `user_id`).
- **`bookmarks`**: ID (`BIGINT`), `document_id`, `user_id`, UNIQUE(`document_id`, `user_id`).
- **`notifications`**: ID (`BIGINT`), `receiver_id`, `sender_id`, `document_id`, `type`, `content`, `is_read`, `is_global`.
- **`followers`**: ID (`BIGINT`), `follower_id`, `following_id`, UNIQUE(`follower_id`, `following_id`).
- **`remote_config`**: Key (`TEXT` Primary Key), `value` (`JSONB`), `updated_at`.

---

## 7. Developer Maintenance & Quality Assurance Manual

### 7.1 Environment Requirements
- **Flutter SDK**: `3.24.0` or higher.
- **Dart SDK**: `^3.5.4` (mandatory for modern color `.withValues()` API compatibility and `activeThumbColor` Switch property support).
- **Android Target**: `compileSdk 36`, Java 17 compatibility configured in `notehub/android/app/build.gradle`.

### 7.2 Zero Warnings Linting Policy
The codebase enforces strict code quality compliance under `flutter analyze`. Developers must adhere to the following rules:
1. **Color Modernization**: Do not use deprecated `.withOpacity()`. Use `.withValues(alpha: 0.x)` instead.
2. **Switch Widgets**: Use `activeThumbColor` instead of deprecated `activeColor` on Flutter `Switch` controls.
3. **Flow Control Braces**: All `if` statements must use explicit curly braces (`curly_braces_in_flow_control_structures`).
4. **Empty Catch Annotation**: Silent `catch` blocks must include the exact comment `// ignore: empty_catches` placed cleanly on its own line inside the catch block.

### 7.3 Testing & Build Commands
- **Run Static Analysis**:
  ```bash
  cd notehub && flutter analyze
  ```
- **Run Unit Tests**:
  ```bash
  cd notehub && flutter test
  ```
- **Build Android APK**:
  ```bash
  cd notehub && flutter build apk --release
  ```

---
*Maintained and Verified by Jules, AI Software Engineer.*
