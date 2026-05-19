# Developer Guide & System Manual - Serious Study

This document serves as the exhaustive technical reference for **Serious Study** (formerly NoteHub), a community-driven academic platform for Mumbai University students. It details the architecture, performance optimizations, design philosophy, and security protocols from a developer's perspective.

## 1. System Architecture
Serious Study utilizes a decoupled, serverless architecture that prioritizes real-time reactivity and local-first responsiveness.

- **Frontend (Flutter)**: Built with Flutter 3.41.2 (SDK 3.11.0), utilizing **GetX** for high-performance reactive state management and dependency injection.
- **State Management**: Logic is encapsulated in specialized controllers (e.g., `DocumentController`, `UploadController`) which are lazily injected.
- **Backend (Supabase)**: A serverless PostgreSQL backend providing managed Authentication (JWT), real-time Database changes (Postgres Changes), and Object Storage.
- **Local Persistence (Hive)**: A high-performance NoSQL database used for caching user sessions (`userBox`) and tracking local downloads (`downloadsBox`).

## 2. Performance Optimizations

### 2.1 Content Discovery & Delivery
- **Sticky Sort Algorithm**: Implemented in `HomeController.fetchUpdates()`, this algorithm prioritizes `is_official` documents at the top of the feed regardless of their chronological order, ensuring critical academic updates are always visible.
- **Lazy Loading & Batching**: Feed results are limited to 50 items per request, with specialized views like `Official Page` fetching targeted subsets (20 items).
- **Shimmer UI**: Standardized shimmer placeholders (e.g., in `HomeDocumentSection`) ensure a smooth perceived performance during asynchronous data fetching.

### 2.2 Media & Resource Management
- **Image Compression**: `flutter_image_compress` is integrated into the `UploadController`. All cover images are compressed (quality: 70) before being uploaded to Supabase Storage via the `ImageHelper`.
- **Thumbnail Caching**: The application utilizes `cached_network_image` to minimize redundant network calls for document covers and user profiles.
- **10MB Upload Limit**: To maintain infrastructure sustainability, `UploadController` enforces a 10MB limit for direct file uploads, encouraging the use of external links (Google Drive/Mega) for larger resources.
- **File Caching**: The `FileCaching` service (using `Dio`) checks for existing local files in the system's temporary directory before initiating a re-download.

### 2.3 Database Performance
- **Atomic Operations (RPCs)**: Critical counters (likes, dislikes) are updated via PostgreSQL `SECURITY DEFINER` functions (e.g., `increment_likes`). This prevents client-side race conditions and ensures data integrity.
- **Optimistic UI Updates**: Interactions like likes, dislikes, and bookmarks are applied optimistically in the `DocumentController` to provide instant feedback before backend synchronization.

## 3. Design Philosophy & UI Patterns
The application adheres to a "Premium Academic" aesthetic, combining professional integrity with modern UI trends.

- **Theming**: Rebranded with **Premium Deep Blue** (`#0D47A1`).
- **Glassmorphism**: Applied to the custom floating navigation bar (`BottomFooter`) and profile cards using semi-transparent overlays (`.withValues(alpha: 0.15)`) and spread shadows.
- **Material 3**: Fully adopted across all widgets, including modern Switches (using `activeThumbColor`) and standardized Buttons.
- **Feedback Mechanisms**:
    - **Lottie Animations**: Used for empty states and successful uploads.
    - **Toastification**: Standardized toast notifications with `flatColored` style and `topRight` alignment.
    - **Loaders**: Standardized `Loader` and `Loader2` components wrap `CircularProgressIndicator` for consistent loading states.

## 4. Security & Data Integrity

### 4.1 Authentication & Authorization
- **Managed Auth**: Supabase Auth (JWT) handles all session management. Passwords are never stored or processed in plain text by the application.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - **Profiles**: `UPDATE` restricted to `auth.uid() = id`.
    - **Documents**: `INSERT`/`DELETE` restricted to `auth.uid() = user_id`.
    - **Notifications**: Private read access only for the `receiver_id`.
- **Security Definer Functions**: By using `SECURITY DEFINER` on PostgreSQL RPCs, the app allows users to trigger atomic counter increments without granting them direct write access to protected columns.

### 4.2 Content Governance
- **Administrative Roles**: The `profiles` table includes an `is_admin` flag. Admins can broadcast global announcements and tag content as `official`.
- **Granular Real-time Security**: `NotificationController` applies `receiver_id` and `is_global` filters on PostgreSQL Change channels to ensure users only receive relevant notifications.

## 5. Developer Workflow & Quality Assurance
- **Zero Warnings Policy**: The repository strictly enforces a zero-warning policy. All linting issues (e.g., modernizing `.withValues()`, `activeThumbColor`, and curly braces in flow control) must be resolved.
- **Validation**:
    - Linting: `flutter analyze`
    - Testing: `flutter test`
- **Environment**: Development is standardized on Flutter 3.41.2 and Dart 3.11.0 (Feb 2026 stable).

---
*Documented and Verified by Jules, AI Software Engineer.*
