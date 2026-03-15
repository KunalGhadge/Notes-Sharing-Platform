# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the **Serious Study** platform from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented in the Flutter application and its Supabase backend.

---

## 1. Architecture & Tech Stack

Serious Study utilizes a modern, serverless architecture designed for scalability and high performance.

- **Frontend**: Flutter 3.24+ (SDK 3.5.4)
- **State Management**: **GetX**
    - Reactive programming using `.obs` variables and `Obx`/`GetBuilder`.
    - Dependency injection via `Get.put()` and `Get.find()`.
    - Decoupled logic in specialized controllers (e.g., `AuthController`, `DocumentController`, `HomeController`).
- **Backend (Serverless)**: **Supabase**
    - **PostgreSQL**: Relational database with advanced features like JSONB and Row Level Security (RLS).
    - **Auth**: JWT-based authentication with support for email confirmation and metadata-based profile creation.
    - **Storage**: Object storage for document uploads and thumbnails, governed by bucket-level policies.
    - **Realtime**: PostgreSQL CDC (Change Data Capture) via WebSockets for live feed updates and notifications.
- **Local Persistence**: **Hive**
    - Lightweight and blazing-fast NoSQL database.
    - Used for caching user sessions (`userBox`) and offline access to download metadata (`downloadsBox`).

---

## 2. Performance Optimizations

High responsiveness is achieved through several strategic implementations:

- **Optimistic UI**:
    - `DocumentController` updates the local UI state (likes, bookmarks) immediately before confirming with the backend.
    - Reverts state gracefully in case of network or database failures.
- **Atomic Operations (RPCs)**:
    - Interaction counters (likes/dislikes) are handled via PostgreSQL functions (`increment_likes`, `decrement_dislikes`).
    - This avoids race conditions and reduces client-side logic overhead.
- **Media Optimization**:
    - **Centralized Compression**: `ImageHelper` uses `flutter_image_compress` to downscale images (1024px, 70% quality) before upload.
    - **Smart Caching**: `CachedNetworkImage` prevents redundant network requests for thumbnails.
    - **File Caching**: `FileCaching` service uses `Dio` and `path_provider` to manage local copies of downloaded PDFs.
- **Data Fetching Strategy**:
    - **Batching**: Documents are fetched in limits of 50 to optimize initial load times.
    - **Sticky Sort**: `HomeController` implements a "Sticky Sort" algorithm that prioritizes official university documents at the top of the feed.
    - **Relational Joins**: `AppSearchController` and `DocumentController` use Supabase's relational query syntax to fetch documents, profiles, and interactions in a single network request.

---

## 3. UI/UX & Design Paradigm

The application adheres to **Material 3** principles with a custom academic aesthetic.

- **Design Language**: **Glassmorphism**
    - Usage of `GlassmorphicContainer` and `AppGradients.glassGradient` for a premium, layered feel.
    - Semi-transparent overlays (e.g., `.withValues(alpha: 0.15)`) for modern UI elements.
- **Theming**:
    - Primary Color: **Premium Deep Blue** (`#0D47A1`).
    - Typography: **Plus Jakarta Sans** (via `google_fonts`).
- **User Experience**:
    - **Shimmer Placeholders**: Prevent layout shifts and "grey space" during data loading in `HomeDocumentSection`.
    - **Lottie Animations**: Provides rich feedback for empty states and successful operations.
    - **Toastification**: Unified notification system for errors, warnings, and successes.

---

## 4. Security & Data Integrity

The migration to Supabase centered on creating a "Secure by Default" environment.

- **Authentication**:
    - Secure password handling via Supabase Auth (Argon2/Bcrypt).
    - Session integrity maintained through JWTs.
- **Authorization (Row Level Security)**:
    - **Public Read**: Profiles and Documents are viewable by all authenticated users.
    - **Restricted Write**: RLS policies ensure that only owners can `INSERT`, `UPDATE`, or `DELETE` their own documents and profile data.
    - **Private Data**: Notifications and Bookmarks are strictly private to the receiving/owning user.
- **API Security**:
    - Use of `SECURITY DEFINER` on PostgreSQL RPCs allows controlled updates to protected columns (like `likes_count`) without exposing the entire table to write access.
- **File Security**:
    - Signed URLs or Public Bucket Policies govern access to storage assets, preventing unauthorized direct links.

---

## 5. Development Workflow

- **Android Configuration**:
    - Supports `compileSdk 36` and `targetSdk 36`.
    - Requires `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` for modern Java API support.
    - Deep linking configured for `io.supabase.flutternotehub://login-callback`.
- **Code Quality**:
    - **Linting**: Strict "Zero Warnings" policy enforced via `flutter analyze`.
    - **Testing**: Test suite located in `notehub/test/` (e.g., `dummy_test.dart`).
- **CI/CD**:
    - GitHub Actions workflows are configured to run `flutter analyze` and `flutter test` in the `notehub/` subdirectory.
- **Coding Conventions**:
    - Avoid `print()` statements; use `debugPrint`.
    - Use `.withValues(alpha: x)` instead of deprecated `.withOpacity()`.
    - Use `activeThumbColor` instead of `activeColor` for Material 3 Switches.

---
*Documented by Jules, AI Software Engineer.*
