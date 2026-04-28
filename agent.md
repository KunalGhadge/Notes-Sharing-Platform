# Developer Guide - Serious Study (NoteHub)

This document provides an exhaustive technical analysis of the Serious Study platform from a developer's perspective, covering performance, design, security, and architectural implementation.

## 1. Architectural Overview
Serious Study follows a **GetX-powered MVC** (Model-View-Controller) architecture, migrated to a serverless **Supabase** backend.

- **Frontend**: Flutter 3.24+ (Stable Channel).
- **State Management**: Reactive state using `GetX` for dependency injection and UI synchronization.
- **Backend**: Supabase (PostgreSQL, Auth, Storage).
- **Local Cache**: Hive (NoSQL) for high-speed persistence of user profiles and download history.

---

## 2. Performance Analysis

### Reactive Data Flow & Batching
- **HomeController**: Optimizes bandwidth by fetching data in batches of 50. It implements a "Sticky Sort" algorithm that prioritizes `is_official` documents followed by chronological order.
- **Real-time Sync**: Uses Supabase Realtime Channels (`public:documents`, `public:notifications`) to push updates instantly without polling.

### Optimization Strategies
- **Media Compression**: The `UploadController` integrates `ImageHelper` (using `flutter_image_compress`) to reduce cover image sizes to ~70% quality before transmission, saving storage and bandwidth.
- **Lazy Loading**: Shimmer placeholders and `CachedNetworkImage` ensure smooth scrolling and immediate visual feedback.
- **Optimistic UI**: Interactions (likes/dislikes/bookmarks) in `DocumentController` update the UI immediately before the backend confirmation. It uses recursive logic to handle mutual exclusivity between likes and dislikes.

### Atomic Database Operations
- Critical counters (likes, dislikes) are not incremented client-side. Instead, they call PostgreSQL **RPC (Remote Procedure Call)** functions (e.g., `increment_likes`, `decrement_dislikes`) to ensure data consistency and prevent race conditions.

---

## 3. Design & UI Implementation

### Premium Academic Aesthetic
- **Color Palette**: Centered on "Premium Deep Blue" (`#0D47A1`) to reflect academic integrity.
- **Glassmorphism**: Implemented using the `glassmorphism` package and custom `AppGradients.glassGradient` for overlays, especially in `PostCard` headers and footers.
- **Material 3**: Fully compliant with M3 guidelines, featuring standardized buttons (`PrimaryButton`, `SecondaryButton`) and responsive layouts.

### User Experience Patterns
- **Standardized Loaders**: `Loader` and `Loader2` components provide consistent feedback across the app.
- **Feedback Systems**: Uses `Toastification` for non-intrusive, styled status alerts (e.g., success, error, warning).
- **Animations**: `Lottie` animations are used for empty states (search, notifications) and success transitions.

---

## 4. Security & Data Integrity

### Authentication (JWT)
- Powered by **Supabase Auth**. Sessions are managed via JSON Web Tokens (JWT).
- Secure registration flows with mandatory university affiliation (`institute: "Mumbai University"`).

### Row Level Security (RLS)
The database enforces granular RLS policies defined in `SUPABASE_SCHEMA.sql`:
- **Profiles**: Publicly viewable, but `UPDATE` is restricted to the owner (`auth.uid() = id`).
- **Documents**: Anyone can read, but only owners or admins (`is_admin: true`) can `DELETE` or `UPDATE`.
- **Notifications**: Strictly private; users can only `SELECT` where `receiver_id = auth.uid()` or `is_global = true`.

### Administrative Safeguards
- **Broadcast System**: `NotificationController` includes a `broadcastAnnouncement` function restricted to users with the `is_admin` flag.
- **Storage Policies**: Files are stored in user-specific paths (`userId/docs/...`), and access is controlled by storage-level RLS.

---

## 5. Service & Networking Layer

### File Management
- **FileDownload**: Integrates `Dio` for chunked downloads and `flutter_local_notifications` for background progress tracking.
- **FileCaching**: Implements a temporary directory caching strategy in `saveAndOpenFile` to prevent redundant downloads of the same resource.

### Notification Service
- Centralized `NotificationService` handles initialization and local display.
- Real-time listeners in `NotificationController` filter for global announcements and user-specific interactions.

---

## 6. Development Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` and `flutter test`.
- **API Modernization**: Use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`.
- **Flow Control**: Explicit curly braces are required for all conditional returns inside `Obx` or build methods.

---
*Documented by Jules, AI Software Engineer (Feb 2026).*
