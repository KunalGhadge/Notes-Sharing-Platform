# Developer Guide & System Manual - Serious Study

This document provides an exhaustive technical analysis and developer manual for the **Serious Study** (formerly NoteHub) mobile application. It is designed to guide AI agents and human developers in maintaining and scaling the platform.

## 1. Architecture & Core Tech Stack
The application follows a reactive **GetX MVC** architecture, ensuring a clean separation between business logic, data models, and UI components.

- **Frontend**: Flutter 3.24+ (SDK ^3.5.4)
- **State Management**: `GetX` for dependency injection, reactive state (`.obs`), and navigation.
- **Local Persistence**: `Hive` for high-performance NoSQL caching (User profile metadata and download history).
- **Backend (Serverless)**: `Supabase` (PostgreSQL, Auth, Storage, and Realtime).
- **Relational Joins**: Performed via Postgrest syntax in controllers (e.g., fetching documents with their profile and interaction data in a single request).

## 2. Performance Optimization
Performance is a core pillar of the Serious Study experience, with several layers of optimization:

- **Media Handling**:
  - **Compression**: `ImageHelper` utilizes `flutter_image_compress` (Quality: 70, minWidth/Height: 1024) to optimize covers before upload.
  - **Caching**: Extensive use of `cached_network_image` to minimize redundant network traffic.
- **Data Flow**:
  - **Batching**: Feed results are limited to 50 items per request in `HomeController`.
  - **Sticky Sort**: Logic in `HomeController` prioritizes official university documents (`is_official`) at the top of the feed, followed by chronological sorting.
  - **Atomic Operations**: Interaction counters (likes/dislikes) are updated via PostgreSQL RPC functions (`increment_likes`, `decrement_likes`) to prevent race conditions and ensure data integrity.
- **Network Efficiency**:
  - A strict **10MB file size limit** is enforced for direct document uploads.
  - **External Link Support**: Users are encouraged to submit Google Drive or Mega links for large resources, reducing cloud storage costs and bandwidth.
- **UI Responsiveness**:
  - **Optimistic UI**: `DocumentController` updates like/bookmark states locally before backend confirmation.
  - **Shimmer Placeholders**: Standardized loading states to reduce perceived latency.

## 3. Design System & UX
Serious Study implements a "Premium Academic" aesthetic using **Material 3** and **Glassmorphism**.

- **Branding**: Primary color is **Premium Deep Blue** (`#0D47A1`). Administrative features use **Premium Gold** (`#FFD700`).
- **Typography**: Primary typeface is **Plus Jakarta Sans** (via `google_fonts`).
- **Visual Effects**:
  - **Glassmorphism**: Implemented via `GlassmorphicContainer` for overlays and cards (e.g., `PostCard` header/footer).
  - **Animations**: `Lottie` animations for state feedback (empty results, success screens).
- **Standardized Components**:
  - `Loader` & `Loader2`: Centralized CircularProgressIndicator wrappers.
  - `Toasts`: Utilizing `toastification` with `flatColored` style and `Alignment.topRight`.
  - `RefresherWidget`: Consistent pull-to-refresh logic using `PrimaryColor.shade500`.

## 4. Security & Data Integrity
The migration from legacy systems to Supabase has introduced a robust, granular security model.

- **Authentication**: JWT-based sessions managed via `Supabase Auth`.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced across all tables in `SUPABASE_SCHEMA.sql`.
  - Profiles: Users can only `UPDATE` their own data.
  - Documents: `INSERT` and `DELETE` restricted to the resource owner.
  - Notifications: Private to the `receiver_id` unless marked `is_global`.
- **API Security**:
  - Counter columns (likes/dislikes) are protected; users cannot direct-write to these. Updates must go through `SECURITY DEFINER` RPC functions.
  - Granular Realtime: Notification streams are filtered by `receiver_id` at the database level.
- **File Security**: Storage buckets utilize RLS policies to prevent unauthorized access to private document paths.

## 5. Developer Instructions & Conventions

### 5.1 Project Setup
- **Dart Version**: `3.11.0` or higher.
- **Android Configuration**: Targets API 36, Java 17, and requires `multiDexEnabled` and `coreLibraryDesugaring`.
- **Pre-commit Checks**: The project enforces a **Zero Warnings** policy. Always run:
  ```bash
  cd notehub && flutter analyze && flutter test
  ```

### 5.2 Coding Conventions
- **Flow Control**: All `if`, `for`, and `while` statements **MUST** use explicit curly braces `{}`.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Switches**: Use `activeThumbColor` instead of `activeColor` for `Switch` widgets.
- **Error Handling**: Use `// ignore: empty_catches` for intentional empty catch blocks to pass linting.
- **Logging**: Avoid `print()` statements; use `debugPrint()` or specialized logging in production.
- **Naming**: Metadata keys and local variables should follow `lowerCamelCase` (e.g., `avatarUrl`, `isExternalLink`).

### 5.3 Database Maintenance
All schema changes must be documented in `SUPABASE_SCHEMA.sql`. When adding new tables, ensure RLS is enabled and appropriate policies are applied immediately.

---
*Maintained by Jules, AI Software Engineer.*
