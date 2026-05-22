# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application, architecture, performance strategies, design principles, and security measures.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 1. Technical Architecture
The application follows a reactive MVC pattern powered by **GetX**.
- **Controllers (`lib/controller/`)**: Manage business logic, state transitions, and API interactions.
- **Views (`lib/view/`)**: Modular UI components that react to controller state changes.
- **Models (`lib/model/`)**: Structured data definitions for Users, Documents, Comments, and Notifications.
- **Services (`lib/service/`)**: Dedicated modules for notifications, file caching, and downloads.

## 2. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient UI updates without full-screen rebuilds.
- **Caching & Local Storage**:
    - **Hive**: High-performance NoSQL local storage used for user profile metadata (`userBox`) and download tracking (`downloadsBox`).
    - **File Caching**: Custom `saveAndOpenFile` service uses `Dio` to cache downloaded documents in the temporary directory.
    - **Image Caching**: `CachedNetworkImage` is used globally to minimize redundant media downloads.
- **Optimized Database Interactions**:
    - **Atomic Operations**: Critical interactions like likes and dislikes are handled via PostgreSQL Functions (`RPCs`) to ensure consistency and prevent race conditions.
    - **Batch Fetching**: The `HomeController` limits document fetching to 50 records per request to optimize initial load times.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is integrated into the upload pipeline to reduce asset sizes before storage.
    - **External Links**: Support for Google Drive/Mega links reduces server-side storage and bandwidth costs.

## 3. Design & UI Implementation
- **Material 3 & Glassmorphism**: The app implements a modern aesthetic featuring semi-transparent overlays (`.withValues(alpha: ...)`), rounded corners, and custom gradients.
- **Branding**: A "Premium Deep Blue" theme (`#0D47A1`) is applied throughout the application to represent academic integrity.
- **Custom Components**:
    - **BottomFooter**: A floating navigation bar with rounded corners (30.0) and spread shadows for a premium feel.
    - **Standardized Loaders**: `Loader` and `Loader2` provide consistent visual feedback during asynchronous tasks.
    - **Sticky Sort**: The `HomeController` implements a custom sorting algorithm that prioritizes 'official' documents at the top of the feed.

## 4. Security & Data Integrity
- **Authentication**: Managed by **Supabase Auth (JWT)**. Sessions are securely persisted and synchronized with Hive.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced at the database level:
    - **Profiles**: Restricted updates to the authenticated owner.
    - **Documents**: Owners have full CRUD; public users have read-only access.
    - **Notifications**: Private to the receiver.
- **Counter Integrity**: Counters for likes/dislikes are protected. They cannot be directly edited by users and are only updated via `SECURITY DEFINER` RPC functions.
- **Validation**: Strict client-side and server-side checks for file size (10MB limit) and file types.

## 5. Development Standards
- **Zero Warnings Policy**: The project maintains a strict linting policy verified via `flutter analyze`.
- **Modern Flutter APIs**: Mandates the use of modern APIs such as `.withValues()` for colors and `activeThumbColor` for Switch widgets.
- **Testing**: Unit and integration tests (e.g., `test/dummy_test.dart`) ensure core stability.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
