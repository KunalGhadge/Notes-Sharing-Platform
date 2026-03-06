# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It serves as the primary system guide and technical source of truth.

## 1. Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It utilizes a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 2. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates and dependency injection.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching. User profile metadata is stored in the `user` box to ensure immediate UI responsiveness.
- **Optimistic UI Pattern**: Implemented in `DocumentController` for likes and bookmarks, providing immediate feedback before backend synchronization.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout (e.g., `PostCard`) to minimize network usage.
    - **Compression**: `flutter_image_compress` (quality 70, minWidth/Height 1024) is integrated into `ImageHelper` and used in `UploadController` to optimize asset sizes.
- **Database Scalability**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_likes` are handled via PostgreSQL RPCs to ensure data consistency and prevent race conditions.
    - **Relational Joins**: `AppSearchController` and `DocumentController` perform relational joins (profiles, interactions, bookmarks) in single Supabase queries to reduce networking overhead.
    - **Sticky Sort**: `HomeController` prioritizes official university documents in the feed using custom sorting logic.

## 3. Design & Architecture
- **UI Paradigm**: Implements **Material 3** with a **Glassmorphism** aesthetic.
    - Uses `glassmorphism` package and `AppGradients.glassGradient` for a modern, layered look.
    - Typography: **Plus Jakarta Sans** via `google_fonts`.
    - Color Palette: Centered around "Premium Deep Blue" (#0D47A1).
- **Project Structure**:
    - `lib/controller/`: Reactive logic and business rules.
    - `lib/view/`: Modular UI components and screen layouts.
    - `lib/model/`: Data models and JSON serialization.
    - `lib/core/`: Centralized config, theme, and helper utilities.
- **Asset Integration**: SVGs rendered via `SvgPicture.asset` with `colorFilter` for theme consistency.

## 4. Security Analysis
- **Authentication**: Powered by **Supabase Auth (JWT)**. Sessions are managed securely by the SDK.
- **Password Security**: Managed by Supabase using industry-standard hashing (Argon2/Bcrypt).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - `profiles`: Owners can UPDATE; public can SELECT.
    - `documents`: Owners can INSERT/UPDATE/DELETE; public can SELECT.
    - `notifications/bookmarks`: Private to the specific user.
- **Counter Integrity**: Counters are updated via `SECURITY DEFINER` RPCs, preventing users from directly manipulating sensitive integer columns.
- **File Access**: Supabase Storage buckets are protected by RLS policies, ensuring authorized access to documents.

## 5. Development & Agent Instructions

### Coding Conventions
- **Naming**: Use `lowerCamelCase` for fields (e.g., `avatarUrl` in `AppMetaData`).
- **Safety**: Avoid `print()` statements; use `debugPrint()` if necessary.
- **Structure**: All flow control structures (if, for, while) MUST use curly braces.
- **Linting**: Ensure code passes `flutter analyze`. Specifically, deprecations like `withOpacity` and `activeColor` are tolerated for Flutter 3.24+ compatibility.
- **Empty Blocks**: Include comments (e.g., `/* silent */`) in intentional empty catch blocks.

### Environment Setup
- **Flutter**: Targeting SDK ^3.5.4 (Flutter 3.24+).
- **Android**:
    - `compileSdk 36`, `targetSdk 36`.
    - AGP `8.9.1`, Kotlin `2.1.0`.
    - Enable `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` (use `com.android.tools:desugar_jdk_libs:2.1.4`).
- **Deep Linking**: Configured with scheme `io.supabase.flutternotehub` and host `login-callback` in `AndroidManifest.xml`.

### Testing & Verification
- Run `flutter analyze` in the `notehub/` directory before any commit.
- Run `flutter test` to execute the test suite.
- For UI changes, verify using Playwright screenshots via `frontend_verification_instructions` when available.

---
*Maintained by Jules, AI Software Engineer.*
