# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study application from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented in the project.

## 1. Project Architecture
The application follows a decoupled **MVC (Model-View-Controller)** pattern powered by **GetX** for reactive state management and dependency injection.

- **Frontend**: Flutter 3.41.2 (Channel Stable).
- **Backend**: Supabase (Serverless PostgreSQL, Auth, and Storage).
- **State Management**: `GetX` is used for global and local state. Controllers (e.g., `DocumentController`, `AuthController`) manage business logic and communicate with the Supabase client.
- **Dependency Injection**: Managed in `main.dart` and `layout.dart` using `Get.put()` to ensure controllers are available when needed.
- **Service Layer**: Dedicated services for notifications (`NotificationService`), file handling (`FileCaching`, `FileDownload`), and local storage.

## 2. Performance Optimizations
Serious Study is engineered for high performance and low latency, essential for a mobile-first student community.

- **Optimistic UI Pattern**: Implemented in `DocumentController` for likes, dislikes, and bookmarks. UI state updates immediately while backend synchronization occurs in the background, providing a lag-free experience.
- **Local Persistence (Hive)**: High-performance NoSQL storage (`Hive`) is used to cache user profile data (`userBox`) and download metadata. This ensures the app is usable immediately upon launch.
- **Advanced Media Handling**:
    - **Centralized Compression**: `ImageHelper` utilizes `flutter_image_compress` (Quality 70, 1024px constraint) to optimize media before upload.
    - **Efficient Caching**: `CachedNetworkImage` is used globally to prevent redundant network requests and provide smooth scrolling.
- **Database Strategy**:
    - **Sticky Sort**: `HomeController` prioritizes official university documents in the feed using a custom sort algorithm (`isOfficial` DESC, `createdAt` DESC).
    - **Batch Fetching**: Data is retrieved in batches of 50 to minimize initial payload and memory usage.
    - **PostgreSQL RPCs**: Atomic operations like `increment_likes` and `decrement_dislikes` are executed via database functions to ensure data consistency and prevent race conditions.

## 3. Design & UI/UX
The application adheres to **Material 3** principles with a premium academic aesthetic.

- **Aesthetics**:
    - **Glassmorphism**: Extensively used via the `glassmorphism` package and custom `AppGradients.glassGradient` to create a modern, layered look (e.g., in `PostCard`).
    - **Typography**: Uses 'Plus Jakarta Sans' as the primary typeface for a professional feel.
    - **Color Palette**: Revolved around "Premium Deep Blue" (`#0D47A1`), symbolizing Mumbai University's academic integrity.
- **Components**:
    - **Shimmer Placeholders**: Used in `HomeDocumentSection` to prevent 'grey space' and provide visual feedback during loading.
    - **Lottie Animations**: Integrated for state feedback (e.g., empty search results, splash screen).
    - **Standardized Feedback**: Custom `Toasts` class (wrapping `toastification`) ensures consistent success/error messaging.

## 4. Security Implementation
The platform prioritizes data integrity and user privacy through a multi-layered security approach.

- **Authentication**: Secure JWT-based sessions managed by **Supabase Auth**. Supports deep linking for email confirmation (`io.supabase.flutternotehub://login-callback`).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - **Profiles**: Publicly viewable, but `UPDATE` is restricted to the authenticated owner.
    - **Documents**: Anyone can view, but only the owner or an admin (`is_admin = true`) can `DELETE` or `UPDATE`.
    - **Interactions**: Unique constraints on `(user_id, document_id)` prevent duplicate likes/bookmarks.
- **Counter Integrity**: By using `SECURITY DEFINER` on RPC functions, users can update protected counters (like `likes_count`) through controlled logic without having direct write access to the underlying table columns.
- **File Security**: Supabase Storage buckets are governed by policies that restrict upload/delete operations to the authenticated owner of the folder (`auth.uid() = owner_id`).

## 5. Development Standards & QA
- **Zero Warnings Policy**: The project maintains a strict linting standard. Modern APIs like `.withValues(alpha: ...)` are required instead of the deprecated `.withOpacity()`.
- **Testing**:
    - Static analysis via `flutter analyze`.
    - Unit/Widget tests located in the `test/` directory.
- **Android Target**: Compiled for Android API 36 with Core Library Desugaring enabled to support modern notification features on older devices.
- **Contribution Workflow**:
    - Follow the reactive GetX pattern for all new features.
    - Ensure all flow control structures use curly braces.
    - Use `// ignore: empty_catches` for intentional empty catch blocks.

---
*Maintained by the Divine Visionary Development Team.*
