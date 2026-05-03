# Developer Guide & System Manual - Serious Study

This document provides an exhaustive technical analysis of the Serious Study (formerly NoteHub) application from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security implementations of the platform.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform dedicated to the Mumbai University student community. It leverages a serverless architecture powered by **Supabase** (PostgreSQL) and a reactive **Flutter** frontend.

## 2. Core Architecture
The application follows the **GetX MVC (Model-View-Controller)** pattern to ensure a clean separation of concerns and reactive state management.

### 2.1 Key Controllers
- **`AuthController`**: Manages JWT-based authentication via Supabase Auth and local session persistence using Hive.
- **`HomeController`**: Handles the primary feed, implementing real-time updates via Supabase PostgreSQL Change channels and "Sticky Sort" logic (prioritizing official documents).
- **`DocumentController`**: Orchestrates document life-cycles, including interactions (likes/dislikes), bookmarks, and deletions with optimistic UI updates.
- **`UploadController`**: Manages complex multi-part uploads, enforcing a **10MB file size limit** and integrating image compression.
- **`NotificationController`**: Synchronizes real-time academic updates and provides administrative broadcasting capabilities.
- **`RemoteConfigController`**: Provides dynamic app-level flags (maintenance mode, global announcements) without requiring APK re-builds.

## 3. Performance Analysis & Optimization
The app is engineered for high performance in low-bandwidth academic environments:

- **Reactive State Management**: `GetX` ensures that only the necessary UI components are rebuilt when data changes.
- **Local Persistence (Hive)**: High-performance NoSQL caching is used for user profile metadata (`userBox`) and tracking downloads (`downloadsBox`).
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` reduces cover image sizes (quality: 70, min: 1024x1024) before upload to Supabase Storage.
    - **Thumbnail Caching**: `cached_network_image` prevents redundant network calls for document covers.
- **Data Flow Efficiency**:
    - **Batch Fetching**: The `HomeController` limits initial feed loads to 50 items.
    - **Sticky Sort**: Critical academic resources (`is_official: true`) are pinned to the top of the feed.
    - **Optimistic UI**: Interactions like likes and bookmarks reflect immediately in the UI before backend confirmation.
- **Database Scalability**:
    - **PostgreSQL RPCs**: Critical counter operations (`increment_likes`, `decrement_dislikes`, etc.) are handled via server-side functions to prevent race conditions and ensure data consistency.

## 4. Design & UI/UX Standards
Serious Study adheres to a **Material 3** design paradigm with a "Premium Deep Blue" aesthetic.

- **Visual Theme**: Primary Color `#0D47A1`, utilizing 'Plus Jakarta Sans' for typography.
- **Glassmorphism**: Implemented using the `glassmorphism` package for high-end UI components like `PostCard` overlays and navigation bars.
- **Feedback Mechanisms**:
    - **Standardized Loaders**: `Loader` and `Loader2` provide consistent progress indicators.
    - **Toasts**: Integrated via `toastification` with `flatColored` styling and `topRight` alignment.
    - **Lottie Animations**: Used for empty states and successful interactions.
- **Modernization**: Strictly adheres to modern Flutter APIs (e.g., using `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`).

## 5. Security Architecture
The platform implements a multi-layered security model:

- **Authentication**: Managed via **Supabase Auth (JWT)**. Sessions are securely persisted and validated on each request.
- **Authorization (Row Level Security - RLS)**: Strict RLS policies are enforced on all PostgreSQL tables:
    - **Profiles**: Public read, owner-only update.
    - **Documents**: Public read, owner-only write/delete.
    - **Notifications**: Locked to the specific `receiver_id`.
- **Database Logic Isolation**: By using `SECURITY DEFINER` on RPC functions, atomic updates to protected columns (like `likes_count`) are permitted without granting users direct write access to the entire row.
- **Administrative Controls**: Access to official content tagging and global broadcasting is gated by the `is_admin` flag in the `profiles` table.
- **Storage Security**: Supabase Storage buckets are governed by policies that prevent unauthorized public access to private document paths.

## 6. Build & Environment Specifications
- **Framework**: Flutter 3.41.2 (Stable Channel, Feb 2026)
- **Language**: Dart 3.11.0
- **Android Target**: API Level 36
- **JDK Version**: Java 17 (with core library desugaring enabled)
- **Backend**: Supabase (PostgreSQL 15+)

## 7. QA & Contribution Guidelines
- **Zero Warnings Policy**: All commits must pass `flutter analyze` without any warnings or info messages.
- **Test Suite**: Run `flutter test` to verify core logic (e.g., `test/dummy_test.dart`).
- **Modernization Requirement**: Always use `.withValues()` for colors and `activeThumbColor` for Switch widgets.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
