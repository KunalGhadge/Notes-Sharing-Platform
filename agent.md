# Developer Technical Manual & System Architecture: Serious Study (formerly NoteHub)

## Executive Summary
**Serious Study** is a high-performance, serverless academic networking and resource-sharing mobile application built for the Mumbai University student community. The application enables students, faculty, and administrative creators to publish study notes, previous year questions (PYQs), important notes (IMPs), and short academic announcements ("tweets").

Originally built on a legacy Django/MongoDB stack, the platform underwent a complete modernization to a serverless **Supabase** backend paired with a **Flutter** (Dart SDK ^3.5.4 / Flutter 3.24+) mobile client. This document presents an in-depth developer-perspective technical analysis covering system architecture, performance optimization, visual design standards, security parameters, database policies, and an exhaustive codebase mapping.

---

## 1. System Architecture & High-Level Design

```
+-----------------------------------------------------------------------------------+
|                                  FLUTTER CLIENT                                   |
|                                                                                   |
|  +---------------------+   +---------------------+   +--------------------------+ |
|  |     UI Views        |   |   GetX Controllers  |   |    Hive Local Storage    | |
|  |  (Material 3 /      |<->| (Document, Profile, |<->|  (userBox / downloads)   | |
|  |   Glassmorphism)    |   |  Upload, Home, Auth)|   |                          | |
|  +---------------------+   +---------------------+   +--------------------------+ |
|                                       |                                           |
+---------------------------------------|-------------------------------------------+
                                        | HTTPS / WSS (JWT Authenticated)
                                        v
+-----------------------------------------------------------------------------------+
|                                 SUPABASE BACKEND                                  |
|                                                                                   |
|  +---------------------+   +---------------------+   +--------------------------+ |
|  |    Supabase Auth    |   | PostgreSQL Engine   |   |     Supabase Storage     | |
|  |   (JWT / Argon2)    |   | (RLS / RPC Functions|   | (Documents & Thumbnails  | |
|  |                     |   | / Postgres Realtime)|   |    Storage Buckets)      | |
|  +---------------------+   +---------------------+   +--------------------------+ |
+-----------------------------------------------------------------------------------+
```

### Core Architecture Components:
- **Client Architecture**: MVC-like reactive design utilizing **GetX** for dependency injection, routing, and state management.
- **Persistence Layer**: **Hive** for ultra-fast NoSQL key-value caching of session tokens and user profiles on mobile devices.
- **Backend Architecture**: Serverless **Supabase** infrastructure leveraging PostgreSQL for data persistence, Row Level Security (RLS) for fine-grained authorization, and RPC functions for atomic counter transactions.
- **Networking & Storage**: `supabase_flutter` for database/auth/realtime subscriptions, combined with `dio` and `path_provider` for managed file downloads and local disk caching.

---

## 2. Performance Analysis

### 2.1 Reactive State Management
- **GetX Reactivity (`Obx` / `GetX` vs `GetBuilder`)**:
  - `Obx` and `GetX` observe reactive variables (`RxBool`, `RxList`, `Rxn`) and trigger granular widget repaints, avoiding expensive subtree rebuilds.
  - `GetBuilder` is strategically used in heavy feed components (e.g., `DocumentCard`, `PostCard`) to perform manual `update()` calls, eliminating streams overhead for static lists.
- **Controller Separation**: Controllers are organized by domain responsibility (`AuthController`, `DocumentController`, `HomeController`, `UploadController`, `ProfileController`), ensuring isolated business logic and lifecycle management.

### 2.2 Local Storage & Offline-First Strategy
- **Hive Integration (`lib/core/helper/hive_boxes.dart`)**:
  - User session profiles are persisted in `userBox`. During app initialization, `HiveBoxes.userId` and `HiveBoxes.username` are immediately accessed synchronously, bypassing asynchronous startup lag.
  - Downloads metadata is stored in `downloadsBox`, enabling offline reference to previously fetched resources without re-querying backend storage.

