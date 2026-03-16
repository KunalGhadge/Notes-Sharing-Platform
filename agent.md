# Developer Guide - Serious Study (Mumbai University Community App)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It details the architecture, performance optimizations, design patterns, and security measures implemented in the application.

## 1. Project Architecture
Serious Study follows a reactive, decoupled architecture using **Flutter** for the frontend and **Supabase** as a serverless backend.

- **State Management**: The application uses **GetX** for state management, dependency injection, and routing. Controllers (e.g., `DocumentController`, `AuthController`) encapsulate business logic and expose reactive variables (`.obs`) to the UI.
- **Backend**: Powered by **Supabase (PostgreSQL)**. It leverages:
    - **Supabase Auth**: JWT-based authentication.
    - **Supabase Storage**: Secure object storage for documents and images.
    - **PostgreSQL Realtime**: Realtime updates via the `supabase_realtime` publication.
- **Local Storage**: **Hive** is utilized for high-performance NoSQL local caching of user profiles and application settings, ensuring a fast startup experience.

## 2. Performance Analysis & Optimizations
- **Atomic Operations (RPCs)**: Critical interactions like liking, disliking, and view counting are handled via PostgreSQL **Remote Procedure Calls (RPCs)** (e.g., `increment_likes`, `decrement_dislikes`). This ensures data integrity and prevents race conditions by processing updates on the server.
- **Optimistic UI**: The `DocumentController` implements optimistic updates for user interactions (likes, bookmarks), providing immediate visual feedback before the backend synchronization completes.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is integrated into the upload pipeline (`UploadController`) to reduce asset sizes before they reach Supabase Storage.
    - **Caching**: `cached_network_image` is used throughout the app to minimize network overhead by caching thumbnails and profile pictures locally.
- **Efficient Data Retrieval**: The `HomeController` fetches updates in batches (limit 50) and implements "Sticky Sort" to prioritize official university documents at the top of the feed.

## 3. Design & Branding
- **UI Paradigm**: The app adheres to **Material 3** principles with a modern **Glassmorphism** aesthetic.
- **Glassmorphism**: Implemented using `GlassmorphicContainer` and custom gradients (`AppGradients.glassGradient`) for elements like the Bottom Navigation bar and Post cards.
- **Branding**: The platform uses a "Premium Deep Blue" color palette (`#0D47A1`) to reflect its academic focus for the Mumbai University community.
- **Typography**: 'Plus Jakarta Sans' is used via `google_fonts` for a clean, professional look.

## 4. Security Implementation
- **Authentication**: JWT-based sessions managed by Supabase Auth. Secure deep linking is configured for the login callback (`io.supabase.flutternotehub://login-callback`).
- **Authorization (RLS)**: **Row Level Security (RLS)** is strictly enforced in the PostgreSQL schema. Each table has policies that restrict data access based on the user's authenticated UID.
- **Security Definer RPCs**: Functions like interaction counters use `SECURITY DEFINER` to allow atomic updates to protected columns without granting users direct write access to the entire table.
- **Storage Policies**: Access to documents and profile images in Supabase Storage is governed by policies that ensure only authorized users can upload or delete their own content.

## 5. Android Configuration
- **Build Settings**:
    - `compileSdk`: 36
    - `targetSdk`: 36
    - `Java Version`: 17
    - `Kotlin Version`: JVM 17
- **Dependencies**:
    - **MultiDex**: Enabled to support large dependency graphs.
    - **Core Library Desugaring**: Enabled (using `com.android.tools:desugar_jdk_libs:2.1.4`) to support modern Java APIs on older Android versions, required by plugins like `flutter_local_notifications`.
- **Deep Linking**: Configured in `AndroidManifest.xml` with an intent filter for the `io.supabase.flutternotehub` scheme.

## 6. Coding Conventions & Linting
- **Zero-Warning Policy**: The project enforces a strict linting policy. All informational, warning, and error-level lints from `flutter analyze` must be resolved.
- **Modern API Usage**: Always use modernized APIs, such as `.withValues(alpha: x)` instead of `.withOpacity(x)`, and `activeThumbColor` for Switches.
- **Error Handling**: Controllers should use toasts (`toastification`) for user-facing errors while maintaining silent catch blocks for non-critical failures, accompanied by explanatory comments.

---
*Maintained by Jules, AI Software Engineer.*
