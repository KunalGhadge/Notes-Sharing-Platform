# Serious Study (formerly NoteHub) - Developer Guide & Technical Manual

This document provides a comprehensive analysis of the **Serious Study** Android application from a software engineer's perspective. It serves as the primary system manual, detailing the application's architecture, file structure, performance optimizations, design paradigm, database security configurations, native Android settings, and QA procedures.

---

## 1. System Architecture & File Structure

The application adopts a decoupled Model-View-Controller (MVC) architecture powered by `GetX` for reactive state management, `Hive` for local persistent storage, `Dio` for background file transfers, and `Supabase` as a serverless backend.

### Project Directory Mapping (`notehub/`)

```
notehub/
├── android/                   # Native Android application configuration & Gradle build scripts
├── assets/                    # Vector graphics, animations (Lottie), images, and custom icons
├── lib/
│   ├── controller/            # Business logic & reactive state management (GetX Controllers)
│   │   ├── auth_controller.dart          # Authentication, user registration, profile sync
│   │   ├── comment_controller.dart       # Real-time document comments & nested replies
│   │   ├── document_controller.dart      # Notes lifecycle, RPC interactions, downloads, bookmarks
│   │   ├── home_controller.dart          # Main feed, category filtering, search, Realtime sync
│   │   ├── notification_controller.dart  # Activity notifications & global announcements
│   │   ├── profile_controller.dart       # User profiles, follow/unfollow, uploaded documents
│   │   └── upload_controller.dart        # Multi-part file/link upload pipeline
│   ├── core/                  # Global utilities, constants, and theme configurations
│   │   ├── config/
│   │   │   └── color.dart                # Palette definitions (Premium Deep Blue, Glassmorphism colors)
│   │   ├── helper/
│   │   │   ├── hive_boxes.dart           # Local NoSQL storage wrappers (userBox, downloadsBox)
│   │   │   └── image_helper.dart         # Asset compression utilities (JPEG 70%, 1024x1024)
│   │   └── meta/
│   │       └── app_meta.dart             # App metadata & Supabase public URL/keys
│   ├── model/                 # Data transfer objects & entity models
│   │   ├── comment_model.dart            # Comment & nested reply model
│   │   ├── document_model.dart           # Document metadata, interaction flags, URLs
│   │   ├── notification_model.dart       # User notification object
│   │   └── user_model.dart               # User profile entity
│   ├── service/               # Specialized network & system services
│   │   └── file_caching.dart             # Dio file downloader with path_provider & local cache check
│   ├── view/                  # UI screens, views, and reusable widgets
│   │   ├── auth_screen/                  # Login & registration views with glassmorphic cards
│   │   ├── bottom_footer/                # Navigation bar with translucent overlays
│   │   ├── document_screen/              # Detailed document view & comment section
│   │   ├── home_screen/                  # Feed view, category chips, shimmer skeletons
│   │   ├── notification_screen/          # User notifications and announcements list
│   │   ├── profile_screen/               # User profile overview, stats, and document grid
│   │   ├── search_screen/                # Real-time search interface
│   │   ├── settings_screen/              # App info, terms, and settings
│   │   ├── upload_screen/                # Upload form for files and external URLs
│   │   └── widgets/                      # Reusable UI widgets (DocumentCard, PostCard, AdminBadge, Toasts)
│   ├── layout.dart            # Main scaffold holding the bottom navigation bar & view index
│   └── main.dart              # App entry point, Supabase & Hive initialization, GetX bindings
└── test/
    └── dummy_test.dart        # Basic sanity test suite for CI validation
```

---

## 2. Performance Analysis

### 2.1 State Management & Reactive UI Updates
- **GetX Framework**: Controllers (e.g., `DocumentController`, `HomeController`) use `Rx` reactive primitives (`.obs`). UI components bind using `Obx` or `GetBuilder`, avoiding unnecessary widget rebuilds.
- **Cross-Controller State Synchronization**: `DocumentController._syncWithHome()` propagates like, bookmark, and count state changes directly to `HomeController`, ensuring instantaneous feedback across screens without requiring network refetches.

### 2.2 Local Persistence & NoSQL Caching (`Hive`)
- **Session Caching**: User session data, user stats (followers, following, documents count), and profile metadata are stored in `userBox` via `lib/core/helper/hive_boxes.dart`. This guarantees instant startup responsiveness.
- **Downloaded Document Metadata**: Download history and local file paths are stored in `downloadsBox`, enabling offline access without repeating network requests.

### 2.3 Media & Asset Optimization
- **Image Compression**: `ImageHelper.compressImage` uses `flutter_image_compress` to re-encode upload images to JPEG format with 70% quality and a maximum target resolution of 1024x1024, preserving bandwidth and Supabase Storage space.
- **Network Image Caching**: All network-rendered images (e.g., cover photos, avatars) use `CachedNetworkImage` with memory and disk cache limits, eliminating redundant image downloads.
- **File Download Management**: `FileCachingService` leverages `Dio` to stream document files directly to device storage (`path_provider`), checking existing file paths in `downloadsBox` before executing network requests.

