# Serious Study - Comprehensive Developer Analysis (Feb 2026)

This document serves as an exhaustive 'Developer Guide' and 'System Manual' for the Serious Study application. It captures the architectural, design, and security decisions made during the platform's migration and modernization.

## 1. Architectural Overview
Serious Study follows a reactive **MVC (Model-View-Controller)** pattern facilitated by **GetX**.

### 1.1 State Management (GetX)
- **Controllers**: Business logic is decoupled from UI. Key controllers include `HomeController` (feed management), `DocumentController` (interactions), and `AuthController` (session management).
- **Reactivity**: Uses `.obs` for reactive variables, ensuring the UI updates automatically when data changes.
- **Optimistic UI**: Implemented in `DocumentController` for likes, dislikes, and bookmarks. The UI updates immediately, and the backend synchronizes asynchronously, with error handling to revert states if necessary.

### 1.2 Data Persistence (Hive)
- **High Performance**: Uses **Hive** for NoSQL local storage.
- **Caching**:
    - `userBox`: Stores `UserModel` data (username, id, profileUrl) for instant profile loading.
    - `downloadsBox`: Tracks downloaded files locally.
- **Helper**: Centralized access via `lib/core/helper/hive_boxes.dart`.

### 1.3 Networking & Backend (Supabase)
- **Supabase Flutter SDK**: Handles Authentication, Database (PostgreSQL), and Storage.
- **Real-time**: `HomeController` subscribes to the `public:documents` channel to provide live feed updates.
- **Atomic Counters**: Uses PostgreSQL RPCs (`increment_likes`, `decrement_likes`) to ensure thread-safe updates to interaction counts.

---

## 2. Performance & Optimization
- **Batching**: HomeController fetches documents in batches (limit 50) to optimize initial load times.
- **Sticky Sort**: The feed prioritizes 'official' documents at the top using a custom sorting algorithm.
- **Media Optimization**:
    - **Compression**: `ImageHelper` uses `flutter_image_compress` to reduce cover image sizes before upload.
    - **10MB Limit**: `UploadController` enforces a 10MB limit for direct document uploads, encouraging external link usage (Google Drive/Mega) for larger files.
    - **Image Caching**: `CachedNetworkImage` is used globally to prevent redundant thumbnail downloads.
- **File Downloads**: `FileDownload` service uses `Dio` for chunked downloads and integrates with `flutter_local_notifications` for real-time progress updates in the Android tray.

---

## 3. Design & UI/UX
- **Design System**: Built on **Material 3** with a custom **Glassmorphism** aesthetic.
- **Theme**: Centered around **Premium Deep Blue** (`#0D47A1`).
- **Modernization (Feb 2026)**:
    - Deprecated `.withOpacity()` replaced with `.withValues(alpha: ...)`.
    - Switches updated to use `activeThumbColor` for compliance with Flutter 3.41.2+.
- **Components**:
    - `DocumentCard`: A modular widget with support for different post types ('note' vs 'tweet') and official branding.
    - `BottomFooter`: A custom floating navigation bar with rounded corners and shadows for a premium feel.
    - `Loader`: Standardized loading indicators (CircularProgressIndicator wrappers).

---

## 4. Security & Data Integrity
- **Authentication**: JWT-based session management via **Supabase Auth**.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - Users can only modify their own profiles and documents.
    - Notifications and bookmarks are private to the owner.
- **Security Definer RPCs**: Database functions (RPCs) are used for sensitive operations (like updating counters) to prevent users from having direct write access to critical columns.
- **File Security**: Storage bucket policies ensure that only owners can delete their files, while public access is governed by Supabase Storage RLS.

---

## 5. Development Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` without errors or warnings.
- **Coding Conventions**:
    - Use explicit curly braces for all flow control structures.
    - Handle silent errors with `// ignore: empty_catches` within catch blocks.
    - Centralize metadata in `AppMetaData` and theme configurations in `lib/core/config/`.
- **Android Manifest**:
    - Namespace: `com.divinevisionary.notehub`.
    - Permissions: INTERNET, READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE, MANAGE_EXTERNAL_STORAGE.
    - Legacy storage enabled: `android:requestLegacyExternalStorage="true"`.

---
*Documented by Jules, AI Software Engineer (Feb 2026).*
