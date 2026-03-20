# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures of the application after its migration to a serverless **Supabase** architecture.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates and dependency injection. Controllers (e.g., `DocumentController`, `HomeController`, `ProfileController`) manage business logic independently from the UI.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching.
    - `userBox` stores `UserModel` data (username, id, profileUrl) for immediate UI responsiveness.
    - `downloadsBox` tracks offline documents.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `PostCard`) to minimize network usage.
    - **Compression**: `flutter_image_compress` is integrated into `ImageHelper` (quality 70, minWidth/Height 1024) to optimize assets before uploading to Supabase Storage.
- **Database Scalability & Efficiency**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_dislikes` are handled via PostgreSQL Functions (`RPCs`) with `SECURITY DEFINER`. This ensures data consistency and prevents race conditions without granting direct write access to sensitive columns.
    - **Optimistic UI**: `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks, providing immediate user feedback while synchronizing with the backend.
    - **Batch Fetching & Sorting**: `HomeController` fetches updates in batches of 50 and implements "Sticky Sort" to prioritize official university documents.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - Semi-transparent overlays (using `.withValues(alpha: x)`) and custom gradients (`AppGradients.glassGradient`) create a modern, layered look.
    - Primary Theme: "Premium Deep Blue" (`#0D47A1`).
    - Typography: 'Plus Jakarta Sans' via `google_fonts`.
- **Project Structure**:
    - `lib/controller/`: Reactive logic and Supabase interactions.
    - `lib/view/`: Modular UI components and screens, organized by feature.
    - `lib/model/`: Data models with JSON serialization and Hive adapters.
    - `lib/core/`: Centralized configurations (`AppMetaData`), themes (`color.dart`, `typography.dart`), and helpers (`ImageHelper`, `HiveBoxes`).
    - `lib/service/`: Background services like `NotificationService` and `FileCaching`.
- **Asset Integration**: SVGs rendered via `SvgPicture.asset` with `colorFilter` in `CustomIcon`, and `Lottie` animations for state feedback.

## 3. Security Analysis
The migration to Supabase has addressed critical legacy vulnerabilities:

- **Authentication**: Uses **Supabase Auth (JWT)**. Sessions are managed securely by the SDK. Deep linking is configured for login callbacks (`io.supabase.flutternotehub://login-callback`).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced in `SUPABASE_SCHEMA.sql`.
    - **Profiles**: Publicly viewable, but only owners can `UPDATE`.
    - **Documents**: Publicly viewable, but only owners can `INSERT`, `UPDATE`, or `DELETE`.
    - **Notifications/Bookmarks**: Private to the owner.
- **File Security**: Supabase Storage buckets (e.g., `documents`) are protected by RLS policies, ensuring only authorized users can upload or delete files.
- **Input Validation**: `AuthController` and `UploadController` implement client-side validation to ensure data integrity before submission.

## 4. Development & CI/QA
- **Prerequisites**:
    - Flutter SDK `^3.5.4`.
    - Dart SDK `^3.11.0`.
- **Android Configuration**:
    - Target SDK: 36.
    - AGP: 8.9.1, Kotlin: 2.1.0, Gradle: 8.10.2.
    - `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` (with `com.android.tools:desugar_jdk_libs:2.1.4`) are required.
- **Linting Policy**: The project enforces a 'Zero Warnings' policy.
    - Modern Flutter APIs must be used: `.withValues(alpha: x)` instead of `.withOpacity(x)` and `activeThumbColor` in `Switch`.
    - Ensure `// ignore: empty_catches` is used for intentional empty blocks.
- **Verification**:
    - Run `flutter analyze` in `notehub/` to verify linting.
    - Run `flutter test` in `notehub/` to execute the test suite.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
