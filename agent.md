# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-centric analysis of the Serious Study platform. It covers architecture, performance, design, and security following the migration to a modern serverless stack.

## 1. Architecture & Tech Stack

Serious Study utilizes a decoupled, reactive architecture designed for scalability and real-time community interaction.

- **Frontend (Flutter 3.41.2)**: Implements the **GetX (MVC)** pattern.
    - **Controllers**: Manage business logic and reactive state (e.g., `AuthController`, `DocumentController`).
    - **Views**: Modular UI components that observe controller states using `Obx` or `GetX` widgets.
    - **Services**: Handle side effects like file downloads (`FileDownload`) and local notifications (`NotificationService`).
- **Backend (Supabase/PostgreSQL)**:
    - **Authentication**: JWT-based secure sessions.
    - **Database**: Relational PostgreSQL with granular **Row Level Security (RLS)**.
    - **Storage**: Governed by RLS policies for secure document and asset hosting.
    - **RPCs**: Atomic database operations (like `increment_likes`) implemented as `SECURITY DEFINER` functions to maintain data integrity.
- **Local Persistence (Hive)**: High-performance NoSQL caching for user profile metadata and download tracking.

## 2. Performance Optimizations

- **Optimistic UI Updates**: Interactions like Likes, Dislikes, and Bookmarks update the UI instantly in `DocumentController` before syncing with the backend, providing a lag-free experience.
- **Media Pipeline**:
    - **Image Compression**: `ImageHelper` utilizes `flutter_image_compress` to optimize cover images (70% quality) before upload.
    - **Efficient Caching**: `CachedNetworkImage` is used for profile avatars and document thumbnails to minimize redundant network requests.
- **Sticky Sort Strategy**: The `HomeController` implements a "Sticky Sort" algorithm that prioritizes `is_official` content followed by chronological order (`created_at`), ensuring verified academic resources remain visible.
- **Payload Management**: Feed queries are limited to 50 records per request to optimize initial load times and memory usage.

## 3. Design System & UI/UX

- **Branding**: The app uses a "Premium Deep Blue" theme (`#0D47A1`) as defined in `lib/core/config/color.dart`.
- **Visual Aesthetic**:
    - **Glassmorphism**: Applied to the custom `BottomFooter` and various overlays using `Opacity` (modernized to `.withValues(alpha: ...)`).
    - **Material 3**: Fully integrated with standard components (Switches, Cards, Dialogs) for a native feel.
- **Typography**: Powered by `GoogleFonts.plusJakartaSans`, providing a modern, professional academic look.
- **Feedback Loop**: Shimmer placeholders (`Shimmer`) and standardized loaders (`Loader`, `Loader2`) provide consistent visual feedback during async operations.

## 4. Security & Data Integrity

- **Row Level Security (RLS)**: Strictly enforced across all tables:
    - **Profiles**: `auth.uid() = id` (Users only update their own profiles).
    - **Documents**: `auth.uid() = user_id` (Users only manage their own uploads).
    - **Notifications**: `auth.uid() = receiver_id` (Private activity feeds).
- **Atomic Interaction Model**: To prevent race conditions in counter increments, the app uses PostgreSQL RPC functions rather than client-side arithmetic.
- **Admin Controls**:
    - `is_admin` flag in the `profiles` table enables administrative broadcasting via `broadcastAnnouncement`.
    - `is_official` flag in `documents` distinguishes verified institutional content.
- **File Security**: Documents are stored in user-specific paths (`userId/docs/...`) and served via public URLs governed by bucket policies.

## 5. Maintenance & Compliance

- **Zero Warnings Policy**: The project strictly adheres to modern Dart/Flutter linting standards.
    - Deprecated `.withOpacity()` replaced with `.withValues()`.
    - `activeColor` modernized to `activeThumbColor`.
    - All flow control structures use explicit curly braces.
- **CI/CD Readiness**: Verified via `cd notehub && flutter analyze && flutter test`.
- **API Targets**: Android API 36, utilizing Java 17 and core library desugaring for maximum compatibility.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
