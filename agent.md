# Serious Study (Formerly NoteHub) - Developer Guide & System Manual

Welcome to the official developer guide and system manual for **Serious Study** (formerly NoteHub). This document provides an exhaustive, developer-centric analysis of the application's architecture, state management, security model, performance characteristics, and native build setups following its complete migration to a serverless **Supabase** backend.

---

## 1. System Overview & Tech Stack

Serious Study is an academic social networking and study material sharing platform built for university students (primarily Mumbai University).

| Layer | Technology | Key Usage |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter (Dart SDK ^3.5.4, Flutter 3.24+) | Cross-platform UI layer targeting Android, Web, iOS |
| **State Management** | GetX (v4.6.6) | Reactive controllers, dependency injection, and routing |
| **Local Persistent Storage** | Hive (v2.2.3) | High-performance NoSQL local key-value store (`userBox`, `downloadsBox`) |
| **Backend & Database** | Supabase (PostgreSQL) | Managed database, PostgreSQL Realtime, Storage buckets |
| **Authentication** | Supabase Auth | JWT-based auth with email/password and custom user metadata |
| **Network & Caching** | Dio & Path Provider | Chunked media caching, file download management |
| **Media Processing** | `flutter_image_compress` | Client-side compression before storage upload |

---

## 2. Architecture & File Mapping Matrix

The application follows an **MVC (Model-View-Controller)** variant tailored for Flutter with GetX.

```
notehub/lib/
├── controller/            # Reactive GetX Controllers (Business Logic)
│   ├── auth_controller.dart
│   ├── bottom_navigation_controller.dart
│   ├── comment_controller.dart
│   ├── connection_controller.dart
│   ├── document_controller.dart
│   ├── download_controller.dart
│   ├── file_controller.dart
│   ├── home_controller.dart
│   ├── notification_controller.dart
│   ├── post_controller.dart
│   ├── profile_controller.dart
│   ├── profile_user_controller.dart
│   ├── remote_config_controller.dart
│   ├── search_controller.dart
│   ├── showcase_controller.dart
│   └── upload_controller.dart
├── model/                 # Data Models & Adapters
│   ├── document_model.dart
│   ├── mini_user_model.dart
│   ├── post_model.dart
│   ├── user_model.dart
│   └── user_model.g.dart   # Hive TypeAdapter
├── service/               # External Services & Background Tasks
│   ├── file_caching.dart
│   ├── file_download.dart
│   └── notification_service.dart
├── core/                  # Configurations, Themes & Helpers
│   ├── config/
│   │   ├── color.dart       # Material 3 & Deep Blue Palette
│   │   └── typography.dart  # Custom Text Styles
│   ├── helper/
│   │   ├── custom_icon.dart
│   │   ├── hive_boxes.dart  # Hive box initializers and static accessors
│   │   └── image_helper.dart# Client-side image compression
│   └── meta/
│       └── app_meta.dart    # Version metadata
└── view/                  # UI Views & Modular Components
    ├── auth_screen/
    ├── bottom_footer/
    ├── connection_screen/
    ├── document_screen/
    ├── home_screen/
    ├── notification_screen/
    ├── official_screen/
    ├── onboarding_screen/
    ├── profile_screen/
    ├── search_screen/
    ├── settings_screen/
    ├── splash_screen/
    ├── upload_screen/
    └── widgets/           # Shared UI Components (DocumentCard, PostCard, AdminBadge)
```

---

## 3. Performance Analysis & Optimization Strategies

### A. State Management & Perceived Speed
- **GetX Reactive Observers**: UI widgets bind directly to `Rx` variables (e.g., `RxList`, `RxBool`). Re-renders are localized strictly to affected widgets using `Obx(() => ...)` without rebuilding entire view trees.
- **Optimistic UI Updates**: User actions like liking a document or toggling a bookmark immediately update the local reactive state (`document.likesCount.value++`) before sending network calls to Supabase. If the backend call fails, state is silently or gracefully rolled back.
- **Shimmer Placeholders**: `Shimmer` overlays are rendered in `HomeDocumentSection` while fetching asynchronously, maintaining visual continuity and eliminating layout shifts.

### B. Storage & Media Management
- **Hive NoSQL Local Caching**: `userBox` maintains session metadata (`id`, `displayName`, `institute`, `followersCount`, `followingCount`), enabling instant cold-start renders without waiting for network authentication checks.
- **Dio Chunked File Caching**: `FileCaching` checks the device's temporary directory (`path_provider`) before fetching media. If present locally, it skips network downloads entirely.
- **Client-Side Image Compression**: `ImageHelper.compressImage` compresses uploaded images to JPEG at 70% quality and max 1024x1024 resolution using `flutter_image_compress`, drastically reducing bandwidth consumption and Supabase Storage costs.

