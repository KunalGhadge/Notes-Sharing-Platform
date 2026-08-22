# Serious Study (formerly NoteHub) - Developer Guide & System Manual

This document provides a comprehensive, technical analysis of the **Serious Study** repository from a developer's perspective. It documents the architecture, performance optimization strategies, Material 3 design system, security & Row Level Security (RLS) implementation, component mapping, and quality assurance procedures.

---

## 1. System Architecture & High-Level Overview

Serious Study is an academic social platform tailored for Mumbai University students, providing note sharing, peer networking, content posting ("tweets"), and official academic updates.

```
+-----------------------------------------------------------------------+
|                             FLUTTER APP                               |
|                                                                       |
|   +-------------------+    +-------------------+    +-------------+   |
|   |    UI Views &     |--->|  GetX Controllers |--->| Hive Caching|   |
|   |   Glass Widgets   |    | (Reactive Logic)  |    | (user/down) |   |
|   +-------------------+    +-------------------+    +-------------+   |
|                                     |                                 |
+-------------------------------------|---------------------------------+
                                      | Supabase SDK / Dio
                                      v
+-----------------------------------------------------------------------+
|                          SUPABASE BACKEND                             |
|                                                                       |
|   +-------------------+    +-------------------+    +-------------+   |
|   | Supabase Auth     |    | PostgreSQL DB     |    |  Supabase   |   |
|   | (JWT / Argon2)    |    | (RLS & RPCs)      |    |  Storage    |   |
|   +-------------------+    +-------------------+    +-------------+   |
+-----------------------------------------------------------------------+
```

### Core Stack
- **Framework**: Flutter 3.24+ / Dart SDK ^3.5.4
- **State Management**: `GetX` (`^4.6.6`) for reactive controller bindings, routing, and dependency injection.
- **Local Storage**: `Hive` (`^2.2.3`) & `hive_flutter` for persistent NoSQL caching of user session state and download metadata.
- **Backend Infrastructure**: Serverless `Supabase` (PostgreSQL 15+, JWT Auth, Object Storage, and Postgres Realtime).
- **HTTP & Downloader**: `Dio` (`^5.9.1`) for direct file transfers and local caching via `path_provider`.
- **Media Compression**: `flutter_image_compress` for client-side asset optimization.

---

## 2. Performance Analysis

### 2.1 Reactive State Management & Memory Efficiency
- **GetX Reactive Binding**: Business logic is separated into standalone `GetxController` classes (e.g., `DocumentController`, `HomeController`, `ProfileController`). Views use `Obx` wrappers or `GetBuilder` to eliminate unnecessary widget subtree re-renders.
- **Controller Lifecycle Management**: Controllers are registered cleanly via `Get.put()` in `main.dart` or lazily instantiated on screen initialization to prevent memory leaks.

### 2.2 Multi-Tier Caching Architecture
- **Instant Boot Local Caching (`HiveBoxes.userBox`)**: User session metadata (`id`, `displayName`, `username`, `profileUrl`, follower/document counts) is persisted in Hive's binary box. Upon app launch, profile views render immediately without waiting for network responses.
- **Offline Download Index (`HiveBoxes.downloadsBox`)**: Metadata for downloaded files is stored locally in `downloadsBox`, enabling full offline document listing and instant local retrieval.
- **Network File Caching (`FileCachingService`)**: The `FileCachingService` checks the local temporary directory before triggering Dio network downloads. Existing cached files are returned immediately, eliminating redundant bandwidth usage.

### 2.3 Media & Image Optimization Pipeline
- **Client-Side Image Compression**: Before uploading cover images or avatars to Supabase Storage, `ImageHelper.compressImage()` compresses images to JPEG format with 70% quality and a maximum 1024x1024 resolution.
- **Network Thumbnail Caching**: `CachedNetworkImage` is used across image components (e.g., `HomeHeader`, `ProfileHeader`) to cache remote images on disk and avoid duplicate transfers.

### 2.4 Database Scalability & Atomic Operations
- **Atomic Database Functions (RPCs)**: User interactions (likes, dislikes, bookmarks) call PostgreSQL RPCs (e.g., `increment_likes`, `decrement_dislikes`) defined in `SUPABASE_SCHEMA.sql`. This delegates counter arithmetic to the database server, avoiding race conditions and payload inflation.
- **Batching & Sticky Pagination**: `HomeController` fetches document feeds in batches (`.limit(50)`) ordered by `created_at desc`, ensuring predictable query timing as the database grows.
- **Real-time Subscriptions**: Realtime integration (`supabase.channel('public:documents').onPostgresChanges(...)`) pushes feed changes directly to active clients without polling.

