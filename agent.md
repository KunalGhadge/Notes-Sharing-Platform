# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Performance Analysis
- **Reactive State Management & Optimistic UI**:
    - Utilizing `GetX` for efficient, reactive state updates.
    - Implements **Optimistic UI** in `DocumentController` for likes, dislikes, and bookmarks. UI state is updated immediately before backend synchronization, with rollback logic on failure to ensure perceived zero-latency.
- **Local Persistent Storage**:
    - `Hive` is used for high-performance NoSQL local caching.
    - User profile metadata and session info are stored in `userBox` (see `lib/core/helper/hive_boxes.dart`) for immediate app launch responsiveness.
- **Efficient Data Fetching**:
    - **Batch Fetching**: `HomeController` limits document fetching to 50 items per request (`limit(50)`) to reduce initial payload and memory usage.
    - **Sticky Sort**: Implemented in `HomeController` to prioritize official university documents (`is_official`) at the top of the feed followed by `created_at` DESC.
- **Media Optimization**:
    - **Caching**: `cached_network_image` prevents redundant downloads.
    - **Compression**: `flutter_image_compress` (quality 70, minWidth/Height 1024) is centralized in `ImageHelper` to optimize assets before upload.
- **Database Efficiency**:
    - **Atomic Operations**: Critical interactions (e.g., `increment_likes`, `decrement_dislikes`) use PostgreSQL RPCs to ensure data integrity and prevent race conditions.
    - **Native Counting**: Uses `CountOption.exact` for native Supabase record counting.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - **Branding**: Rebranded with a "Premium Deep Blue" theme (`#0D47A1`) as the primary color (`PrimaryColor.shade500`).
    - **Typography**: Primarily uses **'Plus Jakarta Sans'** via the `google_fonts` package for a modern academic feel.
    - **Glassmorphism**: Implemented using the `glassmorphism` package and `AppGradients.glassGradient` (e.g., in `PostCard` and navigation components) with semi-transparent overlays (`.withValues(alpha: 0.15)`).
- **Project Structure**:
    - `lib/controller/`: Reactive logic using GetX (e.g., `DocumentController`, `AuthController`).
    - `lib/view/`: Modular UI components, screens, and widgets.
    - `lib/model/`: Data models (e.g., `UserModel`, `DocumentModel`) with Hive adapters.
    - `lib/core/`: Centralized configurations (`AppMetaData`, `AppTypography`, `PrimaryColor`).
- **Asset Integration**:
    - **Vectors**: Uses `SvgPicture.asset` with `colorFilter` for dynamic coloring.
    - **Animations**: `Lottie` animations for state feedback (e.g., empty search results, upload success).
    - **Icons**: Custom icon wrapper (`CustomIcon`) for consistent SVG rendering.

## 3. Security Analysis & Migration Audit
The current analysis confirms that the critical security vulnerabilities present in the legacy Django stack have been systematically addressed:

- **Authentication**: Migrated from a custom session-less system to **Supabase Auth (JWT)**. Sessions are securely managed by the Supabase SDK. Supports deep linking for auth callbacks via `io.supabase.flutternotehub://login-callback`.
- **Password Security**: Managed by Supabase using industry-standard hashing.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all tables in `SUPABASE_SCHEMA.sql`.
    - **Profiles**: Publicly viewable (`FOR SELECT USING (true)`), but only owners can `UPDATE`.
    - **Documents**: Publicly viewable, but only owners (or Admins via specific policies) can `INSERT`, `UPDATE`, or `DELETE`.
    - **Interactions & Bookmarks**: Unique constraints (`document_id, user_id`) prevent duplicate entries; RLS ensures users can only manage their own records.
    - **Notifications**: Strictly private; users can only `SELECT` records where `auth.uid() = receiver_id`.
- **API Integrity**: By using `SECURITY DEFINER` on PostgreSQL functions (RPCs like `increment_likes`), the app allows atomic updates to protected counters (like `likes_count`) without granting users direct write access to those columns.
- **Secure File Access**: All documents and thumbnails in Supabase Storage are governed by bucket policies, ensuring authenticated access and owner-only deletion.

## 4. Android Build Configuration
The Android application (`com.divinevisionary.notehub`) is configured for modern API compatibility and performance:
- **SDK Versions**: `compileSdk 36`, `targetSdk 36`, and `minSdkVersion` (as per flutter defaults).
- **Tooling**: Uses Android Gradle Plugin (AGP) `8.9.1`, Kotlin `2.1.0`, and Gradle `8.10.2`.
- **Legacy Support & Notifications**:
    - `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` are mandatory to support the `flutter_local_notifications` plugin and modern Java 8+ features on older Android versions.
    - Uses `com.android.tools:desugar_jdk_libs:2.1.4`.
- **Deep Linking**: Configured in `AndroidManifest.xml` for the `io.supabase.flutternotehub` scheme to handle Supabase Auth callbacks.

## 5. Development & QA
- **Prerequisites**: Flutter SDK ^3.5.4 (Dart ^3.5.4).
- **Environment**: All commands (analyze, test, build) should be executed within the `notehub/` subdirectory.
- **Code Quality**:
    - Run `flutter analyze` to verify linting compliance. CI is configured to fail on any 'info' level lints.
    - Run `flutter test` to execute the test suite.

## 6. Core Directives for Developers
- **Strict Linting**: Always run `flutter analyze` and ensure zero warnings or infos. CI will reject any deviations.
- **Migration Integrity**: Never modify existing `SUPABASE_SCHEMA.sql` lines; only append new migrations to maintain trackability.
- **Icon Handling**: Use `CustomIcon` for SVGs and always provide a `colorFilter` instead of the deprecated `color` property.
- **State Management**: Use `GetX` tags for controllers that need to support multiple instances (e.g., `ShowcaseController` for different users).
- **Asset Optimization**: All new image uploads must pass through `ImageHelper.compressImage` before being sent to storage.
- **Empty States**: Always use Lottie animations or Shimmer placeholders for empty or loading states to maintain the "Premium" feel.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
