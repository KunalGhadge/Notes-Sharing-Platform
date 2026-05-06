# Developer Guide - Serious Study (Mumbai University Community App)

This document provides an exhaustive technical analysis and system manual for the Serious Study platform from a developer's perspective. It details the architecture, performance optimizations, design paradigms, and security protocols implemented following the migration to a serverless Supabase architecture.

## 1. Architectural Overview
Serious Study follows the **GetX MVC (Model-View-Controller)** pattern, ensuring a clean separation of concerns and reactive state management.

### Key Components:
- **Controllers (`lib/controller/`)**: Manage business logic and reactive state (e.g., `DocumentController` for notes lifecycle, `AuthController` for session management).
- **Views (`lib/view/`)**: Modular UI components that react to controller state changes using `Obx` or `GetBuilder`.
- **Services (`lib/service/`)**: Handles specialized background tasks such as `FileDownload` (with progress notifications) and `FileCaching`.
- **Core (`lib/core/`)**: Centralized configuration for themes (`color.dart`), typography, and app metadata (`app_meta.dart`).

## 2. Performance Analysis & Optimization
The application is engineered for high performance and low latency in a mobile environment.

### Data Flow & Caching:
- **Local Persistence**: `Hive` is utilized for lightning-fast NoSQL local storage. The `userBox` caches profile metadata (username, ID, profile URL) to enable instant UI hydration on startup.
- **Lazy Loading**: The `HomeController` fetches document updates in batches of 50 to minimize initial network payloads.
- **Sticky Sort**: Implemented in `HomeController` to prioritize official university documents (`is_official`) at the top of the feed while maintaining chronological order for peer-contributed notes.

### Media & Asset Optimization:
- **Image Compression**: `flutter_image_compress` is integrated into the `UploadController` pipeline (via `ImageHelper`). Cover images are automatically compressed (Quality 70, 1024px min dimensions) before being uploaded to Supabase Storage.
- **Thumbnail Caching**: `CachedNetworkImage` is used throughout the app to prevent redundant asset downloads and improve scroll performance.
- **File Size Management**: A strict **10MB limit** is enforced for direct document uploads. Users are encouraged to use external links (Google Drive, Mega) for larger resources to reduce cloud storage costs and bandwidth.

### Interaction Logic:
- **Optimistic UI**: `DocumentController` implements optimistic updates for Likes, Dislikes, and Bookmarks, providing immediate visual feedback before the backend synchronization completes.
- **Atomic Operations**: Critical counters are updated using PostgreSQL RPC functions (`increment_likes`, `decrement_dislikes`) defined in `SUPABASE_SCHEMA.sql` to prevent race conditions and ensure data integrity.

## 3. Design & UI Paradigm
The app implements a modern **Material 3** aesthetic with **Glassmorphism** elements.

- **Branding**: Centered around the **Premium Deep Blue** (#0D47A1) primary color, representing academic integrity.
- **Visual Feedback**:
    - **Shimmer Effects**: Standardized placeholders (`shimmer` package) used during data fetching in feed and search views.
    - **Lottie Animations**: Used for empty states and success feedback.
    - **Glassmorphism**: Semi-transparent overlays (`withValues(alpha: 0.15)`) applied to navigation bars and profile cards.
- **Standardized Widgets**: Custom reusable components like `Loader`, `PrimaryButton`, and `Toasts` (using `toastification`) ensure a consistent UX across all screens.

## 4. Security Protocols
Security is integrated at the database level, moving away from vulnerable client-side logic.

- **Authentication**: Managed via **Supabase Auth (JWT)**. Sessions are securely persisted and refreshed by the SDK.
- **Authorization (Row Level Security)**: Granular RLS policies are enforced on all tables in `SUPABASE_SCHEMA.sql`:
    - **Profiles**: Publicly readable; `UPDATE` restricted to the account owner (`auth.uid() = id`).
    - **Documents**: Publicly readable; `INSERT`/`DELETE` restricted to the owner (`auth.uid() = user_id`).
    - **Notifications**: Strictly private; only the `receiver_id` can `SELECT`.
- **Protected Database Logic**: RPC functions use `SECURITY DEFINER`, allowing users to trigger specific logic (like incrementing a like) without granting them direct write access to sensitive columns.
- **Real-time Security**: `NotificationController` filters real-time PostgreSQL Change channels by `receiver_id` or `is_global` flags to ensure data privacy.

## 5. Development & Quality Standards
The project adheres to a **Zero Warnings** linting policy.

### Verification Commands:
- **Static Analysis**: `cd notehub && flutter analyze` (Must return zero issues).
- **Testing**: `cd notehub && flutter test` (Verifies core integrity).
- **Environment**: Flutter 3.41.2, Dart 3.11.0.

### Code Modernization:
- Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- Use `activeThumbColor` for `Switch` widgets instead of `activeColor`.
- Ensure all flow control structures use explicit curly braces.
- Document intentional empty catch blocks with `// ignore: empty_catches`.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
