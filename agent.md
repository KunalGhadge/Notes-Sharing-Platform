# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates. Controllers (e.g., `DocumentController`, `ProfileController`) manage business logic independently from the UI.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching.
    - `userBox`: Stores `UserModel` (id, username, profileUrl) for instant session restoration.
    - `downloadsBox`: Manages metadata for offline-accessible documents.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `HomeHeader`) to minimize network usage.
    - **Compression**: `flutter_image_compress` is integrated into the upload pipeline (`ImageHelper.compressImage`) using **quality 70** and **1024px** min dimensions to optimize bandwidth.
    - **Upload Constraints**: `UploadController` enforces a **10MB limit** for direct document uploads to ensure cloud storage efficiency.
- **Data Flow & Scalability**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_dislikes` are handled via PostgreSQL Functions (`RPCs`) defined in `SUPABASE_SCHEMA.sql` using `SECURITY DEFINER`.
    - **Sticky Sort**: `HomeController` implements a custom sort that prioritizes `is_official` documents followed by chronological order, ensuring critical university updates remain visible.
    - **Perceived Performance**: Shimmer placeholders are implemented in sections like `HomeDocumentSection` to provide smooth visual feedback during asynchronous data fetching.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - **Glassmorphism**: Utilizes the `glassmorphism` package and `AppGradients.glassGradient` for semi-transparent, layered UI elements (e.g., `PostCard`).
    - **Color Palette**: Rebranded with a "Premium Deep Blue" theme (`#0D47A1`) as the primary brand color.
    - **Standardized Components**: Uses a unified `Loader` and `Loader2` for loading states to maintain visual consistency.
- **Project Structure**:
    - `lib/controller/`: Reactive logic using GetX (e.g., `AuthController`, `DocumentController`).
    - `lib/view/`: Modular UI components organized by feature (Auth, Home, Profile).
    - `lib/core/`: Centralized configurations (`AppMetaData`) and theme definitions (`AppGradients`, `PrimaryColor`).
- **Asset Integration**: High-quality vector graphics (`flutter_svg`) and `Lottie` animations are used for state feedback (e.g., empty search results).

## 3. Security Analysis & Migration Audit
The current analysis confirms that the critical security vulnerabilities present in the legacy Django stack have been systematically addressed:

- **Authentication**: Migrated from a custom session-less system to **Supabase Auth (JWT)**. Sessions are securely managed by the Supabase SDK.
- **Password Security**: Passwords are no longer handled in plain text; they are managed by Supabase using industry-standard hashing (Argon2/Bcrypt).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced in `SUPABASE_SCHEMA.sql`. Policies ensure:
    - **Profiles**: Publicly viewable (`SELECT`), but restricted `INSERT`/`UPDATE` to the owner (`auth.uid() = id`).
    - **Documents**: Publicly viewable, but only owners can `INSERT`, `UPDATE`, or `DELETE`.
    - **Interactions & Bookmarks**: Users can only manage their own entries.
    - **Notifications**: Strictly private; users can only `SELECT` where `receiver_id = auth.uid()`.
- **API Integrity**: Atomic updates to counters (like `likes_count`) are performed via PostgreSQL RPCs defined with `SECURITY DEFINER`. This allows the application to increment protected columns without granting users direct write access to the table, preventing data tampering.
- **Secure File Access**: All documents and thumbnails in Supabase Storage are governed by policies, preventing unauthorized public access to private assets.

## 4. Development & QA
- **Prerequisites**: Flutter SDK ^3.5.4.
- **Android Configuration**: The `build.gradle` is configured with `multiDexEnabled` and `coreLibraryDesugaring` to support the `flutter_local_notifications` plugin.
- **Code Quality**:
    - Run `flutter analyze` to verify linting compliance.
    - Run `flutter test` to execute the test suite (e.g., `test/dummy_test.dart`).

---
*Analyzed and Documented by Jules, AI Software Engineer.*
