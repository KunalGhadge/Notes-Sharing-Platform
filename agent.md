# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It serves as a guide for understanding the architecture, performance optimizations, and security measures implemented in the platform.

## 1. System Architecture (GetX MVC)

Serious Study follows a modular MVC (Model-View-Controller) architecture using the **GetX** ecosystem for state management, dependency injection, and routing.

- **Controllers (`lib/controller/`)**: Reactive business logic.
  - `AuthController`: Manages Supabase Auth, profile synchronization, and session persistence in Hive.
  - `DocumentController`: Handles the lifecycle of notes, including optimistic UI updates for likes/bookmarks and communication with Supabase Storage/Database.
  - `HomeController`: Manages the main feed, real-time subscriptions to the `documents` table, and implements the **Sticky Sort** algorithm.
  - `NotificationController`: Handles real-time academic updates via Supabase PostgreSQL Change channels and local notifications.
  - `UploadController`: Manages the multi-step upload process, including image compression and the 10MB file size limit.
- **Models (`lib/model/`)**: Structured data definitions with JSON serialization (e.g., `DocumentModel`, `UserModel`).
- **Services (`lib/service/`)**: Low-level infrastructure tasks like `FileCaching`, `FileDownload`, and `NotificationService`.
- **Views (`lib/view/`)**: Modular UI components. Standardized loaders (`Loader`, `Loader2`) and toasts are used to maintain visual consistency.

### Controller Cross-Communication
The application ensures state consistency across different parts of the app by allowing controllers to communicate. For example, `DocumentController` invokes `Get.find<HomeController>().fetchUpdates()` after a document is deleted to refresh the global feed immediately.

## 2. Performance & Optimization

- **Sticky Sort Algorithm**: Implemented in `HomeController`, this algorithm prioritizes `is_official` documents at the top of the feed while maintaining chronological order for the rest of the content.
- **Optimistic UI**: `DocumentController` implements optimistic updates for interactions (likes, dislikes, bookmarks). The UI reflects the change immediately, and state is reverted only if the backend synchronization fails.
- **High-Performance Caching**:
    - **Hive**: Used for instant loading of user profile data (`userBox`) and tracking local downloads (`downloadsBox`).
    - **CachedNetworkImage**: Minimizes redundant network requests for thumbnails and avatars.
    - **File Caching**: `FileCaching` service checks the system's temporary directory before re-downloading files.
- **Media Pipeline**:
    - **Compression**: `ImageHelper` uses `flutter_image_compress` to optimize cover images (targeting ~70% quality) before upload.
    - **Scalability**: `UploadController` enforces a 10MB limit for direct uploads, encouraging the use of external hosting links (Google Drive, Mega) to reduce server costs and improve upload speed.

## 3. Security & Backend Integrity

The migration to a serverless **Supabase** architecture introduced granular security controls:

- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - Profiles: Owners have exclusive `UPDATE` rights.
    - Documents/Comments: Owners have full control; public has read-only access.
    - Notifications: Restricted to the `receiver_id` or global broadcast.
- **Atomic Operations (RPCs)**: Critical counters (likes, dislikes) are updated via PostgreSQL `SECURITY DEFINER` functions (e.g., `increment_likes`). This prevents users from directly manipulating sensitive columns and ensures data integrity during concurrent updates.
- **JWT Authentication**: Secure session management using Supabase Auth, replacing legacy session-less patterns.
- **Real-time Security**: `NotificationController` applies granular filters (e.g., `receiver_id.eq.$userId`) to PostgreSQL Change channels, ensuring users only receive notifications relevant to them.

## 4. Design Standards

- **Theme**: "Premium Deep Blue" (`#0D47A1`) with Material 3 components.
- **Glassmorphism**: Applied to key UI elements like the `BottomFooter` and `DocumentCard` for a modern, layered aesthetic.
- **Standardized Loaders**: Circular progress indicators are wrapped in `Loader` widgets to ensure consistent spacing and sizing across the app.

## 5. Development & Verification

- **Linting**: Adheres to a 'Zero Warnings' policy. Always run `flutter analyze` before committing.
- **Testing**: Basic unit tests are located in `test/`. Run `flutter test` to ensure core models and logic are intact.
- **Environment**: Optimized for Flutter 3.41.2 and Dart 3.11.0.

---
*Documented by Jules, AI Software Engineer (Feb 2026).*
