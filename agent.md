# Developer Guide & System Manual - Serious Study

This document serves as the exhaustive technical reference for the **Serious Study** (formerly NoteHub) project. It provides a deep-dive analysis of the application's architecture, performance optimizations, design patterns, and security implementation from a developer's perspective.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform dedicated to the Mumbai University community. It leverages a modern Flutter frontend and a serverless Supabase backend to provide a real-time, scalable, and secure experience for students.

## 2. Architecture & Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter 3.24+ (SDK ^3.5.4).
- **State Management**: **GetX** (MVC Pattern). Controllers handle business logic, while views reactively update based on `Obx` or `GetBuilder`.
- **Local Persistence**: **Hive**. Used for high-speed NoSQL caching of user metadata and download history.
- **Routing**: GetX dynamic routing.
- **Dependency Injection**: Centralized initialization in `main.dart` using `Get.put()`.

### Backend (Supabase)
- **Database**: **PostgreSQL** with Row Level Security (RLS).
- **Authentication**: **Supabase Auth** (JWT-based).
- **Storage**: **Supabase Storage** for documents, thumbnails, and profile pictures.
- **Real-time**: **Postgres Changes** via Supabase Channels for instant feed updates and notifications.
- **Logic**: **PostgreSQL RPCs (Functions)** for atomic operations and server-side logic.

## 3. Performance Analysis

### Data Management & Caching
- **Reactive Updates**: Use of GetX Observables (`.obs`) ensures only necessary UI components rebuild.
- **Local Caching**: The `userBox` (Hive) stores `UserModel` data, enabling "Instant-On" profile views without network latency.
- **Batch Fetching**: The `HomeController` limits feed fetches to 50 items to balance initial load time and content availability.
- **Sticky Sort**: The feed implements a custom sorting algorithm:
  1. `is_official` (descending) - Admin-verified content stays at the top.
  2. `created_at` (descending) - Chronological order for community content.

### Media & Network Optimization
- **Image Compression**: `ImageHelper` uses `flutter_image_compress` to optimize cover images (quality: 70) before upload, reducing storage costs and load times.
- **Thumbnail Caching**: `cached_network_image` is used throughout the app to minimize redundant network requests.
- **Direct vs. External**: `UploadController` supports external links (Google Drive/Mega) to offload storage for files exceeding the **10MB limit**.
- **Optimistic UI**: `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks, providing immediate feedback while syncing with the backend in the background.

## 4. Design & UI/UX

### Visual Identity
- **Branding**: "Premium Deep Blue" (`#0D47A1`) theme, reflecting academic integrity.
- **Material 3**: Fully compliant with Material 3 design principles, including tonal buttons and standardized components.
- **Glassmorphism**: Applied to high-interaction areas (Bottom Footer, Profile Cards) using the `glassmorphism` package for a modern, layered aesthetic.
- **Animations**: `Lottie` animations for empty states, success feedback, and loading transitions.

### Standardized Components
- **Loaders**: Centralized `Loader` and `Loader2` widgets for consistent indeterminate progress indicators.
- **Toasts**: Standardized feedback via `toastification` with `flatColored` style and `topRight` alignment.
- **Refresher**: Consistent pull-to-refresh behavior using `LiquidPullToRefresh`.

## 5. Security Analysis

### Authentication & Authorization
- **JWT Security**: Supabase Auth handles secure session management; no sensitive credentials (like passwords) are ever stored in the local database.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
  - **Profiles**: `UPDATE` restricted to `auth.uid() = id`.
  - **Documents**: `INSERT`/`UPDATE`/`DELETE` restricted to `auth.uid() = user_id`.
  - **Notifications**: `SELECT` restricted to `auth.uid() = receiver_id`.
- **Admin Controls**: `is_admin` flag in the `profiles` table controls access to broadcasting announcements and marking content as `is_official`.

### Data Integrity
- **Atomic Operations**: Counters (likes, dislikes) are updated via `SECURITY DEFINER` RPCs (`increment_likes`, etc.). This prevents users from manually tampering with counter values and ensures consistency even under high concurrency.
- **Safe Deletion**: `DocumentController` handles storage cleanup before database record deletion to prevent orphaned files in Supabase Storage.

## 6. Developer Workflow & QA

### Coding Conventions
- **Naming**: `lowerCamelCase` for variables/methods, `UpperCamelCase` for classes/widgets.
- **Zero Warnings Policy**: The project mandates a clean `flutter analyze` report.
- **Flow Control**: All `if/else/for` blocks must use explicit curly braces (`{}`).
- **Error Handling**: Use `// ignore: empty_catches` for intentional silent catches to pass linting.

### Verification & Testing
- **Linting**: Run `cd notehub && flutter analyze`.
- **Testing**: Run `cd notehub && flutter test`.
- **Maintenance Scripts**:
  - `scripts/modernize_colors.py`: Automated migration from `.withOpacity()` to `.withValues()`.
  - `scripts/verify_app.py`: Playwright-based frontend verification.

---
*Analyzed and Documented by Jules, AI Software Engineer (Feb 2026).*
