# Developer Guide - Serious Study (Mumbai University Community App)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It serves as the exhaustive guide for architecture, performance optimizations, design patterns, security measures, and coding conventions.

## 1. Project Overview
Serious Study (formerly NoteHub) is a modernized academic networking and resource-sharing platform for the Mumbai University student community. It features a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 2. Architecture & State Management
- **Pattern**: The application follows a decoupled **GetX MVC** architecture.
- **State Management**: **GetX** is used for reactive state updates, dependency injection, and routing. Controllers (e.g., `DocumentController`, `AuthController`, `HomeController`) manage business logic independently from the modular UI components in `lib/view/`.
- **Instance Management**: `ShowcaseController` instances are managed using GetX tags (based on usernames) to support concurrent profile states without global pollution.

## 3. Performance Optimizations
- **Local Persistent Storage**: **Hive** (`lib/core/helper/hive_boxes.dart`) provides high-performance NoSQL local caching.
    - `userBox`: Stores `UserModel` data (username, id, profileUrl) for immediate UI responsiveness.
    - `downloadsBox`: Manages metadata for offline-available resources.
- **Media Optimization**:
    - **Compression**: `ImageHelper` (`lib/core/helper/image_helper.dart`) uses `flutter_image_compress` (quality 70, minWidth/Height 1024) to optimize uploads and reduce bandwidth.
    - **Caching**: `cached_network_image` is used throughout the app (e.g., `HomeHeader`, `PostCard`) to minimize redundant network calls.
    - **Local Caching**: `FileCaching` (`lib/service/file_caching.dart`) uses `Dio` and `path_provider` to cache downloaded documents locally.
- **Database Efficiency**:
    - **Atomic Operations**: Critical interactions (likes, dislikes) use PostgreSQL **RPCs** (`increment_likes`, `decrement_dislikes`) to ensure data consistency and prevent race conditions.
    - **Sticky Sort**: `HomeController` implements a "Sticky Sort" algorithm to prioritize official university documents in the feed while maintaining chronological order.
    - **Batch Fetching**: Data flow is optimized with a batch fetch limit of 50 items.
- **User Experience**:
    - **Optimistic UI**: `DocumentController` implements an optimistic pattern for likes and bookmarks, providing immediate feedback before backend synchronization.
    - **Shimmer Placeholders**: Used in sections like `HomeDocumentSection` and `SearchPage` to prevent 'grey space' and blank screen issues during data fetching.

## 4. Design & UI Paradigm
- **Aesthetic**: **Material 3** with a **Glassmorphism** effect.
    - Utilizes the `glassmorphism` package's `GlassmorphicContainer` and `AppGradients.glassGradient`.
- **Branding**:
    - **Primary Theme**: "Premium Deep Blue" (`#0D47A1`).
    - **Typography**: 'Plus Jakarta Sans' via `google_fonts`.
- **Visual Cues**:
    - **Official Label**: University-verified documents use a gold theme (`#FFD700`).
    - **Animations**: `Lottie` animations are used for state feedback (e.g., empty search, success states).

## 5. Security Analysis
- **Authentication**: **Supabase Auth (JWT)**. The app supports deep linking for authentication using the `io.supabase.flutternotehub://login-callback` scheme.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - Policies ensure users can only update their own profiles and documents.
    - Private data like bookmarks and notifications are restricted to the owner.
- **Integrity**: PostgreSQL functions are defined as `SECURITY DEFINER`, allowing atomic counter updates without granting users direct write access to sensitive columns.
- **Real-time Security**: `NotificationController` applies granular filters (`receiver_id`, `is_global`) on PostgreSQL Change channels to ensure users only receive relevant academic updates.

## 6. Coding Conventions & Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` without warnings.
- **Color Methods**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)` for compatibility with modern Flutter (3.27+).
- **Naming**: Use `lowerCamelCase` for properties in `AppMetaData` and similar config classes (e.g., `avatarUrl`).
- **Flow Control**: All flow control structures (if, for, while) **must** use curly braces.
- **Logging**: Avoid `print()` statements. Use `debugPrint` or dedicated logging if necessary.
- **Exception Handling**: Use `// ignore: empty_catches` for intentional empty catch blocks to pass analysis.
- **Android Target**: Targets API 36 (compileSdkVersion) with AGP 8.9.1 and Kotlin 2.1.0.

## 7. Development & QA
- **Environment**: Flutter 3.41.x (Stable) and Dart ^3.5.4.
- **Verification**: Run `flutter analyze && flutter test` in the `notehub/` directory before any commit.
- **Integrity**: `notehub/pubspec.lock` should remain unchanged during routine analysis to avoid accidental package downgrades.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
