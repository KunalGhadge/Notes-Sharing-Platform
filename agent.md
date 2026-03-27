# Developer Guide - Serious Study (Mumbai University Community App)

This document provides a comprehensive technical analysis of the Serious Study (formerly NoteHub) project. It serves as the primary reference for developers to understand the architecture, performance optimizations, security protocols, and coding conventions of the platform.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform designed specifically for the Mumbai University student community. The application utilizes a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 2. Architecture: GetX MVC & Serverless Supabase
The application follows a decoupled **Model-View-Controller (MVC)** pattern powered by **GetX** for reactive state management and dependency injection.

- **Frontend**: Flutter 3.41.2 (Channel stable, SDK ^3.5.4).
- **Backend**: Supabase (PostgreSQL with Row Level Security).
- **Controllers**: Located in `lib/controller/`, these manage business logic and interact with the Supabase client.
- **Services**: Located in `lib/service/`, these handle infrastructure concerns like local notifications and file caching.

## 3. Performance Analysis & Optimizations

### 3.1 Data Persistence & Caching
- **Hive NoSQL**: Used for high-speed local persistence.
    - `userBox`: Stores the current user's profile metadata to ensure immediate UI responsiveness on startup.
    - `downloadsBox`: Manages metadata for offline-accessible documents.
- **Image Caching**: `cached_network_image` is used throughout the UI to minimize redundant network requests for thumbnails and profile pictures.

### 3.2 Media Handling
- **Compression**: The `UploadController` utilizes `ImageHelper` (wrapping `flutter_image_compress`) to reduce cover image sizes (quality 70, minWidth/Height 1024) before they are uploaded to Supabase Storage.
- **Transfer Efficiency**: Documents are capped at a **10MB direct upload limit** to manage storage costs and transfer times. Users are encouraged to use external links (Google Drive/Mega) for larger files.

### 3.3 UI Responsiveness
- **Optimistic UI**: The `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks. The UI reflects the change immediately, and background synchronization is handled via atomic RPC calls.
- **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm that prioritizes official university documents at the top of the feed, followed by the latest community contributions.
- **Batch Loading**: The feed fetches documents in batches of 50 to optimize initial load times and reduce bandwidth consumption.

## 4. Security & Data Integrity

### 4.1 Authentication
- **JWT-based Auth**: Migrated from legacy systems to **Supabase Auth**. Sessions are securely managed with JSON Web Tokens.
- **Deep Linking**: Configured in `AndroidManifest.xml` with the `io.supabase.flutternotehub` scheme to support secure login callbacks.

### 4.2 Row Level Security (RLS)
The database schema (`SUPABASE_SCHEMA.sql`) enforces strict RLS policies:
- **Profiles**: Publicly readable, but only the owner can `UPDATE` their metadata.
- **Documents**: Publicly readable; `INSERT` and `DELETE` operations are restricted to the document owner.
- **Notifications**: Users can only `SELECT` notifications where they are the `receiver_id`.

### 4.3 Atomic Interactions
- **RPC Functions**: Interactions like `increment_likes` are handled via PostgreSQL functions (`SECURITY DEFINER`). This prevents race conditions and ensures that users cannot directly manipulate protected counter columns without authorization.

## 5. Design & UI Paradigm

### 5.1 Aesthetic
- **Material 3**: The app adheres to the latest Material Design standards.
- **Glassmorphism**: Implemented using the `glassmorphism` package and custom gradients (`AppGradients.glassGradient`) for a modern, academic feel.
- **Typography**: Uses 'Plus Jakarta Sans' via the `google_fonts` package.
- **Branding**: Centered around "Premium Deep Blue" (#0D47A1).

### 5.2 Feedback & Animations
- **Lottie**: Used for empty states and search feedback.
- **Shimmer**: Placeholder loading states are used in `HomeDocumentSection` to eliminate "grey space" during data fetching.
- **Toasts**: Standardized notifications using the `toastification` package with a flat-colored style aligned to the top-right.

## 6. Coding Conventions & Dev Workflow

- **Zero Warning Policy**: All contributions must pass `flutter analyze` with no errors, warnings, or info-level lints.
- **Modern APIs**: Use `.withValues(alpha: ...)` instead of the deprecated `.withOpacity()`.
- **Flow Control**: All `if`, `for`, and `while` statements must be enclosed in curly braces.
- **Error Handling**: Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.
- **CI/CD**: GitHub Actions run `flutter analyze` and `flutter test` on every PR.

---
*Maintained by the Divine Visionary Team. Last technical audit by Jules, AI Software Engineer.*
