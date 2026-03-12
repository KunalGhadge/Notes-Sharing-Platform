# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective, detailing its architecture, performance optimizations, design patterns, and security implementations.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform specifically built for the Mumbai University student community. It leverages a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 1. Architecture Analysis
- **Framework & State Management**: The application uses **Flutter** with **GetX** for reactive state management, dependency injection, and routing. Controllers (e.g., `DocumentController`, `AuthController`) decouple business logic from the view layer.
- **Backend Architecture**: Migrated from a legacy Django/MongoDB stack to **Supabase**. It utilizes Supabase Auth for identity, PostgreSQL for relational data, and Supabase Storage for media assets.
- **Local Persistence**: **Hive** is used for high-performance NoSQL local caching. User profile data is stored in the `user` box, and download metadata is stored in the `downloads` box.
- **Service Layer**: Specialized services like `file_caching.dart` (using `Dio`) handle background tasks like file downloads and local storage path management.

## 2. Performance Optimizations
- **Optimistic UI**: Interactions like likes, dislikes, and bookmarks use an optimistic update pattern in `DocumentController`. The UI updates immediately, with backend synchronization happening in the background; errors trigger a state rollback.
- **Database Atomic Operations**: Critical counters (likes/dislikes) are updated via **PostgreSQL RPCs** (`increment_likes`, `decrement_dislikes`, etc.). This ensures atomicity and prevents race conditions inherent in client-side increments.
- **Real-time Synchronization**: **Supabase Realtime** channels are used in `HomeController` and `NotificationController` to provide live updates for new documents and interactions without manual polling.
- **Media Handling**:
    - **Image Compression**: `flutter_image_compress` is used in `ImageHelper` (quality 70, minWidth/Height 1024) to optimize assets before upload.
    - **Network Caching**: `cached_network_image` is used for profile and document thumbnails to minimize redundant network requests.
    - **Batch Fetching**: The `HomeController` limits initial document fetches to 50 items to optimize bandwidth and rendering performance.
- **Sticky Sort**: The feed implements a custom sorting algorithm in `HomeController` that prioritizes "Official" documents (marked with `is_official`) followed by chronological order.

## 3. Design & Aesthetic
- **UI Paradigm**: Implements **Material 3** with a custom **Glassmorphism** aesthetic.
- **Branding**: The "Premium Deep Blue" (`#0D47A1`) theme reflects academic integrity.
- **Visual Feedback**:
    - **Glassmorphic Components**: Uses `GlassmorphicContainer` and `AppGradients.glassGradient` (semi-transparent overlays) for a modern, layered look.
    - **Shimmers**: Integrated into `HomeDocumentSection` and search results to prevent blank screens during data loads.
    - **Lottie**: Vector animations are used for empty states and success feedback.
- **Typography**: Optimized for readability using `google_fonts` (primarily 'Plus Jakarta Sans').

## 4. Security Implementation
- **Authentication**: JWT-based session management via **Supabase Auth**.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables:
    - **Profiles**: Publicly readable, but `UPDATE` is restricted to the owner (`auth.uid() = id`).
    - **Documents/Comments**: Owners have full `ALL` access; others have `SELECT` access.
    - **Notifications/Bookmarks**: Strictly private; restricted to the specific `receiver_id` or `user_id`.
- **API Protection**:
    - Counters are protected by `SECURITY DEFINER` RPC functions, allowing users to trigger specific logic (like incrementing a like) without having direct write access to the `likes_count` column.
    - **Storage Policies**: Governing access to the `documents` bucket, ensuring that only authenticated users can upload and owners can manage their assets.
- **Input Validation**: `AuthController` and `UploadController` implement client-side validation, including file size limits (10MB) for direct uploads to manage storage costs.

## 5. Coding Conventions & Standards
- **Modern Flutter APIs**:
    - Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Linting & Quality**:
    - Zero warnings policy: `flutter analyze` must pass with no issues.
    - Flow control structures (if/for/while) **must** always use curly braces.
    - Avoid `print()` statements; use `debugPrint()` or specialized logging.
- **Error Handling**:
    - Intentional empty catch blocks must be annotated with `// ignore: empty_catches` and include a comment explaining the silence (e.g., `/* silent */`).
- **Media**: All SVG icons must be rendered using `SvgPicture.asset` with `colorFilter` instead of the deprecated `color` property.
- **Naming**: Use `lowerCamelCase` for variables (e.g., `avatarUrl`) and `PascalCase` for classes/controllers.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
