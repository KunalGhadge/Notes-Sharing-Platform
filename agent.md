# Developer Guide - Serious Study (Mumbai University Community App)

This document provides a technical deep-dive into the architecture, performance, design, and security of the **Serious Study** platform. It is intended for developers working on the project to understand the core principles and implementation details.

## 1. Architecture & Tech Stack
The application follows a modern, serverless architecture designed for scalability and real-time responsiveness.

- **Frontend**: Flutter 3.41.2 (Stable Channel).
- **State Management**: **GetX** (MVC Pattern). Controllers in `lib/controller/` handle business logic and reactive state.
- **Backend**: **Supabase** (PostgreSQL, Auth, Storage, Realtime).
- **Local Database**: **Hive** for high-performance NoSQL local persistence (caching user sessions and profile data).
- **Networking**: Supabase Flutter SDK for DB/Auth and **Dio** for advanced file operations.

### Directory Structure
- `lib/controller/`: Reactive logic (e.g., `DocumentController`, `AuthController`).
- `lib/view/`: Modular UI components and screens.
- `lib/model/`: Data models (e.g., `UserModel`, `DocumentModel`).
- `lib/core/`: Centralized configurations, themes (`config/`), and helpers.
- `lib/service/`: Low-level services like notifications and file handling.

## 2. Performance Analysis
Performance is optimized through multi-layered caching and efficient data handling:

- **Optimistic UI Updates**: Interactions like Likes, Dislikes, and Bookmarks provide immediate feedback using `GetX` updates before syncing with the backend (see `DocumentController.toggleLike`).
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is used in `UploadController` via `ImageHelper` to reduce asset sizes before upload.
    - **Asset Caching**: `cached_network_image` prevents redundant downloads for thumbnails and profile pictures.
- **Database Efficiency**:
    - **PostgreSQL RPCs**: Atomic operations (e.g., `increment_likes`) are handled via server-side functions to prevent race conditions and reduce client-side logic.
    - **Sticky Sort**: The `HomeController` prioritizes official university documents in the feed using a custom sorting algorithm (`isOfficial DESC, created_at DESC`).
    - **Batching**: Feed data is fetched in batches (limit 50) to minimize initial payload.
- **Perceived Performance**: Shimmer placeholders and Lottie animations are used to bridge the gap during asynchronous operations.

## 3. Design & UI/UX
The app adheres to a "Premium Academic" aesthetic using **Material 3** and **Glassmorphism**.

- **Branding**:
    - **Primary Color**: Premium Deep Blue (`#0D47A1`).
    - **Typography**: 'Plus Jakarta Sans' via Google Fonts.
- **Glassmorphism**: Implemented using the `glassmorphism` package, particularly in `PostCard` overlays and navigation elements.
- **Consistency**: Centralized theme definitions in `lib/core/config/color.dart` and `typography.dart`.
- **Feedback**: Standardized toast notifications via `toastification` (Alignment: `topRight`, Style: `flatColored`).

## 4. Security & Data Integrity
Security is baked into the database layer rather than relying solely on client-side logic.

- **Authentication**: JWT-based session management via Supabase Auth.
- **Authorization (Row Level Security)**:
    - RLS policies in `SUPABASE_SCHEMA.sql` ensure users can only modify their own data (Profiles, Documents, Bookmarks).
    - Public read access is granted for profiles and documents to foster community sharing.
- **Secure Atomic Updates**: By using `SECURITY DEFINER` on PostgreSQL RPCs, the app can increment protected counters (like `likes_count`) without giving users direct write access to those columns.
- **Storage Security**: Supabase Storage buckets are governed by policies that restrict file uploads and deletions to the owner's specific path (`$auth.uid/`).
- **Input Validation**: `UploadController` enforces a 10MB limit for direct file uploads to maintain infrastructure stability.

## 5. Coding Conventions & Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` without warnings.
- **Modern API Usage**:
    - Use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`.
    - `Switch` widgets must include `activeThumbColor` for Flutter 3.41+ compatibility.
- **Atomic Commits**: Ensure each change is logically grouped and verified.
- **Flow Control**: All `if`, `for`, and `while` statements must use curly braces `{}`.
- **Error Handling**: Use `Toasts.showTostError` for user-facing errors and `// ignore: empty_catches` for intentional silent failures.

---
*Maintained by Jules, AI Software Engineer.*
