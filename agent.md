# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance, security, and design principles governing the application.

## 1. Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 2. Technical Architecture
The application follows a reactive **MVC (Model-View-Controller)** architecture using the **GetX** framework.

- **Frontend**: Flutter 3.41.2 (Channel Stable)
- **State Management**: `GetX` for reactive UI updates and dependency injection.
- **Backend**: **Supabase** (PostgreSQL, Auth, Storage).
- **Local Persistence**: `Hive` for high-performance NoSQL local caching (e.g., `userBox`, `downloadsBox`).
- **Communication**: Supabase SDK for real-time Postgres changes and JWT-based authentication.

## 3. Performance Optimizations
- **Optimistic UI**: Interactions like likes, dislikes, and bookmarks (see `DocumentController`) update the UI immediately before confirming with the backend.
- **Atomic Operations**: Critical counters (likes/dislikes) are managed via PostgreSQL RPC functions (`increment_likes`, `decrement_dislikes`) to prevent race conditions.
- **Media Handling**:
    - **Compression**: `flutter_image_compress` is used in the `UploadController` (via `ImageHelper`) to optimize cover images (quality 70, 1024px min dimensions).
    - **Caching**: `cached_network_image` is used for thumbnails, and `Dio` is used for manual file caching in `FileCachingService`.
- **Data Fetching**: The `HomeController` implements a batch limit of 50 items and utilizes "Sticky Sort" to prioritize official university documents.

## 4. Design System & UX
The application implements **Material 3** with a **Glassmorphism** aesthetic.
- **Branding**: "Premium Deep Blue" theme (`#0D47A1`) using 'Plus Jakarta Sans' typography.
- **Visual Feedback**:
    - **Shimmers**: Used in feed sections to prevent blank screen "grey space" issues.
    - **Lottie**: Used for empty states and process animations.
- **Glassmorphism**: Implemented via the `glassmorphism` package and `AppGradients.glassGradient` for UI components like `PostCard`.

## 5. Security & Data Integrity
- **Authentication**: JWT-based session management via Supabase Auth. Deep linking is configured for secure callbacks (`io.supabase.flutternotehub`).
- **Authorization (RLS)**: Row Level Security is enforced on all PostgreSQL tables.
    - Profiles: Owners can update; public can read.
    - Documents: Owners can insert/delete.
    - Notifications: Restricted to the `receiver_id` or `is_global` flag.
- **Security Definer RPCs**: Database functions for incrementing counters are marked as `SECURITY DEFINER`, allowing atomic updates to protected columns without granting users direct write access.

## 6. Coding Conventions & Quality
- **Naming**: Use `lowerCamelCase` for variables (e.g., `avatarUrl` in `AppMetaData`).
- **Modern APIs**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)` for Flutter 3.27+ compatibility.
- **Linting**: Strict 'Zero Warnings' policy.
    - All flow control structures MUST use curly braces.
    - Intentional empty catch blocks MUST include the `// ignore: empty_catches` annotation.
- **Analysis**: Always run `flutter analyze` and `flutter test` before submitting changes.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
