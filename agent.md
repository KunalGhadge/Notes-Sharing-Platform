# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis of the Serious Study project from a developer's perspective. It details the architecture, performance optimizations, design patterns, and security measures implemented in the application.

## Project Overview
Serious Study is a premium academic networking and notes-sharing platform for Mumbai University students. It utilizes a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 1. Architectural Architecture
The application follows a **GetX-based MVC (Model-View-Controller)** pattern for efficient state management and modularity.

### 1.1 State Management
- **Reactive Updates**: GetX controllers (e.g., `DocumentController`, `HomeController`) manage business logic and state using `.obs` variables and `update()` calls.
- **Dependency Injection**: Services and controllers are initialized in `main.dart` or lazily using `Get.put()` to ensure global availability.

### 1.2 Data Flow
- **Supabase Integration**: Direct interaction with Supabase for Auth, Database (PostgreSQL), and Storage.
- **Real-time Synchronization**: Uses Supabase Realtime Channels (`PostgresChangeEvent.all`) in `HomeController` and `NotificationController` to reflect database changes instantly in the UI.

## 2. Performance Optimizations
- **Local Persistence (Hive)**: High-speed NoSQL storage via `Hive` is used for user session data (`userBox`) and download metadata.
- **Media Handling**:
    - **Image Compression**: `ImageHelper` (utilizing `flutter_image_compress`) reduces cover image sizes (quality 70, minWidth/Height 1024) before upload.
    - **Asset Caching**: `cached_network_image` is used for thumbnails and profile pictures to minimize bandwidth usage.
- **Optimistic UI**: Interactions like likes, dislikes, and bookmarks are reflected immediately in the UI before being confirmed by the backend, ensuring a lag-free experience.
- **Efficient Querying**: relational joins are performed in single Supabase queries (e.g., fetching documents with profiles and interactions) to reduce network overhead.
- **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm to prioritize official university documents in the feed.

## 3. Design & UI/UX
- **Material 3 & Glassmorphism**: The UI adheres to Material 3 principles, featuring **Glassmorphism** (via the `glassmorphism` package) for a modern, layered aesthetic.
- **Theming**: A "Premium Deep Blue" (`#0D47A1`) primary color palette, complemented by custom gradients (`AppGradients.premiumGradient`).
- **Typography**: Primary typeface is 'Plus Jakarta Sans' (via `google_fonts`).
- **Visual Feedback**:
    - **Shimmer Effects**: Used in loading states to prevent 'blank screen' issues.
    - **Lottie Animations**: Provides engaging feedback for empty states and successful operations.
    - **Custom Icons**: `CustomIcon` component handles SVG rendering with `colorFilter` for consistent styling.

## 4. Security Measures
- **Authentication**: JWT-based authentication managed by **Supabase Auth**. Secure deep linking for login callbacks is configured.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables. Policies ensure users can only modify their own data (profiles, documents, interactions).
- **Atomic Operations (RPCs)**: Critical counters (likes, dislikes) are updated via `SECURITY DEFINER` PostgreSQL functions to prevent race conditions and unauthorized direct manipulation.
- **Data Integrity**:
    - 10MB file size limit for direct document uploads in `UploadController`.
    - Mandatory profile creation triggers in the database for new Auth users.

## 5. Coding Conventions & Linting
- **Zero Warnings Policy**: Strict adherence to a zero-warning/info linting policy for CI success.
- **Modern Flutter APIs**: Use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`.
- **Naming Conventions**: Follow lowerCamelCase for variables (e.g., `avatarUrl`) and PascalCase for classes.
- **Code Quality**: Avoid `print()` statements; use `debugPrint()` or specialized logging. Ensure all flow control structures use curly braces and empty catch blocks are annotated with `// ignore: empty_catches`.

## 6. Development Workflow
- **Environment**: Flutter SDK ^3.5.4, Dart SDK ^3.11.0.
- **Android Configuration**: Requires `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` (with `com.android.tools:desugar_jdk_libs:2.1.4`) to support the local notification plugin.
- **Verification**: Run `flutter analyze && flutter test` in the `notehub/` directory before any commit.

---
*Maintained and documented by Jules, AI Software Engineer.*
