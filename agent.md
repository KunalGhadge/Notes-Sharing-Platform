# Developer Guide & System Manual - Serious Study

This document provides an exhaustive technical analysis of the Serious Study (Mumbai University Community App) from a developer's perspective, covering performance, design, and security.

## 1. Project Architecture
The application is built using **Flutter** and follows a decoupled **GetX MVC** architecture.

- **State Management**: `GetX` is used for reactive UI updates and dependency injection.
- **Backend**: **Supabase** (Serverless) providing PostgreSQL database, JWT Authentication, and S3-compatible Storage.
- **Local Persistence**: `Hive` for high-performance NoSQL local caching.
- **Project Structure**:
    - `lib/controller/`: Business logic and reactive state management.
    - `lib/core/`: Configuration, theme constants, and helper utilities.
    - `lib/model/`: Data models with serialization logic.
    - `lib/service/`: Low-level infrastructure services (Downloads, Notifications).
    - `lib/view/`: UI components and screens.

## 2. Performance Analysis
Serious Study implements several strategies to ensure a fluid experience even with high content volume:

- **Batch Data Fetching**: `HomeController` fetches updates in batches of 50 to minimize initial payload and network overhead.
- **Sticky Sort**: The feed prioritizes "Official" university documents using a specialized sorting algorithm (Official status -> Upload date).
- **Media Optimization**:
    - **Image Compression**: Mandatory compression using `flutter_image_compress` (70% quality, 1024x1024 min dimensions) for all cover images before upload.
    - **Caching**: `cached_network_image` prevents redundant thumbnail downloads.
- **Direct Link Support**: `UploadController` allows submitting external links (Google Drive, Mega) to scale storage without incurring cloud costs.
- **Atomic Backend Operations**: Interaction counts (likes/dislikes) are handled via **PostgreSQL RPCs** to prevent race conditions and ensure 100% data integrity.
- **Optimistic UI**: `DocumentController` implements optimistic updates for likes and bookmarks, providing instant feedback while syncing with Supabase in the background.

## 3. Design & UX Paradigm
The app adheres to **Material 3** principles with a modern **Glassmorphism** aesthetic.

- **Typography**: Uses 'Plus Jakarta Sans' via `google_fonts` for a premium academic look.
- **Visuals**:
    - **Glassmorphism**: Implemented using `GlassmorphicContainer` for overlays and `PostCard` headers.
    - **Animations**: `Lottie` for state transitions (Loading, Success, Empty states).
    - **Consistency**: Standardized `Loader` components across all asynchronous views.
- **Branding**: Centered around a "Premium Deep Blue" (`#0D47A1`) theme.

## 4. Security & Data Integrity
The migration to Supabase introduces a robust security model:

- **Authentication**: JWT-based session management via Supabase Auth.
- **Authorization (RLS)**: **Row Level Security** policies are enforced on all PostgreSQL tables.
    - Users can only modify their own profiles and documents.
    - Notifications and Bookmarks are isolated per user.
- **API Security**:
    - Critical counter updates are restricted via `SECURITY DEFINER` RPC functions.
    - Storage buckets (e.g., 'documents') are protected by granular policies.
- **Real-time Security**: `NotificationController` filters real-time PostgreSQL changes by `receiver_id` or `is_global` flags at the database level.
- **Administrative Control**: The schema includes an `is_admin` flag in `profiles` to enable features like "Official Content" broadcasting and document verification.

## 5. Development Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` with no warnings or informational issues.
- **Modern APIs**: Mandatory use of `.withValues(alpha: x)` over the deprecated `.withOpacity(x)`.
- **Flow Control**: Explicit curly braces are required for all conditional structures.
- **Error Handling**: Silent catches must be explicitly annotated with `// ignore: empty_catches`.

---
*Maintained by the AI Engineering Team (Divine Visionary).*
