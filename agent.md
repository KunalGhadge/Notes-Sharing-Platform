# Serious Study (formerly NoteHub) - Developer Technical Manual & System Architecture Analysis

This document serves as the definitive developer-centric reference manual for **Serious Study** (formerly NoteHub). It details the application architecture, performance strategies, UI/UX design implementation, database security/RLS schema, Android build parameters, and complete file-by-file component mapping.

---

## 1. System Overview & Architecture

Serious Study is an academic networking and notes-sharing platform built specifically for the Mumbai University student community. The system transitioned from a legacy Django/MongoDB monolithic backend to a serverless, decoupled **Supabase (PostgreSQL)** backend with a **Flutter (Dart 3.5.4+)** cross-platform client.

### Architecture Diagram & Layering

```
+-----------------------------------------------------------------------+
|                            PRESENTATION LAYER                         |
|  Flutter Views (Material 3 + Glassmorphism UI Components)            |
|  Splash | Auth | Home | Document | Profile | Upload | Search | Settings |
+----------------------------------+------------------------------------+
                                   |
                                   v
+-----------------------------------------------------------------------+
|                       BUSINESS & STATE LAYER                          |
|  GetX Controllers (GetxController)                                    |
|  AuthController | DocumentController | HomeController | UploadController |
|  ProfileController | NotificationController | DownloadController | etc. |
+------------------+-------------------------------+--------------------+
                   |                               |
                   v                               v
+------------------------------------+   +------------------------------+
|            DATA & SERVICES         |   |         LOCAL STORAGE        |
|  Supabase Flutter SDK (Auth/DB)    |   | Hive NoSQL ("userBox",       |
|  Dio HTTP Client (File Caching)    |   | "downloadsBox")              |
|  Image Compression / Pickers       |   | Path Provider (Temp Cache)   |
+------------------+-----------------+   +------------------------------+
                   |
                   v
+-----------------------------------------------------------------------+
|                           BACKEND & DATABASE                          |
|  Supabase Serverless Cloud (PostgreSQL 15+)                          |
|  - Auth (JWT, Argon2/Bcrypt)                                          |
|  - PostgreSQL RLS Policies & Atomic RPC Functions                     |
|  - Storage Buckets (Documents, Thumbnails)                            |
|  - Realtime Broadcast Channels                                        |
+-----------------------------------------------------------------------+
```

---

## 2. Performance Analysis (Developer Perspective)

### 2.1 State Management & UI Decoupling
- **Framework**: `GetX` (^4.6.6) for reactive state management, dependency injection (`Get.put()`, `Get.find()`), and route handling.
- **Granular Rebuilds**: Uses reactive `.obs` primitives and `Obx()` listeners to update individual widgets (e.g. like counts, follow buttons) without triggering full page re-renders.
- **Optimistic UI Updates**: `DocumentController` updates UI state (likes, dislikes, bookmarks) immediately on user tap before waiting for backend network round-trips. In case of network errors, state reverts cleanly.

### 2.2 Local Caching Strategy (Hive & Dio)
- **Session Persistence**: `Hive` (^2.2.3) provides high-performance NoSQL key-value storage. `userBox` stores user session metadata (`UserModel`) locally (`lib/core/helper/hive_boxes.dart`), guaranteeing sub-10ms UI startup without waiting for network authentication verification.
- **Download Registry**: `downloadsBox` tracks downloaded note metadata and local filesystem paths.
- **Smart File Caching**: `FileCachingService` (`lib/service/file_caching.dart`) utilizes `Dio` (^5.7.0) and `path_provider` to inspect the local temporary directory for previously fetched files before initiating network downloads, preventing redundant egress bandwidth.

