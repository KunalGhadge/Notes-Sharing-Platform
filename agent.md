# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security protocols implemented in the application.

## 1. Performance Analysis
- **Reactive State Management**: The application utilizes **GetX** for high-performance state management. Controllers (e.g., `DocumentController`, `ProfileController`) manage business logic independently from the UI, using `Obx` and `GetBuilder` for granular widget updates.
- **Local Persistent Storage**: **Hive** is used for high-speed NoSQL local caching.
    - `userBox` stores `UserModel` data (username, id, profileUrl) ensuring immediate UI responsiveness and user context availability upon app launch.
    - `downloadsBox` tracks local file metadata for offline-ready document access.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `HomeHeader`) to minimize redundant network usage for thumbnails.
    - **Compression**: `flutter_image_compress` is integrated into the `UploadController` pipeline to optimize cover images before they reach Supabase Storage, reducing cloud costs and improving upload speed.
    - **File Caching**: A dedicated `FileCaching` service manages temporary storage of viewed documents using `Dio` and `path_provider`.
- **Database Scalability & Real-time**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_dislikes` are handled via PostgreSQL Remote Procedure Calls (`RPCs`) defined as `SECURITY DEFINER`. This ensures data consistency and prevents client-side race conditions.
    - **Real-time Sync**: `Supabase Realtime` (Postgres Changes) is utilized in `HomeController` and `NotificationController` to provide live updates for the feed and notifications without taxing the server with frequent polling.
    - **Sticky Sort Algorithm**: The `HomeController` prioritizes academic integrity by sorting 'Official' documents at the top of the feed regardless of upload time.

## 2. Design & Architecture
- **Material 3 & Aesthetic Paradigm**:
    - **Premium Deep Blue Theme**: The app is built on a custom Material 3 theme anchored by `#0D47A1`, providing a professional "University-grade" look.
    - **Glassmorphism**: Semi-transparent, blurred overlays (implemented via the `glassmorphism` package) are used in the `BottomFooter` and profile cards to create a modern, layered aesthetic.
- **Standardized UI Components**:
    - **Loaders**: `Loader` and `Loader2` components (in `lib/view/widgets/loader.dart`) wrap `CircularProgressIndicator` with standardized padding and colors.
    - **Feedback Systems**: Standardized notification feedback via the `toastification` package, featuring Success, Error, and Warning states with `ToastificationStyle.flatColored`.
    - **Shimmer Effects**: Shimmer placeholders are implemented in sections like `HomeDocumentSection` to eliminate visual "pop-in" during data fetching.
- **MVC/Controller Pattern**:
    - `lib/controller/`: Houses the reactive logic and backend interactions.
    - `lib/view/`: Modular UI components organized by feature (Auth, Home, Document, Upload).
    - `lib/core/`: Centralized configurations including `AppMetaData`, `AppColors`, and `AppTypography`.

## 3. Security Analysis
- **Authentication**: The platform utilizes **Supabase Auth (JWT)**. Sessions are managed securely via the Supabase SDK, and passwords are never exposed to the frontend, utilizing industry-standard hashing managed by the backend.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables:
    - **Profiles**: Only the authenticated owner can `UPDATE` their record.
    - **Documents**: Only the document owner can `INSERT` or `DELETE`.
    - **Notifications**: Users can only `SELECT` notifications where `receiver_id` matches their UID, or global announcements.
- **API Integrity**: By using `SECURITY DEFINER` on PostgreSQL RPC functions, the application allows atomic updates to counters (like `likes_count`) while keeping the underlying table data protected from direct, unauthorized manipulation.
- **Secure Storage**: Supabase Storage buckets are governed by granular policies, ensuring that private documents remain private while public assets (like thumbnails) are accessible via public URLs.

## 4. Development & QA
- **Environment**: Flutter SDK ^3.5.4.
- **Zero Warnings Policy**: The project enforces a strict linting policy verified via `flutter analyze`.
    - Modern standards are followed, such as replacing deprecated `.withOpacity()` with `.withValues(alpha: ...)`.
    - All flow control structures must use curly braces for readability and safety.
- **Testing**: A baseline test suite exists in `test/`, with `flutter test` required to pass before any major deployment.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
