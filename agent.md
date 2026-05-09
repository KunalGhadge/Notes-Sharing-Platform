# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design paradigm, and security implementation after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## 1. Architecture Overview
Serious Study follows the **GetX MVC** (Model-View-Controller) pattern, ensuring a clean separation between UI components and business logic.

- **Frontend**: Flutter 3.41.2 / Dart 3.11.0 (Stable Feb 2026).
- **State Management**: **GetX** for reactive updates, dependency injection, and routing.
- **Backend**: **Supabase** (PostgreSQL, Auth, Storage, Realtime).
- **Local Persistence**: **Hive** for high-performance NoSQL caching.

### Directory Structure:
- `lib/controller/`: Reactive logic (e.g., `DocumentController`, `AuthController`).
- `lib/model/`: Data structures (e.g., `DocumentModel`, `UserModel`).
- `lib/service/`: Infrastructure services (e.g., `FileCaching`, `NotificationService`).
- `lib/view/`: Modular UI components and screen layouts.
- `lib/core/`: Centralized themes, constants, and helper utilities.

## 2. Performance Analysis
- **Reactive Updates**: GetX controllers manage state independently. UI components use `Obx` or `GetX` builders to react only to relevant data changes.
- **Local Caching**:
    - **Hive**: User profile and metadata are cached in `userBox` to ensure instant loading of the "My Profile" section.
    - **File Caching**: `Dio` is used in `FileCaching` to download and store documents locally in the system's temporary directory, avoiding redundant downloads.
- **Media Optimization**:
    - **Thumbnail Caching**: `cached_network_image` is used throughout the app (e.g., `HomeHeader`) to minimize network usage.
    - **Image Compression**: `flutter_image_compress` is integrated into the upload pipeline (`UploadController`) to reduce asset sizes before storage.
- **Batch Loading**: The `HomeController` fetches updates in batches of 50 to maintain high frame rates during feed scrolling.
- **Sticky Sort**: Implemented in `HomeController` to prioritize "Official" university content at the top of the feed regardless of upload time.

## 3. Design Paradigm
- **Material 3**: The app utilizes the latest Material Design standards for components and transitions.
- **Glassmorphism**: Semi-transparent overlays and custom gradients (`AppGradients.premiumGradient`) create a modern, layered aesthetic.
- **Theme**: "Premium Deep Blue" (`#0D47A1`) with "Plus Jakarta Sans" typeface.
- **User Feedback**:
    - **Shimmers**: Integrated in `HomeDocumentSection` for smooth loading states.
    - **Toasts**: Standardized via the `toastification` package for success, error, and warning alerts.
    - **Loaders**: Custom `Loader` and `Loader2` widgets for consistent progress indication.

## 4. Security Implementation
The platform enforces a robust security model using Supabase's built-in features:

- **Authentication**: JWT-based sessions managed by Supabase Auth.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all tables.
    - **Profiles**: Publicly viewable, but only the owner can update.
    - **Documents**: Anyone can view, but only owners can insert or delete.
    - **Notifications**: Private to the receiver.
- **Atomic Counter Security**: Critical counts (likes, dislikes) are updated via **PostgreSQL RPCs** with `SECURITY DEFINER`. This prevents users from directly editing counter columns and ensures data integrity.
- **File Security**: Documents in Supabase Storage are governed by policies, ensuring only authorized actions are performed on assets.

## 5. Development & QA Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` with no warnings.
- **Modern Standards**:
    - Use `.withValues(alpha: ...)` instead of the deprecated `.withOpacity()`.
    - Use `activeThumbColor` for `Switch` widgets.
    - All flow control structures (if/else/for) must use explicit curly braces.
- **Build Environment**:
    - Flutter: 3.41.2
    - Dart: 3.11.0
    - Android API: 36 (targeting latest compatibility).

---
*Maintained by Jules, AI Software Engineer.*
*Last Updated: February 2026*