### 2.4 Database Performance & Scalability
- **Atomic Operations via Database RPCs**: Interaction counts (`likes_count`, `dislikes_count`, `followers`) are managed server-side using PostgreSQL functions (RPCs such as `increment_likes`, `decrement_likes`). This eliminates client-side race conditions.
- **Lazy Pagination & Batching**: Feed documents are queried in batches (e.g., 20 items for official updates, 50 items for general feeds) to minimize query execution time and bandwidth consumption.

---

## 3. Design & UI/UX Paradigm

### 3.1 Aesthetic & Visual Identity
- **Material 3 Paradigm**: Built on Material 3 design standards with rounded borders, elevated dynamic cards, and cohesive typography (`google_fonts`).
- **Premium Deep Blue Palette**: Rebranded with a dominant primary color `#0D47A1` representing Mumbai University's academic integrity.
- **Glassmorphism**: Semi-transparent overlays (e.g., `Colors.white.withValues(alpha: 0.15)`), dynamic blur effects, and subtle white borders create a depth-layered UI.

### 3.2 Visual Feedback & States
- **Skeleton Placeholders**: Custom `Shimmer` loaders mirror layout dimensions during asynchronous network requests.
- **Vector & Lottie Animations**: Interactive feedback for empty states, loading indicators, and error screens using lightweight `Lottie` animations and `flutter_svg` graphics.
- **Toast Notifications**: Built-in status messages using `toastification` to report validation success, warnings, or network errors concisely.

---

## 4. Security Analysis & Row Level Security (RLS) Audit

The platform migrated from a custom Django/MongoDB backend to serverless **Supabase (PostgreSQL)**, resolving critical security issues:

| Vulnerability Category | Legacy Stack (Django / MongoDB) | Modern Serverless Architecture (Supabase) |
| :--- | :--- | :--- |
| **Authentication** | Custom unencrypted session tokens | **Supabase Auth (JWT)** with automated token refresh |
| **Password Storage** | Plaintext / weak hashing | **Argon2 / Bcrypt** managed by Supabase Auth |
| **Database Access** | Exposed backend REST endpoints | **Row Level Security (RLS)** strictly enforcing owner access |
| **Privilege Escalation** | Vulnerable role flags | Protected via `WITH CHECK` policies and database RPC security |
| **File Storage Access** | Open unauthenticated URLs | Governed by Supabase Storage RLS policies |

### 4.1 Database RLS Audit (`SUPABASE_SCHEMA.sql`)
- **`profiles` Table**:
  - `SELECT`: Publicly viewable by all authenticated users.
  - `INSERT`: Restricted to `auth.uid() = id`.
  - `UPDATE`: Restricted to `auth.uid() = id`. `is_admin` changes are protected against client-side tampering via RLS `WITH CHECK` policies.
- **`documents` Table**:
  - `SELECT`: Viewable by everyone.
  - `INSERT`: Restricted to `auth.uid() = user_id`.
  - `UPDATE / DELETE`: Only document owners or system admins (`is_admin = true`) can modify documents.
- **`comments`, `bookmarks`, `interactions` Tables**:
  - Insert and delete privileges are strictly limited to `auth.uid() = user_id`.
- **Database RPC Security**:
  - Counter update RPCs use `SECURITY DEFINER` with explicit search paths (`SET search_path = public`), preventing SQL injection or search path hijacking.

---

## 5. Native Android Infrastructure

### 5.1 Gradle & SDK Specifications (`notehub/android/app/build.gradle`)
- **`compileSdk`**: `36`
- **`targetSdk`**: `36`
- **`minSdkVersion`**: Standard Flutter default (supports Android 5.0+, API Level 21+)
- **Java Compatibility**: `JavaVersion.VERSION_17` source and target compatibility across Gradle compile options and Kotlin JVM targets.
- **Core Library Desugaring**: Enabled via `com.android.tools:desugar_jdk_libs:2.1.4` to support modern Java time and utility libraries required by `flutter_local_notifications`.
- **MultiDex**: Enabled (`multiDexEnabled true`) to prevent 64k method limit issues.

### 5.2 Deep Linking & OAuth Scheme
- **Scheme**: `io.supabase.flutternotehub://login-callback`
- Configured in Auth redirect parameters to handle email verification and OAuth callbacks seamlessly on Android devices.

---

## 6. Developer Development & QA Guide

### 6.1 Prerequisites
- **Flutter SDK**: `3.24+` (Stable channel)
- **Dart SDK**: `^3.5.4`

### 6.2 Code Quality & Verification Commands
Always run the following verification steps inside the `notehub/` directory before committing code:

1. **Verify Dependencies & Formatting**:
   ```bash
   cd notehub
   flutter pub get
   ```

2. **Execute Static Analysis ("Zero Warnings Policy")**:
   ```bash
   flutter analyze
   ```
   *Requirement*: The output must report zero errors or warnings. Ensure modern APIs are used (e.g., `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`, and `activeThumbColor` for `Switch` widgets).

3. **Run Test Suite**:
   ```bash
   flutter test
   ```

---
*Maintained & Documented by Jules, AI Software Engineer.*
