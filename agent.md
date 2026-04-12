# Developer Guide - Serious Study (Architecture & Implementation)

This guide provides a deep-dive analysis of the Serious Study (formerly NoteHub) codebase. It is designed to onboard developers by explaining the technical decisions across performance, design, and security.

## 1. System Architecture (GetX MVC)

Serious Study uses a modified MVC pattern facilitated by **GetX**. The architecture is decoupled into UI (`lib/view`), Logic/State (`lib/controller`), and Data Models (`lib/model`).

### Core Controllers
- **`AuthController`**: Manages Supabase Auth sessions, registration with default 'Mumbai University' institute, and profile synchronization.
- **`HomeController`**: Implements a 50-item batch limit and **Sticky Sort** (prioritizing `is_official` documents). It uses `onPostgresChanges` for real-time feed updates.
- **`DocumentController`**: Handles the lifecycle of notes. It uses **Optimistic UI** patterns for likes, dislikes, and bookmarks, ensuring immediate user feedback before PostgreSQL RPC calls complete.
- **`UploadController`**: Manages multi-part uploads. It allows toggling between direct document uploads (10MB limit) and external links to reduce server storage costs.
- **`RemoteConfigController`**: Fetches dynamic settings (maintenance mode, global announcements) from the `remote_config` table without requiring app updates.

## 2. Performance Optimizations

### Local Persistence & Caching
- **Hive (`lib/core/helper/hive_boxes.dart`)**: Used for ultra-fast local storage.
  - `userBox`: Stores `UserModel` (ID, username, profile URL) for instant profile loading.
  - `downloadsBox`: Tracks local file history.
- **`CachedNetworkImage`**: Implemented in components like `DocumentCard` to prevent redundant network requests for thumbnails.

### Media Handling
- **Image Compression**: `lib/core/helper/image_helper.dart` utilizes `flutter_image_compress` (quality 70, minWidth/Height 1024) to optimize cover images before they are pushed to Supabase Storage.

### Database Efficiency
- **Atomic Operations**: PostgreSQL RPCs (Remote Procedure Calls) are used for incrementing/decrementing interaction counters. This prevents race conditions and ensures data integrity.
  - Examples: `increment_likes`, `decrement_dislikes`.
- **Relational Joins**: The `AppSearchController` and `HomeController` perform relational joins (e.g., `profiles:user_id (...)`) in a single query to minimize round-trips.

## 3. Design & UI/UX Standards

### Visual Identity
- **Theme**: Material 3 based "Premium Deep Blue" (`#0D47A1`).
- **Typography**: 'Plus Jakarta Sans' via `google_fonts`.
- **Glassmorphism**: Implemented using the `glassmorphism` package and `AppGradients.glassGradient` for a modern, layered aesthetic in the navigation and profile cards.

### Feedback Mechanisms
- **Lottie Animations**: Used for empty states in search and successful interactions.
- **Toasts**: Centralized in `lib/view/widgets/toasts.dart` using the `toastification` package with a `topRight` alignment.
- **Shimmer**: Placeholder widgets provide visual continuity during asynchronous data loading.

## 4. Security Framework

### Authentication & Authorization
- **Supabase Auth**: JWT-based authentication. Sessions are re-initialized in `NotificationController` upon login/signup.
- **Row Level Security (RLS)**: Strictly enforced in `SUPABASE_SCHEMA.sql`.
  - `profiles`: Owners have `UPDATE` access; public has `SELECT`.
  - `documents`: Users can only `INSERT` or `DELETE` their own content.
  - `notifications`: Receiver-id based filtering ensures users only see their own alerts.

### Protected Logic
- **Security Definer RPCs**: Database functions are defined with `SECURITY DEFINER`, allowing the app to perform atomic counter updates without giving the client direct write access to sensitive columns like `likes_count`.

## 5. Android Implementation Details

- **Target API**: 36 (Android 15+ compatible).
- **Core Library Desugaring**: Enabled to support modern Java APIs on older Android versions (required for `flutter_local_notifications`).
- **Notification Channels**:
  - `notes_channel`: High-priority channel for academic updates and interactions.
  - `download_channel`: Low-priority channel for file download progress.

## 6. Development Workflow & Policies

### Coding Conventions
- **Zero Warnings**: The project enforces a strict 'Zero Warnings' policy. All code must pass `flutter analyze` without warnings.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Flow Control**: All `if`, `for`, and `while` statements MUST use curly braces `{}`.
- **Safety**: Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.

### Verification
Before submitting any code changes, developers MUST:
1. Run `flutter analyze` in the `notehub/` directory.
2. Run `flutter test` to ensure no regressions.
3. Verify that `pubspec.lock` has not been downgraded or accidentally modified.

---
*Maintained by Jules, AI Software Engineer.*
