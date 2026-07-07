# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective, documenting the architecture, performance optimizations, design patterns, and security implementation.

## Project Overview
Serious Study is a premium academic networking and notes-sharing platform for the Mumbai University community. It features a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 1. Performance & State Management
- **Reactive State Management (GetX)**:
    - The app utilizes `GetX` for business logic separation and reactive UI updates.
    - Controllers (e.g., `HomeController`, `DocumentController`) manage state transitions, ensuring that the UI reacts immediately to data changes without unnecessary rebuilds.
- **Data Fetching & Optimization**:
    - **Sticky Sort**: The `HomeController` implements a custom sorting algorithm that prioritizes 'official' documents at the top of the feed, followed by chronological ordering.
    - **Batching**: Document feeds are fetched in batches (limit 50) to balance network efficiency and responsiveness.
    - **Optimistic UI**: Interactions like likes, dislikes, and bookmarks are reflected in the UI immediately using optimistic updates before being synchronized with the Supabase backend.
- **Local Persistence (Hive)**:
    - `Hive` is used for high-performance NoSQL local storage.
    - User profile data is cached in `userBox` for instant app startup.
    - Download metadata is stored in `downloadsBox` for offline management.
- **Media Optimization**:
    - **Compression**: `flutter_image_compress` is integrated into the `UploadController` to reduce cover image sizes (quality: 70) before uploading to Supabase Storage.
    - **Caching**: `cached_network_image` is used throughout the app to minimize redundant network requests and improve scrolling performance.
    - **File Management**: `file_caching.dart` uses `Dio` and `path_provider` to manage document downloads, checking for existing local files before initiating new downloads.

## 2. Design & Architecture
- **UI/UX Paradigm**:
    - **Material 3**: The app follows the latest Material Design standards.
    - **Glassmorphism**: Semi-transparent overlays and blur effects (using the `glassmorphism` package) are applied to components like the `BottomFooter` and profile cards for a premium, modern aesthetic.
    - **Typography**: "Plus Jakarta Sans" is established as the primary typeface for headings and body text, providing a clean and professional academic feel.
    - **Brand Identity**: Rebranded with a "Premium Deep Blue" theme (`#0D47A1`), implemented via custom `PrimaryColor` shades.
- **Feedback & Motion**:
    - **Shimmer**: `shimmer` placeholders are used during asynchronous data loading to provide visual continuity.
    - **Lottie**: Custom animations are used for state feedback (e.g., empty search results, success states).
    - **Refresh**: `liquid_pull_to_refresh` is used on feeds for an interactive refresh experience.
- **Project Structure**:
    - `lib/controller/`: Business logic and reactive state.
    - `lib/view/`: Modularized UI components (screens and shared widgets).
    - `lib/core/`: Centralized configurations (themes, typography, metadata).
    - `lib/service/`: Infrastructure logic (notifications, file caching).
    - `lib/model/`: Type-safe data representations.

## 3. Security & Backend Architecture
The migration to Supabase has established a robust security model using industry-standard protocols:

- **Authentication**:
    - Managed by **Supabase Auth** using JWT (JSON Web Tokens).
    - Sessions are persisted and managed securely by the Supabase SDK.
- **Authorization (Row Level Security)**:
    - RLS is strictly enforced across all PostgreSQL tables.
    - **Profiles**: Public read, owner-only update.
    - **Documents**: Public read, owner-only write/delete.
    - **Interactions/Bookmarks/Notifications**: Private to the specific user (UID-based policies).
    - **Privilege Escalation Prevention**: Setting `is_official = true` in the `documents` table is restricted via database triggers that verify the user's `is_admin` status in their profile.
- **Database Logic (RPCs)**:
    - Atomic counter updates (likes, dislikes, bookmarks) are handled via PostgreSQL functions (`RPCs`) with `SECURITY DEFINER` context. This ensures that counters are incremented/decremented reliably without exposing direct table manipulation to the client.
- **Storage Security**:
    - All documents and thumbnails in Supabase Storage are governed by policies, ensuring that only authenticated users can upload and that private assets are protected.

## 4. Maintenance & QA
- **Zero Warnings Policy**: The project maintains a strict 'Zero Warnings' status. Developers must run `flutter analyze` and `flutter test` before any submission.
- **Modernization**: Codebase follows modern Flutter standards, including the use of `.withValues(alpha: ...)` instead of deprecated `.withOpacity()` and `activeThumbColor` for Switch widgets.
- **Android Configuration**:
    - Targets `compileSdk 36`.
    - Java 17 compatibility.
    - Permissions: Internet, External Storage (with legacy support enabled in Manifest).

---
*Analyzed and Documented by Jules, AI Software Engineer.*