### 2.3 Media & Asset Optimization
- **Image Compression Pipeline (`lib/core/helper/image_helper.dart`)**:
  - Uploaded cover images are compressed on-device using `flutter_image_compress` (70% quality, 1024x1024 bound) prior to binary submission to Supabase Storage. This reduces network payload size by up to 80%.
- **Network Image Caching**:
  - `cached_network_image` is implemented across document list items and profile headers (`HomeHeader`, `PostCard`), reducing memory allocation and redundant network fetches.
- **Vector Graphics & Animations**:
  - Lightweight vector assets (`flutter_svg`) and `Lottie` animations (`assets/animations/notes.json`) provide responsive feedback without raster graphic overhead.

### 2.4 Data Fetching & Database Query Performance
- **Paginated & Batched Queries**:
  - `HomeController.fetchUpdates()` queries the `documents` table with `limit(50)` and orders results by `created_at DESC`, keeping initial payload small.
- **Database Functions & RPCs**:
  - User interaction counters (`likes_count`, `dislikes_count`, `bookmarks`) use database-level PostgreSQL stored procedures (`increment_likes`, `decrement_dislikes`) to eliminate client-side race conditions and multi-step round trips.
- **Dio File Caching (`lib/service/file_caching.dart`)**:
  - When downloading resources, Dio checks the local temp directory (`path_provider`) before requesting remote files from Supabase Storage buckets.

### 2.5 Perceived Performance & UI Smoothness
- **Shimmer Loading Skeletons**:
  - `Shimmer` effects (`shimmer` package) render placeholder shapes during asynchronous data fetching in `HomeDocumentSection` and `ProfileUser`.
- **Optimistic UI Updates**:
  - `DocumentController.toggleLike()`, `toggleDislike()`, and `toggleBookmark()` update client state immediately upon user tap before firing backend asynchronous requests. If the network call fails, client state reverts gracefully with a toast notification.

---

## 3. Design & Architecture Analysis

### 3.1 Visual Aesthetics & UI Paradigm
- **Design System**: Built on **Material 3** guidelines with customized **Glassmorphic** overlays.
- **Color System (`lib/core/config/color.dart`)**:
  - Primary Brand Palette: "Premium Deep Blue" (`#0D47A1` - `PrimaryColor.shade500`).
  - Accent & Special Roles: Premium Gold (`#FFD700`) and Dark Goldenrod (`#B8860B`) for verified Admin badges and Official content indicators.
  - Modernized Alpha API: Fully updated to use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`, preventing precision loss in Dart SDK 3.5.4+.
- **Gradients**:
  - `AppGradients.premiumGradient`: Linear gradient from `#0D47A1` to `#1976D2`.
  - `AppGradients.glassGradient`: Semi-transparent gradient for glassmorphism overlays.

### 3.2 Typography System (`lib/core/config/typography.dart`)
- Centralized font hierarchy using Google Fonts (`Poppins` / system default):
  - Headings: `heading1` to `heading6` with predefined weights and line heights.
  - Subheads: `subHead1` to `subHead3`.
  - Body Text: `body1` to `body4`.

### 3.3 Reusable Component Architecture (`lib/view/widgets/`)
- **`DocumentCard`**: Renders note/document metadata, cover thumbnail, official badge, popup options menu (Download, Delete), and animated like counter (`LikesWithHeart`).
- **`PostCard`**: Specialized card for resource previews featuring a glassmorphic title overlay (`GlassmorphicContainer`).
- **`AdminBadge`**: Gradient badge (`ADMIN` with verified icon) assigned to administrator accounts.
- **`CommentTile`**: Multi-level nested comment item supporting threaded replies, timestamp formatting, and inline deletion for comment authors or admins.
- **`RefresherWidget`**: Pull-to-refresh wrapper around GetX controller re-fetch methods.

---

## 4. Security & Data Integrity Audit

