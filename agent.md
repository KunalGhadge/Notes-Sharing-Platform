# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective, covering performance, design, and security.

## 1. Performance Analysis
- **Reactive State Management**: The application utilizes **GetX** to manage state. Controllers (e.g., `DocumentController`, `HomeController`) handle business logic, ensuring that only necessary parts of the UI are rebuilt when data changes.
- **Local Persistence**: **Hive** is used for high-performance NoSQL local caching. User profile data is stored in `userBox` for instant loading of the "My Profile" section and session persistence.
- **Database Optimization**:
    - **PostgreSQL RPCs**: Critical operations like `increment_likes` and `decrement_dislikes` are executed as **Remote Procedure Calls (RPCs)** on the database server. This ensures atomicity and prevents race conditions that could occur with client-side increments.
    - **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm that prioritizes official university documents at the top of the feed, followed by the latest community uploads.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is integrated into the upload pipeline (`ImageHelper`), reducing the size of cover images to ~70% quality and a 1024px constraint before they are transmitted to Supabase Storage.
    - **Thumbnail Caching**: `cached_network_image` is used for all remote assets to minimize redundant network traffic.
    - **External Hosting**: The app supports external link submissions (e.g., Google Drive), allowing the community to share large resources without incurring cloud storage costs.

## 2. Design & Architecture
- **UI Paradigm**: The app adheres to **Material 3** principles with a modern **Glassmorphism** aesthetic.
    - **Theme**: Centered around a 'Premium Deep Blue' primary color (#0D47A1) with 'Plus Jakarta Sans' typography.
    - **Visual Feedback**: Shimmer placeholders are used during asynchronous loads, and Lottie animations are employed for state transitions (e.g., empty feeds, successful uploads).
- **Code Organization**:
    - `lib/controller/`: Decoupled business logic and reactive state.
    - `lib/core/`: Centralized configurations (metadata, themes, helpers).
    - `lib/model/`: Data structure definitions with Hive adapters.
    - `lib/service/`: Infrastructure services (notifications, file caching).
    - `lib/view/`: Modular UI components organized by feature.

## 3. Security Analysis
The migration to a serverless Supabase architecture has significantly hardened the application's security posture:

- **Authentication**: Uses **Supabase Auth (JWT)**. Passwords are never handled or stored by the application layer; they are managed by Supabase using industry-standard hashing.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - `profiles`: Users can only update their own profile data.
    - `documents`: Only the author can modify or delete their content.
    - `notifications/bookmarks`: Data is private to the authenticated `receiver_id`.
- **API Integrity**: By using `SECURITY DEFINER` on PostgreSQL RPC functions, the application allows users to perform specific atomic updates (like incrementing a like counter) without granting them direct write access to the underlying table columns.
- **File Security**: Access to Supabase Storage buckets is governed by security policies, ensuring that private documents are not accessible via public URL crawling.

## 4. Development & Environment
- **Environment**: Flutter 3.41.2, Dart 3.11.0.
- **Build System**: Utilizes Gradle 8.12 and Kotlin 2.1.0 for Android.
- **Static Analysis**: The project maintains a **Zero Warnings** policy. All code must pass `flutter analyze` with modern standards (e.g., using `.withValues()` instead of `.withOpacity()`).

---
*Documented by Jules, AI Software Engineer.*
