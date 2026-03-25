# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It serves as the primary guide for understanding the architecture, performance optimizations, design patterns, and security measures of the application.

## 1. Project Architecture
The application follows a decoupled **GetX (MVC)** architecture, separating business logic (Controllers) from the UI (Views). It leverages **Supabase** as a serverless backend for Authentication, PostgreSQL Database, and Object Storage.

### Key Components:
- **State Management**: `GetX` for reactive updates, dependency injection, and routing.
- **Backend**: `Supabase` for real-time data sync, JWT-based auth, and Row Level Security (RLS).
- **Persistence**: `Hive` for high-performance NoSQL local caching of user profiles and download metadata.
- **Networking**: `Supabase Flutter SDK` for primary operations and `Dio` for specialized file handling.

## 2. Performance Optimizations
- **Optimistic UI**: The `DocumentController` implements an optimistic pattern for likes, dislikes, and bookmarks, providing immediate visual feedback while syncing with the backend in the background.
- **Sticky Sort**: The `HomeController` prioritizes official university documents in the feed using a "Sticky Sort" algorithm (`is_official` DESC, `created_at` DESC).
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is used in `UploadController` (via `ImageHelper`) with quality 70 and min dimensions of 1024 to reduce storage and bandwidth costs.
    - **Caching**: `cached_network_image` is used throughout the app to prevent redundant asset downloads.
- **Database Efficiency**:
    - **Relational Joins**: `AppSearchController` and `HomeController` perform relational joins (profiles, interactions, bookmarks) in a single Supabase query to minimize network round-trips.
    - **Atomic RPCs**: High-concurrency operations like `increment_likes` are handled via PostgreSQL `SECURITY DEFINER` functions to ensure data integrity and prevent race conditions.
- **Lazy Loading**: Feed updates are fetched in batches of 50 to maintain a responsive initial load.

## 3. Design & UI/UX
- **Design Language**: Material 3 with a "Premium Deep Blue" theme (`#0D47A1`).
- **Aesthetics**:
    - **Glassmorphism**: Implemented via the `glassmorphism` package, particularly in `PostCard` and navigation elements.
    - **Typography**: Uses 'Plus Jakarta Sans' via `google_fonts`.
- **Feedback**:
    - **Shimmer**: Placeholder loading states in `HomeDocumentSection` to prevent blank screens.
    - **Lottie**: Custom animations for empty states and success feedback.
    - **Toastification**: Enhanced toast notifications for system alerts.
- **Modernization**: The project maintains a "Zero Warnings" policy. All deprecated `.withOpacity()` calls are replaced with `.withValues(alpha: x)` for Flutter 3.27+ compatibility.

## 4. Security & Data Integrity
- **Authentication**: JWT-based session management via Supabase Auth.
- **Authorization (RLS)**: Row Level Security is strictly enforced on all PostgreSQL tables.
    - **Profiles**: Only owner-writeable.
    - **Documents**: Only owner-writeable; public-readable.
    - **Interactions**: Unique constraints per user/document pair.
- **API Security**: Counter updates (likes/dislikes) are restricted to `SECURITY DEFINER` RPCs, preventing users from directly modifying numeric columns.
- **Storage Policies**: Supabase Storage buckets are protected by RLS, ensuring users can only manage their own uploads.
- **File Limits**: `UploadController` enforces a 10MB limit for direct document uploads to control cloud costs.

## 5. Android Configuration
- **Build Specs**:
    - `compileSdk`: 36
    - `targetSdk`: 36
    - `minSdkVersion`: 21 (Flutter default)
- **Features**:
    - **MultiDex**: Enabled for large dependency support.
    - **Core Library Desugaring**: Enabled (`com.android.tools:desugar_jdk_libs:2.1.4`) for modern Java API support.
    - **Deep Linking**: Configured for `io.supabase.flutternotehub://login-callback` to handle authentication redirects.
    - **Notifications**: Local notifications initialized with `@mipmap/ic_launcher`.

## 6. Coding Conventions
- **Naming**: Use `lowerCamelCase` for metadata fields (e.g., `avatarUrl`).
- **Linting**:
    - Zero warnings policy for `flutter analyze`.
    - Always use curly braces for flow control.
    - Use `// ignore: empty_catches` for intentional empty catch blocks.
- **UI Practices**:
    - Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
    - Centralize color and typography in `lib/core/config/`.
- **Verification**: Run `flutter analyze && flutter test` in the `notehub/` directory before any commit.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
