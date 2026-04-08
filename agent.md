# Developer Guide & Project Analysis: NoteHub (Serious Study)

This document serves as the primary technical guide for developers working on the NoteHub (Serious Study) project. It outlines the architecture, performance optimizations, design patterns, and security measures implemented in the application.

## 1. Project Overview
NoteHub is a specialized notes-sharing and academic networking platform for the Mumbai University community. It follows a serverless architecture using **Flutter** for the frontend and **Supabase** for the backend.

## 2. Technical Stack
- **Frontend**: Flutter 3.41.2 (Dart 3.11.0)
- **State Management**: GetX (Reactive & Dependency Injection)
- **Database & Auth**: Supabase (PostgreSQL with RLS)
- **Local Caching**: Hive (NoSQL)
- **Media Handling**: Flutter Image Compress & Cached Network Image
- **Networking**: Supabase SDK & Dio

## 3. Architecture Analysis
The project follows a modified MVC pattern facilitated by GetX.

- **Controllers (`lib/controller/`)**: Contain all business logic and reactive state.
  - `DocumentController`: Lifecycle of notes, interactions, and optimistic UI updates.
  - `AuthController`: Session management, profile sync, and persistent login.
  - `NotificationController`: Real-time listeners for PostgreSQL changes.
- **Views (`lib/view/`)**: Modular screens and reusable widgets.
  - Uses `GetBuilder` or `Obx` for fine-grained UI updates.
- **Services (`lib/service/`)**: External integrations (File caching, Notifications).
- **Models (`lib/model/`)**: Data structures with JSON serialization.

## 4. Performance Optimizations
- **Optimistic UI**: Interactions like Liking/Bookmarking (in `DocumentController`) update the UI immediately before the backend sync, providing zero-latency feedback.
- **Atomic Operations (RPCs)**: Critical counters (likes/dislikes) are managed via PostgreSQL Functions (`decrement_likes`, `increment_likes`). This prevents race conditions and ensures data integrity.
- **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm that prioritizes official university documents at the top of the feed regardless of upload time.
- **Media Compression**: All user-uploaded covers are compressed via `ImageHelper` (quality 70, 1024x1024) to reduce bandwidth and storage costs.
- **Local Persistence**: `Hive` stores the primary user profile (`userBox`) to ensure the app feels instant upon launch.

## 5. Design & UI/UX
- **Material 3**: Fully embraces Material 3 components and design principles.
- **Glassmorphism**: Implemented using the `glassmorphism` package for premium-feeling overlays (e.g., in `PostCard`).
- **Typography**: Uses 'Plus Jakarta Sans' via `google_fonts` for a modern, academic aesthetic.
- **Theme**: Centered around a "Premium Deep Blue" (`#0D47A1`) primary color.
- **Loading States**: Shimmer effects (`shimmer` package) and Lottie animations are used to eliminate "blank screen" anxiety.

## 6. Security & Infrastructure
- **Authentication**: JWT-based authentication managed by Supabase. Passwords are never handled in plain text by the application code.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
  - Profiles are public but only editable by the owner.
  - Documents are public but only manageable by the creator or admins.
  - Notifications are strictly private to the receiver.
- **Security Definer RPCs**: Database functions use `SECURITY DEFINER` to perform atomic updates on protected columns (like `likes_count`) without granting direct write access to users.
- **Storage Policies**: Supabase Storage buckets are protected, ensuring only authenticated users can upload documents to their designated folders.

## 7. Development Guidelines
- **Zero Warnings Policy**: Developers must maintain clean static analysis. Run `flutter analyze` before any commit.
- **State Sync**: When updating shared data (e.g., deleting a doc), always trigger updates in related controllers (e.g., `Get.find<HomeController>().fetchUpdates()`).
- **Icon Attributions**: See `notes.txt` for required attributions for FlatIcons and Icons8 assets.

---
*Maintained by the NoteHub Engineering Team.*
