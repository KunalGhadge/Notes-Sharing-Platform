# Serious Study (formerly NoteHub) - Master Developer Guide & Maintenance Manual

> **Document Version**: 2.0.0
> **Last Updated**: August 2026
> **Target Audience**: Core Engineers, System Architects, Mobile Developers, QA & DevOps Engineers

---

## Table of Contents
1. [Executive Summary & Technology Stack](#1-executive-summary--technology-stack)
2. [Architectural Overview & Data Flow](#2-architectural-overview--data-flow)
3. [Complete Directory & File Blueprint](#3-complete-directory--file-blueprint)
4. [In-Depth Performance Analysis](#4-in-depth-performance-analysis)
5. [In-Depth Design & UI/UX Paradigm](#5-in-depth-design--uiux-paradigm)
6. [In-Depth Security Architecture & Vulnerability Audit](#6-in-depth-security-architecture--vulnerability-audit)
7. [Android Native Configuration & Platform Integration](#7-android-native-configuration--platform-integration)
8. [Maintenance, Development & QA Standard](#8-maintenance-development--qa-standard)

---

## 1. Executive Summary & Technology Stack

**Serious Study** (formerly *NoteHub*) is a high-performance academic content platform and peer-to-peer sharing ecosystem designed for the Mumbai University (MU) student community. The application bridges notes sharing, official academic circulars, community social posts ("tweets"), and real-time interaction feeds into a unified mobile application.

The core platform underwent a architectural migration from a legacy Django/MongoDB monolithic backend to a serverless **Supabase** (PostgreSQL + Auth + Storage + Realtime) engine with a **Flutter** client.

### Core Tech Stack

| Layer | Component | Version / Library | Purpose |
| :--- | :--- | :--- | :--- |
| **Frontend Framework** | Flutter SDK | `^3.24.0` | Cross-platform UI engine |
| **Language** | Dart SDK | `^3.5.4` | Modern language runtime (`.withValues()`, activeThumbColor) |
| **State Management** | GetX | `^4.6.6` | Reactive state, dependency injection, route management |
| **Local Storage** | Hive & Hive Flutter | `^2.2.3` / `^1.1.0` | High-speed binary NoSQL key-value store for session & metadata |
| **Networking & API** | Supabase Flutter | `^2.12.0` | Auth, PostgreSQL database client, Realtime channels, Storage |
| **File Operations** | Dio & Path Provider | `^5.9.1` / `^2.1.5` | Chunked file downloading, local caching, progress tracking |
| **Media Compression**| Flutter Image Compress | `^2.4.0` | Pre-upload image optimization (70% quality JPEG conversion) |
| **Database** | PostgreSQL | 15+ (Supabase) | Relational database with Row Level Security (RLS) |
| **Native Platform** | Android SDK | `compileSdk 36` | Android platform compatibility with Java 17 desugaring |

---

## 2. Architectural Overview & Data Flow

Serious Study implements a decoupled **Model-View-Controller (MVC)** architectural pattern empowered by **GetX** reactive state management.

```
+-----------------------------------------------------------------------+
|                              VIEW LAYER                               |
|   (DocumentCard, HomeHeader, UploadForm, CommentSection, Profile)     |
+-----------------------------------------------------------------------+
                                   |
                       Listens via Obx() / GetBuilder
                                   v
+-----------------------------------------------------------------------+
|                           CONTROLLER LAYER                            |
| (DocumentController, HomeController, AuthController, UploadController)|
+-----------------------------------------------------------------------+
            |                              |                   |
    Local Cache Hit                Optimistic UI          Database Query
            v                              v                   v
+-----------------------+     +-------------------+   +-----------------+
|      HIVE ENGINE      |     |  STATE MUTATION   |   | SUPABASE CLIENT |
| (userBox/downloadsBox)|     |  (Reactive .obs)  |   | (Postgrest/RPC) |
+-----------------------+     +-------------------+   +-----------------+
                                                               |
                                                       Postgres Realtime
                                                               v
                                                      +-----------------+
                                                      | POSTGRES DB     |
                                                      | & RLS POLICIES  |
                                                      +-----------------+
```

### Key Architectural Flow
1. **Unidirectional UI Data Flow**: Views never issue raw SQL or direct API calls. All operations pass through GetX controllers.
2. **Optimistic State Updates**: UI counters (likes, bookmarks, dislikes) react immediately upon user tap, applying state changes to reactive observable variables (`.obs`). If the backend RPC or Postgrest query fails, state is silently or visually rolled back with a Toast notification.
3. **Reactive Inter-Controller Synchronization**: `DocumentController.update()` automatically calls `_syncWithHome()` to notify `HomeController` when document state changes, maintaining synchronization across tabs without unnecessary API re-fetches.

---

## 3. Complete Directory & File Blueprint

### Directory Hierarchy (`notehub/lib/`)

```
lib/
├── controller/                  # Business Logic & GetX Controllers (16 controllers)
│   ├── auth_controller.dart     # Authentication, registration, session sync
│   ├── bottom_navigation_controller.dart # Navigation tab indexing
│   ├── comment_controller.dart  # Document comments & nested replies logic
│   ├── connection_controller.dart # Follow/Unfollow & community networking
│   ├── document_controller.dart # Core document lifecycle, likes, bookmarks, file launch
│   ├── download_controller.dart # Download tracking
│   ├── file_controller.dart     # Auxiliary file state management
│   ├── home_controller.dart     # Main feed batching, pull-to-refresh, Realtime listener
│   ├── notification_controller.dart # User notifications & activity logs
│   ├── post_controller.dart     # Tweet/post creation and interaction
│   ├── profile_controller.dart  # Current user profile editing & statistics
│   ├── profile_user_controller.dart # Peer user profile inspection
│   ├── remote_config_controller.dart # Supabase remote configuration flags
│   ├── search_controller.dart   # Live document search filtering
│   ├── showcase_controller.dart # Onboarding showcase step tracking
│   └── upload_controller.dart   # Media picking, compression, direct/link uploads
├── core/                        # Core Configuration, Helpers & Utilities
│   ├── config/
│   │   ├── color.dart           # AppGradients, PrimaryColor, Deep Blue palette
│   │   └── typography.dart      # Standardized AppTypography styles
│   ├── helper/
│   │   ├── custom_icon.dart     # Custom SVG & Avatar rendering wrapper
│   │   ├── hive_boxes.dart      # Hive storage initialization & key accessors
│   │   └── image_helper.dart    # JPEG compression utility (quality 70%)
│   └── meta/
│       └── app_meta.dart        # Supabase keys, application version strings
├── model/                       # Data Models & Adapters
│   ├── document_model.dart      # DocumentModel (notes & tweets)
│   ├── mini_user_model.dart     # MiniUserModel for search & follow lists
│   ├── post_model.dart          # PostModel & Comment model definitions
│   ├── user_model.dart          # Hive-annotated UserModel (@HiveType)
│   └── user_model.g.dart        # Generated Hive TypeAdapter for UserModel
├── service/                     # Background Services & I/O
│   ├── file_caching.dart        # Local file existence check & Dio downloader
│   ├── file_download.dart       # Local storage file writing helper
│   └── notification_service.dart# Local notification channel manager
└── view/                        # UI Screens & Widgets (38 views & primitives)
    ├── auth_screen/             # Login & Registration views
    ├── bottom_footer/           # Glassmorphic bottom navigation bar
    ├── connection_screen/       # User search & connections list
    ├── document_screen/         # Document details, comments, and action buttons
    ├── home_screen/             # Main document feed with HomeHeader and shimmer states
    ├── notification_screen/     # Activity feed & notifications screen
    ├── official_screen/         # Filtered feed for MU Official updates
    ├── profile_screen/          # User profile view & edit modal
    ├── search_screen/           # Search view with live filtering
    ├── settings_screen/         # About page & settings drawer
    ├── splash_screen/           # App boot splash
    ├── upload_screen/           # Multi-type content upload form (file or link)
    └── widgets/                 # Common UI components (DocumentCard, PostCard, Toasts, AdminBadge, Buttons)
```

---

## 4. In-Depth Performance Analysis

### 4.1 Persistent Local Session Caching (Hive NoSQL)
- **Zero Latency Boot**: User credentials and profile attributes (`id`, `displayName`, `username`, `institute`, `profile`, `followers`, `following`, `documents`) are stored in Hive (`userBox`). On application startup, `HiveBoxes.userId` is immediately available without blocking on network queries.
- **Fast Session Verification**: `HiveBoxes.isLoggedIn` provides instant sync authentication status during `Splash` screen execution.

### 4.2 Network & Payload Optimization
- **Batch Pagination**: `HomeController` fetches documents in batches (limit 50) sorted by `created_at DESC` to minimize network payload on cold boot.
- **Network Image Caching**: `CachedNetworkImage` is used throughout `DocumentCard`, `PostCard`, and `HomeHeader` to cache remote thumbnails in temporary disk storage.
- **File Download Caching**: `saveAndOpenFile()` in `lib/service/file_caching.dart` checks if a document exists in `getApplicationDocumentsDirectory()` before initiating Dio downloads, preventing duplicate bandwidth usage.

### 4.3 Media Compression Pipeline
- **Automatic Compression**: Images selected for cover thumbnails or document posts are processed via `ImageHelper.compressImage()` using `flutter_image_compress`:
  - Format: `CompressFormat.jpeg`
  - Quality: `70%`
  - Max Dimensions: `1024x1024`
- **File Size Guardrails**: `UploadController` enforces a **10MB direct file limit**. Posts larger than 10MB require external link sharing (e.g. Google Drive / Mega), keeping Supabase Storage usage within bounds.

### 4.4 Database Atomic RPCs & Realtime Updates
- **Atomic Counters**: Interacting with likes and dislikes invokes PostgreSQL Remote Procedure Calls (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`) to update counters atomically on the database server.
- **Realtime Postgres Channels**: `HomeController` establishes a realtime channel on `public:documents` using `supabase.channel('public:documents').onPostgresChanges(...)`, delivering live updates to the UI feed without polling.

---

## 5. In-Depth Design & UI/UX Paradigm

### 5.1 Design Tokens & Palette

The application follows **Material 3** guidelines combined with a **Glassmorphism** visual hierarchy rebranded around a "Premium Deep Blue" theme.

- **Primary Color**: Deep Blue (`#0D47A1` / `Color(0xFF0D47A1)`)
- **Accent Gradient**: `AppGradients.premiumGradient` (`#0D47A1` -> `#1976D2`)
- **Glassmorphism Spec**: Semi-transparent white background `Colors.white.withValues(alpha: 0.15)` paired with `BackdropFilter` (Blur Sigma 10x10) on navigation footers and cards.
- **Color Migration Standard**: Strict usage of Dart 3.5+ `.withValues(alpha: ...)` for alpha adjustments, completely replacing deprecated `.withOpacity()`.

### 5.2 Visual Feedback & Motion Primitives
- **Shimmer States**: Async loading states in `HomeDocumentSection` display animated shimmer placeholder boxes matching exact card dimensions.
- **Lottie Vector Animations**: Empty search states and upload success screens utilize lightweight Lottie JSON animations (`assets/animations/notes.json`).
- **Interactive Micro-Interactions**: Custom heart animation on `LikesWithHeart` widget provides tactile feedback on double-tap or like button toggle.

---

## 6. In-Depth Security Architecture & Vulnerability Audit

```
+-------------------------------------------------------------------------+
|                           SUPABASE AUTH (JWT)                           |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                    ROW LEVEL SECURITY (RLS) POLICIES                    |
|   +-----------------------------------------------------------------+   |
|   | PROFILES: FOR SELECT (Public), FOR UPDATE (auth.uid() = id)     |   |
|   | DOCUMENTS: FOR SELECT (Public), FOR ALL (auth.uid() = user_id)  |   |
|   | COMMENTS: FOR SELECT (Public), FOR INSERT (auth.uid() = user_id)|   |
|   | NOTIFICATIONS: FOR SELECT (auth.uid() = receiver_id)            |   |
|   +-----------------------------------------------------------------+   |
+-------------------------------------------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                  SECURITY DEFINER RPCs & TRIGGER GUARDS                 |
|   - increment_likes(), decrement_likes(), handle_interaction()         |
|   - ensure_official_permission() Trigger (Prevents non-admin official) |
|   - Search Path Protection: SET search_path = public                    |
+-------------------------------------------------------------------------+
```

### 6.1 Row Level Security (RLS) Audit

Every table in `SUPABASE_SCHEMA.sql` explicitly enforces Row Level Security (`ENABLE ROW LEVEL SECURITY`):

1. **`profiles` Table**:
   - `SELECT`: Public access (`USING (true)`).
   - `INSERT`: Strictly restricted to authenticated owner (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Owner restricted (`USING (auth.uid() = id)`).
2. **`documents` Table**:
   - `SELECT`: Publicly accessible (`USING (true)`).
   - `INSERT`: Verified creator ownership (`WITH CHECK (auth.uid() = user_id)`).
   - `UPDATE`/`DELETE`: Restricted to creator (`USING (auth.uid() = user_id)`) or Admin users via policy.
3. **`notifications` & `bookmarks` Tables**:
   - Private access policy enforced via `auth.uid() = receiver_id` or `auth.uid() = user_id`.

### 6.2 SQL RPC Security & Privilege Escalation Mitigation
- **Search Path Hijacking Defense**: Database RPC functions (e.g. `check_official_permission`, `increment_likes`) explicitly declare `SET search_path = public` to protect against search-path injection attacks in PostgreSQL functions running under `SECURITY DEFINER`.
- **Official Status Guard**: Privilege escalation for official content verification is prevented at the database trigger level (`ensure_official_permission`), ensuring setting `is_official = true` in `documents` fails unless `is_admin = true` on the user's profile.

---

## 7. Android Native Configuration & Platform Integration

### 7.1 Gradle Settings (`android/app/build.gradle`)
- **Application ID**: `com.divinevisionary.notehub`
- **Compile SDK Target**: `36`
- **Java Compatibility**: `JavaVersion.VERSION_17` for both `sourceCompatibility` and `targetCompatibility`.
- **Desugaring**: `coreLibraryDesugaringEnabled true` with `com.android.tools:desugar_jdk_libs:2.1.4` enabled to support modern Java APIs required by `flutter_local_notifications`.
- **MultiDex**: `multiDexEnabled true` enabled to prevent DEX limit overflow on legacy Android devices.

### 7.2 Manifest Configuration (`android/app/src/main/AndroidManifest.xml`)
- **Permissions Declared**:
  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
  <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE"/>
  ```
- **Deep Linking Scheme**: Configured intent filter for Supabase magic link/auth redirects:
  ```xml
  <data android:scheme="io.supabase.flutternotehub" android:host="login-callback" />
  ```

---

## 8. Maintenance, Development & QA Standard

### 8.1 "Zero Warnings" Code Quality Standard
The project adheres to a strict **Zero Warnings Policy** enforced by `flutter analyze`.

1. **Color Deprecations**: Do not use `.withOpacity(x)`. Use `.withValues(alpha: x)` instead.
2. **Switch Controls**: Use `activeThumbColor` instead of deprecated `activeColor` on `Switch` widgets.
3. **Flow Control**: All `if` statements must include explicit curly braces (`curly_braces_in_flow_control_structures`).
4. **Empty Catch Blocks**: Must either log errors or be explicitly annotated on their own line with `// ignore: empty_catches`.

### 8.2 Testing & Quality Assurance
- **Static Analysis**: Execute `flutter analyze` inside `notehub/` to confirm zero issues.
- **Unit & Widget Tests**: Run `flutter test` to execute test suites (e.g., `test/dummy_test.dart`).

---
*Analyzed and Documented by Jules, AI Software Engineer.*
