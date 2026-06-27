# Developer Guide: Serious Study (MU Community App)

This document serves as a comprehensive technical manual and maintenance guide for the Serious Study Android application (formerly NoteHub). It outlines the architecture, performance optimizations, design patterns, and security model from a developer's perspective.

## 1. Project Overview
Serious Study is a premium academic networking and resource-sharing platform for Mumbai University students. It utilizes a **Flutter** frontend with a serverless **Supabase** (PostgreSQL) backend.

### Technical Stack
- **Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management**: **GetX** (Reactive MVC)
- **Local Storage**: **Hive** (High-performance NoSQL)
- **Backend**: **Supabase** (Auth, Database, Storage, Realtime)
- **Design**: Material 3 with Glassmorphism aesthetic

---

## 2. Performance Analysis

### Reactive State Management & UI
- **GetX Architecture**: Business logic is decoupled into controllers (e.g., `DocumentController`, `HomeController`). Reactive variables (`.obs`) ensure minimal UI rebuilds.
- **Optimistic UI Updates**: Interactions like likes, dislikes, and bookmarks are reflected immediately in the UI (see `DocumentController.toggleLike`) before synchronization with the Supabase backend.
- **Shimmer Placeholders**: Used in `HomeDocumentSection` and `SearchPage` to provide immediate visual feedback during asynchronous data fetching.

### Data & Media Optimization
- **Batching & Sorting**: `HomeController` fetches documents in batches of 50 to optimize payload size. It implements a "Sticky Sort" algorithm prioritizing `is_official` content.
- **Image Compression**: `UploadController` utilizes `ImageHelper` to compress cover images before upload, reducing storage costs and improving load times.
- **Direct Upload Limits**: A strict 10MB limit is enforced for direct document uploads to ensure platform stability and cost-efficiency.
- **Lazy Loading**: Thumbnails are managed via `cached_network_image` to prevent redundant network requests.

### Database Efficiency
- **Atomic Operations**: Counter increments (likes/dislikes) are handled via PostgreSQL RPCs (`increment_likes`, `decrement_dislikes`) defined in `SUPABASE_SCHEMA.sql`, preventing race conditions.
- **Local Caching**: `HiveBoxes` caches user profile metadata (`userBox`) and tracked downloads (`downloadsBox`) for instant access on startup.

---

## 3. Design System & UX

### Branding & Aesthetics
- **Premium Deep Blue**: The primary brand color (#0D47A1) is established via `PrimaryColor.shade500` and `shade900` in `color.dart`.
- **Glassmorphism**: Implemented in components like `BottomFooter` using the `glassmorphism` package and custom `glassGradient` for a modern, layered look.
- **Typography**: "Plus Jakarta Sans" is the primary typeface, configured modularly in `typography.dart`.

### User Interface Patterns
- **Material 3**: The app utilizes `useMaterial3: true` with a custom `ColorScheme` seeded from the brand blue.
- **Micro-interactions**: Enhanced using `Lottie` animations for empty states and successful uploads, and `liquid_pull_to_refresh` for feed updates.
- **Responsive Layouts**: Screens use `SingleChildScrollView` and `SafeArea` to ensure compatibility across various Android aspect ratios and notches.

---

## 4. Security Architecture

### Authentication & Authorization
- **JWT-Based Auth**: Secured via Supabase Auth. Sessions are persisted and refreshed automatically by the SDK.
- **Row Level Security (RLS)**: Strictly enforced on all PostgreSQL tables.
    - `profiles`: Publicly readable; updateable only by the owner.
    - `documents`: Owners have full CRUD; others have read-only access.
    - `notifications`: Private to the `receiver_id`.

### Data Integrity & Access Control
- **Administrative Privileges**: Column-level security is simulated via a `check_official_permission` trigger that restricts setting `is_official = true` to users with `is_admin` status.
- **Search-Path Hijacking Mitigation**: Database functions are defined with explicit `SET search_path = public` directives.
- **Storage Policies**: Supabase Storage buckets use RLS-like policies to ensure that only authorized users can delete or modify uploaded assets.

---

## 5. Maintenance & QA

### Zero Warnings Policy
- The project adheres to a strict 'Zero Warnings' policy verified via `flutter analyze`.
- Modern APIs (e.g., `.withValues(alpha: ...)` instead of `.withOpacity()`) must be used for compatibility with the project's SDK requirements.

### Testing & Verification
- **Static Analysis**: `cd notehub && flutter analyze`.
- **Unit Testing**: `cd notehub && flutter test` (e.g., `test/dummy_test.dart`).
- **UI Verification**: Visual changes can be verified using a Playwright-based Flutter Web server setup for rapid iteration.

---
*Generated and Verified by Jules, AI Software Engineer.*