### 2.5 UI & Render Performance
- **Shimmer Placeholders**: `HomeDocumentSection` and `SearchPage` render lightweight `shimmer` skeletons during asynchronous data loading, preventing layout shifts.
- **Lottie Vector Animations**: Used for empty search states and upload confirmation feedback, delivering smooth 60fps visuals without raster asset overhead.

---

## 3. Design & UI/UX System

### 3.1 Design Philosophy & Aesthetics
- **Material 3 Foundation**: Built using Flutter's `useMaterial3: true` design tokens.
- **Rebranded "Premium Deep Blue" Palette**: Primary primary color token is `#0D47A1` (Deep Blue), representing academic integrity and trust.
- **Glassmorphism Aesthetic**: UI containers feature semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`), multi-stop linear gradients (`AppGradients.glassGradient`), and rounded borders (`BorderRadius.circular(16)`).

### 3.2 Color Palette Tokens (`lib/core/config/color.dart`)
- **Primary Color (`PrimaryColor`)**:
  - `shade500` / `shade900`: `#0D47A1` (Premium Deep Blue)
  - `shade100`: `#E3F2FD`, `shade200`: `#BBDEFB`, `shade600`: `#1976D2`
- **App Gradients (`AppGradients`)**:
  - `premiumGradient`: LinearGradient from `#0D47A1` to `#1976D2`.
  - `glassGradient`: LinearGradient from `white (10% alpha)` to `white (5% alpha)`.
- **Special Accent Colors**: `premiumGold` (`#FFD700`), `royalBlue` (`#0D47A1`).

### 3.3 Typography & Custom Icons
- **Typography (`lib/core/config/typography.dart`)**: Enforces clean font hierarchies using `Poppins` and `Inter` through `google_fonts`.
- **Custom Icons (`lib/core/helper/custom_icon.dart`)**: Vector-rendered custom icon helpers mapped to academic actions (notes, download, official verification badge).

---

## 4. Security & Database Audit

### 4.1 Authentication & Session Management
- **Supabase Auth (JWT)**: User authentication utilizes managed JWT tokens. Passwords are securely hashed with Argon2/Bcrypt on Supabase servers.
- **Custom App Redirect Scheme**: OAuth and email verification callbacks use `io.supabase.flutternotehub://login-callback` for deep-linking back into the app session.

### 4.2 Row Level Security (RLS) Policies
Row Level Security is enabled across all 7 PostgreSQL tables in `SUPABASE_SCHEMA.sql`:

