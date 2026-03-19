# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented in the platform.

## 1. Project Overview
Serious Study is a premium academic community platform for Mumbai University students, enabling seamless note sharing, networking, and resource discovery. It is built using a Flutter frontend and a serverless Supabase backend.

## 2. Architecture & State Management
- **Framework**: Flutter (SDK ^3.5.4)
- **State Management**: **GetX** is used for reactive state updates, dependency injection, and routing. Controllers (e.g., `DocumentController`, `AuthController`) decouple business logic from the UI.
- **Local Persistence**: **Hive** provides high-performance NoSQL local storage.
    - `userBox`: Stores `UserModel` for session persistence and immediate profile loading.
    - `downloadsBox`: Manages metadata for offline-accessible resources.
- **Service Layer**:
    - `SupabaseClient`: Directly used within controllers for real-time data sync and Auth.
    - `Dio`: Utilized for specialized networking tasks like file caching and progress-tracked downloads.

## 3. Performance Analysis & Optimizations
The platform is engineered for high performance and low bandwidth usage:
- **Reactive Updates**: Real-time listeners via Supabase `PostgresChangeEvent` ensure the UI stays in sync without manual refreshes (see `HomeController`).
- **Media Handling**:
    - **Centralized Compression**: `flutter_image_compress` reduces asset sizes (quality 70, max 1024px) in `ImageHelper` before upload.
    - **Smart Caching**: `cached_network_image` prevents redundant network calls for repetitive assets like profile pictures and document covers.
- **Database Efficiency**:
    - **Atomic Counters**: PostgreSQL RPCs (`increment_likes`, `decrement_dislikes`) handle interaction logic on the server to prevent race conditions and ensure data integrity.
    - **Optimistic UI**: Interactions like likes and bookmarks provide immediate feedback on the UI before the backend confirmation (implemented in `DocumentController`).
- **Batch Processing**: Home feed fetches are limited to 50 items with "Sticky Sort" logic to prioritize official university resources.

## 4. Design & UX Implementation
- **Material 3**: The app adheres to Material 3 design principles, featuring modern typography and standardized components.
- **Glassmorphism**: Implemented using the `glassmorphism` package and custom gradients (`AppGradients.glassGradient`). This is prominently used in `PostCard` overlays and navigation elements.
- **Typography & Color**:
    - **Primary Color**: Premium Deep Blue (`#0D47A1`).
    - **Font**: 'Plus Jakarta Sans' via `google_fonts`.
- **Loading States**: Shimmer effect placeholders (e.g., `HomeDocumentSection`) prevent 'grey space' and provide a premium feel during data transitions.

## 5. Security Analysis
Security is a core pillar of the migrated architecture:
- **Authentication**: JWT-based authentication managed by Supabase Auth. Passwords are never handled in plain text by the application layer.
- **Authorization (Row Level Security)**: PostgreSQL RLS is strictly enforced across all tables:
    - `profiles`: Owners can update; public can read.
    - `documents`: Only owners can insert or delete.
    - `interactions`/`bookmarks`: Private to the authenticated user.
- **File Security**: Supabase Storage buckets use policies to restrict unauthorized writes while allowing controlled public access to shared resources.
- **Counter Integrity**: By using `SECURITY DEFINER` on interaction RPCs, users can update counters without having direct write access to sensitive count columns in the `documents` table.

## 6. Android Configuration
- **Package Name**: `com.divinevisionary.notehub`
- **Target API**: 35 (Android 15)
- **Build Features**:
    - `multiDexEnabled true`
    - `coreLibraryDesugaringEnabled true` (supports modern Java APIs on older devices via `com.android.tools:desugar_jdk_libs:2.1.4`).
- **Deep Linking**: Configured for `io.supabase.flutternotehub://login-callback` to handle authentication redirects.

## 7. Developer Quick Start
- **Linting**: The project maintains a 'Zero Warnings' policy. Run `flutter analyze` and ensure all issues (including 'info' level) are resolved before committing.
- **Testing**: Run `flutter test` to execute the test suite (primarily focused on controller logic and model integrity).
- **Coding Conventions**:
    - Use `.withValues(alpha: x)` instead of deprecated `.withOpacity()`.
    - Use `activeThumbColor` for switches.
    - Avoid `print()`; use `debugPrint()` if necessary.
    - All flow control structures must use curly braces.

---
*Maintained by the Divine Visionary Engineering Team.*
