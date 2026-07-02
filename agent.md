# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective, documenting the architecture, performance, design, and security of the application.

## 1. Architecture Overview
Serious Study is a cross-platform Android application built with **Flutter** and powered by a serverless **Supabase** backend. It follows a decoupled MVC-like architecture using the **GetX** framework.

- **State Management**: `GetX` is used for reactive state updates and dependency injection. Controllers (e.g., `DocumentController`, `AuthController`) manage business logic and sync with the UI via observable variables (`.obs`).
- **Backend**: **Supabase** (PostgreSQL) provides authentication, real-time database capabilities, and object storage.
- **Local Persistence**: **Hive** is utilized for high-performance NoSQL local storage, primarily for caching user profile metadata (`userBox`) and tracking local downloads (`downloadsBox`).
- **Initialization Sequence**: The app initializes in `main.dart`, setting up Supabase, Local Notifications, Hive adapters, and core GetX controllers before launching the `Splash` screen.

## 2. Performance Analysis
The application implements several strategies to ensure a responsive and efficient user experience:

- **Reactive Updates**: Real-time synchronization is achieved via Supabase PostgreSQL Changes, specifically in `HomeController`, which listens for updates to the `documents` table.
- **Database Optimization**:
    - **Atomic Operations**: Critical interaction counters (likes, dislikes, bookmarks) are updated using PostgreSQL Functions (`RPCs`) to prevent race conditions and ensure data integrity.
    - **Batch Fetching**: The `HomeController` fetches updates in batches of 50 to optimize network throughput and initial load times.
- **Media & Asset Management**:
    - **Thumbnail Caching**: `cached_network_image` is used to prevent redundant downloads of asset thumbnails.
    - **Image Compression**: `flutter_image_compress` is integrated into the upload pipeline (`ImageHelper`) to reduce the payload of cover images.
    - **Local File Caching**: The `saveAndOpenFile` utility in `lib/service/file_caching.dart` uses `Dio` to download documents to the temporary directory and checks for existing local files before re-downloading.
- **UI Responsiveness**: Shimmer placeholders and Lottie animations provide immediate visual feedback during asynchronous operations.

## 3. Design & UI/UX
The application follows a **Material 3** design system with a specialized **Glassmorphism** aesthetic to achieve a premium look.

- **Theming**:
    - **Primary Color**: "Premium Deep Blue" (`#0D47A1`), established in `lib/core/config/color.dart`.
    - **Gradients**: Custom `AppGradients.premiumGradient` and `glassGradient` are used for depth and layering.
- **Glassmorphism**: Semi-transparent overlays (e.g., `withValues(alpha: 0.15)`) and specialized widgets are used for the `BottomFooter` and various UI cards.
- **Typography**: "Plus Jakarta Sans" is the primary typeface, configured modularly in `lib/core/config/typography.dart`.
- **Feed Logic**: The `HomeController` implements a "Sticky Sort" algorithm, prioritizing 'official' documents at the top of the feed regardless of chronological order.
- **Interactivity**: Optimistic UI updates are used in `DocumentController` for likes and bookmarks, providing instant feedback before backend confirmation.

## 4. Security Analysis
Security is a core pillar of the architecture, leveraging Supabase's built-in features:

- **Authentication**: JWT-based session management via **Supabase Auth**. No sensitive credentials (like passwords) are stored locally or handled in plain text.
- **Row Level Security (RLS)**: Enforced at the database level in `SUPABASE_SCHEMA.sql`. Policies ensure:
    - Users can only update their own profiles.
    - Document deletion and updates are restricted to the owner.
    - Interactions and bookmarks are private to the user who created them.
- **Authorization**: An `is_admin` flag in the `profiles` table controls access to administrative features, such as marking documents as "Official." This is enforced via RLS and PostgreSQL triggers.
- **Data Integrity**: Atomic RPCs (`increment_likes`, etc.) use `SECURITY DEFINER` to allow controlled updates to counters without granting users direct write access to the `documents` table.
- **Storage Protection**: Supabase Storage buckets are governed by policies that restrict file access and ensure only authorized users can upload or delete assets.
- **Input Validation**: `UploadController` enforces a 10MB limit for direct document uploads to mitigate storage abuse.

## 5. Maintenance & QA
- **Environment Requirements**: Dart SDK ^3.5.4 and Flutter 3.24+ (channel stable).
- **Code Quality**:
    - **Zero Warnings Policy**: All code must pass `flutter analyze` without warnings.
    - **Tests**: Core logic should be verified using `flutter test`.
- **Linting**: The project uses `flutter_lints` and specific project-wide rules (e.g., mandatory curly braces in flow control).
- **Modernization**: The codebase uses modern APIs like `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
