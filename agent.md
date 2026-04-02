# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## 1. Project Overview
Serious Study is a premium notes-sharing and academic networking platform tailored for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 2. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates and dependency injection. Controllers (e.g., `DocumentController`, `ProfileController`, `HomeController`) manage business logic independently from the UI.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching. User profile metadata is stored in `userBox` (see `lib/core/helper/hive_boxes.dart`) to ensure immediate UI responsiveness upon app launch.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `PostCard`) to minimize network usage and avoid re-downloading images.
    - **Compression**: `flutter_image_compress` is integrated into the upload pipeline (`lib/core/helper/image_helper.dart`) to optimize asset sizes (quality 70, minWidth/Height 1024) before they reach Supabase Storage.
    - **File Size Limits**: `UploadController` enforces a 10MB limit for direct document uploads to control storage costs and bandwidth.
- **Database Scalability & Efficiency**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_dislikes` are handled via PostgreSQL Functions (`RPCs`) defined in `SUPABASE_SCHEMA.sql`. This ensures data consistency and prevents race conditions.
    - **Perceived Performance**: Shimmer placeholders and the `Loader` widget are implemented to provide smooth visual feedback during asynchronous data fetching.
    - **Optimistic UI**: Interactions like liking, disliking, and bookmarking use an optimistic UI pattern in `DocumentController`, providing immediate feedback before backend synchronization.
    - **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm to prioritize official university documents in the community feed.

## 3. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - **Glassmorphism**: Semi-transparent overlays and custom gradients (e.g., `AppGradients.glassGradient`) are used, specifically in the `PostCard` and navigation elements.
    - **Theming**: Rebranded with a "Premium Deep Blue" theme (`#0D47A1`) as the primary identity.
    - **Typography**: Uses the 'Plus Jakarta Sans' typeface via the `google_fonts` package for a modern academic feel.
- **Project Structure (MVC with GetX)**:
    - `lib/controller/`: Reactive business logic and state management.
    - `lib/view/`: Modular UI components, screens, and custom widgets.
    - `lib/model/`: Data models (e.g., `UserModel`, `DocumentModel`).
    - `lib/core/`: Centralized configurations, theme definitions (`lib/core/config/`), and helpers.
    - `lib/service/`: Utility services like local file caching (`lib/service/file_caching.dart`).
- **Asset Integration**: High-quality vector graphics (`flutter_svg`) and `Lottie` animations are used for state feedback and enhancing the user experience.

## 4. Security Analysis & Migration Audit
The migration to Supabase has systematically addressed legacy vulnerabilities:

- **Authentication**: Migrated to **Supabase Auth (JWT)**. Sessions are securely managed by the Supabase SDK, and the app supports deep linking for auth callbacks (`io.supabase.flutternotehub://login-callback`).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced via `SUPABASE_SCHEMA.sql`. Policies ensure:
    - **Profiles**: Publicly readable, but only owners can `UPDATE`.
    - **Documents**: Publicly readable, but only owners can `INSERT` or `DELETE`.
    - **Notifications/Bookmarks**: Private to the specific user (`receiver_id` or `user_id` check).
- **Database Integrity**: Using `SECURITY DEFINER` on PostgreSQL RPC functions allows users to trigger atomic updates to protected counters (like `likes_count`) without having direct write access to the underlying columns.
- **Secure File Access**: Assets in Supabase Storage are governed by policies, with public access only granted via signed URLs or public bucket configurations for authorized content.

## 5. Development & QA
- **Prerequisites**:
    - Dart SDK `^3.5.4`.
    - Flutter SDK `3.41.x` (channel stable).
- **Android Configuration**:
    - `compileSdk` and `targetSdk` set to 36.
    - `multiDexEnabled` and `coreLibraryDesugaring` enabled to support modern plugins like `flutter_local_notifications`.
- **Code Quality**:
    - **Zero Warnings Policy**: The project strictly adheres to a zero-warning linting policy. Developers must use modern APIs (e.g., `.withValues(alpha: x)` instead of `.withOpacity(x)`).
    - **Static Analysis**: Run `flutter analyze` within the `notehub/` directory to verify compliance.
    - **Testing**: Run `flutter test` to execute the test suite.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
