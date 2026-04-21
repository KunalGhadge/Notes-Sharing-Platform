# Developer Guide - Serious Study (Mumbai University Community App)

This document provides an exhaustive technical analysis and developer guide for **Serious Study** (formerly NoteHub). It outlines the architecture, performance optimizations, design principles, and security measures implemented in the platform.

## 1. Architectural Overview
The application is built using **Flutter** and follows a decoupled **GetX MVC (Model-View-Controller)** architecture to separate business logic from the UI.

- **Entry Point**: `lib/main.dart` initializes Supabase, Hive, and Local Notifications.
- **State Management**: **GetX** is used for reactive state updates, dependency injection, and routing. Controllers (e.g., `DocumentController`, `HomeController`) manage state transitions and API interactions.
- **Core Layer**: `lib/core/` contains centralized metadata (`AppMetaData`), themes (`AppGradients`), and helpers.
- **Service Layer**: `lib/service/` handles hardware-level or specialized interactions like `FileDownload`, `FileCaching`, and `NotificationService`.
- **Database**: **Supabase (PostgreSQL)** provides a serverless backend with real-time capabilities via Postgres Change streams.

## 2. Performance & Optimization
Serious Study is optimized for a smooth user experience even under variable network conditions.

- **Caching Strategy**:
    - **User Data**: `Hive` provides high-speed NoSQL local persistence. The `userBox` stores `UserModel` data (username, profile URL, counts) to eliminate splash-screen latency.
    - **Media**: `CachedNetworkImage` is used for thumbnails to reduce redundant bandwidth consumption.
    - **Downloads**: `downloadsBox` tracks local file paths for offline access.
- **Real-time Synchronization**:
    - `HomeController` uses `PostgresChangeEvent.all` on the `public:documents` channel to keep the feed updated without manual refreshes.
    - `NotificationController` filters real-time payloads by `receiver_id` or `is_global` flags for efficiency.
- **Media Handling**:
    - **Compression**: `ImageHelper.compressImage` (using `flutter_image_compress`) reduces cover image sizes before upload.
    - **Upload Limits**: `UploadController` enforces a **10MB limit** for direct document uploads to control cloud storage overhead, encouraging users to use "External Links" (Google Drive/Mega) for larger files.
- **Feed Logic**:
    - **Sticky Sort**: The `HomeController` implements a custom sort algorithm that prioritizes `is_official` documents followed by the latest `created_at` timestamp.
    - **Batching**: Primary feeds are limited to 50 items per fetch to optimize initial payload size.

## 3. Design Principles
The UI adheres to a "Premium Academic" aesthetic tailored for the Mumbai University community.

- **Design System**: **Material 3** with custom **Glassmorphism** implementations (via `glassmorphism` package and `AppGradients.glassGradient`).
- **Branding**: Primary theme color is **Premium Deep Blue (#0D47A1)**. Typography utilizes **Plus Jakarta Sans** via `google_fonts`.
- **User Feedback**:
    - **Loaders**: Standardized `Loader` and `Loader2` widgets provide consistent activity indication.
    - **Shimmers**: `shimmer` package is used in `HomeDocumentSection` and `SearchPage` for perceived performance.
    - **Toasts**: `toastification` is used for non-intrusive status updates (success, warning, error).

## 4. Security & Data Integrity
Security is a core pillar, leveraging Supabase's built-in features and custom PostgreSQL logic.

- **Authentication**: **Supabase Auth (JWT)** manages user sessions. Password hashing (Argon2/Bcrypt) is handled natively by the backend.
- **Authorization (RLS)**: **Row Level Security** is enabled on all tables in `SUPABASE_SCHEMA.sql`.
    - **Profiles**: `UPDATE` is restricted to `auth.uid() = id`.
    - **Documents**: Owners have `ALL` permissions; others have `SELECT`.
    - **Notifications**: Users can only `SELECT` where `receiver_id = auth.uid()` or `is_global = true`.
- **Atomic Interactions (RPCs)**:
    - Counters (likes/dislikes) are not updated directly by the client. Instead, the app calls PostgreSQL Functions (`increment_likes`, `decrement_likes`, etc.) using the `.rpc()` method.
    - These functions use `SECURITY DEFINER` to allow protected table updates while maintaining strict RLS on the base tables.
- **Admin Security**:
    - The `is_admin` flag in `public.profiles` controls access to administrative features like `broadcastAnnouncement` and `isOfficial` document tagging.
    - The `is_official` documents are visually distinguished and prioritized in the feed.

## 5. Developer Workflow & QA
- **Linter**: Strictly follows `package:flutter_lints/flutter.yaml`. A "Zero Warnings" policy is maintained.
- **Testing**: `flutter test` executes the test suite.
- **Verification**: Always run `flutter analyze` before committing to ensure modern Flutter standards (e.g., using `.withValues()` instead of `.withOpacity()`) are met.
- **Versioning**: Dart SDK ^3.5.4 and Flutter 3.24+ are required.

---
*Maintained by the Serious Study Engineering Team.*
