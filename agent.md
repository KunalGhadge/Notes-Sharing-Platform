# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis and system manual for the Serious Study project, documenting its architecture, performance strategies, design philosophy, and security implementation from a developer's perspective.

## 1. System Architecture
Serious Study follows a reactive, decoupled architecture using **Flutter** and **Supabase**.

- **Frontend Framework**: Flutter 3.5.4 (Stable Channel).
- **State Management**: `GetX` is used for reactive state updates, dependency injection, and routing. Controllers (e.g., `DocumentController`, `HomeController`) encapsulate business logic.
- **Backend-as-a-Service**: `Supabase` (PostgreSQL) provides authentication, real-time database, and object storage.
- **Local Persistence**: `Hive` (NoSQL) caches user metadata and session info for instant cold-starts.

## 2. Performance Analysis
- **Reactive Feed & Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm that prioritizes 'official' documents at the top of the feed while maintaining chronological order for others. It fetches data in batches of 50 to optimize network utilization.
- **Optimistic UI Updates**: Interactions like Likes, Dislikes, and Bookmarks are performed optimistically in `DocumentController`. The UI updates immediately, and the backend sync happens in the background, with automatic rollback on failure.
- **Atomic Database Operations**: Counters (likes, dislikes, bookmarks) are managed via PostgreSQL stored procedures (`RPCs`) like `increment_likes` and `decrement_likes`. This prevents race conditions and ensures data integrity.
- **Media & Asset Optimization**:
    - **Caching**: `cached_network_image` is used for all thumbnails and profile pictures.
    - **Compression**: `flutter_image_compress` is integrated into the `UploadController` to compress cover images before storage.
    - **Size Constraints**: A hard 10MB limit is enforced for direct document uploads to ensure consistent performance.
- **Real-time Synchronization**: Supabase Realtime (Postgres Changes) is used to keep the document feed and notifications synchronized across all active clients.

## 3. Design & UX Philosophy
- **Modern Aesthetic**: The app implements **Material 3** combined with **Glassmorphism**.
    - Semi-transparent overlays (`.withValues(alpha: ...)` for precision) and custom gradients create a premium look.
    - Primary Brand Color: **Premium Deep Blue** (`#0D47A1`).
- **Typography**: "Plus Jakarta Sans" is used as the primary typeface for its modern, academic feel.
- **Feedback Loops**:
    - **Shimmer**: Used extensively for skeleton loading states.
    - **Lottie**: High-quality animations for success states and empty results.
    - **Toastification**: Standardized, non-intrusive notification toasts for errors and warnings.
- **Custom Components**: A custom `BottomFooter` with glassmorphism provides a premium navigation experience.

## 4. Security & Data Integrity
- **JWT Authentication**: Secure user sessions managed by Supabase Auth using industry-standard JWTs.
- **Row Level Security (RLS)**: The database is strictly protected by RLS policies defined in `SUPABASE_SCHEMA.sql`.
    - Users can only modify their own profiles and documents.
    - Private data like bookmarks and notifications are restricted to the owner.
- **Privilege Escalation Prevention**: The `is_official` flag in the `documents` table can only be set via the backend after verifying the user's `is_admin` status, preventing unauthorized official broadcasts.
- **SQL Hardening**: Stored procedures use `SECURITY DEFINER` and explicit `search_path` settings to prevent search-path hijacking and unauthorized access.

## 5. Maintenance & QA (Zero Warnings Policy)
The project adheres to a strict **Zero Warnings** policy. All code must pass `flutter analyze` and `flutter test` before submission.

- **Linting Compliance**: Explicit curly braces for all flow control structures; mandatory `// ignore: empty_catches` for intentional empty catch blocks.
- **Modern API Usage**: Deprecated APIs (like `.withOpacity()` or `activeColor`) must be modernized (to `.withValues(alpha: ...)` and `activeThumbColor`) to ensure compatibility with Flutter 3.5.4+.
- **Automated Verification**: Developers should run the following before committing:
  ```bash
  cd notehub
  flutter analyze
  flutter test
  ```

---
*Maintained by the Serious Study Engineering Team.*
