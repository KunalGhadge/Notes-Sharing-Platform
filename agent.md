# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-centric technical analysis and maintenance guide for **Serious Study** (formerly NoteHub), the premier notes-sharing and academic networking platform for the Mumbai University student community.

---

## 1. Executive Summary & Architectural Overview

Serious Study is engineered using a modern, decoupled serverless architecture combining a high-performance **Flutter** frontend with a robust **Supabase** backend (PostgreSQL + JWT Auth + Object Storage).

```
+-----------------------------------------------------------------------+
|                            FLUTTER CLIENT                             |
|                                                                       |
|  +--------------------+  +----------------------+  +---------------+  |
|  |   GetX Views / UI   |  |   GetX Controllers   |  | Local Caching |  |
|  |  (Material 3 / M3) | <-> (State Management)  | <-> (Hive Boxes)  |  |
|  +--------------------+  +----------------------+  +---------------+  |
+-------------------------------------^---------------------------------+
                                      | Supabase SDK / Dio
                                      v
+-----------------------------------------------------------------------+
|                          SUPABASE BACKEND                             |
|                                                                       |
|  +--------------------+  +----------------------+  +---------------+  |
|  |   Supabase Auth    |  | PostgreSQL Database  |  | Storage Bucket|  |
|  |   (JWT / Argon2)   |  | (RLS / Triggers/RPC) |  | (Docs/Covers) |  |
|  +--------------------+  +----------------------+  +---------------+  |
+-----------------------------------------------------------------------+
```

### Key Architectural Principles:
- **Client Framework**: Flutter 3.24+ running on Dart SDK ^3.5.4.
- **Backend Infrastructure**: Serverless Supabase (PostgreSQL 15+, Supabase Auth, Supabase Storage).
- **State Management**: `GetX` reactive state management using an MVC-like pattern (Controllers decoupled from UI Views).
- **Local Persistence & Caching**: `Hive` NoSQL local storage for user profile metadata and offline download records.
- **Networking & File Operations**: `supabase_flutter` for database RPCs and real-time streams; `Dio` for high-throughput file streaming and caching.

---

## 2. In-Depth Performance Analysis

### 2.1 Reactive State Management (GetX)
- **Zero-Boilerplate Reactivity**: Uses GetX observable properties (`.obs`, `RxList`, `RxBool`, `RxString`) to eliminate redundant widget re-renders compared to standard stateful widgets.
- **Decoupled Business Logic**: Logic resides in dedicated controllers (`DocumentController`, `HomeController`, `UploadController`, `ProfileController`) ensuring views remain pure UI rendering layers.
- **Dependency Injection**: Controllers are lazily or globally initialized via `Get.put()` or `Get.lazyPut()`, minimizing memory footprint during app navigation.

### 2.2 Local Persistent Caching (Hive NoSQL)
- **Instant UI Bootstrapping**: User session data and profile info are stored locally in Hive boxes (`userBox` in `lib/core/helper/hive_boxes.dart`), ensuring instant profile loading on app start without awaiting network responses.
- **Download Tracking**: Local metadata for downloaded notes is saved in `downloadsBox`, enabling offline availability checks and reducing redundant download requests.

### 2.3 Media & File Handling Pipeline
- **Image Compression Pipeline**: `ImageHelper.compressImage()` (`lib/core/helper/image_helper.dart`) compresses user uploaded images to JPEG format at 70% quality with a maximum target dimension of 1024x1024 before uploading to Supabase Storage.
- **Network Image Caching**: `CachedNetworkImage` is used throughout avatar and cover renders (e.g., `HomeHeader`, `ProfileShowcase`) to cache remote assets in memory and disk storage.
- **Optimized Document Downloads**: `FileCachingService` (`lib/service/file_caching.dart`) checks local temporary storage before initializing Dio streams, preventing duplicate bandwidth usage.
- **Bandwidth Reduction via External Links**: `UploadController` supports dual-post modes: direct file uploads (enforcing a strict 10MB limit) and external links (Google Drive, Mega), enabling light storage overhead.

### 2.4 Database Scalability & Server-Side Atomic Operations
- **PostgreSQL Atomic RPCs**: To avoid client-side race conditions when updating engagement stats (likes, dislikes, bookmarks), the client executes atomic PostgreSQL RPC functions (`increment_likes`, `decrement_likes`, etc.).
- **Batching & Pagination**: `HomeController` fetches public documents in optimized batches (50 records per query), reducing payload size and initial rendering latency.
- **Realtime Postgres Channels**: Utilizes `supabase.channel('public:documents').onPostgresChanges(...)` to stream real-time document creation and updates directly to active feeds without continuous polling.
- **Visual Feedback & Perceived Performance**: Shimmer placeholders (`HomeDocumentSection`, `SearchPage`) are displayed during async queries to eliminate abrupt layout shifts.

---

