# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design principles, and security measures implemented in the application.

## 1. Architecture & State Management
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management**: `GetX` is used for reactive state updates, dependency injection, and routing. Controllers (e.g., `DocumentController`, `AuthController`) decouple business logic from the UI.
- **Backend-as-a-Service**: **Supabase** (PostgreSQL) powers the authentication, database, and storage.
- **Directory Structure**:
    - `lib/controller/`: Reactive business logic.
    - `lib/view/`: Modular UI components and screens.
    - `lib/model/`: Data models (e.g., `UserModel`, `DocumentModel`).
    - `lib/service/`: Infrastructure services like `FileCaching`.
    - `lib/core/`: Global configurations, theme definitions (`AppTypography`, `PrimaryColor`), and helpers.

## 2. Performance Analysis
- **Local Persistent Storage**: `Hive` is utilized for high-performance NoSQL local caching.
    - `userBox` stores profile metadata for immediate app responsiveness.
    - `downloadsBox` tracks locally cached documents.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` (quality 70, minWidth/Height 1024) is integrated into `ImageHelper` to optimize assets before uploading to Supabase Storage.
    - **Image Caching**: `cached_network_image` is used throughout the app to minimize redundant network requests.
- **Database Scalability & Efficiency**:
    - **Atomic Operations**: Critical interactions (likes, dislikes) are handled via PostgreSQL RPCs (e.g., `increment_likes`) to prevent race conditions and ensure data consistency.
    - **Optimistic UI**: The `DocumentController` implements optimistic updates for likes and bookmarks, providing instant feedback while syncing with the backend in the background.
    - **Batch Fetching**: `HomeController` limits feed updates to 50 items to optimize initial load times.
- **Perceived Performance**: Shimmer placeholders are implemented in document lists to ensure a smooth visual experience during data retrieval.

## 3. Design & UI/UX
- **Design Paradigm**: Material 3 with a **Glassmorphism** aesthetic.
- **Branding**: "Premium Deep Blue" (`#0D47A1`) theme reflecting academic integrity.
- **Visual Elements**:
    - **Glassmorphism**: Implemented using the `glassmorphism` package and custom gradients (`AppGradients.glassGradient`).
    - **Typography**: `Plus Jakarta Sans` via Google Fonts.
    - **Animations**: `Lottie` animations for state feedback (e.g., empty search results, success states).
- **Sticky Sort**: `HomeController` prioritizes official university documents by sorting them to the top of the feed.

## 4. Security Implementation
- **Authentication**: JWT-based authentication managed by **Supabase Auth**.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - `profiles`: Publicly viewable, but only owners can update.
    - `documents`: Publicly viewable, but only owners (or admins) can modify.
    - `notifications/bookmarks`: Private to the specific user.
- **Storage Security**: Supabase Storage buckets are governed by policies that restrict file uploads and deletions to authorized users.
- **API Integrity**: Sensitive logic (like counter increments) is encapsulated in PostgreSQL functions with `SECURITY DEFINER`, protecting the underlying tables from direct unauthorized manipulation.

## 5. Coding Conventions & Best Practices
- **Naming**: Use `lowerCamelCase` for metadata fields (e.g., `avatarUrl` in `AppMetaData`).
- **Logging**: Avoid `print()` statements. Use `debugPrint()` for development logs.
- **Flow Control**: Always use curly braces for `if`, `for`, and `while` blocks.
- **Error Handling**: Include comments (e.g., `/* silent */`) in intentional empty catch blocks to pass static analysis.
- **Analysis**: The project is strictly linted. Run `flutter analyze` and ensure zero warnings/infos before submitting.

## 6. Android Configuration
- **Build settings**: `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` (with `com.android.tools:desugar_jdk_libs:2.1.4`) are required to support the `flutter_local_notifications` plugin and modern API features.
- **Versions**: `compileSdk 36`, `targetSdk 36`, AGP `8.9.1`, Kotlin `2.1.0`.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
