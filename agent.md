# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates and dependency injection. Controllers (e.g., `DocumentController`, `HomeController`, `ProfileController`) manage business logic independently from the UI.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching. User profile metadata and download history are stored in `userBox` and `downloadsBox` (see `lib/core/helper/hive_boxes.dart`) to ensure immediate UI responsiveness upon app launch.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `PostCard` and `HomeHeader`) to minimize network usage and provide a smooth scrolling experience.
    - **Compression**: `flutter_image_compress` is integrated into the `ImageHelper` (`lib/core/helper/image_helper.dart`) and used in the `UploadController` to optimize cover images (quality: 70, minWidth/Height: 1024) before they reach Supabase Storage.
    - **File Size Management**: Direct document uploads are limited to **10MB** to maintain storage efficiency. The app encourages the use of external links (e.g., Google Drive) for larger files.
- **Database Scalability**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_dislikes` are handled via PostgreSQL Functions (`RPCs`) defined in `SUPABASE_SCHEMA.sql`. This ensures data consistency and prevents race conditions.
    - **Optimistic UI**: `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks, ensuring immediate user feedback while synchronizing with the backend in the background.
    - **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm, prioritizing official university documents at the top of the feed followed by the most recent community contributions.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - Semi-transparent overlays (e.g., `Colors.white.withValues(alpha: 0.15)`) and custom gradients (`AppGradients.glassGradient`) are used to create a modern, layered look, especially in `PostCard` and `BottomFooter`.
    - Rebranded with a "Premium Deep Blue" theme (`#0D47A1`) using `Plus Jakarta Sans` typography.
- **Project Structure**:
    - `lib/controller/`: Reactive logic using GetX. Instances are often tagged (e.g., `ShowcaseController`) to manage multiple states (like different user profiles).
    - `lib/view/`: Modular UI components and screens organized by feature (e.g., `auth_screen`, `home_screen`, `upload_screen`).
    - `lib/core/`: Centralized configurations like `AppMetaData`, theme definitions, and core helpers.
    - `lib/service/`: Utility services for file caching, downloads, and notifications.
- **Visual Feedback**:
    - **Shimmer Effects**: Implemented in `HomeDocumentSection` and `SearchPage` to prevent "grey space" and provide smooth visual feedback during data loading.
    - **Lottie Animations**: Used for empty states, success feedback, and splash screens.

## 3. Security Analysis & Migration Audit
The migration from the legacy Django stack to Supabase has systematically addressed several critical security vulnerabilities:

- **Authentication**: Migrated to **Supabase Auth (JWT)**. Sessions are securely managed by the SDK, and deep linking (`io.supabase.flutternotehub://login-callback`) is configured for secure auth flows.
- **Password Security**: Managed by Supabase using industry-standard hashing (Argon2/Bcrypt).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all tables in `SUPABASE_SCHEMA.sql`:
    - **Profiles**: Public read, owner-only write.
    - **Documents**: Public read, owner-only write/delete.
    - **Notifications/Bookmarks**: Private to the specific user.
- **API Integrity**: By using `SECURITY DEFINER` on PostgreSQL RPC functions, the app allows atomic updates to counters (like `likes_count`) while keeping the underlying tables protected from direct unauthorized manipulation.
- **Storage Security**: Document and thumbnail buckets are governed by policies, ensuring that users can only manage their own assets while allowing public access to shared community notes.

## 4. Real-time Features
- **Live Feed**: `HomeController` uses Supabase Realtime channels to listen for changes in the `documents` table, automatically refreshing the feed for all users when new notes are shared.
- **Notifications**: `NotificationController` listens for new records in the `notifications` table. It supports both personal interactions (likes/comments) and global announcements broadcasted by admins. Local notifications are triggered using `flutter_local_notifications`.

## 5. Development & QA
- **Prerequisites**: Flutter 3.41.2 (channel stable), Dart SDK 3.11.0.
- **Android Configuration**:
    - `compileSdk`: 36
    - `minSdkVersion`: 21 (Support for `multiDexEnabled` and `coreLibraryDesugaring`)
    - `AGP`: 8.9.1, `Kotlin`: 2.1.0, `Gradle`: 8.12
- **Code Quality**:
    - The project follows a "Zero Warnings" policy for CI success.
    - Run `flutter analyze` to verify linting compliance.
    - Run `flutter test` to execute the test suite (e.g., `test/dummy_test.dart`).

---
*Analyzed and Documented by Jules, AI Software Engineer.*
