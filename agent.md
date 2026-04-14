# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective, detailing its architecture, performance optimizations, and security model.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University community. It features a Flutter frontend and a serverless **Supabase** backend.

## 1. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates and dependency injection. Controllers (e.g., `DocumentController`, `HomeController`, `UploadController`) encapsulate business logic and use `obs` variables for reactive UI updates.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching.
    - `userBox` stores `UserModel` data (id, username, profileUrl) to ensure immediate availability of user context (see `lib/core/helper/hive_boxes.dart`).
    - `downloadsBox` tracks downloaded files for offline access management.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `PostCard`) to minimize redundant network requests and provide smooth scrolling.
    - **Compression**: `flutter_image_compress` is integrated into the upload pipeline in `UploadController` (using `ImageHelper`) to optimize cover images before they are uploaded to Supabase Storage, reducing bandwidth and storage costs.
- **Database Scalability & Integrity**:
    - **Atomic Operations**: Critical interactions like `increment_likes`, `decrement_likes`, `increment_dislikes`, and `decrement_dislikes` are handled via PostgreSQL RPCs defined in `SUPABASE_SCHEMA.sql`. This ensures data consistency by performing updates server-side.
    - **Optimistic UI**: `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks, providing instantaneous feedback to the user while synchronizing with the backend in the background.
- **Efficient Data Fetching**:
    - **Batching**: `HomeController` fetches updates in batches of 50 using `.limit(50)`.
    - **Relational Queries**: Supabase's relational querying (e.g., `.select('*, profiles:user_id (*)')`) is used to fetch documents and their associated author profiles in a single request.
    - **Sticky Sort**: The feed implements a "Sticky Sort" logic, prioritizing official university documents (`is_official: true`) at the top, followed by chronological ordering.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - **Glassmorphism**: Leverages the `glassmorphism` package for semi-transparent, blurred components like the document title overlay in `PostCard`.
    - **Theme**: A centralized "Premium Deep Blue" theme (`#0D47A1`) defined in `lib/core/config/color.dart`.
- **Project Structure**:
    - `lib/controller/`: Reactive logic and state management using GetX.
    - `lib/view/`: Modular UI components (widgets) and full-screen views.
    - `lib/core/`: Centralized configurations (`AppMetaData`), themes (`AppGradients`), and helpers (`ImageHelper`, `HiveBoxes`).
    - `lib/service/`: Low-level services for file downloads, local notifications, and caching.
- **Asset Integration**: Uses `flutter_svg` for vector icons and `Lottie` for high-quality animations during loading and empty states.

## 3. Security Analysis
The migration to Supabase has addressed legacy vulnerabilities with a modern security stack:

- **Authentication**: Uses **Supabase Auth (JWT)**. Sessions are securely managed via the SDK, and passwords are hashed using industry-standard algorithms (Argon2/Bcrypt) managed by Supabase.
- **Authorization (RLS)**: **Row Level Security (RLS)** is strictly enforced in `SUPABASE_SCHEMA.sql`.
    - **Profiles**: Only the owner (matching `auth.uid()`) can update their profile.
    - **Documents**: Only the author can insert, update, or delete their documents.
    - **Notifications/Bookmarks**: Select policies ensure users only see their own private data.
- **API Integrity**: Sensitive counter updates (likes/dislikes) are restricted to `SECURITY DEFINER` RPC functions, preventing users from directly manipulating count columns in the `documents` table.
- **Storage Security**: Supabase Storage buckets for 'documents' are governed by RLS policies, ensuring that while public URLs can be generated, the underlying storage operations (upload/delete) are restricted to authorized owners.

## 4. Development & QA
- **Environment**: Flutter SDK `^3.5.4`, Dart SDK `^3.11.0`.
- **Zero Warnings Policy**: The project maintains a strict linting policy. Developers must run `flutter analyze` before any submission.
- **Testing**: Run `flutter test` to execute the test suite (e.g., `test/dummy_test.dart`).
- **Android Configuration**:
    - Targeted API: 36.
    - Features Java 17, AGP 8.9.1, and Kotlin 2.1.0.
    - Uses `coreLibraryDesugaring` to support `flutter_local_notifications` on older Android versions.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
