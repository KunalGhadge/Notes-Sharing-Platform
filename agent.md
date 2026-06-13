# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, optimizations, and security posture of the platform.

## 1. Performance & Scalability
- **Reactive State Management**: Powered by **GetX**. Controllers manage business logic independently, ensuring high responsiveness and clear separation of concerns.
- **Local Persistence (Hive)**: Utilizes `Hive` for low-latency NoSQL storage. The `userBox` stores `UserModel` data (id, username, profileUrl) for instant profile loading.
- **Optimized Feed (Sticky Sort)**: The `HomeController` fetches documents in batches (limit 50). It implements a custom **Sticky Sort** algorithm that prioritizes `is_official` content at the top of the feed before chronological ordering.
- **Media Optimization**:
    - **Compression**: `UploadController` enforces a 10MB limit for direct uploads and uses `ImageHelper` (flutter_image_compress) to optimize cover images.
    - **Caching**: `cached_network_image` is used for thumbnails to reduce redundant network requests.
- **Atomic Backend Operations**: Database integrity is maintained via PostgreSQL **RPCs** (e.g., `increment_likes`, `decrement_dislikes`), preventing race conditions in community interactions.

## 2. Design & UI/UX Architecture
- **Theme**: Premium Deep Blue (`#0D47A1`) with Material 3 integration.
- **Aesthetics**: Extensive use of **Glassmorphism** for premium components like the `BottomFooter`.
- **Navigation**: Custom floating navigation bar (`BottomFooter`) with spread shadows and a 30.0 border radius.
- **UX Feedback**: Shimmer placeholders (`shimmer` package) and Lottie animations are used for asynchronous state transitions.
- **Typography**: "Plus Jakarta Sans" is used across the app to maintain a modern academic feel.

## 3. Security Analysis
- **Authentication**: JWT-based authentication via **Supabase Auth**.
- **Authorization (RLS)**: **Row Level Security** is enabled on all tables.
    - **Documents**: `SELECT` is public; `INSERT`/`UPDATE`/`DELETE` requires `auth.uid() = user_id`.
    - **Notifications**: Strictly private to the `receiver_id`.
- **Identified Security Risk**: A critical privilege escalation vulnerability exists where authenticated users can potentially update their own `is_admin` status via direct API calls, as the `profiles` table `UPDATE` policy (`auth.uid() = id`) lacks column-level restrictions.
- **Data Integrity**: `SECURITY DEFINER` functions allow users to trigger count updates without having direct write access to the counter columns.

## 4. Maintenance & QA
- **Zero Warnings Policy**: The project strictly adheres to modern Flutter standards.
    - **Flow Control**: All structures must use explicit curly braces.
    - **Modern APIs**: Uses `.withValues(alpha: x)` instead of `.withOpacity(x)`.
    - **Switch Widgets**: Must use `activeThumbColor` to satisfy deprecation warnings for `activeColor`.
- **Code Health**: Always verify integrity by running `flutter analyze` and `flutter test` from the `notehub/` directory.

---
*Maintained by Jules, AI Software Engineer.*
