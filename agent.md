# Developer Guide - Serious Study (Mumbai University Community)

This document serves as the comprehensive technical reference for the Serious Study project (formerly NoteHub), detailing its architecture, performance strategies, design principles, and security model from an engineering perspective.

## 1. Core Architecture
The application follows a **Decoupled MVC (Model-View-Controller)** pattern powered by **GetX**.

- **State Management**: Reactive state management is handled via `GetX` (`.obs`, `Obx`, `GetBuilder`). Controllers encapsulate business logic and communicate with the Supabase backend.
- **Dependency Injection**: Controllers are lazily or globally initialized (e.g., `Main.dart` uses `Get.put()` for core services, while views use `Get.put()` or `Get.find()`).
- **Relational Data Model**:
  - `DocumentModel`: Central entity for notes and updates (Tweets).
  - `UserModel`: Profile and activity metadata.
  - `NotificationModel`: Real-time activity tracking.

## 2. Performance & Optimization
Serious Study is optimized for a seamless mobile experience under varying network conditions.

- **Local Persistence (Hive)**:
  - High-performance NoSQL storage via `Hive` for session management and user profile caching (`userBox`).
  - `downloadsBox` tracks local file availability to prevent redundant downloads.
- **Media Optimization Pipeline**:
  - **Image Compression**: `lib/core/helper/image_helper.dart` utilizes `flutter_image_compress` (70% quality, 1024px min dimension) for all cover uploads.
  - **Relational Caching**: `cached_network_image` is used globally with shimmer placeholders to reduce bandwidth.
- **Data Retrieval (Sticky Sort)**:
  - `HomeController` implements a "Sticky Sort" algorithm, prioritizing official university documents (`is_official`) followed by a chronological descent (`created_at`).
  - Relational joins (Profiles, Interactions, Bookmarks) are performed in single Supabase queries to minimize round-trips.
- **Download Management**:
  - `FileDownload` service utilizes `Dio` for chunk-based downloads and integrates with `flutter_local_notifications` to provide real-time progress in the system tray.

## 3. Design System & UX
Built with **Material 3** principles and a custom academic aesthetic.

- **Visual Theme**: "Premium Deep Blue" (`#0D47A1`) and "Plus Jakarta Sans" typography.
- **Glassmorphism**: Extensive use of semi-transparent layers and blur effects via the `glassmorphism` package (e.g., `PostCard` glass overlays).
- **Responsive Standard**: Standardized loaders (`Loader` and `Loader2`) and consistent button components (`PrimaryButton`, `SecondaryButton`) ensure a cohesive UI.
- **Dynamic Content**:
  - `RemoteConfigController`: Subscribes to `public:remote_config` for real-time maintenance flags and global announcements without requiring app updates.
  - `ShowcaseController`: Manages walkthrough states and tutorial sequences for new users.

## 4. Security & Backend (Supabase)
The application leverages a serverless architecture with a focus on data integrity and user privacy.

- **Authentication**: JWT-based session management via Supabase Auth.
- **Row Level Security (RLS)**:
  - **Profiles**: Restricted write access (owner-only); public read.
  - **Documents**: Granular policies ensuring only owners or admins can modify content.
  - **Notifications**: Private to the `receiver_id`.
- **Atomic Operations (RPCs)**:
  - Critical counters (likes, dislikes) are handled via PostgreSQL Functions with `SECURITY DEFINER` (e.g., `increment_likes`). This prevents race conditions and protects underlying data from direct manipulation.
- **Storage Policies**: Supabase Storage buckets for `documents` and `covers` are governed by authenticated-user policies.

## 5. Maintenance & Compliance
- **Zero Warnings Policy**: All code must pass `flutter analyze` with no warnings. Modern APIs (e.g., `.withValues()` instead of `.withOpacity()`) are mandatory.
- **Continuous Integration**: GitHub Actions runs `flutter analyze` and `flutter test` on every pull request.
- **Linting**: Standard `flutter_lints` with additional strictness on flow control (mandatory curly braces) and empty catch block documentation (`// ignore: empty_catches`).

---
*Maintained by Jules, AI Software Engineer.*
