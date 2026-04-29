# Developer Guide & System Manual - Serious Study

This document serves as the exhaustive technical reference for the **Serious Study** (formerly NoteHub) project. It provides a deep-dive analysis of the application's architecture, performance optimizations, design philosophy, and security implementation from an engineering perspective.

## 1. Architectural Overview
Serious Study follows a strictly decoupled **MVC (Model-View-Controller)** pattern facilitated by the **GetX** framework.

- **Frontend**: Flutter 3.41.2 (Stable Channel, Feb 2026)
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **State Management**: Reactive (Obx) using GetX Controllers.
- **Directory Structure**:
    - `lib/controller/`: Business logic, API orchestration, and reactive state.
    - `lib/model/`: Data structures and JSON serialization (e.g., `UserModel`, `DocumentModel`).
    - `lib/view/`: Modular UI components, screens, and custom widgets.
    - `lib/core/`: Application constants, theme configurations, and global helpers.
    - `lib/service/`: Infrastructure-level logic (Notifications, Caching, Downloads).

## 2. Performance Engineering

### 2.1 Data Management & Caching
- **Reactive Feed**: The `HomeController` utilizes Supabase's `onPostgresChanges` real-time listener to provide instant feed updates without manual refreshing.
- **Local Persistence**: **Hive** is utilized for sub-millisecond local data access.
    - `userBox`: Stores `UserModel` to prevent flickering during authentication checks.
    - `downloadsBox`: Tracks local file metadata for offline access.
- **Optimistic UI**: `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks. The UI reflects the change immediately while the backend synchronization happens in the background, with automatic rollback on failure.
- **Batching**: Global feeds are capped at 50 items per fetch to reduce bandwidth and memory pressure.

### 2.2 Media Optimization
- **Mandatory Compression**: The `UploadController` forces all cover images through the `ImageHelper` (using `flutter_image_compress`), reducing quality to 70 and capping dimensions at 1024px.
- **Upload Guards**: A hard 10MB limit is enforced for direct document uploads. For larger files, the system encourages the use of external links (Google Drive/Mega).
- **Network Caching**: `cached_network_image` is standardized across all profile pictures and document covers to eliminate redundant network traffic.

### 2.3 Database Performance
- **Sticky Sort**: The `HomeController` performs a client-side sort that prioritizes `is_official` documents followed by `created_at` timestamps, ensuring verified university content remains at the top.
- **Atomic Counters**: All document interaction counters (likes/dislikes) are managed via PostgreSQL `RPC` functions (`increment_likes`, etc.) to ensure atomicity and prevent race conditions common in client-side increments.

## 3. Design Philosophy (Material 3 & Glassmorphism)
The app adheres to a "Premium Academic" aesthetic:
- **Typography**: Standardized on 'Plus Jakarta Sans' via `google_fonts`.
- **Theming**: Centered around **Premium Deep Blue** (`#0D47A1`).
- **Visual Effects**: Extensive use of the `glassmorphism` package and `BackdropFilter` for navigation bars and overlays.
- **Standardized Loaders**: `Loader` and `Loader2` components provide consistent feedback during asynchronous operations, utilizing `PrimaryColor.shade500`.

## 4. Security & Compliance

### 4.1 Authentication & Authorization
- **JWT-Based Auth**: Leverages Supabase Auth for secure session management.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - `profiles`: Users can only edit their own profile.
    - `documents`: Delete/Update operations require `auth.uid() == user_id`.
    - `notifications`: Visible only to the intended `receiver_id`.
- **Admin Privileges**: Controlled via the `is_admin` column in `profiles`. Admins can broadcast `is_global` notifications and mark documents as `is_official`.

### 4.2 API Security
- **Security Definer RPCs**: Database functions for interaction counters use `SECURITY DEFINER`, allowing specific atomic updates to protected columns without granting users direct write access to the entire `documents` table.
- **Payload Sanitization**: `UploadController` sanitizes filenames and enforces session validation before initiating storage uploads.

## 5. Development Workflow

### 5.1 Standards & Linting
- **Zero Warnings Policy**: All contributions must pass `flutter analyze` without warnings or info-level issues.
- **Modern Flutter**: Use `.withValues(alpha: x)` instead of `.withOpacity(x)` to adhere to the latest Flutter API standards.
- **Flow Control**: Explicit curly braces are required for all flow control structures (`if`, `else`, `for`) even for single-line statements.

### 5.2 Commands
- **Analyze**: `cd notehub && flutter analyze`
- **Test**: `cd notehub && flutter test`
- **Build Runner**: `cd notehub && dart run build_runner build` (required for Hive adapter generation).

---
*Documentation maintained by the Serious Study Engineering Team.*
