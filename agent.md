# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Architecture & State Management
- **Framework**: Flutter 3.24+ (SDK 3.5.4).
- **Pattern**: GetX MVC. Controllers (e.g., `DocumentController`, `ProfileController`) manage business logic independently from the UI.
- **Routing**: GetX dynamic routing for seamless transitions.
- **Dependency Injection**: Centralized in `main.dart` and lazily loaded in view `initState`.

## 2. Performance Optimizations
- **Reactive State Management**: Utilizing `GetX` for efficient state updates.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching. User profile metadata is stored in `userBox` (see `lib/core/helper/hive_boxes.dart`) to ensure immediate UI responsiveness upon app launch.
- **Optimistic UI**: Interactions like likes, dislikes, and bookmarks are applied locally first in `DocumentController` to provide instant feedback, then synchronized with the backend.
- **Sticky Sort**: The `HomeController` prioritizes official university documents in the feed by sorting them to the top (`is_official` DESC) regardless of the upload timestamp.
- **Batch Fetching**: To minimize network overhead, documents are fetched in batches (e.g., 50 per request in `HomeController`).
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `PostCard`) to minimize network usage.
    - **Compression**: `flutter_image_compress` is integrated into the `UploadController` to optimize asset sizes before they reach Supabase Storage.

## 3. Backend & Security (Supabase)
- **Database**: PostgreSQL with Row Level Security (RLS).
- **Authentication**: Supabase Auth (JWT). Sessions are securely managed by the SDK.
- **Authorization (RLS)**: Strictly enforced policies in `SUPABASE_SCHEMA.sql`:
    - **Profiles**: Only owners can `UPDATE`.
    - **Documents**: Publicly viewable; only owners can `INSERT`, `UPDATE`, or `DELETE`.
    - **Notifications/Bookmarks**: Private to the specific user.
- **Atomic Operations (RPCs)**: Critical interactions are handled via PostgreSQL functions (`increment_likes`, `decrement_likes`, etc.) using `SECURITY DEFINER`. This ensures data integrity and prevents race conditions by performing updates server-side.
- **Storage**: All media (documents, covers) are stored in Supabase Buckets with specific access policies.

## 4. Design System
- **UI Paradigm**: Material 3 with a Glassmorphism aesthetic.
- **Branding**: "Premium Deep Blue" theme (`#0D47A1`).
- **Glassmorphism**: Implemented using the `glassmorphism` package and custom `AppGradients.glassGradient` (notably in `PostCard` overlays).
- **Typography**: 'Plus Jakarta Sans' via `google_fonts`.
- **Feedback**: Shimmer placeholders (`HomeDocumentSection`) and Lottie animations are used to manage asynchronous states and enhance UX.

## 5. Development & QA
- **Lints**: Zero-tolerance policy for warnings. Modern APIs like `.withValues()` are required for color manipulations.
- **Testing**: Run `flutter analyze && flutter test` within the `notehub/` directory to verify integrity.
- **Deep Linking**: Configured for `io.supabase.flutternotehub://login-callback` in `AndroidManifest.xml`.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
