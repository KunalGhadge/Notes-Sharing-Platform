# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates. Controllers (e.g., `DocumentController`, `ProfileController`) manage business logic independently from the UI.
- **Local Persistent Storage (Hive)**:
    - **`userBox`**: Caches critical `UserModel` data (`username`, `id`, `profileUrl`, `displayName`) for instant access on startup.
    - **`downloadsBox`**: Tracks locally saved documents, enabling offline access to previously downloaded academic resources.
- **Media Optimization**:
    - **Thumbnails**: Uses `CachedNetworkImage` for all document covers and user avatars to eliminate redundant network fetches.
    - **Image Compression**: `ImageHelper` (`lib/core/helper/image_helper.dart`) enforces mandatory compression for covers: `quality: 70`, `minWidth/Height: 1024`.
- **Backend Optimization**:
    - **Atomic RPCs**: Uses `SECURITY DEFINER` PostgreSQL functions (`increment_likes`, `decrement_dislikes`) to handle concurrent counter updates safely without direct column write access.
    - **Batch Fetching**: `HomeController` limits feed updates to 50 items per request, and `ProfileController` uses `count(CountOption.exact)` for efficient statistical retrieval.
- **Sticky Sort Feed**: Custom logic in `HomeController` prioritizes `is_official` university documents at the top of the feed, followed by `created_at` timestamp.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - **Glassmorphism**: Leverages the `glassmorphism` package and `AppGradients.glassGradient` for UI depth (e.g., in `PostCard` overlays).
    - **Color Palette**: Centered on "Premium Deep Blue" (`#0D47A1`) and "Premium Gold" (#B8860B) for official administrative highlights.
    - **Typography**: Uses **Plus Jakarta Sans** via `google_fonts` for a clean, academic look.
- **Component Standardization**:
    - **Loaders**: `Loader` and `Loader2` (`lib/view/widgets/loader.dart`) provide uniform circular indicators.
    - **Toasts**: Centralized `Toasts` using `toastification` with `flatColored` style and `Alignment.topRight`.
- **Architecture (GetX MVC)**:
    - **Controllers**: Handle business logic and Supabase communication (e.g., `UploadController`, `NotificationController`).
    - **Views**: Modularized components (e.g., `CommentSection`, `HomeHeader`) for reuse and clarity.
    - **Services**: Specialized utility classes for background tasks like `FileDownload` (with local notification integration) and `FileCaching`.
- **Interactive Feedback**: Integrated `Lottie` animations for empty states and `LiquidPullToRefresh` (`RefresherWidget`) for feed updates.

## 3. Security Analysis & Migration Audit
The current analysis confirms that the critical security vulnerabilities present in the legacy Django stack have been systematically addressed:

- **Authentication**: Migrated from a custom session-less system to **Supabase Auth (JWT)**. Sessions are securely managed by the Supabase SDK.
- **Password Security**: Passwords are no longer handled in plain text; they are managed by Supabase using industry-standard hashing (Argon2/Bcrypt).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all tables.
    - **Profiles**: Public read access; write access limited via `auth.uid() = id`.
    - **Documents**: Public read; insertion and management restricted via `auth.uid() = user_id` and administrative policies.
    - **Notifications**: Private to the specific `receiver_id`, ensuring user interaction privacy.
- **Backend Integrity**:
    - **PostgreSQL RPCs**: Counters for likes/dislikes are updated via `SECURITY DEFINER` functions, preventing clients from directly altering numeric columns.
    - **Real-time Security**: Notification channels utilize granular PostgreSQL change filters (`receiver_id` or `is_global`) to ensure secure data streaming.
- **Secure File Access**: All documents and thumbnails in Supabase Storage are governed by policies, preventing unauthorized public access to private assets.

## 4. System Environment & DevOps
- **Verified Environment**:
    - **Flutter SDK**: 3.41.2 (channel stable)
    - **Dart SDK**: 3.11.0
    - **Android Build**: Java 17, Target SDK 36, AGP 8.9.1.
- **DevOps & Linting**:
    - **Zero Warnings Policy**: The project strictly enforces a warning-free state. Use `cd notehub && flutter analyze && flutter test` to verify.
    - **Modern APIs**: Mandatory use of `.withValues(alpha: ...)` instead of `.withOpacity()` and `activeThumbColor` for `Switch` widgets to comply with latest Flutter stable standards.
- **CI/CD**: GitHub Actions are configured to block pull requests that introduce new linting warnings or test failures.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
