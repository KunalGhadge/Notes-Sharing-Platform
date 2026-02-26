# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design principles, and security protocols of the application.

## 1. Project Architecture Overview
Serious Study follows a modern, serverless architecture using **Flutter** for the frontend and **Supabase** (PostgreSQL + Auth + Storage) for the backend.

- **Frontend**: Flutter (3.5.4+) with GetX for state management.
- **Backend**: Supabase (PostgreSQL with RLS, GoTrue Auth, PostgREST).
- **State Management**: Reactive pattern using `GetX` controllers.
- **Persistence**: Hybrid approach using `Hive` for fast local NoSQL caching and Supabase for cloud-synced data.

## 2. Performance Analysis
The application implements several strategies to ensure a fluid user experience:

- **Reactive State Management**: `GetX` is used to manage UI states independently. Observables (`.obs`) and `Obx` widgets minimize unnecessary rebuilds.
- **Local Persistence (Hive)**: User metadata and session info are stored in Hive boxes (`notehub/lib/core/helper/hive_boxes.dart`). This enables "instant-on" capabilities by providing immediate UI data while network requests are in flight.
- **Atomic Database Operations (RPCs)**: To prevent race conditions and ensure data integrity, high-frequency updates like liking or disliking documents use PostgreSQL Functions (`RPCs`):
    - `increment_likes`, `decrement_likes`
    - `increment_dislikes`, `decrement_dislikes`
    Reference: `SUPABASE_SCHEMA.sql`.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is leveraged for all remote assets to reduce bandwidth and latency.
    - **Compression**: `flutter_image_compress` is integrated in `UploadController` to optimize user-uploaded files before they are sent to Supabase Storage.
- **Perceived Performance**: Shimmer loading effects (via `shimmer` package) are used in `HomeDocumentSection` and `ProfileHeader` to provide immediate visual feedback during async operations.

## 3. Design & UI/UX Analysis
The UI adheres to **Material 3** guidelines with a premium, modern aesthetic:

- **Glassmorphism**: Extensively used throughout the app to create depth. Implemented via the `glassmorphism` package and custom alpha-blended containers (e.g., `Colors.white.withValues(alpha: 0.15)`).
- **Typography & Color**: Uses `Google Fonts` (Inter/Roboto) and a "Premium Deep Blue" primary palette (`#0D47A1`).
- **Interactive Elements**:
    - **Lottie Animations**: Used for state transitions (e.g., empty states, success feedback).
    - **Liquid Pull to Refresh**: Enhanced refresh experience for document lists.
- **Modular Components**: Highly reusable widgets located in `notehub/lib/view/widgets/` (e.g., `DocumentCard`, `PrimaryButton`).

## 4. Security & Data Integrity
Security is baked into the database layer, moving away from vulnerable legacy custom backends:

- **Authentication**: Uses **Supabase Auth (JWT)**. Sessions are managed securely via the SDK, with deep-link support (`io.supabase.flutternotehub://login-callback`) for email confirmations.
- **Authorization (Row Level Security)**: Every table has strict RLS policies defined in `SUPABASE_SCHEMA.sql`:
    - `profiles`: Publicly viewable, but `UPDATE` is restricted to `auth.uid() = id`.
    - `documents`: Publicly viewable, but `INSERT/DELETE` is restricted to the document owner.
    - `notifications`: Strictly private; users can only `SELECT` where `receiver_id = auth.uid()`.
- **API Integrity**: Atomic counters are updated via `SECURITY DEFINER` functions, allowing the app to trigger specific updates without granting users direct write access to sensitive columns like `likes_count`.
- **Storage Security**: Supabase Storage buckets are protected by policies, ensuring that only authenticated users can upload and that private documents remain inaccessible to unauthorized parties.

## 5. Technical Implementation Details
- **Networking**: `supabase_flutter` for core DB/Auth/Storage and `Dio` for external API interactions (if any).
- **Notifications**: Integrated with `flutter_local_notifications`. The `NotificationController` manages real-time subscriptions to the `notifications` table.
- **Form Validation**: Centralized validation logic in `AuthController` and `UploadController` ensures data quality before submission.

## 6. Build & Maintenance
- **Analysis**: The project uses `flutter_lints`. Running `flutter analyze` is mandatory before any commit.
- **Testing**: Foundational tests are in `notehub/test/`. Use `flutter test` for verification.
- **Android Configuration**: Optimized with `multiDexEnabled true` and `coreLibraryDesugaring` to support modern Java APIs on older Android versions.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
