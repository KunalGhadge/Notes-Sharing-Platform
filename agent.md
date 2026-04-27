# Agent Guide: Serious Study (Mumbai University Community App)

This document provides a comprehensive technical breakdown of the Serious Study application from a developer's perspective. It details the architecture, performance strategies, design principles, and security implementations within the Feb 2026 stable environment.

## 1. Technical Architecture (GetX MVC)
The application follows a decoupled **Model-View-Controller (MVC)** pattern facilitated by the **GetX** framework.

- **Controllers (`lib/controller/`)**: Manage reactive state and business logic.
    - `AuthController`: Handles Supabase JWT authentication and profile synchronization with Hive.
    - `HomeController`: Manages the real-time document feed with "Sticky Sort" (prioritizing official documents).
    - `DocumentController`: Handles interactions (likes, bookmarks) using **Optimistic UI** and atomic **PostgreSQL RPCs**.
    - `UploadController`: Manages multi-part uploads with file size enforcement (10MB limit) and image compression.
    - `NotificationController`: Manages real-time alerts via Supabase PostgreSQL Changes and local Android notifications.
- **Services (`lib/service/`)**: Abstracted infrastructure logic.
    - `FileDownload`: Chunk-based downloading with real-time notification progress.
    - `FileCaching`: Manages temporary local storage via `Dio` and `path_provider`.
- **Core (`lib/core/`)**: Centralized configuration and helpers.
    - `AppMetaData`: Backend credentials and app branding constants.
    - `HiveBoxes`: Static access to high-performance local storage.

## 2. Performance & Optimization
- **Database Atomic Operations**: To prevent race conditions, interactions like liking a document use `SECURITY DEFINER` PostgreSQL RPCs (`increment_likes`, `decrement_likes`) instead of direct client-side counter increments.
- **High-Speed Caching**:
    - `Hive`: Used for session persistence and profile metadata, ensuring zero-latency access to user data on startup.
    - `CachedNetworkImage`: Standardized across the app to reduce bandwidth for thumbnails and avatars.
- **Media Optimization**:
    - `flutter_image_compress`: Automatically reduces cover image sizes (Quality 70, 1024px constraints) before upload to Supabase Storage.
    - **10MB Upload Limit**: Enforced in `UploadController` to maintain backend cost-efficiency; users are prompted to use external links (Google Drive/Mega) for larger files.
- **Network Efficiency**:
    - Batch fetching (limit 50) for document feeds.
    - Relational joins performed in single Supabase queries (`select('*, profiles:user_id(...)')`) to minimize round-trips.

## 3. Design & UI/UX Standards
- **Material 3 & Glassmorphism**:
    - Uses the `glassmorphism` package and `AppGradients.glassGradient` for a modern, layered aesthetic.
    - Primary Color: **Premium Deep Blue** (`#0D47A1`).
    - Typography: **Plus Jakarta Sans** (via `google_fonts`).
- **Standardized Loaders**: `Loader` and `Loader2` components (in `lib/view/widgets/loader.dart`) ensure consistent visual feedback during async operations.
- **Lottie Animations**: Integrated for state feedback (e.g., empty search results or success states).
- **Sticky Sort**: The `HomeController` implements a custom sorting algorithm that prioritizes official university documents (`is_official`) followed by chronological order.

## 4. Security & Data Integrity
- **Auth Strategy**: **Supabase Auth (JWT)**. Sessions are managed securely via the SDK, and passwords are never handled as plain text by the application layer.
- **Row Level Security (RLS)**: Strictly enforced in `SUPABASE_SCHEMA.sql`.
    - Users can only `UPDATE` their own profiles and `DELETE` their own documents.
    - Notifications and Bookmarks are isolated per `user_id`.
- **Role-Based Features**: `profiles.is_admin` column enables administrative features:
    - **Official Badge**: Admins can toggle `isOfficial` on documents, styled with gold branding (`#FFD700`).
    - **Global Announcements**: Admins can broadcast messages to all users (`is_global` notifications).
- **Secure Counter Updates**: PostgreSQL functions use `SECURITY DEFINER` to allow users to trigger count changes without having direct write access to the `likes_count` columns.

## 5. Developer Workflow (Zero Warnings Policy)
The project adheres to a strict "Zero Warnings" linting policy verified via `flutter analyze`.
- **Modern API Usage**: Always use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`.
- **Switch Widgets**: Use `activeThumbColor` (not `activeColor`) for modern Flutter compatibility.
- **Flow Control**: All `if/else/for` structures must use explicit curly braces.
- **Empty Catches**: Intentional silent errors must be annotated with `// ignore: empty_catches`.

---
*Maintained by Jules, AI Software Engineer.*
