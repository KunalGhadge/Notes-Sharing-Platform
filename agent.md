# Developer Guide - Serious Study (Mumbai University Community)

This document provides a comprehensive technical analysis of the Serious Study application, detailing its architecture, performance optimizations, and security implementations from a developer's perspective.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform designed specifically for the Mumbai University student community. The application utilizes a serverless **Supabase** backend and a **Flutter** frontend, following a reactive MVC-style architecture.

### Environment & Stack
- **Flutter SDK**: 3.41.2 (Channel stable, Feb 2026)
- **Dart SDK**: 3.11.0
- **State Management**: GetX ^4.6.6
- **Database**: Supabase (PostgreSQL)
- **Local Storage**: Hive ^2.2.3

## 2. Performance Analysis
The application is engineered for high responsiveness and efficient resource utilization:

- **Reactive State Management**: Utilizing **GetX** to manage business logic and UI state independently. Controllers like `DocumentController` and `HomeController` provide reactive streams that the UI observes, minimizing unnecessary rebuilds.
- **Local Persistence (Hive)**:
    - `Hive` (a high-performance NoSQL database) is used to cache critical user metadata in `userBox` (see `lib/core/helper/hive_boxes.dart`). This enables instant profile loading and offline session persistence.
    - `downloadsBox` tracks local file paths for quickly opening previously downloaded notes.
- **Data Fetching & Feed Optimization**:
    - **Batching**: The `HomeController` fetches documents in batches of 50 to optimize initial load times.
    - **Sticky Sort**: Implements a custom sorting algorithm in `HomeController` to prioritize "Official" documents at the top of the feed while maintaining reverse-chronological order for other content.
    - **Real-time Sync**: Uses Supabase PostgreSQL Changes (`RealtimeChannel`) to automatically refresh the feed when new content is uploaded or updated.
- **Media & Assets**:
    - **Shimmer Placeholders**: Standardized loading feedback via `shimmer` package to improve perceived performance.
    - **Image Compression**: `flutter_image_compress` is integrated into the `UploadController` pipeline to optimize cover images before they are uploaded to storage.
    - **Caching**: `cached_network_image` is used throughout the app (e.g., `PostCard`, `HomeHeader`) to prevent redundant downloads of thumbnails and profile pictures.

## 3. Design & Architecture
The application follows modern UI/UX principles with a focus on academic professionalism:

- **UI Paradigm**: Implements **Material 3** with a **Glassmorphism** aesthetic.
    - Uses `GlassmorphicContainer` for high-end UI elements like the bottom navigation bar and post headers.
    - **Premium Deep Blue Theme**: The brand identity is anchored by `#0D47A1` (Primary Deep Blue) and complementary gold accents for administrative features.
- **Modular Component Library**:
    - `lib/view/widgets/`: Contains reusable components like `DocumentCard`, `PostCard`, `Loader`, and `Toasts`.
    - `lib/view/widgets/toasts.dart`: Uses the `toastification` package for standardized, non-intrusive user feedback.
- **Layout Management**: Uses a custom `BottomFooter` (lib/view/bottom_footer/bottom_footer.dart) with elevated shadows and rounded corners to provide a floating navigation experience.

## 4. Security & Data Integrity
The migration to Supabase has enabled a robust security model:

- **Authentication**: Managed via **Supabase Auth (JWT)**. Sessions are handled securely by the SDK, and passwords are hashed using industry-standard algorithms (Argon2/Bcrypt) handled by Supabase internally.
- **Authorization (Row Level Security)**:
    - RLS is strictly enforced on all tables (`profiles`, `documents`, `interactions`, `bookmarks`, `notifications`, `followers`).
    - **Documents**: Only the owner (matching `auth.uid()`) can `INSERT`, `UPDATE`, or `DELETE`.
    - **Profiles**: Restricted to owner-only updates.
    - **Notifications**: Private to the receiver (receiver_id check).
- **Atomic Operations (RPCs)**:
    - Critical counters (likes, dislikes) are updated via **PostgreSQL Functions (SECURITY DEFINER)**. This ensures that users cannot directly manipulate the `likes_count` column but must use defined logic (`increment_likes`, `decrement_dislikes`) which validates the interaction in the background.
- **Admin Security**:
    - Administrative features (is_official flag, global announcements) are protected by checks against the `is_admin` column in the `profiles` table.

## 5. Development & QA
- **Zero Warnings Policy**: The codebase is strictly maintained with zero linting warnings (checked via `flutter analyze`).
- **Modern Standards**:
    - Uses modern Color APIs (`.withValues(alpha: x)`) instead of deprecated `.withOpacity()`.
    - Modern Switch configuration (`activeThumbColor`).
    - Explicit flow control (curly braces) for all logic blocks.
- **Android Configuration**:
    - The `build.gradle` is configured with `multiDexEnabled: true` and `coreLibraryDesugaringEnabled: true` to support modern Java features and the `flutter_local_notifications` plugin on older Android versions.
- **Standardized Loading**: `Loader` and `Loader2` components (lib/view/widgets/loader.dart) provide consistent circular progress indicators across all screens.

---
*Maintained by the Serious Study Engineering Team.*