## 3. Design System & Modern UI Paradigm

### 3.1 Design Guidelines & Palette
- **UI Architecture**: Implements Material 3 guidelines paired with modern **Glassmorphism**.
- **Primary Rebranded Palette**:
  - **Primary Accent**: "Premium Deep Blue" (`#0D47A1`).
  - **Secondary Accent**: Deep Dark Blue (`#0A3678`).
  - **Backgrounds**: Slate Dark (`#121824`) and Card Dark (`#1E2738`).
  - **Gradients**: `AppGradients.premiumGradient` creates a signature depth across headers and floating controls.
- **Typography**: Uses `GoogleFonts.poppins()` (`lib/core/config/typography.dart`) for a modern aesthetic.

### 3.2 Glassmorphism & Micro-Interactions
- Custom semi-transparent color overlays (e.g., `Colors.white.withValues(alpha: 0.15)`) create translucent floating cards, app bars, and bottom navigation.
- Custom vector graphics (`flutter_svg`) and `Lottie` animations deliver clear visual state feedback (e.g., empty search states, successful uploads, loading animations).

---

## 4. Security Architecture & Threat Model

### 4.1 Authentication & Session Management
- **Managed JWT Authentication**: Legacy custom session handling replaced with **Supabase Auth**. Requests carry signed JSON Web Tokens (JWT).
- **Password Security**: Passwords are saved with industry-standard hashing (Argon2/Bcrypt) handled directly by Supabase Auth; cleartext passwords never touch the database.
- **Deep-Link Callback Integration**: Custom URL scheme `io.supabase.flutternotehub://login-callback` handles secure OAuth and email confirmation callbacks.

### 4.2 Row Level Security (RLS) & Authorization
Row Level Security is strictly enabled across all PostgreSQL tables in `SUPABASE_SCHEMA.sql`:

| Table | SELECT Policy | INSERT Policy | UPDATE / DELETE Policy |
| :--- | :--- | :--- | :--- |
| `profiles` | Public (`true`) | Owner (`auth.uid() = id`) | Owner (`auth.uid() = id`) WITH CHECK (`is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())`) |
| `documents` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) or Admin |
| `comments` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `interactions` | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `bookmarks` | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `notifications`| Receiver (`auth.uid() = receiver_id` or `is_global = true`) | System / User | Receiver (`auth.uid() = receiver_id`) |
| `followers` | Public (`true`) | Follower (`auth.uid() = follower_id`) | Follower (`auth.uid() = follower_id`) |

### 4.3 Privilege Escalation Defenses & Security Hardening
- **Profile Privilege Escalation Prevention**: The `UPDATE` policy on `profiles` includes a `WITH CHECK` clause validating that regular users cannot modify their own `is_admin` flag.
- **Official Document Verification Guard**: An explicit PostgreSQL trigger `ensure_official_permission` verifies that setting `is_official = true` on `documents` is restricted exclusively to authenticated users with `is_admin = true` in their profile.
- **Search Path Hijacking Defense**: PostgreSQL RPC functions (e.g., `check_official_permission`, counter RPCs) are defined with `SECURITY DEFINER` and an explicit `SET search_path = public` parameter to prevent schema hijacking.

---

## 5. Comprehensive File-by-File & Directory Component Mappings