1. **`profiles` Table**:
   - `SELECT`: Publicly viewable (`FOR SELECT USING (true)`).
   - `INSERT`: Owner restriction (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Owner restriction (`FOR UPDATE USING (auth.uid() = id)`). Prevents updating non-owned profiles.
2. **`documents` Table**:
   - `SELECT`: Publicly viewable (`FOR SELECT USING (true)`).
   - `INSERT`: Verified user (`WITH CHECK (auth.uid() = user_id)`).
   - `UPDATE/DELETE`: Document owner (`FOR ALL USING (auth.uid() = user_id)`).
   - `ADMIN UPDATE`: Controlled by RLS policy `Admins can update documents` checking `is_admin = true` on `profiles`.
3. **`comments` Table**:
   - `SELECT`: Publicly viewable.
   - `INSERT`: User restriction (`WITH CHECK (auth.uid() = user_id)`).
4. **`interactions` & `bookmarks` Tables**:
   - Unique constraints (`document_id, user_id`) prevent duplicate likes/bookmarks.
5. **`notifications` Table**:
   - Private read policy (`USING (auth.uid() = receiver_id)`).

### 4.3 RPC Function Security & Definer Protections
- **`SECURITY DEFINER` Execution**: Counter RPCs execute with security definer privileges to update interaction aggregates atomically.
- **Search Path Protection**: RPC definitions include explicit `SET search_path = public` directives to mitigate search-path hijacking attacks.

### 4.4 Privilege Escalation Prevention
- **Official Post Verification**: Official updates (`is_official = true`) are gated by backend verification checks and admin user profiles (`is_admin = true`).
- **Profile Privilege Isolation**: Updates to `is_admin` status cannot be executed via general profile update endpoints; changes require database service role key overrides.

---

## 5. Component Directory & File Mapping

```
notehub/lib/
├── controller/                      # GetX Controllers (Business & Reactive Logic)
│   ├── auth_controller.dart          # Auth signin, signup, profile sync, Hive session store
│   ├── document_controller.dart      # Document lifecycle, likes, bookmarks, RPC calls, sync
│   ├── home_controller.dart          # Feed fetching, sticky sort, real-time channels
│   ├── upload_controller.dart        # Upload pipeline, 10MB limit check, image compression
│   ├── profile_controller.dart       # User profile data, document feeds, follower stats
│   ├── profile_user_controller.dart  # Secondary user profile view controller
│   ├── comment_controller.dart       # Comment hierarchy and nested replies
│   ├── connection_controller.dart    # Peer follow/unfollow network management
│   ├── download_controller.dart      # Local download indexing and status tracking
│   ├── file_controller.dart          # File picker and file system bridge
│   ├── notification_controller.dart  # User notification feed & global broadcast state
│   ├── remote_config_controller.dart# Dynamic app config fetched from Supabase remote_config
│   ├── showcase_controller.dart      # Onboarding walkthrough state
│   ├── search_controller.dart        # Search filter and query management
│   └── bottom_navigation_controller.dart # Bottom bar tab index state
├── service/                         # External & Platform Services
│   ├── file_caching.dart             # Local temp file caching service using Dio & path_provider
│   ├── file_download.dart            # Native file downloading and saving service
│   └── notification_service.dart     # Flutter local notification initialization & dispatch
├── model/                           # Data Models & Hive Adapters
│   ├── user_model.dart               # User model with HiveType adapter (@HiveType(typeId: 0))
│   ├── user_model.g.dart             # Auto-generated Hive type adapter
│   ├── document_model.dart           # Document metadata model (notes & tweets)
│   ├── post_model.dart               # Social post model
│   └── mini_user_model.dart          # Compact user profile model
├── core/                            # Core Constants, Utilities & Themes
│   ├── config/
│   │   ├── color.dart                # PrimaryColor (#0D47A1), AppGradients, color tokens
│   │   └── typography.dart           # GoogleFonts typography definitions
│   ├── meta/
│   │   └── app_meta.dart             # App title, Supabase URL, and Anon Key configuration
│   └── helper/
│       ├── hive_boxes.dart           # Static accessor for userBox and downloadsBox
│       ├── image_helper.dart         # FlutterImageCompress utility wrapper
│       └── custom_icon.dart          # Vector icon asset helpers
├── view/                            # UI Views & Screeen Components
│   ├── splash_screen/splash.dart     # Splash screen with auth session check
│   ├── auth_screen/login.dart        # Login and registration interface
│   ├── home_screen/                  # Main feed view and header components
│   ├── document_screen/              # Note detail view, previewer, and comments
│   ├── upload_screen/                # Document and tweet upload form
│   ├── profile_screen/               # User profile, edit bio, and document lists
│   ├── notification_screen/          # Activity notifications list
│   ├── connection_screen/            # Followers and following user lists
│   ├── official_screen/              # Official university announcements feed
│   ├── search_screen/                # Search bar and filtered results
│   ├── settings_screen/              # Settings, about app, and theme info
│   └── bottom_footer/                # Glassmorphic bottom navigation footer
└── main.dart                        # App entry point, Supabase init, Hive init, GetMaterialApp
```

---

## 6. Maintenance & QA Procedures

### 6.1 Prerequisites
- **Flutter SDK**: `3.24+`
- **Dart SDK**: `^3.5.4`
- **Java JDK**: `Java 17` (configured in `android/app/build.gradle`)
- **Android Target**: `compileSdk 36`

### 6.2 Modernization & Linting Rules ("Zero Warnings")
1. **Color Opacity**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
2. **Switch Widgets**: Use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Braces**: Always enclose `if` / `else` statements in curly braces `{}`.
4. **Empty Catches**: Place `// ignore: empty_catches` on its own line inside empty catch blocks:
   ```dart
   try {
     // action
   } catch (e) {
     // ignore: empty_catches
   }
   ```

### 6.3 Verification Commands
To verify code quality and test health:

```bash
# Run static analysis (must report zero errors)
cd notehub
flutter analyze

# Execute automated test suite
flutter test
```

---
*Maintained by Jules, AI Software Engineer.*
