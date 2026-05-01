# Developer Guide & System Manual - Serious Study (NoteHub)

This document serves as the exhaustive technical reference for Serious Study, a premium academic resource-sharing platform built with Flutter and Supabase.

## 1. Architectural Overview
Serious Study follows a reactive **GetX MVC** architecture, ensuring a clean separation between UI components and business logic.

- **Frontend**: Flutter (targeting Android primarily).
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime).
- **State Management**: GetX (Controllers manage reactive states via `.obs`).
- **Persistence**: Hive (NoSQL local storage for high-speed metadata access).

## 2. Performance Analysis
The application is optimized for the Mumbai University student community, where network reliability can vary.

### 2.1 Data Management & Caching
- **Reactive Synchronization**: `HomeController` and `NotificationController` utilize Supabase Realtime (`PostgresChangeEvent`) to ensure the UI stays updated without manual refreshes.
- **Local Cache (Hive)**:
    - `userBox`: Stores `UserModel` data (ID, username, profile URL) to enable "Instant-On" UI.
    - `downloadsBox`: Tracks locally saved documents to prevent redundant network calls.
- **Relational Optimization**: `AppSearchController` and `HomeController` perform relational joins (profiles, interactions, bookmarks) in a single query to minimize latency.
- **Sticky Sort**: The `HomeController` implements a custom sorting algorithm that prioritizes official university documents (`is_official`) followed by chronological order (`created_at`).

### 2.2 Media Optimization
- **Image Compression**: Mandatory compression is enforced in `UploadController` via `ImageHelper`. Images are resized to a max of 1024x1024 at 70% quality using `flutter_image_compress`.
- **Upload Limits**: A strict **10MB limit** is enforced for direct document uploads to Supabase Storage. Users are encouraged to provide external links (Google Drive/Mega) for larger files to ensure platform scalability.
- **Network Caching**: `cached_network_image` is used for all user avatars and document covers.

### 2.3 Fluid UI
- **Optimistic Updates**: `DocumentController` performs optimistic UI updates for Likes, Dislikes, and Bookmarks, reverting only if the backend RPC fails.
- **Shimmer Effects**: Loading states are handled via the `shimmer` package to maintain visual continuity.

## 3. Design & Aesthetics
The app adheres to **Material 3** principles with a "Premium Deep Blue" academic theme.

- **Typography**: 'Plus Jakarta Sans' (via `google_fonts`).
- **Visual Style**: Glassmorphism is a core design element, implemented using the `glassmorphism` package and `AppGradients.glassGradient`.
- **Primary Color**: `#0D47A1` (Deep Blue).
- **Feedback**: Lottie animations are used for empty states and success/error feedback.
- **Standardized Loaders**: `Loader` and `Loader2` (in `lib/view/widgets/loader.dart`) provide consistent circular progress indicators across the app.

## 4. Security & Data Integrity
Security is baked into the database layer via Supabase's granular controls.

### 4.1 Authentication & Authorization
- **JWT Authentication**: Secured via Supabase Auth.
- **Row Level Security (RLS)**: Strictly enforced on all PostgreSQL tables.
    - Profiles: Owners only for updates.
    - Documents: Owner/Admin write access.
    - Notifications: Receiver-specific read access.
- **Admin Verification**: The `is_admin` flag in the `profiles` table controls access to broadcast tools and the "Official" content toggle.

### 4.2 Atomic Operations (RPCs)
To prevent race conditions and unauthorized data manipulation, counters are updated via PostgreSQL Functions (`SECURITY DEFINER`):
- `increment_likes` / `decrement_likes`
- `increment_dislikes` / `decrement_dislikes`
These functions allow users to trigger count changes without having direct `UPDATE` permissions on the `likes_count` columns.

### 4.3 Storage Security
- **Path-Based Access**: Document storage is partitioned by `userId`. Policies ensure users can only delete their own assets.

## 5. Development Standards
- **Zero Warnings Policy**: All commits must pass `flutter analyze` and `flutter test`.
- **Modern APIs**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
- **Naming**: Use `lowerCamelCase` for variables and `UpperCamelCase` for classes/widgets.
- **Flow Control**: Explicit curly braces are required for all flow control structures (if/for/while) to pass linting.

---
*Maintained by Jules, AI Software Engineer.*
