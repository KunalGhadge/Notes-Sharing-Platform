# Developer Guide - NoteHub (Serious Study)

This document provides a deep technical analysis of the NoteHub project (rebranded as Serious Study) from a senior developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented after the migration to a serverless **Supabase** stack.

---

## 1. Architectural Overview
The application follows a reactive **MVC (Model-View-Controller)** pattern facilitated by the **GetX** framework.

- **Frontend**: Flutter 3.24+ (SDK ^3.5.4)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **State Management**: GetX (Reactive observables and dependency injection)
- **Local Persistence**: Hive (High-performance NoSQL for session and profile caching)

### Key Directories:
- `lib/controller/`: Contains business logic and reactive state management.
- `lib/view/`: Modular UI screens and reusable widgets.
- `lib/core/`: Application-wide configurations, themes, and helpers.
- `lib/service/`: Low-level services for notifications and caching.

---

## 2. Performance Analysis

### Reactive State & Dependency Injection
By using `GetX`, the app achieves high performance with minimal boilerplate. Controllers are injected only when needed and disposed of automatically, reducing memory overhead.

### Local Persistent Storage (Hive)
- **User Sessions**: The `userBox` (see `lib/core/helper/hive_boxes.dart`) stores the `UserModel` locally. This allows the app to load the user's profile and settings instantly without waiting for a network response.
- **Downloads**: The `downloadsBox` tracks locally cached documents for offline access.

### Media Optimization
- **Image Compression**: `ImageHelper` (in `lib/core/helper/image_helper.dart`) uses `flutter_image_compress` (Quality: 70, Dimensions: 1024x1024) to optimize document covers before upload, significantly reducing storage costs and load times.
- **Lazy Loading**: The `HomeController` implements a fetch limit of 50 items and "Sticky Sort" logic to prioritize official university content while maintaining a fast-loading feed.
- **Image Caching**: `cached_network_image` is utilized globally to prevent redundant network requests for thumbnails and profile pictures.

### Atomic Database Operations
To prevent race conditions and ensure data integrity, critical interactions like likes and dislikes are handled via **PostgreSQL RPCs** (`increment_likes`, `decrement_dislikes`) defined in `SUPABASE_SCHEMA.sql`. This offloads computation to the database and ensures atomic updates to counters.

---

## 3. Design & UI/UX

### Material 3 & Aesthetics
- **Branding**: The app uses a "Premium Deep Blue" primary color (`#0D47A1`) to reflect academic integrity.
- **Typography**: Primary typeface is 'Plus Jakarta Sans' (via `google_fonts`).
- **Glassmorphism**: Implemented using the `glassmorphism` package and custom `AppGradients.glassGradient` for a modern, layered look (e.g., in `PostCard`).

### Visual Performance
- **Shimmer Effects**: `shimmer` placeholders are used during data fetching (e.g., `HomeDocumentSection`) to prevent "blank screen" issues and provide smooth transitions.
- **Lottie Animations**: Used for empty states and success feedback to enhance user engagement.

---

## 4. Security Analysis

### Authentication & Authorization
- **JWT Authentication**: Migrated from a custom session-less system to **Supabase Auth**. Tokens are managed securely by the Supabase SDK.
- **Deep Linking**: Configured in `AndroidManifest.xml` with the scheme `io.supabase.flutternotehub` for secure login-callback flows.

### Data Protection (RLS)
The database enforces strict **Row Level Security (RLS)**. Policies defined in `SUPABASE_SCHEMA.sql` ensure:
- **Public Read**: Profiles and documents are publicly viewable.
- **Owner Write**: Only the user who created a document or profile can update or delete it.
- **Secure RPCs**: Using `SECURITY DEFINER` on PostgreSQL functions allows users to perform specific atomic actions (like liking a post) without granting them direct write access to sensitive columns like `likes_count`.

### File Security
Supabase Storage buckets for documents and covers are protected by policies, ensuring that users can only upload to their own directories (`auth.uid() = (storage.foldername(name))[1]`).

---

## 5. Development & QA

### CI/CD and Testing
- **Analysis**: The project strictly adheres to a "Zero Warnings" policy. Run `flutter analyze` to verify linting.
- **Modernization**: Deprecated `.withOpacity()` calls have been replaced with `.withValues(alpha: ...)` to comply with Flutter 3.27+ standards.
- **Testing**: Basic functionality is verified via `flutter test`.

### Android Configuration
- **Compile/Target SDK**: 36 (Android 15+)
- **Build Tools**: AGP 8.9.1, Kotlin 2.1.0, Gradle 8.12
- **Features**: `multiDexEnabled` and `coreLibraryDesugaring` are enabled to support local notification plugins and modern Java APIs.

---
*Maintained by Jules, AI Software Engineer.*
