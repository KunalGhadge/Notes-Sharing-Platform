# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the current state of the application, architecture, performance optimizations, and security measures.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Architecture: GetX MVC
The application follows a decoupled GetX MVC architecture to ensure a clean separation of concerns:
- **`lib/controller/`**: Manages business logic and reactive state.
- **`lib/view/`**: Contains modular UI components and screens that react to controller states.
- **`lib/model/`**: Defines data structures (e.g., `UserModel`, `DocumentModel`).
- **`lib/service/`**: Handles external integrations like file downloads and local notifications.
- **`lib/core/`**: Centralized configurations for themes, helper utilities, and app metadata.

## 2. Performance Optimizations
- **High-Performance Caching**:
    - **Local Persistence**: `Hive` is used for ultra-fast local storage. `userBox` caches profile metadata (username, id, profileUrl) for immediate UI responsiveness.
    - **Image Caching**: `cached_network_image` is implemented across all feed components to reduce redundant network requests.
- **Efficient Data Handling**:
    - **Batch Fetching**: The `HomeController` limits initial data fetching to 50 items to optimize bandwidth.
    - **Sticky Sort**: The feed implements a custom sorting algorithm that prioritizes official university documents (`is_official`) at the top, followed by chronological ordering.
- **Media Optimization**:
    - **Compression**: `ImageHelper` utilizes `flutter_image_compress` (70% quality, 1024px constraints) to optimize cover images before upload.
    - **Storage Scalability**: Supports external link submissions (Google Drive, Mega) to reduce server costs and accommodate large files (>10MB).
- **Backend Performance**:
    - **PostgreSQL RPCs**: Heavy logic like atomic counter updates (`increment_likes`) is handled on the server side via `SECURITY DEFINER` functions to prevent client-side race conditions.

## 3. Design Principles
- **Aesthetic**: **Material 3** with a **Glassmorphism** overlay system.
- **Typography**: Primary typeface is 'Plus Jakarta Sans'.
- **Theming**: Rebranded with a "Premium Deep Blue" primary color (`#0D47A1`).
- **Visual Feedback**:
    - Custom Shimmer effects for loading states.
    - Lottie animations for empty states and successful uploads.
    - Standardized `Loader` widgets for consistent asynchronous indicators.

## 4. Security & Data Integrity
- **Authentication**: **Supabase Auth (JWT)**. Sessions are managed securely via the SDK, and passwords are hashed using Argon2/Bcrypt by Supabase.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced in `SUPABASE_SCHEMA.sql`:
    - Users can only `UPDATE` their own profiles.
    - `INSERT` and `DELETE` on documents are restricted to the owners.
    - Personal data like notifications and bookmarks are private to the specific user.
- **Interaction Security**: Atomic interactions (Likes/Dislikes) are protected via PostgreSQL RPCs, preventing users from directly manipulating counter columns.
- **Admin Controls**: Specific columns like `is_admin` (profiles) and `is_official` (documents) allow for administrative broadcasting and verified content classification.

## 5. Development & QA Standards
- **Zero Warnings Policy**: The project strictly adheres to a zero-warning linting status.
- **Modern API Usage**:
    - Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
    - Use `activeThumbColor` in `Switch` widgets to resolve deprecation warnings.
- **Verification**:
    - Run `cd notehub && flutter analyze` to verify linting compliance.
    - Run `cd notehub && flutter test` to execute the test suite.
- **Build Environment**:
    - **Target**: Android API 36.
    - **Tools**: Flutter 3.41.2+, Java 17, Kotlin 2.1.0, Gradle 8.12.
    - **Desugaring**: Enabled for compatibility with legacy Android devices.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
