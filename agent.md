# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design principles, and security posture of the application.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Performance Analysis
- **Reactive State Management**: Utilizing `GetX` for efficient state updates. Controllers (e.g., `DocumentController`, `ProfileController`) manage business logic independently from the UI.
- **Local Persistent Storage**: `Hive` is used for high-performance NoSQL local caching. User profile metadata is stored in `userBox` (see `lib/core/helper/hive_boxes.dart`) to ensure immediate UI responsiveness upon app launch.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `HomeHeader`) to minimize network usage.
    - **Compression**: `flutter_image_compress` is integrated into the upload pipeline to optimize asset sizes (specifically cover images) before they reach Supabase Storage.
- **Database Scalability**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_dislikes` are intended to be handled via PostgreSQL Functions (`RPCs`). This ensures data consistency and prevents race conditions.
    - **Batch Loading**: The `HomeController` limits document fetching to 50 items per request to balance performance and data availability.
    - **Perceived Performance**: Shimmer placeholders and standardized loaders (`Loader`, `Loader2`) are implemented to provide smooth visual feedback during asynchronous data fetching.

## 2. Design & Architecture
- **UI Paradigm**: The application implements **Material 3** with a **Glassmorphism** aesthetic.
    - Semi-transparent overlays (`.withValues(alpha: ...)`) and custom gradients (`AppGradients.premiumGradient`) are used to create a modern, layered look.
    - Rebranded with a "Premium Deep Blue" theme (`#0D47A1`).
- **Typography**: Uses the "Plus Jakarta Sans" typeface for all UI text, providing a clean and professional academic feel.
- **Project Structure**:
    - `lib/controller/`: Reactive logic and state management using GetX.
    - `lib/view/`: Modular UI components and screens, organized by feature.
    - `lib/core/`: Centralized configurations like `AppMetaData`, theme definitions, and helper utilities.
    - `lib/service/`: Background services for notifications, file downloads, and caching.
- **Asset Integration**: High-quality vector graphics (`flutter_svg`) and `Lottie` animations are used for state feedback and empty states.

## 3. Security Analysis
### 3.1 Authentication & Authorization
- **Authentication**: Uses **Supabase Auth (JWT)**. Sessions are securely managed by the Supabase SDK.
- **Authorization (RLS)**: **Row Level Security** is enabled on all tables. Policies generally ensure:
    - **Profiles**: Public read, owner-only write.
    - **Documents**: Public read, owner-only write.
    - **Notifications**: Private to the receiver.

### 3.2 Security Audit Findings (May 2026)
A deep audit has identified several critical security risks that need to be addressed:
- **Privilege Escalation (is_admin)**: The RLS policy for the `profiles` table allows any user to update their own profile. Since the `is_admin` column is in the same table, a malicious user could theoretically set `is_admin = true` via a direct API call, gaining administrative privileges.
- **Unauthorized Official Marking (is_official)**: Similarly, the `documents` table RLS allows owners to update their own documents. A user could set `is_official = true` on their notes, bypassing administrative verification.
- **Incomplete Schema Documentation**: The `SUPABASE_SCHEMA.sql` file is missing the definitions for critical RPC functions like `increment_likes`, which are required by the `DocumentController`.
- **Recommendation**: Move sensitive flags like `is_admin` to a separate table with restricted RLS, or use a PostgreSQL trigger to prevent users from modifying these specific columns.

## 4. Maintenance & QA
- **Prerequisites**: Flutter SDK ^3.41.2 (mandatory for `.withValues()` support).
- **Zero Warnings Policy**: The project maintains a "Zero Warnings" status. All developers must run `flutter analyze` before committing.
- **Testing**: A dummy test suite is provided in `test/dummy_test.dart` to verify CI/CD pipelines.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