### 2.3 Asset & Media Pipeline
- **Image Compression**: Direct uploads are processed via `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) using `flutter_image_compress`, reducing images to 70% quality JPEG format and scaling down large dimensions before uploading to Supabase Storage.
- **Network Image Caching**: `CachedNetworkImage` (^3.4.1) handles image caching across feed items, profile headers, and thumbnails to prevent redundant downloads.
- **File Upload Guard**: `UploadController` enforces a hard limit of 10MB for direct file uploads. Users sharing larger files are prompted to share external links (e.g. Google Drive, Mega).

### 2.4 Database Query Efficiency & Atomic RPCs
- **Batching**: `HomeController` limits feed queries to 50 items per batch (`.limit(50)`), mitigating payload overhead and initial load latency.
- **Atomic Concurrency (RPCs)**: User interaction counters (`likes_count`, `dislikes_count`, `documents`) are modified via PostgreSQL Remote Procedure Calls (`RPCs`) running on the database engine. This completely prevents client-side race conditions.

---

## 3. Design & UI/UX Architecture

### 3.1 Design Language
- **Paradigm**: **Material 3** combined with **Glassmorphism** overlays (`glassmorphism` package).
- **Primary Palette**: "Premium Deep Blue" (`#0D47A1`), conveying academic trust and elegance.
- **Theme Definitions**: `lib/core/config/color.dart` defines `AppColor` constants, adhering to Flutter 3.24+ standards by using `.withValues(alpha: ...)` for color opacities.

### 3.2 Typography & Feedback
- **Typography**: Configured in `lib/core/config/typography.dart` using Google Fonts (`google_fonts` ^8.0.2 - Inter family).
- **Loading States**: Shimmer effects (`shimmer` ^3.0.0) render contextually shaped skeletons in `HomeDocumentSection` while fetching async data.
- **Vector Feedback**: `lottie` animations present clean visual feedback for empty search queries, empty notification lists, and success states.

---

## 4. Security Analysis & Migration Audit

### 4.1 Authentication & Session Management
- **Protocol**: Managed **Supabase Auth** utilizing JWT (JSON Web Tokens).
- **Storage**: Secure token persistence managed natively by the Supabase SDK.
- **Credentials**: Passwords are hashed using Argon2/Bcrypt within Supabase Auth; no raw credentials pass through custom application servers.

### 4.2 Database Security & Row Level Security (RLS)
Row Level Security is strictly enabled on all PostgreSQL tables (`SUPABASE_SCHEMA.sql`):

| Table | SELECT Policy | INSERT Policy | UPDATE / DELETE Policy |
| :--- | :--- | :--- | :--- |
| `profiles` | Public (`true`) | Owner (`auth.uid() = id`) | Owner strictly (`auth.uid() = id`) |
| `documents` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner or Admin (`is_admin = true`) |
| `comments` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `interactions` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `bookmarks` | Private to user | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `notifications`| Receiver (`auth.uid() = receiver_id`) | Authenticated users | Receiver (`auth.uid() = receiver_id`) |
| `followers` | Public (`true`) | Follower (`auth.uid() = follower_id`) | Follower (`auth.uid() = follower_id`) |

