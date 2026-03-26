# Developer Guide - Serious Study (NoteHub)

This document provides an exhaustive technical analysis of the Serious Study project from a developer's perspective, documenting architecture, performance, design, and security.

## 1. Project Architecture
The application follows a decoupled **MVC (Model-View-Controller)** pattern facilitated by **GetX**.

- **Frontend**: Flutter 3.41.2 (Stable) with SDK constraint `^3.5.4`.
- **State Management**: **GetX** for reactive UI, dependency injection, and navigation.
- **Backend (Serverless)**: **Supabase** (PostgreSQL, Auth, Storage, Realtime).
- **Data Persistence**: **Hive** for high-speed local NoSQL caching of user sessions and metadata.
- **Dependency Management**: Centralized in `pubspec.yaml`, utilizing modern libraries like `dio`, `supabase_flutter`, `cached_network_image`, and `toastification`.

## 2. Performance Optimizations
Serious Study is engineered for low latency and high perceived performance:

- **Reactive Updates**: GetX controllers (e.g., `HomeController`, `DocumentController`) handle business logic, ensuring the UI only rebuilds when necessary.
- **Optimistic UI**: Interactions like likes, dislikes, and bookmarks are applied locally first in `DocumentController` to provide instant feedback, with background synchronization to Supabase.
- **Local Caching (Hive)**: User profile data is stored in `userBox` (`lib/core/helper/hive_boxes.dart`), allowing the app to launch into a populated state without waiting for network calls.
- **Media Handling**:
    - **Compression**: `ImageHelper` uses `flutter_image_compress` (quality 70, minWidth/Height 1024) to optimize assets before upload.
    - **Efficient Retrieval**: `cached_network_image` prevents redundant downloads of thumbnails and profile pictures.
- **Data Batching & Sticky Sort**:
    - `HomeController` fetches updates in batches of 50.
    - **Sticky Sort**: Implements a custom sorting algorithm that prioritizes "Official" university documents at the top of the feed regardless of upload time.
- **Atomic Operations**: PostgreSQL RPC functions (e.g., `increment_likes`) handle counter updates on the server side to prevent race conditions and ensure data integrity.

## 3. Design & UI/UX
The app adheres to **Material 3** principles with a premium academic aesthetic.

- **Theme**: Centered around "Premium Deep Blue" (`#0D47A1`) defined in `lib/core/config/color.dart`.
- **Typography**: Uses 'Plus Jakarta Sans' via `google_fonts` for a modern, readable feel.
- **Visual Effects**:
    - **Glassmorphism**: Implemented using the `glassmorphism` package for layered, semi-transparent UI elements (e.g., in `PostCard`).
    - **Shimmer Placeholders**: Used in `HomeDocumentSection` and search results to eliminate "grey space" during loading.
    - **Lottie Animations**: Provides rich feedback for empty states and successful operations.
- **Responsiveness**: Layouts are designed to be fluid across different Android device sizes.

## 4. Security Posture
The migration to Supabase has significantly hardened the application:

- **Authentication**: JWT-based auth via Supabase. Deep linking (`io.supabase.flutternotehub`) is configured in `AndroidManifest.xml` for secure callback handling.
- **Authorization (RLS)**: **Row Level Security** is enforced on all PostgreSQL tables.
    - Profiles: Owners can update their data; public can read.
    - Documents: Owners have full CRUD; others have read-only access.
    - Notifications: Strictly private to the `receiver_id`.
- **Database Integrity**: Critical tables use `SECURITY DEFINER` RPCs to allow authorized updates to sensitive columns (like interaction counts) without exposing the whole table to write access.
- **File Security**: Storage buckets are governed by policies that restrict file uploads and deletions to authenticated owners.
- **Sensitive Data**: Passwords and session tokens are managed entirely by Supabase Auth, adhering to industry standards (Argon2/Bcrypt).

## 5. Development & CI/CD
- **Android Configuration**:
    - Targets API 36.
    - Uses AGP 8.9.1, Kotlin 2.1.0, and Gradle 8.12.
    - **MultiDex & Desugaring**: Enabled to support modern Java APIs and large plugin dependencies like `flutter_local_notifications`.
- **Linting Policy**: The project enforces a "Zero Warnings" policy. `flutter analyze` must return no issues for CI to pass.
- **Testing**: Run `flutter test` to execute the suite (e.g., `test/dummy_test.dart`).

---
*Analyzed and Documented by Jules, AI Software Engineer.*
