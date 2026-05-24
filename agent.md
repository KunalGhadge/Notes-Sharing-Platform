# Developer Guide & System Manual - Serious Study

This document serves as the exhaustive technical reference for the **Serious Study** (formerly NoteHub) application. It details the architecture, performance optimizations, design philosophy, and security protocols from an engineering perspective.

## 1. System Architecture
Serious Study is built on a decoupled, serverless architecture utilizing **Flutter** for the frontend and **Supabase** (PostgreSQL) for the backend.

### Core Stack:
- **Frontend**: Flutter 3.5.4+ (Stable)
- **State Management**: **GetX** – Used for reactive state, dependency injection (`Get.put`, `Get.find`), and simplified routing.
- **Local Persistence**: **Hive** – High-performance NoSQL storage for caching user sessions (`userBox`) and tracking offline resources (`downloadsBox`).
- **Backend-as-a-Service**: **Supabase** – Handles Authentication (JWT), Database (PostgreSQL with RLS), Storage (S3-compatible), and Real-time subscriptions.
- **Networking**: **Dio** – Specialized for complex file downloads with progress tracking and chunk-based operations.

---

## 2. Performance Analysis & Optimization

### 2.1 Reactive Data Flow
- **Batching**: The `HomeController` fetches updates in batches of **50** to optimize initial load times and reduce network overhead.
- **Sticky Sort Algorithm**: Implemented in `HomeController.fetchUpdates()`, prioritizing `is_official` documents at the top of the feed followed by chronological order (`created_at`).
- **Optimistic UI Updates**: Interactions (Likes, Dislikes, Bookmarks) in `DocumentController` use optimistic updates to provide immediate feedback. State is reverted only if the Supabase RPC/Update fails.

### 2.2 Storage & Media Efficiency
- **Image Compression**: All document covers are processed through `flutter_image_compress` in the `UploadController` before being transmitted to Supabase Storage, maintaining a quality/size balance (70% quality).
- **File Size Constraints**: Direct uploads are strictly limited to **10MB**. For larger files, the system encourages the use of **External Links** (Google Drive, Mega), reducing cloud storage costs and improving access speed for users.
- **Network Caching**: `CachedNetworkImage` is used universally for avatars and thumbnails to prevent redundant traffic.
- **File Caching**: The `FileCaching` service (`lib/service/file_caching.dart`) checks for existing local files in the system's temporary directory before initiating a re-download.

### 2.3 Database Performance
- **Atomic Counters**: Counter increments (likes/dislikes) are handled via PostgreSQL **RPCs** (`increment_likes`, `decrement_dislikes`). This avoids race conditions inherent in client-side increment logic.
- **Real-time Subscriptions**: Granular filters are applied to Supabase Real-time channels (e.g., in `NotificationController`) to ensure users only receive relevant Postgres changes.

---

## 3. Design Philosophy (UX/UI)

### 3.1 Visual Language
- **Theme**: A "Premium Deep Blue" aesthetic (`#0D47A1`) replaces generic branding to align with the academic integrity of Mumbai University.
- **Glassmorphism**: Applied to the Bottom Navigation Bar and Profile cards using semi-transparent overlays (`.withValues(alpha: 0.15)`) and standard `BackdropFilter` techniques.
- **Standardized Loaders**: The `Loader` and `Loader2` components provide consistent visual feedback for asynchronous operations.

### 3.2 Component Library
- **Toasts**: Centrally managed in `lib/view/widgets/toasts.dart` using the `toastification` package, featuring `Alignment.topRight` and flat-colored styles.
- **Refresher**: Custom `RefresherWidget` wrapping `LiquidPullToRefresh` for a high-quality interaction feel during feed updates.

---

## 4. Security Audit

### 4.1 Authentication & Authorization
- **JWT Management**: Supabase Auth handles all token lifecycle events. Controllers verify the presence of a valid session before allowing write operations.
- **Row Level Security (RLS)**: Enforced on all tables in `SUPABASE_SCHEMA.sql`.
    - **Profiles**: Restricted `UPDATE` policy to `auth.uid() = id`.
    - **Documents**: Restricted `INSERT/DELETE` policy to `auth.uid() = user_id`.
    - **Notifications**: Granular visibility based on `receiver_id` or `is_global` flag.

### 4.2 Data Integrity
- **SECURITY DEFINER RPCs**: Database functions used for counters are defined as `SECURITY DEFINER`. This allows them to run with owner privileges to update protected columns (like `likes_count`) while the table remains read-only for general users.
- **Admin Controls**: The `is_admin` column in `profiles` and `is_official` in `documents` provide a privileged layer for official MU broadcasts and verified content.

---

## 5. Developer Guide & Coding Conventions

### 5.1 Project Structure
```text
lib/
├── controller/ # Reactive business logic (GetX)
├── core/       # Configurations (meta, config, helper)
├── model/      # Data models (JSON serialization)
├── service/    # Standalone services (download, caching, notifications)
└── view/       # UI screens and modular widgets
```

### 5.2 Mandatory Standards
- **Zero Warnings Policy**: All contributions must pass `flutter analyze` and `flutter test`.
- **Modern Color API**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Flow Control**: Braces `{}` are mandatory for all if/else/for/while blocks to ensure readability and prevent logic errors.
- **Error Handling**: Silent catches must be explicitly marked with `// ignore: empty_catches`.
- **Documentation**: New features must include a corresponding update to `agent.md`.

### 5.3 Common Workflows
- **Fetching Data**: Always use `maybeSingle()` for profile lookups to avoid crash on missing records.
- **Notifications**: Local notifications are initialized in `main.dart` and managed via `NotificationService`. Channel ID `notes_channel` is used for all academic updates.

---
*Maintained by Jules, AI Software Engineer.*
*Last Updated: Feb 2026*
