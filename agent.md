# Developer Guide & Technical Analysis - Serious Study (formerly NoteHub)

This document provides a comprehensive technical overview and maintenance guide for the **Serious Study** platform. It documents the architecture, performance optimizations, design paradigms, and security protocols implemented after the migration to a serverless **Supabase** ecosystem.

## 1. System Architecture & Tech Stack

Serious Study utilizes a decoupled, reactive architecture designed for high scalability and real-time community interaction.

- **Frontend**: Flutter 3.5.4+ utilizing the **GetX** MVC pattern for state management, dependency injection, and routing.
- **Backend**: **Supabase** (PostgreSQL) providing Managed Auth (JWT), Real-time Database, and S3-compatible Object Storage.
- **Local Persistence**: **Hive** (NoSQL) for high-performance caching of user sessions and document metadata.
- **Asynchronous Services**:
    - **NotificationService**: Handles background push-like alerts using `flutter_local_notifications`.
    - **FileDownload**: Manages chunk-based file retrieval via `Dio` with real-time notification tray progress updates.

---

## 2. Performance Analysis & Optimization

### 2.1 User Experience (Perceived Performance)
- **Optimistic UI Updates**: The `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks. The UI reflects the change immediately before the Supabase RPC call completes, with automatic reversion on network failure.
- **Sticky Sort Feed**: The `HomeController` fetches updates in batches of 50. It applies a "Sticky Sort" algorithm: `is_official` documents are prioritized at the top, followed by chronological ordering.
- **Visual Feedback**: Standardized `Loader` and `Loader2` components, along with Shimmer effects, ensure a smooth experience during data fetching.

### 2.2 Data & Resource Optimization
- **Aggressive Caching**:
    - User profile metadata (username, ID, profile URL) is cached in Hive's `userBox` for instant dashboard loading.
    - `CachedNetworkImage` is used globally to minimize redundant media fetching.
- **Media Pipeline**: `flutter_image_compress` is integrated into the `UploadController` to reduce cover image sizes (targeting ~70% quality) before storage upload.
- **File Constraints**: Direct uploads are capped at **10MB** to maintain storage efficiency; the UI proactively suggests external links (Google Drive/Mega) for larger resources.

---

## 3. Design Paradigm

### 3.1 Visual Language
- **Theme**: **Premium Deep Blue** (`#0D47A1`) serves as the primary brand color, representing Mumbai University's academic integrity.
- **Aesthetic**: **Glassmorphism** is applied to navigation bars and cards using semi-transparent overlays (`withValues(alpha: 0.15)`) and custom gradients.
- **Typography**: **Plus Jakarta Sans** is the primary typeface, configured with modular scales (Heading 1-8, SubHead, Body 1-4) in `AppTypography`.

### 3.2 Component Library
The UI is built on a library of standardized widgets in `lib/view/widgets/`:
- **Buttons**: `PrimaryButton`, `SecondaryButton`, `NormalButton`, and `OptionButton` for consistent interaction patterns.
- **Feedback**: Custom `Toasts` using the `toastification` package, aligned to `topRight` for non-intrusive alerts.

---

## 4. Security & Data Integrity

### 4.1 Authentication & Authorization
- **JWT Auth**: Secured sessions via Supabase Auth. Passwords are never handled by the application logic and are hashed using Argon2/Bcrypt.
- **Row Level Security (RLS)**: Strictly enforced on all PostgreSQL tables.
    - **Profiles**: Publicly viewable, but `UPDATE` is restricted to the account owner (`auth.uid() = id`).
    - **Documents**: `INSERT`/`DELETE` restricted to the owner (`auth.uid() = user_id`).
    - **Notifications**: Private read-access for the receiver only.

### 4.2 Backend Logic & Atomicity
- **PostgreSQL RPCs**: Critical counters (likes, dislikes) are updated via **SECURITY DEFINER** functions (e.g., `increment_likes`). This prevents "Double Counting" and ensures users cannot directly manipulate count columns.
- **Administrative Control**: The `is_admin` flag in the `profiles` table allows for broadcasting global announcements via the `NotificationController`.

---

## 5. Maintenance & QA

### 5.1 Standards & Conventions
- **Zero Warnings Policy**: All contributions must pass `flutter analyze` without warnings.
- **Version Compatibility**: Target Flutter SDK ^3.5.4.
- **Android Manifest**: Ensure `requestLegacyExternalStorage="true"` is maintained for broad file system compatibility across Android versions.

### 5.2 Verification Workflow
Before submission, ensure the following checks pass:
1. `cd notehub && flutter analyze`
2. `cd notehub && flutter test`
3. Verify Supabase connectivity via `AppMetaData` credentials.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
