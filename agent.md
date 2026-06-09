# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis and system manual for the Serious Study project from a developer's perspective. Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community, utilizing a Flutter frontend and a serverless Supabase backend.

## 1. Architecture & Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.44.1+ (SDK 3.5.4)
- **State Management**: **GetX** – Implements a reactive MVC-like pattern. Controllers (e.g., `DocumentController`, `AuthController`) manage business logic and state, decoupled from UI widgets.
- **Dependency Injection**: Handled via `Get.put()` and `Get.find()`, predominantly initialized in `main.dart` and `Layout`.
- **Local Storage**: **Hive** – Used for high-performance NoSQL local caching of user profile metadata (`userBox`) and download tracking (`downloadsBox`).
- **Navigation**: GetX routing is utilized for screen transitions.

### Backend (Supabase - Serverless)
- **Database**: **PostgreSQL** – Relational data storage with Row Level Security (RLS).
- **Authentication**: **Supabase Auth** – Managed JWT-based authentication.
- **Storage**: **Supabase Storage** – Object storage for documents (PDFs/Images) and cover thumbnails.
- **Logic**: **PostgreSQL Functions & RPCs** – Atomic operations like incrementing like/dislike counts are handled server-side to ensure data consistency.
- **Real-time**: **Supabase Realtime** – Subscriptions are used to refresh feeds and notifications instantly.

## 2. Performance Analysis
- **Reactive UI**: GetX ensures that only necessary widgets are rebuilt when data changes.
- **Media Optimization**:
    - **Caching**: `cached_network_image` prevents redundant network requests for thumbnails.
    - **Compression**: `flutter_image_compress` is integrated into the upload pipeline in `UploadController` via `ImageHelper`.
- **Caching Strategy**:
    - `Hive` stores user metadata to allow immediate app launch and instant profile loading.
    - `FileCaching` service uses `Dio` to manage local persistence of downloaded documents in the system's temporary directory.
- **Optimistic UI**: Interactions like liking, disliking, and bookmarking (in `DocumentController`) update the UI immediately before confirming with the Supabase backend.
- **Batching**: HomeController fetches documents in batches (limit 50) to optimize initial payload.
- **Sticky Sort**: The feed algorithm prioritizes 'official' documents at the top of the feed regardless of chronological order.

## 3. Security Analysis
The migration from legacy systems to Supabase has established a robust security posture:

- **Authentication**: JWT (JSON Web Tokens) are used for session management, handled securely by the Supabase SDK.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all tables.
    - `profiles`: Users can only `UPDATE` their own data.
    - `documents`: Owners have full control; others have read-only access.
    - `notifications`: Private to the recipient, except for global announcements.
- **Atomic Operations**: `SECURITY DEFINER` RPCs (e.g., `increment_likes`) prevent direct manipulation of counter columns by users.
- **Input Validation**: `AuthController` and `UploadController` implement client-side validation before hitting backend endpoints.
- **Sensitive Data**: Passwords are managed by Supabase Auth using industry-standard hashing; the application never handles plain-text credentials.

## 4. UI/UX Standards
- **Design System**: Implements **Material 3** with a **Glassmorphism** aesthetic (using the `glassmorphism` package).
- **Brand Identity**: Premium Deep Blue theme (`#0D47A1`).
- **Typography**: "Plus Jakarta Sans" via the `google_fonts` package.
- **Feedback Loops**:
    - `shimmer` placeholders for loading states.
    - `lottie` animations for success states and empty feeds.
    - `toastification` for non-intrusive user notifications.
- **Modernized APIs**: Strict adherence to Flutter 3.44.1+ standards, including the use of `.withValues(alpha: ...)` instead of deprecated `.withOpacity()` and `activeThumbColor` for Switch widgets.

## 5. Maintenance & QA
- **Zero Warnings Policy**: All code must pass `flutter analyze` and `flutter test` without warnings or errors.
- **Coding Conventions**:
    - Use explicit curly braces in all flow control structures (including `Obx` returns).
    - Use `// ignore: empty_catches` for intentional silent error handling, placed on a separate line within the block.
    - Avoid `print()` statements; use `debugPrint()` or specialized logging if necessary.
- **Android Specifics**:
    - Requires `INTERNET`, `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`, and `MANAGE_EXTERNAL_STORAGE` permissions.
    - `requestLegacyExternalStorage="true"` is enabled in the Manifest for compatibility.
    - `multiDexEnabled` and `coreLibraryDesugaring` are active in `build.gradle`.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