### 4.1 Authentication & Password Security
- **Supabase Auth Integration**: Custom plain-text session authentication from the legacy Django app was replaced with **Supabase Auth (JWT)**.
- **Cryptographic Hashing**: User credentials are not handled in plain text; Supabase handles password storage using industry-standard password hashing (Argon2 / Bcrypt).
- **Session Tokens**: JWT access tokens are automatically stored and refreshed by `SupabaseClient`.

### 4.2 Row Level Security (RLS) Enforcement
Row Level Security is enabled across all database tables in `SUPABASE_SCHEMA.sql`:

```sql
-- Security Baseline: Enable RLS on all public tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;
```

- **`profiles` Policy**: Public read (`SELECT USING (true)`), restricted write (`INSERT/UPDATE WITH CHECK (auth.uid() = id)`).
- **Privilege Escalation Prevention**: An explicit `WITH CHECK` clause prevents standard users from setting their own `is_admin` column to `true`:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
  ```
- **`documents` Policy**: Public read (`SELECT USING (true)`), author insert (`INSERT WITH CHECK (auth.uid() = user_id)`), author/admin update and delete (`ALL USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true))`).
- **Official Content Protection**: Setting `is_official = true` on documents is protected via database trigger `ensure_official_permission()`, enforcing that only users with `is_admin = true` in `profiles` can mark posts as official.

### 4.3 Database Function Security
- **RPC Search Path Isolation**: PostgreSQL functions defined with `SECURITY DEFINER` explicitly declare `SET search_path = public` to prevent search-path hijacking attacks.

---

## 5. Exhaustive Directory & File Mappings

### 5.1 Root & Configuration Files
- **`SUPABASE_SCHEMA.sql`**: Full PostgreSQL database schema definition including tables, migration alterations, indexes, RLS policies, triggers, realtime publication setup, and RPC counter functions.
- **`ANALYSIS.md`**: High-level executive summary and tech stack comparison.
- **`agent.md`**: Primary system developer guide and maintenance manual.
- **`README.md`**: Project introduction, features overview, setup instructions, and screenshot showcase.

### 5.2 Application Source (`notehub/lib/`)

#### Controllers (`lib/controller/`)
- `auth_controller.dart`: Handles registration, login with Supabase Auth, profile sync with `userBox`, and session teardown.
- `document_controller.dart`: Coordinates document fetching, deletion, optimistic like/dislike/bookmark updates, and external URL/file opening.
- `home_controller.dart`: Manages feed tabs ("For You", "Official Updates"), paginated fetching, real-time Postgres changes subscription (`supabase.channel`), and sticky ordering.
- `upload_controller.dart`: Validates input, manages multi-part uploads (document file + cover image), handles external link entries, applies image compression, and blocks uploads exceeding 10MB.
- `profile_controller.dart`: Syncs logged-in user state from Hive and Supabase.
- `profile_user_controller.dart`: Handles target user profile loading and follow/unfollow operations.
- `showcase_controller.dart`: Manages profile sub-tabs ("Uploads", "Saved Documents").
- `comment_controller.dart`: Manages nested comment creation, parent-child reply chains, and comment deletion.
- `notification_controller.dart`: Queries user notifications and marks notifications as read.
- `search_controller.dart`: Implements resource and user search with subject/title filtering.
- `download_controller.dart` & `file_controller.dart`: Manage local file reference lists and disk storage cleanup.
- `bottom_navigation_controller.dart`: Manages current bottom navigation bar index.
- `connection_controller.dart`: Monitors device connectivity state.
- `remote_config_controller.dart`: Fetches dynamic app configurations from Supabase `remote_config` table.

#### Core Modules (`lib/core/`)
- `config/color.dart`: Defines primary (`PrimaryColor`), danger (`DangerColors`), grayscale, gradient, and glassmorphic color tokens.
- `config/typography.dart`: Text styles configured using Google Fonts Poppins.
- `helper/hive_boxes.dart`: Hive setup providing typed getters for `userBox` and `downloadsBox`.
- `helper/image_helper.dart`: Image compression utility using `flutter_image_compress`.
- `helper/custom_icon.dart`: SVG icon and custom avatar rendering helpers.
- `meta/app_meta.dart`: Environment configuration containing Supabase URL, Anon Key, app name, and default avatar CDN URL.

#### Data Models (`lib/model/`)
- `document_model.dart`: Data class representing notes and tweets with likes, dislikes, bookmark status, external links, official flags, and author metadata.
- `user_model.dart` / `user_model.g.dart`: Data class and Hive adapter for user profiles.
- `mini_user_model.dart`: Lightweight user representation for search lists.
- `post_model.dart`: Specialized post representation.

#### Services (`lib/service/`)
- `file_caching.dart`: Local cache management checking temp directory prior toDio network download.
- `file_download.dart`: Download manager utilizing Dio and posting local push notifications via `flutter_local_notifications`.
- `notification_service.dart`: Initialization and handler for local notifications.

#### Views & UI Screen Components (`lib/view/`)
- `layout.dart`: Root application scaffold containing `BottomFooter` navigation.
- `auth_screen/`: Login (`login.dart`), Registration (`register.dart`), and form widgets (`login_form.dart`, `login_header.dart`).
- `home_screen/`: Main feed view (`home.dart`), header with profile greeting and search action (`home_header.dart`), and document list sections (`home_document_section.dart`).
- `official_screen/`: Dedicated tab showcasing verified official university notices (`official_screen.dart`).
- `document_screen/`: Detailed note view (`document.dart`), PDF/Image previewer (`document_details.dart`), and comment section (`comment_section.dart`, `comment_tile.dart`).
- `upload_screen/`: Resource creation page (`upload_screen.dart`), upload form (`upload_form.dart`), file picker buttons (`upload_button.dart`).
- `profile_screen/`: Personal profile view (`profile.dart`), third-person profile view (`profile_user.dart`), follower metrics (`follower_widget.dart`), and content showcase (`profile_showcase.dart`).
- `search_screen/`: Search UI with real-time text query filtering (`search.dart`).
- `notification_screen/`: List view displaying activity alerts (`notifications.dart`).
- `settings_screen/`: Information and about page (`about.dart`).
- `splash_screen/`: Animated splash screen checking session validity (`splash.dart`).
- `bottom_footer/`: Custom floating bottom navigation bar with active state highlights (`bottom_footer.dart`).
- `widgets/`: Reusable components (`document_card.dart`, `post_card.dart`, `admin_badge.dart`, `primary_button.dart`, `secondary_button.dart`, `loader.dart`, `toasts.dart`, `refresher_widget.dart`, `upload_text_field.dart`).

---

## 6. Developer QA & Maintenance Manual

### 6.1 Environmental Prerequisites
- **Flutter SDK**: `^3.24.0` (Channel stable)
- **Dart SDK**: `^3.5.4`
- **Android Target**: `compileSdk 36`, `minSdk 21`, `targetSdk 34`
- **Java Compatibility**: `Java 17` source and target compatibility configured in `notehub/android/app/build.gradle`.

### 6.2 Zero Warnings Code Quality Standard
The project enforces a strict "Zero Warnings" policy under `flutter analyze`.

To verify compliance:
```bash
cd notehub
flutter analyze
```
*Expected Output*: `No issues found!`

Key linter rules enforced across the codebase:
- `curly_braces_in_flow_control_structures`: All flow control statements (`if`, `else`, `for`) must be enclosed in explicit curly braces.
- Modernized Color API: All color opacity calls must use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
- Modernized Switch Controls: Switch widgets must use `activeThumbColor` instead of deprecated `activeColor`.
- `// ignore: empty_catches`: Silent catch blocks must be annotated on their own line within the block.

### 6.3 Test Execution
To run the automated test suite:
```bash
cd notehub
flutter test
```

---
*Maintained and Verified by Jules, AI Software Engineer.*
