# Developer Guide & System Manual - Serious Study

This document serves as the definitive technical reference for the **Serious Study** (formerly NoteHub) platform. It provides an exhaustive analysis of the application's architecture, performance optimizations, design philosophy, and security implementation from a developer's perspective.

---

## 1. System Architecture (GetX MVC)

Serious Study utilizes the **GetX** framework to implement a decoupled Model-View-Controller (MVC) architecture, ensuring high maintainability and testability.

### 1.1 Core Components
- **Controllers (`lib/controller/`)**: Manage business logic and reactive state.
  - `AuthController`: Handles Supabase Auth sessions and local Hive profile syncing.
  - `HomeController`: Manages the global feed, real-time subscriptions, and "Sticky Sort" logic.
  - `DocumentController`: Encapsulates interactions (Likes/Dislikes), document lifecycle (CRUD), and optimistic UI updates.
  - `UploadController`: Manages multi-part uploads, 10MB file limits, and external link validation.
  - `NotificationController`: Subscribes to real-time PostgreSQL changes and triggers local system notifications.
  - `RemoteConfigController`: Manages dynamic flags like `maintenance_mode` and `global_announcement`.
- **Views (`lib/view/`)**: Modular UI components. Views are typically wrapped in `Obx` or `GetX` to respond to controller state changes.
- **Models (`lib/model/`)**: Plain Old Dart Objects (PODOs) representing the domain entities (`UserModel`, `DocumentModel`, `NotificationModel`).
- **Services (`lib/service/`)**: Singleton-like classes for low-level operations (`FileDownload`, `FileCaching`, `NotificationService`).

### 1.2 Data Flow
The app follows a unidirectional data flow:
1. **User Interaction**: Triggered in the View.
2. **Controller Logic**: The View calls a method in the Controller.
3. **Optimistic Update**: The Controller updates the local reactive state immediately.
4. **Backend Sync**: The Controller performs an asynchronous call to Supabase (via SDK or RPC).
5. **Finalization**: If the sync fails, the Controller reverts the reactive state and notifies the user via `Toasts`.

---

## 2. Performance Analysis & Optimizations

Performance is a first-class citizen in Serious Study, addressed through both frontend and backend strategies.

### 2.1 Frontend Optimizations
- **Persistent Caching (Hive)**: High-performance NoSQL storage is used in `HiveBoxes` to cache the current user's profile and download metadata. This eliminates "empty states" on app launch.
- **Media Compression**: The `ImageHelper` uses `flutter_image_compress` (quality 70, minWidth/Height 1024) to optimize document covers before upload, significantly reducing cloud storage costs and bandwidth.
- **Lazy Loading & Batching**: The `HomeController` fetches updates in batches of 50, and images are loaded lazily via `cached_network_image`.
- **Sticky Sort**: A custom sorting algorithm in `HomeController` prioritizes verified university documents (`isOfficial`) at the top of the feed, regardless of upload date, ensuring high-quality content visibility.

### 2.2 Backend & Network Optimizations
- **PostgreSQL RPCs**: Heavy logic like counter increments (`increment_likes`, `decrement_dislikes`) is offloaded to the database. This reduces network round-trips and ensures atomicity.
- **Real-time Subscriptions**: Instead of polling, the app uses Supabase Realtime (WebSockets) to listen for `INSERT` events in the `documents` and `notifications` tables.
- **File Offloading**: The `UploadController` supports "External Links," allowing the platform to serve as a metadata hub for large files (hosted on Google Drive/Mega), keeping the core storage usage lean.

---

## 3. Design Philosophy (Material 3 & Glassmorphism)

The visual identity of Serious Study is centered around "Academic Excellence" and "Modernity."

### 3.1 Visual Elements
- **Branding**: The "Premium Deep Blue" (`#0D47A1`) theme is consistently applied via `ThemeData` and `PrimaryColor` classes.
- **Glassmorphism**: Semi-transparent overlays and blurred backgrounds (e.g., in `BottomFooter`) create a layered, premium feel.
- **Typography**: Uses `Plus Jakarta Sans` via Google Fonts for superior readability.
- **Feedback Systems**:
  - **Shimmers**: Standardized `Shimmer` widgets are used for skeleton loaders.
  - **Lottie**: Vector animations handle "Empty Feed" and "Success" states.
  - **Toastification**: A modern toast system with `Alignment.topRight` and `flatColored` style.

### 3.2 UI Components
- **Floating Navigation**: The `BottomFooter` is a custom-designed floating container with interactive icons.
- **Responsive Layout**: Utilizing `ListView` and `shrinkWrap` patterns to ensure compatibility across various screen aspect ratios.

---

## 4. Security & Data Integrity

The migration to Supabase provides enterprise-grade security features.

### 4.1 Authentication & Authorization
- **JWT (JSON Web Tokens)**: All API calls are authenticated via JWTs managed by Supabase Auth.
- **Row Level Security (RLS)**: Strictly enforced in `SUPABASE_SCHEMA.sql`.
  - Users can only `UPDATE` or `DELETE` their own profiles and documents.
  - Public can `SELECT` documents but cannot modify interaction counters directly.
- **Security Definer RPCs**: Database functions (RPCs) are defined with `SECURITY DEFINER`, allowing them to execute with elevated privileges (e.g., updating a protected `likes_count` column) without exposing write access to the client.

### 4.2 Data Validation
- **Upload Guards**: The `UploadController` enforces a 10MB limit for direct file uploads.
- **Session Validation**: Every sensitive operation checks for a valid, non-expired session before proceeding.
- **Sanitization**: Document names and paths are sanitized in the `UploadController` to prevent storage injection or path traversal issues.

---

## 5. Development & Contribution Guidelines

### 5.1 Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` with zero warnings.
- **API Modernization**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`. Use `activeThumbColor` for Switches.
- **Flow Control**: Always use explicit curly braces in `if`, `else`, and `Obx` blocks to satisfy linter constraints.

### 5.2 Verification Commands
```bash
# Verify linting and syntax
cd notehub && flutter analyze

# Run unit and widget tests
cd notehub && flutter test
```

---
*Maintained by Jules, AI Software Engineer. Last Updated: Feb 2026.*
