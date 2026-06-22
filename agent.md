# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective, covering performance, design, and security.

## 1. Performance Analysis

### Reactive State Management (GetX)
- **Architecture**: The app utilizes the GetX MVC pattern. Controllers (e.g., `DocumentController`, `HomeController`, `ProfileController`) manage business logic and state reactively, ensuring that the UI updates immediately when data changes.
- **Dependency Injection**: Controllers are lazily or permanently put into memory using `Get.put()` or `Get.lazyPut()`, optimizing resource usage.

### Local Data Persistence & Caching
- **Hive NoSQL**: High-performance local storage is managed via `HiveBoxes` (`lib/core/helper/hive_boxes.dart`).
  - `userBox`: Stores `UserModel` data (ID, username, profile URL) for instant session recovery and "My Profile" rendering without network delay.
  - `downloadsBox`: Tracks downloaded documents for offline access.
- **Media Caching**: `cached_network_image` is used throughout the app (e.g., in `HomeHeader`) to minimize redundant network requests and provide a smooth scrolling experience.

### Database & Network Optimization
- **Atomic Counter Updates**: To prevent race conditions and ensure data consistency, interactions like likes, dislikes, and bookmarks are handled via PostgreSQL RPCs (`increment_likes`, `decrement_likes`, etc.) as defined in `SUPABASE_SCHEMA.sql`.
- **Optimistic UI**: `DocumentController` implements optimistic updates for user interactions. The UI reflects the change immediately while the backend synchronization happens asynchronously.
- **Batching & Sorting**:
  - `HomeController` fetches documents in batches (limit 50) to balance responsiveness and network utilization.
  - **Sticky Sort Algorithm**: Official documents are prioritized at the top of the feed using a custom sort logic: `is_official DESC, created_at DESC`.

### Media Pipeline
- **Compression**: `UploadController` utilizes `ImageHelper` (wrapping `flutter_image_compress`) to automatically compress cover images to 70% quality before upload.
- **Resource Constraints**: Direct document uploads are enforced with a 10MB limit to manage storage costs and transfer times. Users are encouraged to use external links (Google Drive/Mega) for larger files.

## 2. Design & Architecture

### UI/UX Paradigm
- **Material 3**: The app adheres to modern Material 3 standards, featuring rounded components and standardized elevation.
- **Glassmorphism**: A premium aesthetic is achieved using the `glassmorphism` package and custom semi-transparent overlays (e.g., `.withValues(alpha: 0.15)`), particularly in the `BottomFooter` and profile cards.
- **Visual Feedback**:
  - **Shimmer**: Used in `HomeDocumentSection` to provide graceful loading states.
  - **Lottie**: Custom animations are used for empty states and search results to maintain user engagement.
  - **Liquid Pull to Refresh**: Enhances the feed refresh experience.

### Branding & Typography
- **Premium Deep Blue**: The brand identity is anchored by `#0D47A1` (`PrimaryColor.shade500`), representing academic integrity.
- **Typography**: "Plus Jakarta Sans" is used as the primary typeface for headings and UI text, providing a clean, modern look.

### Code Organization
- `lib/controller/`: Reactive business logic.
- `lib/view/`: Modularized UI screens and reusable widgets.
- `lib/core/`: Global configurations, theme definitions, and helper utilities.
- `lib/service/`: Specialized services for notifications, file caching, and downloads.

## 3. Security Analysis

### Authentication & Authorization
- **Supabase Auth**: Managed JWT-based authentication ensures secure session management.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
  - Users can only `UPDATE` their own profiles.
  - Users can only `DELETE` their own documents.
  - Interactions (likes/bookmarks) are scoped to the authenticated user's ID.

### Administrative Integrity
- **Privilege Escalation Prevention**: The `is_official` flag on documents can only be set by users with `is_admin = true` in their profile. This is enforced via the `ensure_official_permission` trigger in PostgreSQL.
- **Secure RPCs**: Counter functions are defined with `SECURITY DEFINER` and explicit `search_path` settings to allow atomic updates without exposing raw table access.

### Data Privacy
- **Bucket Policies**: Supabase Storage buckets (e.g., `documents`) are governed by policies that restrict file deletion to the original uploader while allowing public read access for community sharing.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