```
notehub/
├── android/                   # Native Android project configuration
│   └── app/build.gradle       # Gradle build rules (compileSdk 36, Java 17, MultiDex)
├── assets/                    # Static assets (images, icons, SVG, Lottie animations)
├── lib/
│   ├── main.dart              # Application entry point (Supabase, Hive, GetX initialization)
│   ├── layout.dart            # Main shell widget managing BottomNavigationBar views
│   ├── controller/            # GetX Business Logic Controllers
│   │   ├── auth_controller.dart              # User authentication, registration, session sync
│   │   ├── bottom_navigation_controller.dart # Bottom tab index state management
│   │   ├── comment_controller.dart           # Comment creation, fetching, nested replies
│   │   ├── connection_controller.dart        # Follow/unfollow networking logic
│   │   ├── document_controller.dart          # Note details, likes, dislikes, bookmarks, RPC calls
│   │   ├── download_controller.dart          # Local file download status & progress
│   │   ├── file_controller.dart              # File picking & document metadata parsing
│   │   ├── home_controller.dart              # Main feed fetching, Realtime subscriptions, batching
│   │   ├── notification_controller.dart      # Real-time notifications & feed alerts
│   │   ├── post_controller.dart              # Short post/tweet creation and interaction
│   │   ├── profile_controller.dart           # Auth user profile state & Hive sync
│   │   ├── profile_user_controller.dart      # Peer user profile views & stats
│   │   ├── remote_config_controller.dart     # Dynamic app configuration from Supabase
│   │   ├── search_controller.dart            # Document and user search query handler
│   │   ├── showcase_controller.dart          # Featured notes showcase state
│   │   └── upload_controller.dart            # Multi-part upload form handler & size checks
│   ├── core/                  # Configurations, metadata, utilities
│   │   ├── config/
│   │   │   ├── color.dart       # Color constants & Premium Deep Blue theme
│   │   │   └── typography.dart  # GoogleFonts Poppins text styles
│   │   ├── helper/
│   │   │   ├── custom_icon.dart # Custom SVG icon widgets
│   │   │   ├── hive_boxes.dart  # Hive box getters & storage keys
│   │   │   └── image_helper.dart# Compression utility (flutter_image_compress)
│   │   └── meta/
│   │       └── app_meta.dart    # App branding strings & Supabase credentials
│   ├── model/                 # Data Models & Adapters
│   │   ├── document_model.dart  # Document/Note data schema
│   │   ├── mini_user_model.dart  # Compact user avatar schema
│   │   ├── post_model.dart      # Post/Tweet schema
│   │   ├── user_model.dart      # User Profile schema
│   │   └── user_model.g.dart    # Hive TypeAdapter generated code
│   ├── service/               # Background & System Services
│   │   ├── file_caching.dart    # Dio file streaming & local caching service
│   │   ├── file_download.dart   # Disk download manager & path provider integration
│   │   └── notification_service.dart # Local system notifications setup
│   └── view/                  # UI Screens & Widgets
│       ├── auth_screen/        # Login & Registration views
│       ├── bottom_footer/      # Glassmorphic bottom navigation tab bar
│       ├── connection_screen/  # Peer connection & followers list views
│       ├── document_screen/    # Document detail, preview, comment section
│       ├── home_screen/        # Home feed, headers, category filters
│       ├── notification_screen/# User activity notifications list
│       ├── official_screen/    # Verified Mumbai University official updates
│       ├── onboarding_screen/  # First-time app introduction carousel
│       ├── profile_screen/     # User profile, edit modal, published notes showcase
│       ├── search_screen/      # Search bar & categorized query results
│       ├── settings_screen/    # About app, privacy, settings drawer
│       ├── splash_screen/      # App startup animation & session router
│       ├── upload_screen/      # Upload form, document picker, link input
│       └── widgets/            # Reusable UI components (buttons, cards, toasts, loaders)
```

---

## 6. Android Native Platform & Build Engineering

### 6.1 Build Gradle Configuration (`notehub/android/app/build.gradle`)
- **Namespace**: `com.divinevisionary.notehub`
- **Compile SDK & Target SDK**: `36` (Android 15 compatibility)
- **Java Compatibility**: `JavaVersion.VERSION_17` (Source and Target)
- **JVM Target**: `17`
- **Core Library Desugaring**: Enabled via `com.android.tools:desugar_jdk_libs:2.1.4` to support modern Java APIs across older Android runtime environments (required by `flutter_local_notifications`).
- **MultiDex**: `multiDexEnabled true` configured to support extensive method counts from third-party SDKs.

### 6.2 Android Manifest (`AndroidManifest.xml`)
- **Permissions**: Internet access (`INTERNET`), Storage read/write permissions (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE`).
- **Deep-Link Intent Filter**:
  ```xml
  <intent-filter>
      <action android:name="android.intent.action.VIEW" />
      <category android:name="android.intent.category.DEFAULT" />
      <category android:name="android.intent.category.BROWSABLE" />
      <data android:scheme="io.supabase.flutternotehub" android:host="login-callback" />
  </intent-filter>
  ```

---

## 7. Developer QA, Maintenance & "Zero Warnings" Guidelines

### 7.1 Environmental Requirements
- **Flutter SDK**: `^3.24.0` (Stable channel)
- **Dart SDK**: `^3.5.4`

### 7.2 "Zero Warnings" Code Standards
1. **Modern Color API Usage**: Avoid deprecated `.withOpacity()`. Use `.withValues(alpha: opacity_value)` (e.g., `Colors.white.withValues(alpha: 0.15)`).
2. **Switch Controls**: Use `activeThumbColor` instead of deprecated `activeColor` on `Switch` widgets.
3. **Empty Catch Block Annotations**: Place `// ignore: empty_catches` on its own line inside the catch block to prevent syntax corruption of subsequent `finally` blocks.
   ```dart
   try {
     // operation
   } catch (e) {
     // ignore: empty_catches
   } finally {
     // cleanup
   }
   ```
4. **Flow Control Braces**: Always enclose conditional blocks in explicit curly braces (`if (condition) { ... }`).

### 7.3 Testing & Quality Verification Commands
Always run the following commands inside `notehub/` before submitting pull requests:

```bash
# 1. Run Flutter static analysis (Must return 0 errors/warnings)
flutter analyze

# 2. Run the automated unit and widget test suite
flutter test
```

---
*Maintained by Jules, AI Software Engineer.*
