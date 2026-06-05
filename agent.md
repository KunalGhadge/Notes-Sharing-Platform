# Developer Guide & System Analysis - Serious Study (formerly NoteHub)

This document provides a comprehensive, deep-dive analysis of the **Serious Study** application from a developer's perspective. It covers architecture, performance, security, and design patterns used across the platform.

## 1. System Architecture
Serious Study follows a modular, reactive architecture powered by **Flutter** and **GetX**.

- **State Management**: Uses `GetX` for reactive updates, dependency injection, and clean separation of business logic from the UI.
- **Directory Structure**:
    - `lib/controller/`: Contains reactive business logic (e.g., `DocumentController`, `AuthController`, `HomeController`).
    - `lib/view/`: Modular UI components and screens organized by feature (e.g., `home_screen/`, `auth_screen/`).
    - `lib/model/`: Data structures and serialization logic (e.g., `UserModel`, `DocumentModel`).
    - `lib/service/`: Utility services for file operations and notifications (e.g., `FileDownload`, `NotificationService`).
    - `lib/core/`: Centralized configurations:
        - `core/meta/`: App-level metadata and Supabase credentials.
        - `core/config/`: Theme, typography, and color definitions.
        - `core/helper/`: Common utilities and local storage helpers (`HiveBoxes`).
- **Backend**: Serverless architecture using **Supabase** (PostgreSQL, Auth, Storage).

## 2. Performance & Optimization
The app is engineered for a smooth experience on the Mumbai University community scale.

- **Data Batching**: The `HomeController` fetches documents in batches of **50** to optimize network payload.
- **Sticky Sort Algorithm**: Official documents are prioritized at the top of the feed (`is_official` DESC), followed by chronological order (`created_at` DESC).
- **Local Persistence (Hive)**:
    - `userBox`: Caches user profile metadata for instant UI rendering on launch.
    - `downloadsBox`: Tracks local document state to prevent redundant downloads.
- **Media Optimization**:
    - **Image Compression**: `ImageHelper` utilizes `flutter_image_compress` (70% quality, 1024x1024 max dimensions) before uploading covers to Supabase Storage.
    - **Caching**: `cached_network_image` is used globally to minimize repeat asset fetches.
- **Upload Constraints**: Direct document uploads are capped at **10MB**; external links (Google Drive, Mega) are encouraged for larger resources to maintain platform performance.

## 3. Security Deep Dive
A multi-layered security model protects user data and platform integrity.

- **Authentication**: Managed via **Supabase Auth (JWT)**. Sessions are securely persisted and managed by the SDK.
- **Row Level Security (RLS)**: PostgreSQL RLS is strictly enforced:
    - **Ownership Integrity**: Users can only `UPDATE` or `DELETE` records where `auth.uid() = user_id`.
    - **Access Control**: Notifications and bookmarks are private to the receiver/owner.
- **Atomic Operations (RPCs)**: Critical counters (likes, dislikes) are updated via PostgreSQL `SECURITY DEFINER` functions. This prevents client-side race conditions and unauthorized manipulation of raw counts.
- **Risk Assessment**:
    - *Privilege Escalation*: Current RLS allows users to update their own profile; however, without column-level restrictions, there is a theoretical risk of users self-promoting to `is_admin` via direct API calls if not properly gated in the database.
    - *Official Flag*: The `is_official` flag in the `documents` table should be audited to ensure only authenticated admins can toggle it.

## 4. Design System
The app follows a **Material 3** specification with a modern **Glassmorphism** aesthetic.

- **Branding**: The primary color is **Premium Deep Blue** (`#0D47A1`), symbolizing academic integrity.
- **Typography**: Standardized using the **Plus Jakarta Sans** typeface via `AppTypography`.
- **UI Components**:
    - **BottomFooter**: Features a floating design with a blur effect and rounded corners (30.0).
    - **Loaders**: Standardized `Loader` and `Loader2` (Sized/Stroke-controlled) components for consistent async feedback.
    - **Toasts**: Powered by `toastification` with `flatColored` style and `topRight` alignment.

## 5. Data Schema (PostgreSQL)
Key tables in the Supabase ecosystem:
- `profiles`: Extends auth metadata (institute, interests, bio, `is_admin`).
- `documents`: Stores note metadata, URLs, and the `is_official` status.
- `interactions`: Unique (user_id, document_id) pairs for likes/dislikes.
- `comments`: Supports nested replies via `parent_id`.
- `remote_config`: Key-value pairs for maintenance mode and global announcements.
- `notifications`: Tracks interactions with `is_global` support for broadcasts.

## 6. Maintenance & Development Workflow
- **Prerequisites**: Flutter SDK **^3.5.4**.
- **Zero Warnings Policy**: The project adheres to a strict linting standard. All code must pass `flutter analyze` without warnings.
- **Modernized APIs**: Uses `.withValues(alpha: ...)` for color transparency instead of deprecated `.withOpacity()`.
- **Testing**: Includes a basic test suite in the `test/` directory.

---
*Maintained by Jules, AI Software Engineer.*
