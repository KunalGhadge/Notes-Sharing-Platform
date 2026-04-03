# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis and developer guide for the Serious Study project, documenting its architecture, performance optimizations, design principles, and security measures.

## 1. Architecture Overview
Serious Study follows a modular **MVC (Model-View-Controller)** architecture, enhanced by the **GetX** ecosystem for state management and dependency injection.

- **Controllers (`lib/controller/`)**: Reactive business logic. Controllers like `DocumentController` and `AuthController` manage the application state and interact with Supabase.
- **Views (`lib/view/`)**: Modular UI components. Each screen (e.g., `home_screen`, `auth_screen`) is decoupled from logic.
- **Models (`lib/model/`)**: Structured data representations (e.g., `UserModel`, `DocumentModel`).
- **Services (`lib/service/`)**: Dedicated layers for side-effects like `NotificationService` and `FileCaching`.
- **Core (`lib/core/`)**: Centralized configuration (`AppMetaData`), themes (`color.dart`, `typography.dart`), and utility helpers.

## 2. Performance Optimizations
The application is engineered for high performance and low latency, specifically catering to mobile users.

- **Reactive State Management**: Utilizing GetX `obs` variables and `Obx` widgets to ensure targeted UI rebuilds.
- **High-Performance Caching**:
    - **Hive**: Used for lightning-fast local storage of user profiles (`userBox`) and download metadata (`downloadsBox`).
    - **CachedNetworkImage**: Implemented in components like `HomeHeader` to reduce redundant network requests for thumbnails.
- **Media Optimization**:
    - **Image Compression**: `lib/core/helper/image_helper.dart` utilizes `flutter_image_compress` to optimize assets (Quality: 70, Min Width/Height: 1024) before they are uploaded to Supabase Storage.
    - **Bandwidth Control**: Direct document uploads are restricted to 10MB. Users are encouraged to use external links (Google Drive, Mega) for larger files via the `isExternalLink` toggle.
- **Optimistic UI**:
    - `DocumentController` implements optimistic updates for likes, dislikes, and bookmarks, providing immediate visual feedback while background synchronization occurs.
- **Efficient Data Fetching**:
    - `HomeController` utilizes batch fetching (limit: 50) and implements "Sticky Sort" to prioritize official university documents in the feed.

## 3. Design Principles
Serious Study adheres to a premium academic aesthetic, combining modern UI trends with intuitive UX.

- **Visual Style**:
    - **Material 3**: Fully integrated with custom ColorSchemes derived from "Premium Deep Blue" (`#0D47A1`).
    - **Glassmorphism**: Implemented using the `glassmorphism` package and custom `AppGradients.glassGradient` for a modern, layered look.
- **Typography**: Uses 'Plus Jakarta Sans' globally via the `google_fonts` package to maintain a clean, academic feel.
- **Standardized UI Components**:
    - Standardized loaders (`Loader`, `Loader2`) and toasts (`Toasts`) ensure UI consistency.
    - Lottie animations and Shimmer placeholders are used to handle loading and empty states gracefully.

## 4. Security & Data Integrity
The migration to Supabase has introduced a robust, serverless security model.

- **Authentication**: Managed via **Supabase Auth (JWT)**. The app utilizes deep linking (`io.supabase.flutternotehub://login-callback`) for secure authentication flows.
- **Authorization (RLS)**: **Row Level Security** is strictly enforced on all PostgreSQL tables.
    - Users can only `UPDATE` their own profiles.
    - `INSERT` and `DELETE` operations on documents are restricted to the asset owner.
- **Atomic Operations**: Critical interactions (likes/dislikes) are handled via PostgreSQL RPCs defined with `SECURITY DEFINER`. This ensures that counter increments are atomic and that users cannot directly manipulate sensitive columns.
- **Storage Security**: Supabase Storage buckets are governed by policies that restrict file modifications to the original uploader.

## 5. Development Workflow
- **Prerequisites**: Flutter 3.41.2 (Channel Stable), Dart SDK 3.11.0.
- **Analysis**: The project enforces a 'Zero Warnings' policy. Developers must use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`. Note: For Flutter 3.41.x+, the `activeThumbColor` property is used in `Switch` widgets to satisfy modern analysis requirements.
- **Testing**: Ensure all changes are verified by running `flutter analyze && flutter test` in the `notehub/` directory.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
