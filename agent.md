# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance, design, and security of the application as of Feb 2026.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Architecture (GetX MVC)
The application follows a modular architecture using the **GetX** ecosystem for state management, dependency injection, and routing.

- **Controllers (`lib/controller/`)**: Manage reactive business logic.
    - `DocumentController`: Handles note lifecycles, atomic interactions (likes/dislikes), and global state syncing.
    - `HomeController`: Manages the main feed with batch fetching (limit 50) and "Sticky Sort" (prioritizing official documents).
    - `UploadController`: Manages complex multi-part uploads with a 10MB limit and mandatory image compression.
    - `NotificationController`: Handles real-time academic updates via Supabase PostgreSQL changes.
- **View (`lib/view/`)**: Modular UI components. Separated into feature-based directories (e.g., `document_screen`, `profile_screen`).
- **Core (`lib/core/`)**: Centralized configuration, themes, and helpers.

## 2. Performance Analysis
- **Reactive State Updates**: GetX ensures that only the necessary widgets are rebuilt during state changes.
- **High-Performance Caching**:
    - **NoSQL Local Storage**: `Hive` is used to cache user profile metadata and download history for instant responsiveness.
    - **Asset Caching**: `cached_network_image` prevents redundant downloads of thumbnails and profile pictures.
    - **File Caching**: `FileCaching` service (`lib/service/file_caching.dart`) uses the system's temporary directory to avoid re-downloading documents during a single session.
- **Media Optimization**:
    - **Mandatory Compression**: `ImageHelper` uses `flutter_image_compress` (Quality 70, 1024px min dimensions) to reduce bandwidth and storage costs.
- **Database Scalability**:
    - **Atomic Operations**: PostgreSQL RPCs (e.g., `increment_likes`) prevent race conditions and ensure data integrity.
    - **Lazy Loading**: Feeds are fetched in batches (50 items) to optimize initial payload.

## 3. Design System
- **Branding**: "Premium Deep Blue" theme centered around primary color `#0D47A1`.
- **Typography**: Uses 'Plus Jakarta Sans' via Google Fonts for a modern, clean academic aesthetic.
- **UI Aesthetic**:
    - **Glassmorphism**: Semi-transparent overlays and gradients (`AppGradients.glassGradient`) are used for depth and modern layering.
    - **Material 3**: Fully utilizes Material 3 components and color schemes.
- **Consistency**: Centralized `AppTypography` and `PrimaryColor` classes ensure a unified look across all screens.

## 4. Security Analysis
- **Authentication**: JWT-based session management via **Supabase Auth**.
- **Authorization (RLS)**: **Row Level Security** is enforced at the database level.
    - `profiles`: Owners can UPDATE; public can SELECT.
    - `documents`: Owners have full CRUD; public can SELECT.
    - `notifications`: Only the `receiver_id` can SELECT.
- **Granular Security**:
    - **RPCs with SECURITY DEFINER**: Allows users to trigger protected counter updates (likes/dislikes) without having direct write access to the `likes_count` columns.
    - **Notification Filtering**: Real-time channels use `receiver_id` and `is_global` filters to ensure users only receive relevant data.
- **Storage Protection**: Supabase Storage buckets are governed by policies that restrict upload and delete permissions to the file owners.

## 5. Development & QA
- **Environment**: Flutter 3.41.2, Dart 3.11.0.
- **'Zero Warnings' Policy**: The project maintains a strict linting standard. All code must pass `flutter analyze` without warnings.
- **Key Commands**:
    - `cd notehub && flutter analyze`: Verify linting.
    - `cd notehub && flutter test`: Run the test suite.
- **CI/CD**: GitHub Actions are configured to enforce these checks on every pull request.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