### C. Database RPCs & Query Pagination
- **Atomic Counter Updates**: High-frequency updates (likes, dislikes, bookmarks) bypass direct table writes and invoke PostgreSQL `RPC` functions (e.g., `increment_likes`, `decrement_dislikes`) to prevent race conditions under concurrent usage.
- **Query Batching**: `HomeController` limits document feeds to batches (e.g., limit 20 for official updates) with sticky sorting by `created_at DESC`.

---

## 4. UI/UX Paradigm & Design System

### A. Design Tokens
- **Theme**: Material 3 with a custom **Glassmorphism** overlay layer (`glassmorphism` package).
- **Primary Color Palette**:
  - **Deep Blue**: `#0D47A1` (Primary Brand)
  - **Dark Accent**: `#002171`
  - **Official Gold**: `#B8860B` (Admin / Official Badges)
  - **Background**: `#0F0F0F` (Dark Mode Default)
- **Modern API Compliance**: Replaced all deprecated `withOpacity()` calls with `.withValues(alpha: ...)` to ensure compliance with Dart SDK ^3.5.4.
- **Switch Control Standards**: All administrative toggles (e.g., `upload_form.dart`) utilize `activeThumbColor: const Color(0xFFB8860B)` to satisfy modern Flutter lint requirements.

### B. Layout & Flow
1. **Onboarding / Splash**: `SplashView` verifies local Hive session -> routes to `Layout` or `LoginScreen`.
2. **Main Layout**: Bottom navigation with 5 primary sections: Home Feed, Connections, Upload, Official Updates, Profile.
3. **Document Viewer**: Multi-tab viewer supporting inline PDF previews, comments, likes, download managers, and author profiles.

---

## 5. Security Analysis & Database Infrastructure

### A. Authentication & Session Management
- Migrated from legacy Django sessions to **Supabase Auth (JWT)**.
- Passwords are secure via industry-standard password hashing algorithms managed on Supabase Auth.
- Session state is securely synchronized between Supabase JWT tokens and Hive local storage (`HiveBoxes`).

### B. PostgreSQL Schema & Row Level Security (RLS)
Every table in `SUPABASE_SCHEMA.sql` enforces strict RLS policies:

- **`profiles`**: Public `SELECT`, owner-only `INSERT` and `UPDATE` (`auth.uid() = id`).
- **`documents`**: Public `SELECT`, owner-only `INSERT`/`UPDATE`/`DELETE`.
- **`comments`**: Public `SELECT`, owner-only `INSERT`.
- **`notifications`**: Private `SELECT` restricted to the recipient (`auth.uid() = receiver_id`).
- **`interactions` & `bookmarks`**: Public `SELECT`, user-bound `INSERT`/`DELETE`.

### C. Privilege Escalation Prevention
- Administrative rights (`is_admin`) are guarded at both the database and application levels.
- Direct user updates to `is_admin` are blocked by RLS policies.
- Setting `is_official = true` on documents requires `is_admin = true` on the executing user profile.

---

## 6. Native Android Setup & Build Configuration

The Android application is configured in `notehub/android/app/build.gradle`:

```groovy
android {
    namespace = "com.divinevisionary.notehub"
    compileSdk = 36

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.divinevisionary.notehub"
        minSdkVersion = flutter.minSdkVersion
        targetSdk = 36
        multiDexEnabled true
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

- **Java 17 Compatibility**: Required for recent Flutter and Android Gradle Plugin (AGP) toolchains.
- **Core Library Desugaring**: Enables modern Java 8+ API support on older Android SDK versions for background notification plugins.
- **MultiDex Enabled**: Prevents 64K method limit errors caused by combined Flutter, GetX, Hive, and Supabase dependencies.

---

## 7. QA, Maintenance & Zero Warnings Standard

### Code Quality Rules
1. **Zero Warnings Policy**: Code MUST pass `flutter analyze` without any errors, warnings, or deprecation notices.
2. **Explicit Flow Control**: Flow control structures MUST use curly braces (`if (cond) { ... }`).
3. **Catch Block Documentation**: Silent catch blocks must include `// ignore: empty_catches` on a dedicated line inside the catch body.
4. **Testing**: Run unit and widget tests using `flutter test`.

---
*Maintained and documented by Jules, AI Software Engineer.*
