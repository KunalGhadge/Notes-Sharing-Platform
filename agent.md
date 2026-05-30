# Developer Guide & System Manual - Serious Study

This document serves as the authoritative technical reference for the **Serious Study** platform, an academic collaboration ecosystem for the Mumbai University community.

## 1. System Architecture
Serious Study follows a modern, serverless architecture designed for high availability and real-time responsiveness.

- **Frontend**: Flutter (targeting Android/iOS/Web) using the **GetX** MVC-pattern for state management and dependency injection.
- **Backend**: **Supabase** (PostgreSQL) provides managed Authentication, Database, and Object Storage.
- **Local Persistence**: **Hive** for high-speed NoSQL caching of user sessions and metadata.
- **Networking**: Supabase SDK for real-time data and **Dio** for complex file transfers with progress tracking.

## 2. Performance & Optimization Strategy

### 2.1 State Management & UI
- **Reactive Updates**: GetX Obx/GetX widgets ensure that only the necessary parts of the UI are rebuilt when the state changes.
- **Optimistic UI**: Interactions like *Likes*, *Dislikes*, and *Bookmarks* in the `DocumentController` update the local state immediately before syncing with the backend, providing zero-latency feedback.
- **Shimmer Feed**: Standardized placeholders are used during data fetching to improve perceived performance.

### 2.2 Data Fetching & Caching
- **Sticky Sort Algorithm**: Implemented in `HomeController` to prioritize "Official" documents at the top of the feed, followed by chronological ordering.
- **Batching**: Feed results are limited (e.g., 50 per request) to minimize network payload.
- **Media Caching**:
  - `CachedNetworkImage` for thumbnails and profile pictures.
  - `FileCaching` service uses the system's temporary directory to store downloaded documents, preventing redundant downloads.
- **Atomic Operations**: PostgreSQL functions (`RPCs`) like `increment_likes` ensure counter integrity without requiring complex client-side transaction logic.

### 2.3 Media Handling
- **Image Compression**: `ImageHelper` utilizes `flutter_image_compress` to optimize cover images before upload.
- **File Size Enforcement**: A strict **10MB limit** is enforced in the `UploadController` for direct document uploads to manage storage costs and bandwidth.

## 3. Design & Aesthetics
- **Material 3**: Fully integrated with the latest Flutter components.
- **Glassmorphism**: Applied to high-interaction components like the Bottom Navigation Bar (`BottomFooter`) and Profile cards for a premium, layered aesthetic.
- **Theme**: "Premium Deep Blue" (`#0D47A1`) is the core brand color, complemented by a clean, grayscale-focused interface.
- **Feedback**: Integrated `Toastification` for non-intrusive success and error notifications.

## 4. Security & Data Integrity

### 4.1 Authentication
- Managed via **Supabase Auth (JWT)**.
- Passwords are never handled or stored by the application logic; they are managed by Supabase using industry-standard hashing.

### 4.2 Authorization (RLS)
- **Row Level Security (RLS)** is enabled on all tables.
- **Profiles**: Publicly viewable, but only the owner can update.
- **Documents**: Publicly viewable; only owners can delete or modify.
- **Notifications**: Strictly private; only the `receiver_id` can access their data.

### 4.3 Identified Security Risks & Mitigation
- **Flag Manipulation**: Current RLS policies allow document owners to potentially set the `is_official` flag during `INSERT`.
- **Recommendation**: Administrative flags should be handled exclusively via `SECURITY DEFINER` RPCs or restricted via RLS `WITH CHECK` clauses that verify `auth.jwt() ->> 'is_admin'`.
- **RPC Protection**: Critical counters are updated via RPC functions with `SECURITY DEFINER`, allowing the database to perform updates that users are not directly authorized to execute on the table columns.

## 5. Coding Conventions
- **Zero Warnings Policy**: All code must pass `flutter analyze` with zero errors or warnings.
- **Modern Flutter**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Formatting**: Explicit curly braces are required for all flow control structures.
- **Silent Errors**: Intentional empty catch blocks (e.g., for silent background sync) must be annotated with `// ignore: empty_catches`.

---
*Maintained by Jules, Divine Visionary Software Engineer.*
*Last Update: Feb 2026*
