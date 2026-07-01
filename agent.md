# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project, serving as a manual for developers working on the application.

## 1. Project Architecture & State Management
- **Framework**: Flutter 3.24+ (SDK ^3.5.4) following the GetX MVC pattern.
- **State Management**: **GetX** is used for reactive state updates, dependency injection, and routing. Controllers (e.g., `DocumentController`, `HomeController`) encapsulate business logic and maintain observable states.
- **Local Persistence**: **Hive** manages local data caching (e.g., user profile metadata in `userBox`, download history in `downloadsBox`), ensuring immediate UI responsiveness.
- **Initialization Sequence**: The app initializes Supabase, FlutterLocalNotifications, and Hive boxes in `main.dart` before launching the `SplashScreen`.

## 2. Performance Analysis
- **Optimistic UI Updates**: Interactions such as likes, dislikes, and bookmarks are implemented with optimistic logic in `DocumentController`, providing instantaneous feedback while synchronizing with the backend in the background.
- **Batching & Lazy Loading**: The `HomeController` fetches documents in batches (limit: 50) and official updates (limit: 20) to balance network efficiency and responsiveness.
- **Sticky Sort Algorithm**: The main feed prioritizes 'official' documents at the top, followed by a chronological sort (`created_at DESC`).
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is used in `UploadController` via `ImageHelper` to reduce asset sizes before upload to Supabase Storage.
    - **Caching**: `cached_network_image` is utilized throughout the UI to minimize redundant network requests.
    - **External Resources**: Supports linking to Google Drive/Mega to bypass direct upload limits (10MB) and save server bandwidth.

## 3. Design & UI/UX
- **Aesthetic**: Modern **Material 3** design with **Glassmorphism** elements (implemented via the `glassmorphism` package) for a premium look.
- **Branding**: Centralized "Premium Deep Blue" theme (`#0D47A1`) managed in `lib/core/config/color.dart`.
- **Typography**: Modularized typography using the "Plus Jakarta Sans" typeface (`lib/core/config/typography.dart`).
- **Feedback**: Shimmer placeholders and Lottie animations are used to maintain high perceived performance during loading states.

## 4. Security Analysis
- **Authentication**: **Supabase Auth (JWT)** handles secure user sessions and password hashing (Argon2/Bcrypt).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - Owners have `ALL` permissions on their own content.
    - Public access is restricted to `SELECT` on non-sensitive data.
    - Column-level updates to sensitive fields like `is_admin` are restricted.
- **Backend Validation**:
    - **PostgreSQL Triggers**: The `ensure_official_permission` trigger prevents non-admin users from marking content as 'official' during `INSERT` or `UPDATE` operations.
    - **Atomic Operations**: PostgreSQL functions (`RPCs`) like `increment_likes` ensure counter integrity and prevent race conditions.
- **Secure File Storage**: Supabase Storage buckets are protected by RLS policies, ensuring only authorized users can manage files.

## 5. Maintenance & QA
- **Zero Warnings Policy**: All code must pass `flutter analyze` with no warnings. This includes:
    - Modernizing deprecated APIs (e.g., using `.withValues(alpha: ...)` instead of `.withOpacity(...)`).
    - Using `activeThumbColor` for `Switch` widgets.
    - Ensuring explicit curly braces in all flow control structures.
- **Testing**: Run `flutter test` to verify logic integrity.
- **Notifications**: `NotificationService` handles local notifications, while `NotificationController` syncs real-time academic updates from Supabase.

---
*Maintained by the Serious Study Engineering Team.*