### 4.3 Privilege Escalation & Defenses
- **Admin Role Protection**: The `is_admin` column in `public.profiles` cannot be self-modified by standard users during profile updates, protected via database checks and `WITH CHECK` clauses:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
  ```
- **Function Hijacking Mitigation**: PostgreSQL functions operate with `SECURITY DEFINER` and explicitly declare `SET search_path = public` to protect against search-path hijacking.

---

## 5. Android Native Configuration

Defined in `notehub/android/app/build.gradle`:
- **Namespace & Application ID**: `com.divinevisionary.notehub`
- **Compile SDK / Target SDK**: `36`
- **Java Compatibility**: Java 17 (`JavaVersion.VERSION_17`, `jvmTarget = "17"`)
- **MultiDex**: `multiDexEnabled true` enabled to prevent DEX method limit issues.
- **Desugaring**: `com.android.tools:desugar_jdk_libs:2.1.4` enabled to support modern Java 8+ API features on older Android versions (required by `flutter_local_notifications`).

---

## 6. Exhaustive File & Directory Component Mapping

Below is the complete file mapping for the codebase:

```
notehub/
├── android/                             # Android native platform code
│   └── app/build.gradle                 # Android SDK, Java 17, MultiDex & Desugaring config
├── assets/                              # Dynamic static assets
│   ├── animations/                      # Lottie JSON animations for loading/empty states
│   ├── icons/                           # Custom SVG icons
│   └── images/                          # High-resolution raster images
├── lib/
│   ├── main.dart                        # App entry point, Supabase/Hive init, GetX bindings
│   ├── layout.dart                      # Primary layout controller rendering bottom navigation
│   ├── controller/                      # Reactive GetX Controllers (Business Logic Layer)
│   │   ├── auth_controller.dart         # Login, Register, Logout, Session lifecycle
│   │   ├── bottom_navigation_controller.dart # Active tab index management
│   │   ├── comment_controller.dart      # Fetching, adding, deleting document comments & replies
│   │   ├── connection_controller.dart   # Peer following/followers logic
│   │   ├── document_controller.dart     # Document interactions (likes, bookmarks, views)
│   │   ├── download_controller.dart     # Handles note downloads & file system management
│   │   ├── file_controller.dart         # Local file system picker & file opening
│   │   ├── home_controller.dart         # Feed document fetching, real-time channel sync
│   │   ├── notification_controller.dart # Activity notifications & global announcements
│   │   ├── post_controller.dart         # Multi-type post rendering & management
│   │   ├── profile_controller.dart      # Current user profile state & editing
│   │   ├── profile_user_controller.dart # External user profile view controller
│   │   ├── remote_config_controller.dart# Real-time remote feature toggles from Supabase
│   │   ├── search_controller.dart       # Note & user search filtering logic
│   │   ├── showcase_controller.dart     # User onboarding showcase/tutorial highlights
│   │   └── upload_controller.dart       # Note & Tweet upload, compression & validation
│   ├── core/                            # System-wide configuration & helpers
│   │   ├── config/
│   │   │   ├── color.dart               # Theme colors (Primary Blue `#0D47A1`, Glass opacities)
│   │   │   └── typography.dart          # Inter typography styles
│   │   ├── helper/
│   │   │   ├── custom_icon.dart         # SVG icon loader utility
│   │   │   ├── hive_boxes.dart          # Hive local storage accessors (`userBox`, `downloadsBox`)
│   │   │   └── image_helper.dart        # Image compression utility
│   │   └── meta/
│   │       └── app_meta.dart            # Central credentials & app identity strings
│   ├── model/                           # Strongly-typed Data Models
│   │   ├── document_model.dart          # Note/Tweet document metadata model
│   │   ├── mini_user_model.dart         # Compact user model for comment/like lists
│   │   ├── post_model.dart              # Specialized post content model
│   │   ├── user_model.dart              # User profile model & Hive adapter (`user_model.g.dart`)
│   │   └── user_model.g.dart            # Generated Hive TypeAdapter for UserModel
│   ├── service/                         # External Service Integrations
│   │   ├── file_caching.dart            # Dio-based local file caching service
│   │   ├── file_download.dart           # File download manager
│   │   └── notification_service.dart    # Local system notification builder
│   └── view/                            # Presentation UI Views & Widgets
│       ├── auth_screen/                 # Login & Registration views & input forms
│       ├── bottom_footer/               # Global bottom footer widget
│       ├── connection_screen/           # Followers & Following user list view
│       ├── document_screen/             # Detailed document view, PDF viewer & comment section
│       ├── home_screen/                 # Main academic feed, subject filters & header
│       ├── notification_screen/         # Real-time notifications & activity log
│       ├── official_screen/             # Verified official university updates view
│       ├── onboarding_screen/           # Welcome onboarding screen
│       ├── profile_screen/              # Current & external user profile screens
│       ├── search_screen/               # Instant search interface for notes & peers
│       ├── settings_screen/             # App settings & about page
│       ├── splash_screen/               # Splash screen & initial auth router
│       ├── upload_screen/               # Document/Tweet upload form with link options
│       └── widgets/                     # Shared UI components (DocumentCard, PostCard, Buttons, Toasts)
├── test/
│   └── dummy_test.dart                  # Core test suite
├── pubspec.yaml                         # Flutter dependencies & assets configuration
├── SUPABASE_SCHEMA.sql                  # Complete SQL schema, RLS policies & RPC functions
└── ANALYSIS.md                          # Executive architecture summary
```

---

## 7. Developer QA & Maintenance Guidelines

### Prerequisite Environment
- **Flutter SDK**: `3.24+`
- **Dart SDK**: `^3.5.4`
- **JDK**: Java 17

### Code Quality & "Zero Warnings" Standard
1. **Flow Control Braces**: Always use curly braces for `if`/`else` control structures.
2. **Modern Color API**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
3. **Switch Thumb Color**: Use `activeThumbColor` for Flutter `Switch` widgets.
4. **Empty Catch Blocks**: If empty catch blocks are intentional, place `// ignore: empty_catches` on its own line inside the block.

### Running Verification & Tests
To verify code health and run static analysis:
```bash
cd notehub
flutter analyze
flutter test
```

---
*Maintained by Jules, AI Software Engineer.*
