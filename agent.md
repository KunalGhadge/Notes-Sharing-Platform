# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It serves as the definitive guide for understanding the application's performance optimizations, design architecture, and security model.

## 1. Performance Analysis & Optimization

### Reactive State Management
The application utilizes **GetX** for high-performance reactive state management. Business logic is strictly decoupled from the UI in controllers (e.g., `DocumentController`, `HomeController`), ensuring efficient, targeted updates without unnecessary widget rebuilds.

### Optimistic UI Pattern
To provide a seamless user experience, the `DocumentController` implements an **Optimistic UI** pattern for high-frequency interactions:
- **Likes, Dislikes, and Bookmarks**: UI state is updated immediately upon user interaction.
- **Backend Sync**: Synchronization with Supabase is performed in the background using atomic PostgreSQL RPC calls (e.g., `increment_likes`, `decrement_dislikes`).
- **Error Handling**: If a network or database error occurs, the UI state is gracefully reverted to its original value.

### High-Performance Local Caching
- **Hive**: A lightweight NoSQL database used for local persistence. User profiles (`UserModel`) and session metadata are stored in Hive boxes (e.g., `userBox`), ensuring the "My Profile" tab and other personalized sections load instantly upon app launch.
- **File Caching**: The `FileCaching` service uses `Dio` and `path_provider` to cache downloaded documents locally, preventing redundant network transfers for previously viewed resources.

### Media & Bandwidth Optimization
- **Centralized Image Compression**: Integrated into the upload pipeline via `lib/core/helper/image_helper.dart`. It uses `flutter_image_compress` to optimize thumbnails before they reach Supabase Storage (target quality: 70%, min dimensions: 1024px).
- **Network Image Caching**: `CachedNetworkImage` is used throughout the UI to manage image memory and disk caching automatically.
- **Upload Limits**: Direct document uploads are capped at 10MB in `UploadController` to maintain free-tier limits and encourage the use of external links (Google Drive/Mega) for heavy assets.

---

## 2. Design & Architecture

### Visual Identity
- **Material 3**: The app is built on Material 3 principles, offering a modern, clean, and accessible UI.
- **Glassmorphism**: A "premium" aesthetic is achieved using semi-transparent containers, blur effects, and custom gradients (`AppGradients.glassGradient`). This is particularly evident in the `PostCard` components.
- **Branding**: The theme is centered around "Premium Deep Blue" (`#0D47A1`) with "Plus Jakarta Sans" typography.

### Modular Codebase Structure
- **`lib/controller/`**: Reactive business logic and dependency injection.
- **`lib/model/`**: Strongly typed data structures, including Hive adapters for local storage.
- **`lib/view/`**: Modular UI components organized by feature (Auth, Home, Document, Profile, etc.).
- **`lib/service/`**: Reusable system services for notifications, downloads, and caching.

---

## 3. Security Model (Supabase)

The platform leverages a serverless architecture with Supabase, providing enterprise-grade security:

### Authentication & Authorization
- **JWT (JSON Web Tokens)**: Secure, stateless authentication managed by Supabase Auth.
- **Row Level Security (RLS)**: The database schema (`SUPABASE_SCHEMA.sql`) enforces granular access control:
    - **Profiles**: Publicly viewable, but only the owner can `UPDATE`.
    - **Documents**: Owners have full CRUD; others have read-only access.
    - **Interactions/Bookmarks**: Strictly private to the owning user.

### Atomic Integrity
- **RPC Functions**: Counter-based interactions (likes, dislikes) are handled via PostgreSQL functions defined with `SECURITY DEFINER`. This allows the application to update protected counters atomically without granting users direct write access to sensitive table columns.

### Storage Security
- Access to Supabase Storage buckets (e.g., `documents`) is governed by policies that restrict file deletion and updates to the original uploader.

---

## 4. Development & CI/CD

### Environment Requirements
- **Flutter SDK**: ^3.11.0
- **Android**:
    - `compileSdk 36`, `targetSdk 36`.
    - `multiDexEnabled true` and `coreLibraryDesugaringEnabled true` are mandatory.
    - Uses stable AndroidX libraries forced via `resolutionStrategy` in `build.gradle`.

### Code Quality & Linting
- **Zero Warnings Policy**: The project enforces strict linting via `flutter analyze`.
- **CI Workflows**: GitHub Actions (`dart.yml`, `flutter-build.yml`) verify every commit for analysis errors and successful builds.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
