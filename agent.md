# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, optimizations, and security measures implemented in the platform following its migration to a serverless **Supabase** architecture.

## 1. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates and dependency injection. Controllers (e.g., `DocumentController`, `HomeController`, `AuthController`) manage business logic independently from the UI, ensuring a clean separation of concerns.
- **Local Persistent Storage**: `Hive` (high-performance NoSQL) is used for local caching. User profile metadata is stored in `userBox` to ensure immediate UI responsiveness upon app launch, while the `downloads` box tracks offline-accessible resources.
- **Optimized Data Flow**:
    - **Batch Fetching**: `HomeController` implements a 50-item limit for the main feed to minimize initial payload and networking overhead.
    - **Sticky Sort**: The feed utilizes a "Sticky Sort" algorithm, prioritizing official university documents (`is_official`) at the top, followed by a chronological sort (`created_at`).
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `PostCard` and `HomeHeader`) to minimize redundant network usage and improve scroll performance.
    - **Compression**: `flutter_image_compress` (quality 70, minWidth/Height 1024) is integrated into the `UploadController` pipeline via `ImageHelper` to optimize assets before they reach Supabase Storage.
- **Database Performance**:
    - **Atomic Operations**: Critical interactions (likes, dislikes) are handled via PostgreSQL RPCs (e.g., `increment_likes`, `decrement_dislikes`). These use `SECURITY DEFINER` to allow atomic updates to protected counters without granting users direct write access to sensitive columns.
    - **Optimistic UI**: `DocumentController` implements optimistic updates for likes and bookmarks, providing immediate visual feedback before backend synchronization.
    - **Visual Continuity**: Shimmer placeholders (e.g., `HomeDocumentSection`) prevent 'grey space' and blank screen issues during asynchronous data fetching.

## 2. Design Paradigm & UX
- **UI Architecture**: The application implements **Material 3** principles with a modern **Glassmorphism** aesthetic.
    - **Glassmorphism**: Utilizes the `glassmorphism` package's `GlassmorphicContainer` and custom gradients (`AppGradients.glassGradient`) for bottom navigation and post overlays.
    - **Theme**: Rebranded with a "Premium Deep Blue" primary color (`#0D47A1`) to reflect academic integrity.
- **Typography & Assets**:
    - **Primary Typeface**: 'Plus Jakarta Sans' (via `google_fonts`) for a premium academic look.
    - **Feedback**: `Lottie` animations are used for state feedback (e.g., empty search results, successful uploads).
    - **Vector Icons**: SVGs are rendered via `SvgPicture.asset` with `colorFilter` to ensure consistent icon quality.

## 3. Security Architecture
The migration to Supabase has resolved critical vulnerabilities present in the legacy stack through a "security by design" approach:

- **Authentication**: Uses **Supabase Auth (JWT)**. Sessions are securely managed by the SDK, and passwords are protected using industry-standard hashing (Argon2/Bcrypt).
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - **Profiles**: Publicly viewable, but only owners can `UPDATE`.
    - **Documents**: Publicly viewable; only authenticated owners can `INSERT` or `DELETE`.
    - **Interactions/Bookmarks**: Private and tied directly to the `auth.uid()`.
- **API Integrity**: By using `SECURITY DEFINER` on RPC functions, the app protects the database from direct manipulation while allowing necessary atomic operations.
- **Secure File Storage**: Supabase Storage buckets are governed by policies that prevent unauthorized public access to private assets. Direct document uploads are capped at 10MB to maintain free-tier limits.

## 4. Technical Specifications & CI
- **Prerequisites**: Flutter SDK ^3.5.4.
- **Android Configuration**:
    - `compileSdk 36`, `targetSdk 36`.
    - `multiDexEnabled true`.
    - `coreLibraryDesugaringEnabled true` (using `com.android.tools:desugar_jdk_libs:2.1.4`) to support modern Java APIs and the `flutter_local_notifications` plugin.
- **Code Quality & CI**:
    - **Linting Policy**: The project enforces a zero-issue policy from `flutter analyze`. All deprecated member uses (e.g., `.withOpacity` vs `.withValues`) must be resolved.
    - **CI Workflow**: GitHub Actions run `flutter analyze` and `flutter test` within the `notehub/` directory. Any informational issue or test failure results in a build failure.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
