# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented in the application.

## 1. Performance Analysis
Serious Study is designed for high performance and responsiveness, leveraging both client-side and server-side optimizations.

- **Reactive State Management (GetX)**:
  - The application uses `GetX` for efficient state management, ensuring only necessary widgets are rebuilt during updates.
  - Controllers like `DocumentController` and `HomeController` manage business logic independently of the UI.
  - `GetX` is also used for dependency injection and routing, reducing boilerplate and improving navigation speed.

- **Local Persistent Storage (Hive)**:
  - `Hive`, a lightweight and fast NoSQL database, is used for local caching.
  - User profile metadata is stored in `userBox` (see `lib/core/helper/hive_boxes.dart`) to allow the app to load personal data instantly without waiting for network responses.
  - `Hive` is also used to track downloads and local file paths.

- **Media Optimization**:
  - **Image Compression**: `flutter_image_compress` is integrated into `lib/core/helper/image_helper.dart`. All images are compressed (quality 70, minWidth/Height 1024) before being uploaded to Supabase Storage, significantly reducing bandwidth and storage costs.
  - **Thumbnail Caching**: The `cached_network_image` package is used throughout the app to prevent redundant downloads of media assets.

- **Database Efficiency (PostgreSQL & RPCs)**:
  - **Atomic Operations**: Critical interactions such as liking or disliking documents use PostgreSQL Functions (RPCs) like `increment_likes` and `decrement_likes`. This ensures data integrity and prevents race conditions that occur with client-side increments.
  - **Optimistic UI**: The `DocumentController` implements an optimistic update pattern for likes, dislikes, and bookmarks, providing immediate visual feedback to the user while synchronizing with the backend in the background.
  - **Sticky Sort**: The `HomeController` implements a "Sticky Sort" logic where official university documents (`is_official: true`) are prioritized at the top of the feed, followed by regular updates sorted by creation date.
  - **Batch Fetching**: Data is fetched in batches (limit 50) to minimize initial payload and improve perceived load times.

- **Real-time Synchronization**:
  - The app utilizes Supabase Realtime (Postgres Changes) in `HomeController` to listen for new document uploads and automatically refresh the feed without manual user intervention.

## 2. Design & Architecture
The application adheres to modern UI/UX principles, featuring a premium academic aesthetic.

- **UI Paradigm (Material 3 & Glassmorphism)**:
  - Material 3 is used for standard components and theming across the app.
  - **Glassmorphic Aesthetic**: The application incorporates semi-transparent, layered designs (e.g., in `PostCard` and the bottom navigation bar) using the `glassmorphism` package and custom gradients.
  - **Premium Deep Blue Theme**: The primary color is `#0D47A1` (`PrimaryColor.shade500`), representing the academic integrity and professional nature of the platform.
  - **Typography**: The app uses 'Plus Jakarta Sans' via `google_fonts` for all textual content.
  - **Animations**: `Lottie` animations are used for feedback during empty searches and successful operations.
  - **Vector Graphics**: SVGs (via `flutter_svg`) are preferred for consistent rendering across different screen resolutions.

- **Decoupled Architecture**:
  - **Controller/View Separation**: Business logic is entirely contained within `GetxController` classes (e.g., `AuthController`, `DocumentController`), keeping views strictly for UI presentation.
  - **Data Models**: Typed `UserModel`, `DocumentModel`, and `CommentModel` ensure type safety across the application.
  - **Service Layer**: Specialized tasks like file caching and media handling are delegated to service-level classes (`lib/service/file_caching.dart`).

- **Project Structure**:
  - `lib/controller/`: Reactive logic using GetX.
  - `lib/view/`: Modular UI components and screens, organized by feature (e.g., `auth_screen`, `home_screen`).
  - `lib/core/`: Global configurations, including `AppMetaData`, constants, and theme definitions.
  - `lib/model/`: Data structures and serialization logic.

## 3. Security Analysis
The application has been migrated from a legacy stack to a serverless architecture, addressing several security vulnerabilities.

- **Authentication & Authorization**:
  - **JWT-Based Sessions**: Supabase Auth (JWT) ensures secure session management.
  - **Password Security**: Passwords are never handled by the application in plain text; they are hashed (Argon2/Bcrypt) by Supabase.
  - **Row Level Security (RLS)**: PostgreSQL RLS policies in `SUPABASE_SCHEMA.sql` are strictly enforced for all tables:
    - **Profiles**: Public read, owner-only update.
    - **Documents**: Public read, owner-only insert and delete.
    - **Interactions/Bookmarks/Notifications**: Private access restricted to the respective user.

- **API Integrity**:
  - **Security Definer RPCs**: Database functions (e.g., `increment_likes`) use `SECURITY DEFINER`, allowing specific atomic updates to protected columns without granting the user direct write access to the table.
  - **Admin Roles**: The schema includes an `is_admin` column in `profiles`, and specific RLS policies grant admins extended permissions (e.g., updating any document).

- **Media and File Security**:
  - **Storage Policies**: Access to Supabase Storage buckets is governed by security policies, ensuring only authorized users can upload assets to their folders.
  - **Upload Limit**: A strict 10MB direct upload limit is enforced in the `UploadController` to prevent abuse and manage storage costs.
  - **External Links Support**: For larger files, users are encouraged to use secure external links (Google Drive, Mega).

## 4. Coding Conventions & Best Practices
The following standards must be followed for all contributions:

- **Analysis & Linting**:
  - `flutter analyze` must return zero issues. All warnings and informational messages must be resolved before submission.
  - No `print()` statements should be present in the final code. Use `debugPrint()` or the app's logging utilities instead.

- **Dart Language Standards**:
  - All flow control structures (e.g., `if`, `for`, `while`) MUST use curly braces, even for single-line statements.
  - Follow lowerCamelCase for members like `avatarUrl` in `AppMetaData`.
  - Prefer modern Flutter methods: use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
  - Avoid using deprecated members: use `activeThumbColor` instead of `activeColor`.

- **Error Handling**:
  - Intentional empty catch blocks must be annotated with `// ignore: empty_catches` and include a comment (e.g., `/* silent */`) to pass static analysis.
  - Toasts must be used to communicate failures to the user (e.g., `Toasts.showTostError()`).

- **Architecture Compliance**:
  - Controllers must not contain UI logic. All view-related operations must be handled in the `view/` layer.
  - Direct database queries should be limited to `GetxController` classes.
  - Atomic operations (like counter increments) MUST be performed via PostgreSQL RPCs rather than client-side calculations.

## 5. Development & QA
- **Prerequisites**: Flutter SDK ^3.5.4.
- **Android Configuration**: The `build.gradle` is configured with `multiDexEnabled` and `coreLibraryDesugaring` to support the `flutter_local_notifications` plugin.
- **Code Quality**:
    - Run `flutter analyze` to verify linting compliance.
    - Run `flutter test` to execute the test suite.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
