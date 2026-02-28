# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented after the migration to a serverless **Supabase** architecture.

## 1. Performance Analysis

### 1.1 State Management & UI Responsiveness
- **GetX Integration**: The app uses `GetX` for reactive state management. Controllers (e.g., `DocumentController`, `HomeController`) handle business logic and notify the UI via `.obs` variables and `update()` calls.
- **Optimistic UI Updates**: Critical interactions like Likes, Dislikes, and Bookmarks use an optimistic UI pattern. The UI updates immediately before the backend request is finalized, with a rollback mechanism in case of failure (see `DocumentController.toggleLike`).
- **Sticky Feed Logic**: The `HomeController` implements a "sticky" content feature where official documents (marked `is_official`) are prioritized at the top of the feed, followed by chronological updates.

### 1.2 Caching & Media Optimization
- **Local Persistence**: `Hive` is used for high-performance NoSQL storage of user profiles (`user` box) and download metadata (`downloads` box).
- **Network Caching**: `cached_network_image` is used for all remote images (e.g., in `PostCard`) to minimize redundant network requests.
- **File Caching**: The `saveAndOpenFile` service in `file_caching.dart` uses `dio` to download documents to the device's temporary directory (`path_provider`), checking for existing files before re-downloading.
- **Image Compression**: `flutter_image_compress` is integrated into the upload flow to optimize asset sizes before they reach Supabase Storage.

### 1.3 Database Efficiency
- **Relational Joins**: The `AppSearchController` and `DocumentController` fetch relational data (profiles, interactions, bookmarks) in a single Supabase query using PostgreSQL joins to minimize networking overhead.
- **Atomic Operations**: PostgreSQL Functions (`RPCs`) like `increment_likes` and `decrement_likes` ensure atomic updates to counters, preventing race conditions.

## 2. Design & Architecture

### 2.1 UI Paradigm: Glassmorphism & Material 3
- **Aesthetic**: The app implements a **Material 3** foundation with a **Glassmorphism** overlay.
- **Glassmorphic Implementation**: Uses the `GlassmorphicContainer` package combined with `AppGradients.glassGradient` (semi-transparent white) to create modern, layered UI elements, particularly in `PostCard`.
- **Branding**: Utilizes a "Premium Deep Blue" palette (`#0D47A1`) to reflect academic integrity.
- **Typography**: Uses 'Plus Jakarta Sans' (via `google_fonts`) for a clean, professional look.

### 2.2 Core UI Components
- **`PostCard`**: The primary feed component, featuring high-quality image previews, glassmorphic overlays, and integrated interaction buttons.
- **`DocumentCard`**: A list-style component for search results and profile views, supporting official badges and quick-action menus.
- **Shimmer Placeholders**: `shimmer` is used globally to prevent "grey space" and provide visual feedback during data fetching.

### 2.3 Project Structure
- `lib/controller/`: Reactive business logic.
- `lib/view/`: Modular, reusable UI components.
- `lib/service/`: Infrastructure services (Caching, Download, Notifications).
- `lib/core/`: Configuration (Theme, MetaData, Helper utilities).

## 3. Security Analysis

### 3.1 Authentication & Authorization
- **JWT-based Auth**: Migrated to **Supabase Auth**. Sessions are securely managed via JWTs.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - **Profiles**: `auth.uid() = id` ensures users can only edit their own profile.
    - **Documents**: Owners have `ALL` permissions; others have `SELECT` only.
    - **Interactions/Bookmarks**: Private to the specific user via `auth.uid() = user_id`.
- **Admin Security**: `is_admin` boolean in `profiles` is checked via RLS policies to allow official content management.

### 3.2 File Security
- **Signed Storage**: Access to Supabase Storage buckets is governed by policies, preventing unauthorized direct links.
- **Validation**: File uploads are restricted by size (10MB limit) and type in `UploadController`.

## 4. Android Configuration
- **Build Requirements**:
    - `multiDexEnabled true`
    - `coreLibraryDesugaringEnabled true` (with `com.android.tools:desugar_jdk_libs:2.1.4`) to support `flutter_local_notifications`.
    - `compileSdk 36`, `targetSdk 35`.
- **Deep Linking**: Configured for `io.supabase.flutternotehub://login-callback` to handle email confirmation redirects.

## 5. Development & QA
- **Linting**: Strict compliance with `flutter_lints`. Run `flutter analyze` regularly.
    - **Note on Deprecations**: The project uses modern Flutter conventions. Avoid `.withOpacity()`, use `.withValues(alpha: ...)` instead. Avoid `activeColor` in Switches, use `activeThumbColor`.
    - **Formatting**: All flow control structures (if/else) must use curly braces. Empty catch blocks must contain a comment (e.g., `/* silent */`) to pass CI.
- **Testing**: Basic unit and widget tests are located in the `test/` directory.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
