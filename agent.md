# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective, documenting its performance, design, and security architecture.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform dedicated to the Mumbai University community. It utilizes a Flutter frontend and a serverless Supabase backend, migrated from a legacy Django/MongoDB stack to enhance scalability and security.

## 2. Performance Analysis
- **Reactive State Management**: The application uses **GetX** for high-performance reactive state management. Controllers like `DocumentController` and `HomeController` decouple business logic from the UI, ensuring efficient updates.
- **Local Persistence**: **Hive** is utilized for local NoSQL caching, storing user profile data and download metadata. This allows for near-instantaneous UI rendering upon app launch.
- **Database Atomic Operations**: Critical interactions such as like/dislike counts are handled via **PostgreSQL RPCs** (`increment_likes`, `decrement_dislikes`, etc.) to prevent race conditions and ensure data consistency.
- **Optimistic UI Updates**: Interactions like bookmarking and liking implement optimistic UI patterns, providing immediate visual feedback while the backend synchronizes asynchronously.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used for efficient thumbnail and profile image caching.
    - **Compression**: `flutter_image_compress` is integrated into the upload pipeline to minimize storage usage and upload times.
- **Lazy Loading**: The `HomeController` implements batch fetching (limit 50) and "Sticky Sort" (official content first) to optimize feed responsiveness.

## 3. Design & Architecture
- **Material 3 & Glassmorphism**: The UI follows Material 3 guidelines enhanced with a premium **Glassmorphism** aesthetic (semi-transparent overlays, blur effects).
- **Branding**: Rebranded with a "Premium Deep Blue" theme (`#0D47A1`).
- **Typography**: Uses "Plus Jakarta Sans" for all UI elements, centrally managed in `lib/core/config/typography.dart`.
- **Modular Architecture**:
    - `lib/controller/`: Reactive business logic.
    - `lib/model/`: Strongly typed data models with JSON serialization.
    - `lib/view/`: Modular and reusable UI components.
    - `lib/service/`: Infrastructure services (caching, notifications).

## 4. Security Architecture
- **JWT-Based Authentication**: Managed by **Supabase Auth**, replacing legacy session-less systems with secure, token-based authentication.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - **Profiles**: Only owners can update their data; critical columns like `is_admin` are protected against unauthorized modification via refined RLS policies.
    - **Documents**: Ownership-based write access; public read access.
- **Atomic Counter Integrity**: Counters are managed via `SECURITY DEFINER` functions (RPCs), preventing direct, unauthorized table manipulation.
- **File Security**: Supabase Storage buckets are governed by policies that restrict file access and modification based on user identity.

## 5. Maintenance & QA
- **Environment**: Requires Dart SDK ^3.5.4 and Flutter 3.24+ (stable channel).
- **'Zero Warnings' Policy**: The codebase is strictly maintained to pass `flutter analyze` with no warnings.
- **Modernized APIs**: Uses modern Flutter APIs like `.withValues(alpha: ...)` for color manipulation and `activeThumbColor` for Switches.
- **Verification**: UI changes are verified using Playwright-based visual testing against a local Flutter web server.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
