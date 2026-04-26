# Developer Guide & System Manual - Serious Study

This document serves as the authoritative technical reference and developer guide for the **Serious Study** (formerly NoteHub) project. It provides an exhaustive analysis of the application's architecture, performance optimizations, design philosophy, and security protocols from a developer's perspective.

---

## 1. Architectural Overview
Serious Study is built using the **GetX MVC (Model-View-Controller)** pattern, ensuring a clean separation of concerns and reactive state management.

- **Frontend**: Flutter 3.41.2 (Stable Channel) / Dart 3.11.0.
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime).
- **State Management**: Reactive programming via `GetX` (Obx, GetBuilder).
- **Local Persistence**: `Hive` for high-performance NoSQL local caching.
- **Navigation**: GetX routing and dependency injection.

### Directory Structure
- `lib/controller/`: Business logic and reactive state.
- `lib/core/`: Global configurations, themes, and helper utilities.
- `lib/model/`: Data structures and serialization logic.
- `lib/service/`: Infrastructure services (Downloads, Notifications, Caching).
- `lib/view/`: UI components and modular screens.

---

## 2. Performance Optimizations
The application is engineered for speed and efficiency, particularly for students in low-bandwidth environments.

### Media & Storage
- **Image Compression**: Mandatory compression using `flutter_image_compress` in `ImageHelper` (quality: 70, minWidth/Height: 1024) before upload.
- **Hybrid Uploads**: Supports direct file uploads (10MB limit) and external link submissions (Google Drive, Mega) to scale storage without increasing cloud costs.
- **Caching Strategy**: Uses `cached_network_image` for thumbnails and `Hive` for persistent profile caching (`userBox`).

### Data Flow
- **Sticky Sort**: The `HomeController` prioritizes official university documents at the top of the feed using a custom sorting algorithm (`isOfficial DESC, created_at DESC`).
- **Batching**: Feed updates are fetched in batches of 50 to minimize payload size.
- **Optimistic UI**: Interactions like likes, dislikes, and bookmarks provide immediate visual feedback before synchronizing with the backend.

### Real-time Sync
- Uses Supabase `RealtimeChannel` to subscribe to PostgreSQL changes (documents, notifications, remote config), ensuring the feed is always up-to-date without manual refreshes.

---

## 3. Design & UI/UX Philosophy
Serious Study implements a **Premium Academic Aesthetic** using **Material 3** principles.

- **Theme**: "Premium Deep Blue" (`#0D47A1`) primary color with gold accents (`#FFD700`) for official/admin content.
- **Typography**: 'Plus Jakarta Sans' via `google_fonts`.
- **Glassmorphism**: Semi-transparent overlays and `GlassmorphicContainer` (blur: 10) are used in `PostCard` and the navigation footer.
- **Interaction Design**:
    - `LiquidPullToRefresh` for intuitive updates.
    - `Lottie` animations for state feedback (e.g., empty searches).
    - `Toastification` for standardized, non-intrusive alerts.

---

## 4. Security Infrastructure
The application follows a "Zero Trust" model for database interactions.

### Authentication
- Fully integrated with **Supabase Auth (JWT)**.
- Local session synchronization via Hive `userBox` to prevent redundant login prompts.

### Database Security (RLS)
- **Row Level Security (RLS)**: Enforced on all tables in `SUPABASE_SCHEMA.sql`.
- **Granular Policies**:
    - Users can only update their own profiles.
    - Only owners (or admins) can delete/update documents.
    - Notifications and bookmarks are private to the receiver.
- **Security Definer RPCs**: Counters (likes/dislikes) are updated via PostgreSQL functions using `SECURITY DEFINER`, allowing atomic increments without granting users direct write access to sensitive columns.

### Administrative Controls
- **is_admin Flag**: Controlled via the `profiles` table to enable broadcasting (`broadcastAnnouncement`) and official tagging.
- **is_official Toggle**: Visually distinguished in the `UploadForm` with a gold theme, restricted to administrative users.

---

## 5. Developer Guidelines & Compliance
To maintain the project's high standards, all developers must adhere to the following:

- **Zero Warnings Policy**: Code must pass `flutter analyze` with zero errors or warnings.
- **Modern API Usage**: Always use `.withValues(alpha: x)` instead of `.withOpacity(x)` and `activeThumbColor` for `Switch` widgets.
- **Flow Control**: All `if/else` and `for` loops must use explicit curly braces (`curly_braces_in_flow_control_structures`).
- **Error Handling**: Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.
- **Testing**: Run `flutter test` before every commit to ensure no regressions in the core logic.

---
*Maintained by Jules, AI Software Engineer.*
*Last Updated: Feb 2026*
