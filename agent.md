# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis of the Serious Study application from a lead developer's perspective. It covers architectural decisions, performance optimizations, design patterns, and security implementations following the migration to a serverless Supabase architecture.

## 1. Architectural Overview
Serious Study follows a reactive **MVC (Model-View-Controller)** pattern facilitated by **GetX**.

- **Core Framework**: Flutter 3.41.2 (Stable) | Dart 3.11.0.
- **State Management**: **GetX** handles dependency injection, reactive state (`.obs`), and navigation.
- **Backend-as-a-Service (BaaS)**: **Supabase** (PostgreSQL, Auth, Storage, Real-time).
- **Local Persistence**: **Hive** for high-speed NoSQL caching of user sessions and persistent metadata.

### Project Structure
- `lib/controller/`: Business logic and state management (e.g., `HomeController`, `AuthController`, `DocumentController`).
- `lib/view/`: Modular UI components organized by feature (e.g., `home_screen/`, `profile_screen/`).
- `lib/model/`: Type-safe data models with Hive adapters.
- `lib/service/`: low-level utility services (Notification, File Download, Caching).
- `lib/core/`: Global configurations, theme definitions, and shared helpers.

## 2. Performance Analysis
The application is optimized for low-latency interactions and efficient bandwidth usage, critical for a student community app.

- **Reactive Feeds & Sticky Sort**:
    - `HomeController` utilizes `supabase.channel()` for real-time Postgres changes.
    - Implements **Sticky Sort**: Official university documents are hoisted to the top of the feed (`is_official DESC`), followed by chronological ordering (`created_at DESC`).
    - Data fetching is batched (Limit: 50) to minimize initial payload.
- **Media Optimization**:
    - **Image Compression**: `ImageHelper` uses `flutter_image_compress` (Quality 70, Min Width/Height 1024) before upload to reduce storage costs and user data consumption.
    - **Asset Caching**: `cached_network_image` is used throughout the app (e.g., in `PostCard`) to eliminate redundant downloads.
- **Data Layer Efficiency**:
    - **Atomic RPCs**: High-frequency operations like likes/dislikes use PostgreSQL RPCs (`increment_likes`) to ensure single-trip data updates and prevent client-side race conditions.
    - **Hive Caching**: User profiles are stored in `userBox` for instant "My Profile" tab loads without network calls.
- **Connectivity & Configuration**:
    - `RemoteConfigController` listens to a dedicated `remote_config` table for real-time maintenance toggles and global announcements.

## 3. Design & UX Implementation
The UI adheres to modern **Material 3** principles with a custom **Glassmorphism** aesthetic.

- **Visual Language**:
    - **Primary Theme**: "Premium Deep Blue" (`#0D47A1`).
    - **Glassmorphism**: Implemented via the `glassmorphism` package, particularly in `PostCard` overlays using `AppGradients.glassGradient`.
    - **Typography**: `Plus Jakarta Sans` via Google Fonts for a clean, academic look.
- **User Feedback**:
    - **Loaders**: Standardized `Loader` and `Loader2` components.
    - **Animations**: `Lottie` files are used for empty states, search results, and successful uploads.
    - **Shimmers**: Integrated into `HomeDocumentSection` for perceived performance during data fetching.
    - **Toasts**: Managed by `toastification` for non-intrusive success/error alerts.

## 4. Security & Data Integrity
Post-migration security is significantly hardened compared to the legacy Django/MongoDB stack.

- **Authentication**:
    - **Supabase Auth (JWT)**: Secure session management.
    - **Password Safety**: Handled by Supabase using Argon2/Bcrypt hashing.
- **Authorization (RLS)**:
    - **Row Level Security (RLS)** is strictly enforced on all PostgreSQL tables.
    - Policies ensure users can only `UPDATE` or `DELETE` their own documents/profiles.
    - Profiles are publicly readable but privately writable.
- **Database Hardening**:
    - RPC functions are defined with `SECURITY DEFINER`, allowing controlled atomic updates to counters (like `likes_count`) without granting users direct write access to sensitive columns.
    - `interactions` table uses unique constraints `(document_id, user_id)` to prevent duplicate likes.
- **Storage Protection**:
    - Supabase Storage policies restrict bucket access, ensuring only authorized owners can delete assets.
    - 10MB file size limit enforced in `UploadController` to prevent storage abuse.

## 5. Coding Conventions & Best Practices
- **Linting**: Strict "Zero Warnings" policy. Use `flutter analyze` frequently.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of `.withOpacity(x)` for Flutter 3.41.2+ compatibility.
- **Control Flow**: Always use curly braces for `if/else` statements.
- **Error Handling**: Use `// ignore: empty_catches` for intentional silent catches and detailed error reporting in UI Toasts for `PostgrestException` or `AuthException`.
- **Optimization**: Use `Obx` for fine-grained reactive UI updates; avoid rebuilding large widget trees.

---
*Maintained by Jules, AI Software Engineer.*
