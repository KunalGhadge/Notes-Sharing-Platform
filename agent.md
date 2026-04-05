# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design patterns, and security measures implemented in the application.

## 1. Architecture Overview
Serious Study follows the **GetX MVC (Model-View-Controller)** architecture, ensuring a clean separation of concerns and reactive state management.

- **Controllers (`lib/controller/`)**: Manage business logic, reactive state (`.obs`), and backend interactions.
- **Views (`lib/view/`)**: Modular UI components that react to controller state changes.
- **Models (`lib/model/`)**: Structured data representations (e.g., `UserModel`, `DocumentModel`).
- **Services (`lib/service/`)**: External integrations like `NotificationService` and `FileCaching`.

## 2. Performance Analysis
The application is optimized for speed and efficiency across network and local operations:

- **Reactive State Management**: Utilizing `GetX` for granular UI updates, reducing unnecessary rebuilds.
- **High-Performance Local Caching**:
    - **Hive**: Used for immediate access to user profiles and session data (see `lib/core/helper/hive_boxes.dart`).
    - **Dio & path_provider**: Implements local file caching for downloaded documents to minimize redundant network requests.
- **Media Optimization**:
    - **Centralized Compression**: `lib/core/helper/image_helper.dart` uses `flutter_image_compress` (Quality: 70, Min Width/Height: 1024) to optimize all cover image uploads.
    - **Bandwidth Efficiency**: `cached_network_image` is used globally for media assets.
- **Database Scalability**:
    - **PostgreSQL RPCs**: Critical interactions like `increment_likes` and `decrement_dislikes` are executed atomically in the database to prevent race conditions and ensure data integrity.
    - **Sticky Sort**: `HomeController` prioritizes "Official" university content at the top of the feed followed by chronological updates.
    - **Batch Fetching**: Data is retrieved in batches (e.g., limit 50) to optimize initial payload sizes.

## 3. Design & UI/UX
The design follows **Material 3** principles with a premium academic aesthetic:

- **Glassmorphism**: Implemented using the `glassmorphism` package and custom gradients (`AppGradients.glassGradient`) to create a modern, layered feel.
- **Typography**: Uses the 'Plus Jakarta Sans' typeface via the `google_fonts` package for a clean, legible look.
- **Branding**: Centered around a 'Premium Deep Blue' primary color (`#0D47A1`).
- **User Experience**:
    - **Optimistic UI**: Interactions like likes and bookmarks provide immediate visual feedback before backend synchronization.
    - **Smooth Transitions**: Utilizes Shimmer placeholders and Lottie animations for loading and empty states.

## 4. Security & Backend
The platform utilizes a serverless **Supabase** architecture with a focus on data privacy and integrity:

- **Authentication**: JWT-based secure sessions via Supabase Auth. Includes deep linking for login callbacks.
- **Authorization (RLS)**: **Row Level Security** policies in PostgreSQL ensure that users can only modify their own data (Profiles, Documents, Bookmarks).
- **Security Definer RPCs**: Database functions used for counters (likes, dislikes) run with elevated privileges (`SECURITY DEFINER`), allowing atomic updates without granting users direct write access to sensitive columns.
- **Real-time Security**: `NotificationController` applies granular filters (`receiver_id` or `is_global`) on PostgreSQL Change channels to ensure users only receive relevant updates.

## 5. Development Standards (Zero Warnings Policy)
The project strictly enforces a **Zero Warnings** linting policy to maintain high code quality:

- **Modern APIs**: All deprecated calls like `.withOpacity()` have been modernized to `.withValues(alpha: ...)` (Flutter 3.27+).
- **Widget Compliance**: Modern properties like `activeThumbColor` in `Switch` widgets are required.
- **Code Integrity**: Flow control structures must always use curly braces. Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.
- **CI/CD**: The GitHub Actions pipeline runs `flutter analyze` and `flutter test`. Any warning or informational issue will result in a build failure.

---
*Last updated by Jules, AI Software Engineer.*
