# Developer Guide - Serious Study (Mumbai University Community App)

This document provides a comprehensive technical analysis and system manual for the Serious Study project from a developer's perspective. It documents the architecture, performance strategies, design language, and security model.

## 1. System Architecture (GetX MVC)
The application follows a decoupled Model-View-Controller architecture using **GetX** for state management, dependency injection, and routing.

### Core Controllers
- **`AuthController`**: Manages Supabase JWT sessions and local user metadata sync via Hive.
- **`HomeController`**: Handles the main document feed with real-time updates via Supabase Postgrest changes. Implements "Sticky Sort" to prioritize official content.
- **`DocumentController`**: Orchestrates document interactions (Likes, Dislikes, Bookmarks) using optimistic UI updates and PostgreSQL RPCs for atomic counter increments.
- **`UploadController`**: Manages multi-part uploads (Cover + Document). Enforces a **10MB file size limit** for direct uploads and supports external resource links (e.g., Google Drive).
- **`NotificationController`**: Provides real-time activity tracking and administrative broadcasting with global announcement support.
- **`RemoteConfigController`**: Facilitates dynamic app behavior (e.g., Maintenance Mode) via the `remote_config` table.

### Data Models
- **`UserModel`**: Stores profile information, including academic interests and administrative status (`is_admin`). Uses Hive for persistence.
- **`DocumentModel`**: Represents notes and "tweets". Includes metadata for tracking interaction states (`isLiked`, `isBookmarked`) and verification flags (`is_official`).

## 2. Performance Strategy
- **High-Performance Caching**:
    - **Hive**: Used for immediate access to user profiles (`userBox`) and tracking local downloads (`downloadsBox`).
    - **CachedNetworkImage**: Centralized image caching to reduce bandwidth and improve scroll performance.
- **Media Optimization**:
    - **Image Compression**: `ImageHelper` utilizes `flutter_image_compress` with a target quality of **70** and dimensions restricted to **1024x1024** to optimize storage usage.
    - **File Management**: `FileCaching` and `FileDownload` services manage temporary storage and chunk-based downloads via `Dio`.
- **Database Efficiency**:
    - **Atomic Operations**: Critical interactions (likes/dislikes) are handled by server-side RPC functions (`increment_likes`, `decrement_dislikes`) to prevent race conditions.
    - **Batch Fetching**: The feed retrieves 50 items per request to balance initial load time and content availability.
- **UX Fluidity**: Standardized `Shimmer` effects and `Loader` widgets ensure a smooth perception of performance during asynchronous data retrieval.

## 3. Design Language & UI Paradigm
- **Branding**: "Premium Deep Blue" theme (#0D47A1) centered around academic integrity.
- **Typography**: **Plus Jakarta Sans** via `google_fonts` package.
- **Visual Aesthetic**:
    - **Material 3**: Modern component architecture.
    - **Glassmorphism**: Applied to the custom `BottomFooter` and profile overlays using semi-transparent layers and spread shadows.
- **Standardized Feedback**:
    - **Toasts**: Consistent success/error/warning notifications via the `toastification` package with `flatColored` styling.
    - **Animations**: `Lottie` and `flutter_svg` for interactive states and empty feed illustrations.

## 4. Security Model
- **Authentication**: Industry-standard **JWT (JSON Web Tokens)** managed by Supabase Auth. Passwords are never handled in plain text and are hashed via Argon2/Bcrypt.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables:
    - **Profiles**: Only the record owner can perform `UPDATE`.
    - **Documents**: Publicly viewable, but `INSERT` and `DELETE` are restricted to the owner.
    - **Notifications**: Private to the receiver (except for `is_global` announcements).
- **Administrative Integrity**:
    - Sensitive columns like `is_admin` and `is_official` are protected.
    - `is_official` content is distinguished with a gold branding (#B8860B).
- **API Security**: Using `SECURITY DEFINER` on RPC functions allows controlled updates to interaction counters without granting direct write access to sensitive columns.

## 5. Developer Workflow & QA
- **Environment**: Flutter 3.41.2 | Dart 3.11.0.
- **Policy**: **Zero Warnings**. All contributions must pass `flutter analyze` and `flutter test`.
- **Bulk Modernization**: Use `python3` regex scripts for mass API updates (e.g., replacing `.withOpacity()` with `.withValues()`).
- **Real-time Debugging**: Monitor Supabase channels (e.g., `public:documents`) to verify state synchronization across clients.

---
*Maintained and Analyzed by Jules, AI Software Engineer.*
