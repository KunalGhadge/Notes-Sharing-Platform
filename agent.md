# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented in the application.

## 1. Architecture Overview
Serious Study follows a reactive, decoupled architecture built on the Flutter framework.

- **State Management**: **GetX** is the primary state management solution. It handles reactive state updates (`.obs`, `GetX`, `Obx`), dependency injection (`Get.put`, `Get.find`), and simplified navigation. Controllers are separated by domain (e.g., `AuthController`, `DocumentController`, `HomeController`) to ensure a clean separation of concerns.
- **Backend-as-a-Service**: **Supabase** replaces the legacy Django/MongoDB stack. The app leverages:
    - **Supabase Auth**: JWT-based secure authentication.
    - **PostgreSQL**: Relational data storage with advanced features like Row Level Security (RLS) and stored procedures (RPCs).
    - **Supabase Storage**: Object storage for documents, covers, and profile avatars.
    - **Realtime**: PostgreSQL Change streams for live feed updates.
- **Local Persistence**: **Hive** is used for high-performance NoSQL local caching.
    - `userBox`: Stores `UserModel` (adapter-based) for session persistence.
    - `downloadsBox`: Tracks local file paths for offline access.

## 2. Performance Analysis
- **Optimistic UI Pattern**: Implemented in `DocumentController` for likes, dislikes, and bookmarks. The UI updates immediately upon user interaction, with background synchronization and automatic rollback on network failure.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is used in the `UploadController` to optimize cover images before upload (quality 70).
    - **Network Caching**: `cached_network_image` ensures that thumbnails and profile pictures are cached on the device, reducing redundant network requests.
- **Database Efficiency**:
    - **Atomic Counters**: Critical metrics like `likes_count` are updated via PostgreSQL Functions (`RPCs`) such as `increment_likes`. This prevents race conditions and ensures data integrity.
    - **Batch Fetching**: The `HomeController` fetches data in batches (limit 50) and implements "Sticky Sort" to prioritize official documents at the database/application layer.
- **File Handling**: `FileCaching` service uses `Dio` to download and store documents in the temporary directory, checking for existing files before re-downloading.

## 3. Design & UI/UX
- **Material 3**: The app adheres to Material 3 design principles, using `useMaterial3: true` and `ColorScheme.fromSeed`.
- **Glassmorphism**: A core aesthetic feature implemented via the `glassmorphism` package and custom gradients (`AppGradients.glassGradient`). Seen in `PostCard` overlays and navigation elements.
- **Typography & Color**:
    - **Font**: 'Plus Jakarta Sans' (via `google_fonts`) for a clean, academic look.
    - **Primary Color**: Premium Deep Blue (`#0D47A1`).
- **Visual Feedback**:
    - **Shimmer**: Used in `HomeDocumentSection` to eliminate "grey space" during data loading.
    - **Lottie**: Integrated for engaging empty states and success animations.
    - **Toastification**: Provides modern, non-blocking notifications for errors and successes.

## 4. Security & Data Integrity
- **Authentication**: JWT-based sessions managed by Supabase. The `AuthController` ensures that users are authenticated before performing sensitive operations.
- **Authorization (RLS)**: Row Level Security is the backbone of data security.
    - Users can only `UPDATE` their own profiles.
    - Only the document owner (or admins) can `DELETE` or `UPDATE` a resource.
    - Notifications and Bookmarks are private to the recipient/owner.
- **Storage Policies**: Policies on the `documents` bucket ensure that while files can be read publicly (if intended), write access is restricted to authenticated owners.
- **Input Validation**: The `UploadController` enforces a 10MB limit on direct file uploads and requires mandatory fields to maintain community content quality.

## 5. Database Schema (PostgreSQL)
Key tables defined in `SUPABASE_SCHEMA.sql`:
- `profiles`: Extended user metadata (institute, academic interests, admin status).
- `documents`: Metadata for shared notes and 'tweets'. Includes flags for `is_external` and `is_official`.
- `interactions`: Unique mapping for user likes/dislikes on documents.
- `bookmarks`: User-specific saved resources.
- `notifications`: Real-time activity logs.
- `followers`: Social graph mapping.

*Note: RPC functions like `increment_likes` and `decrement_likes` should be implemented with `SECURITY DEFINER` in the database to allow counter updates without exposing write access to the main tables.*

## 6. Development & QA Workflow
- **Linting**: Strict adherence to `flutter_lints`. All flow control must use curly braces, and `print()` statements are prohibited in favor of `debugPrint`.
- **Testing**: `flutter test` is used for unit and widget tests.
- **Android Configuration**: Optimized with `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` to support modern APIs and the `flutter_local_notifications` plugin.
- **Deep Linking**: Configured for `io.supabase.flutternotehub://login-callback` to handle authentication redirects.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
