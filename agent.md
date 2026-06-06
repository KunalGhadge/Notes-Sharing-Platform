# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis and guide for the Serious Study project from a developer's perspective. It serves as the "source of truth" for architecture, design, and security standards.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform tailored for the Mumbai University student community. The application utilizes a modern serverless architecture powered by Flutter and Supabase.

## 2. Architecture (GetX MVC)
The application follows a decoupled Model-View-Controller (MVC) pattern implemented via **GetX**.

- **Controllers (`lib/controller/`)**:
    - **Reactive Logic**: Uses `.obs` variables and `Obx` or `GetX` widgets for real-time UI updates without manual state management.
    - **Dependency Injection**: Controllers are initialized in `main.dart` or lazily loaded using `Get.put()` or `Get.lazyPut()`.
    - **Service Integration**: Controllers act as the bridge between the UI and backend services (Supabase, Hive).
- **Models (`lib/model/`)**:
    - JSON serializable classes for consistent data handling across the app.
- **Views (`lib/view/`)**:
    - Modular UI components organized by screen.
    - Uses `Get.find<Controller>()` to access business logic.

## 3. Performance & Optimization
- **High-Performance Caching**:
    - **Hive**: Used for NoSQL local persistence (`userBox` and `downloadsBox`). This ensures that user sessions and profile data are available offline and load instantly.
    - **File Caching**: The `FileCaching` service uses `Dio` and `path_provider` to manage system temporary directory caches for downloaded resources.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is integrated into the `UploadController`. Cover images are compressed to 70% quality before reaching Supabase Storage to save bandwidth and storage.
    - **Thumbnail Caching**: `cached_network_image` is used globally to prevent redundant network requests for profile pictures and document covers.
- **Efficient Data Fetching**:
    - **Batching**: HomeController fetches documents in batches (limit 50) to balance responsiveness and payload size.
    - **Sticky Sort**: Implemented in `HomeController` to prioritize 'official' documents at the top of the feed regardless of chronological order.
    - **Optimistic UI**: `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks, ensuring immediate feedback before backend synchronization.

## 4. Design & UX Standards
- **Premium Branding**:
    - **Primary Theme**: "Premium Deep Blue" (`#0D47A1`), implemented via `PrimaryColor.shade500`.
    - **Typography**: Uses "Plus Jakarta Sans" via `AppTypography` configuration for a modern, academic feel.
- **UI Paradigm**:
    - **Material 3**: The app is fully compliant with Material 3 design principles.
    - **Glassmorphism**: Semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`) and custom gradients (`AppGradients.premiumGradient`) are used for premium components like the Bottom Navigation bar.
    - **Standardized Feedback**: Uses `Loader` and `Loader2` for loading states and `toastification` for consistent user notifications.
- **Animations**: `Lottie` animations are used for empty states, errors, and success feedback to enhance user engagement.

## 5. Security Architecture
The platform implements a "Security First" approach using Supabase's built-in features.

- **Authentication**:
    - Managed by **Supabase Auth (JWT)**.
    - Secure session handling via the Supabase SDK.
- **Row Level Security (RLS)**:
    - **Granular Policies**: Every table has RLS enabled.
    - `profiles`: Users can only `UPDATE` their own data.
    - `documents`: Owners have full control; others have read-only access.
    - `notifications`: Private to the `receiver_id`.
- **Database Logic (RPCs)**:
    - **Atomic Counters**: Operations like `increment_likes` are performed using PostgreSQL functions (`SECURITY DEFINER`) to prevent client-side race conditions and unauthorized manipulation.
- **Storage Protection**:
    - Supabase Storage buckets are governed by policies that restrict file uploads and deletions to the authenticated owner.

## 6. Maintenance & QA
- **Zero Warnings Policy**: The project maintains a strict linting policy. Developers MUST run `flutter analyze` and ensure no warnings or errors are present before submission.
- **Static Analysis**: All flow control structures must use explicit curly braces. Intentional empty catch blocks must include the `// ignore: empty_catches` annotation.
- **Environment**:
    - Flutter SDK ^3.44.1
    - Dart SDK ^3.5.4
- **Testing**:
    - Run `flutter test` to execute the baseline test suite.
    - Verify UI changes visually using the provided screenshots in the `outputs/` directory as a reference.

---
*Maintained by Jules, AI Software Engineer.*
