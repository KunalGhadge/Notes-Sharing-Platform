# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented in the platform.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It utilizes a **Flutter** frontend and a serverless **Supabase** backend.

## 1. Architecture & State Management
- **Pattern**: The application follows a modular MVC-like pattern using **GetX**.
    - `lib/controller/`: Contains reactive business logic (e.g., `DocumentController`, `AuthController`).
    - `lib/view/`: Contains UI components and screens.
    - `lib/service/`: Infrastructure services like `FileDownload` and `NotificationService`.
- **Reactivity**: State is managed via `Rx` variables (e.g., `.obs`) and updated using `Obx` or `GetX` builders to ensure minimal UI rebuilds.

## 2. Performance Analysis
- **Local Persistent Caching**:
    - **Hive**: Used for high-performance NoSQL local storage. User metadata is cached in `userBox` (see `lib/core/helper/hive_boxes.dart`) to allow instant profile loading.
    - **File Caching**: The `FileCaching` service uses `Dio` and `path_provider` to cache downloaded documents in the system's temporary directory, preventing redundant network calls.
- **Real-time Synchronization**:
    - `HomeController` utilizes `SupabaseRealtime` to listen for `PostgresChanges` on the `documents` table, ensuring the feed stays updated without manual refreshes.
- **Media Optimization**:
    - **Compression**: `ImageHelper` integrates `flutter_image_compress` to optimize cover images before they are uploaded to Supabase Storage.
    - **Lazy Loading**: Thumbnails are loaded using `cached_network_image` with shimmer placeholders for smooth UX.
- **Database Scalability**:
    - **Atomic Operations**: Interactions like `increment_likes` are handled via PostgreSQL Functions (`RPCs`) to ensure data consistency under high concurrency.
    - **Sticky Sort**: The feed implements a custom sorting algorithm that prioritizes `is_official` content followed by the latest uploads.

## 3. Design & Branding
- **UI Paradigm**: Implements **Material 3** with a **Glassmorphism** aesthetic.
    - Custom gradients (`AppGradients.premiumGradient`) and semi-transparent overlays (`.withValues(alpha: ...)`) create a premium, layered look.
- **Branding**: The "Premium Deep Blue" theme (`#0D47A1`) is consistently applied across the app to reflect academic integrity.
- **Component Standard**: Standardized widgets like `PrimaryButton`, `Loader`, and `Toasts` (via `toastification`) ensure visual consistency.

## 4. Security Analysis
The platform enforces granular security at both the application and database layers:

- **Authentication**: Managed by **Supabase Auth** using **JWT**. Session state is synchronized with Hive for local persistence.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all tables:
    - **Profiles**: Public read access; write access restricted to the authenticated `auth.uid()`.
    - **Documents**: Public read access; owner-only write access (`auth.uid() = user_id`).
    - **Notifications**: Granular access ensuring users only see notifications where they are the `receiver_id`.
- **API Integrity**: Atomic counters (likes/dislikes) are protected by `SECURITY DEFINER` RPC functions, preventing users from directly manipulating count columns.
- **Storage Security**: Policies on Supabase Storage buckets ensure that document deletions in the database can trigger corresponding cleanups in object storage.

## 5. Development & QA ("Zero Warnings" Policy)
The project strictly adheres to a **Zero Warnings** policy. All contributions must pass `flutter analyze` without any issues.

- **Modernization Rules**:
    - Use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`.
    - Use `activeThumbColor` for `Switch` widgets.
    - Ensure all flow control structures use explicit curly braces.
    - Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.
- **CI/CD**: The project includes `flutter_test` support (e.g., `test/dummy_test.dart`) to verify basic integrity.

---
*Analyzed and Documented by Jules, AI Software Engineer (Feb 2026).*
