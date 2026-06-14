# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive analysis of the Serious Study project from a developer's perspective. It serves as both a system manual and a maintenance guide.

## Project Overview
Serious Study is a premium academic networking and resource-sharing platform specifically designed for the Mumbai University student community. It utilizes a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 1. Performance Analysis & Optimization
- **Reactive State Management**: The application uses **GetX** (`GetxController`, `Obx`) for efficient, decoupled state management. Optimistic UI updates are implemented in `DocumentController` (likes, dislikes, bookmarks) for immediate feedback.
- **Local Persistence**: **Hive** is used for high-performance NoSQL local caching.
    - `userBox`: Stores `UserModel` data (ID, username, profile URL) for instant session restoration.
    - `downloadsBox`: Manages local metadata for downloaded resources.
- **Feed Performance**:
    - **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm where `official` documents are prioritized at the top of the feed, followed by a chronological sort (`created_at`).
    - **Batching**: Documents are fetched in batches of 50 to balance initial load time and user experience.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is integrated into the `UploadController`. Cover images are compressed to 70% quality before storage upload.
    - **Upload Limits**: A strict 10MB limit is enforced for direct document uploads to optimize storage costs and performance.
    - **Network Caching**: `cached_network_image` is used throughout the UI to prevent redundant downloads of asset thumbnails.
- **Atomic Backend Operations**: Interaction counters (likes/dislikes) are updated via PostgreSQL **RPCs** (`increment_likes`, `decrement_dislikes`, etc.) to ensure data consistency across concurrent users.

## 2. Design & UX Standards
- **Design Paradigm**: **Material 3** with a heavy emphasis on **Glassmorphism**.
- **Theming**:
    - **Brand Color**: "Premium Deep Blue" (`#0D47A1`), implemented via `PrimaryColor.shade500`.
    - **Typography**: "Plus Jakarta Sans" is the primary typeface for all UI elements.
- **Custom Components**:
    - **BottomFooter**: A custom floating navigation bar with rounded corners (30.0) and glassmorphic shadows.
    - **Sticky Header**: `HomeHeader` uses glassmorphic backgrounds for a premium layered feel.
- **State Feedback**:
    - **Shimmer**: Used in `HomeDocumentSection` and `SearchPage` for smooth asynchronous loading.
    - **Lottie**: Integrated for empty states and success animations.

## 3. Security & Data Integrity Audit
- **Authentication**: JWT-based security via **Supabase Auth**. Sessions are managed securely and verified before sensitive operations like uploads or deletions.
- **Authorization (RLS)**: Row Level Security is enforced on all PostgreSQL tables:
    - **Documents**: `auth.uid() = user_id` check for deletions and updates.
    - **Profiles**: Public read, but private write. *Note: Users can currently update their own profile columns including `is_admin` via direct API calls; future hardening should move `is_admin` to a private metadata table.*
    - **Security Definer Functions**: Critical logic (like interactions) is wrapped in `SECURITY DEFINER` functions to prevent direct unauthorized manipulation of the `interactions` table.
- **Storage Policies**: Files are organized in user-specific paths (`userId/docs/`, `userId/covers/`) with bucket-level policies restricting unauthorized deletions.

## 4. Maintenance & QA
- **Zero Warnings Policy**: The codebase strictly adheres to a zero-warning linting standard.
    - Modern APIs: Always use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
    - Switches: Use `activeThumbColor` for Material 3 compliance.
- **Tech Stack Requirements**:
    - **Flutter SDK**: ^3.5.4
    - **Dart SDK**: ^3.5.0
- **Verification Commands**:
    - `cd notehub && flutter analyze`: Ensure zero linting issues.
    - `cd notehub && flutter test`: Run functional tests (e.g., `test/dummy_test.dart`).

---
*Last Technical Audit: June 2026 by Jules, AI Software Engineer.*
