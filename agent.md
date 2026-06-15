# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance, design, and security of the application.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It utilizes a Flutter frontend and a Supabase (PostgreSQL) serverless backend.

## 1. Performance Analysis
- **Reactive State Management**: The app uses `GetX` for efficient state management and dependency injection. Controllers handle business logic, ensuring a clean separation of concerns.
- **Local Persistent Storage**: `Hive` provides high-performance local NoSQL storage. It is used to cache user profile data (`userBox`) for instant app launches and to manage `downloadsBox` for offline access.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the UI to minimize redundant network requests and improve scroll performance.
    - **Compression**: The `UploadController` integrates `ImageHelper` to compress cover images before uploading to Supabase Storage, significantly reducing bandwidth consumption.
    - **File Limits**: A strict 10MB limit is enforced for direct document uploads to ensure platform stability. Users are encouraged to use external links (Google Drive/Mega) for larger files.
- **Database Efficiency**:
    - **Sticky Sort**: The `HomeController` implements a custom sorting algorithm that prioritizes "Official" documents at the top of the feed while maintaining chronological order for community posts.
    - **Batch Fetching**: Feed updates are limited to 50 items per request to balance responsiveness and data usage.
    - **Atomic Operations**: Critical interactions (likes, dislikes) utilize PostgreSQL RPCs to ensure data integrity and prevent race conditions.
    - **Optimistic UI**: `DocumentController` updates the UI immediately upon user interaction (like/bookmark) before synchronizing with the backend, providing a snappy user experience.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - Rebranded to a "Premium Deep Blue" theme (`#0D47A1`).
    - Semi-transparent glass effects are used on the custom `BottomFooter` and various card components.
- **Project Structure**:
    - `lib/controller/`: Reactive business logic using GetX.
    - `lib/view/`: Modular UI components and screens, including specialized widgets for comments and search.
    - `lib/core/`: Centralized configurations:
        - `config/`: Theme colors and typography using Google Fonts (Plus Jakarta Sans).
        - `helper/`: Utility classes for Hive, image processing, and file handling.
        - `meta/`: App-wide metadata and Supabase credentials.
- **Zero Warnings Policy**: The project adheres to a strict "Zero Warnings" linting policy. Recent modernizations include replacing deprecated `.withOpacity()` with `.withValues(alpha: ...)` and updating `Switch` components to use `activeThumbColor`.

## 3. Security Analysis
- **Authentication**: Secured by **Supabase Auth (JWT)**. Sessions are managed via the SDK, and user passwords are hashed using industry-standard algorithms (Argon2/Bcrypt) by Supabase.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - **Profiles**: Publicly viewable, but only the owner can update.
    - **Documents**: Publicly viewable; only the owner can insert, update, or delete.
    - **Notifications/Bookmarks**: Private to the specific user.
- **Atomic Interaction Logic**: Interactions like `likes_count` are updated via `SECURITY DEFINER` RPC functions, preventing users from directly manipulating counter values in the `documents` table.
- **Storage Security**: Supabase Storage policies ensure that only authenticated users can upload documents and that file paths follow a `userId/` convention for organized access control.

## 4. Maintenance & QA
- **Environment**: Flutter SDK ^3.41.2, Dart SDK ^3.11.0.
- **Static Analysis**: Always run `flutter analyze` in the `notehub/` directory before committing changes to maintain the 'Zero Warnings' status.
- **Testing**: Functional integrity can be verified by running `flutter test`.
- **UI Verification**: For visual changes, utilize the `flutter run -d web-server --web-port 8080` command combined with Playwright verification scripts where applicable.

---
*Last Updated: June 2026 by Jules, Divine Visionary AI Engineer.*
