# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It serves as the authoritative guide for the application's architecture, performance optimizations, and security protocols.

## Project Overview
Serious Study is a premium academic community platform tailored for Mumbai University students. It enables seamless notes sharing, academic networking, and real-time updates. The platform utilizes a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 1. Technical Architecture
The application follows a reactive MVC pattern powered by **GetX**, ensuring a clear separation between business logic and the UI.

- **Frontend**: Flutter 3.41.2 (Stable Channel) with Dart SDK ^3.5.4.
- **Backend**: Supabase (PostgreSQL with RLS, Storage, Auth, and Real-time).
- **State Management**: GetX (Controllers, Reactive variables, Dependency Injection).
- **Local Persistence**: **Hive** for high-performance NoSQL caching of user sessions and metadata.
- **Networking**: Supabase Flutter SDK for database/auth and **Dio** for advanced file operations.

## 2. Performance Analysis & Optimization
- **Reactive Efficiency**: Controllers (e.g., `HomeController`, `DocumentController`) manage state independently. The `HomeController` optimizes feed performance with a batch fetch limit of 50 items.
- **Sticky Sort Logic**: The global feed implements "Sticky Sort," prioritizing official university documents (`is_official`) while maintaining chronological order for community contributions.
- **Media Optimization**:
    - **Image Compression**: `lib/core/helper/image_helper.dart` uses `flutter_image_compress` (Quality: 70) to reduce bandwidth and storage costs.
    - **Bandwidth Management**: Direct document uploads are capped at **10MB**. To scale effectively, users are encouraged to submit external hosting links (Google Drive, Mega) via a dedicated 'isExternalLink' toggle in the `UploadController`.
    - **Caching**: `cached_network_image` is utilized throughout the app to minimize redundant network requests.
- **Database Scalability**:
    - **Atomic Counters**: PostgreSQL RPCs (e.g., `increment_likes`, `decrement_dislikes`) use `SECURITY DEFINER` to allow atomic updates to counters without granting users direct write access to sensitive columns.

## 3. Design & UI Standards
- **Visual Paradigm**: Implements **Material 3** with a **Glassmorphism** aesthetic.
- **Design Elements**:
    - **Color Palette**: Centered around "Premium Deep Blue" (`#0D47A1`).
    - **Typography**: Uses **Plus Jakarta Sans** for a modern academic feel.
    - **Glassmorphism**: Achieved using `GlassmorphicContainer` and custom gradients (`AppGradients.glassGradient`).
- **Standardized Loaders**: UI loading states are managed via `Loader` and `Loader2` components (in `lib/view/widgets/loader.dart`).
- **Modern API Compliance**:
    - Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
    - `Switch` widgets must use `activeThumbColor` for modern Flutter compatibility.

## 4. Security & Data Integrity
- **Authentication**: JWT-based session management via Supabase Auth.
- **Authorization (RLS)**: Strict **Row Level Security** policies in `SUPABASE_SCHEMA.sql` ensure:
    - Profiles are publicly readable but only editable by the owner.
    - Documents can only be modified or deleted by the original uploader.
    - Notifications and Bookmarks are private to the respective user.
- **Real-time Security**: `NotificationController` enforces granular security by applying `receiver_id` and `is_global` filters on PostgreSQL Change channels.

## 5. Development & Troubleshooting
- **Zero Warnings Policy**: The project maintains a strict 'Zero Warnings' status. All code changes must pass `flutter analyze` and `flutter test`.
- **Known Issues**:
    - **File Corruption**: `lib/controller/auth_controller.dart` is prone to recurring syntax corruption (e.g., invalid `qaWSQA` prefixes). Always verify file integrity before committing.
- **Android Configuration**:
    - Compiled SDK: API 36.
    - Gradle: 8.12 | Kotlin: 2.1.0 | AGP: 8.9.1.
    - Core Library Desugaring is enabled for broad device compatibility.

---
*Maintained by Jules, AI Software Engineer.*
