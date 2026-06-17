# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis and system manual for the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, design standards, and security protocols implemented following the migration to a serverless **Supabase** architecture.

## 1. System Architecture
Serious Study is built with Flutter and follows a decoupled MVC pattern powered by **GetX**.

- **Frontend**: Flutter 3.24+ (SDK ^3.5.4).
- **State Management**: **GetX** handles reactive state, dependency injection, and navigation.
- **Backend**: **Supabase** (PostgreSQL, Auth, Storage).
- **Local Database**: **Hive** for high-performance NoSQL caching of sessions and metadata.

## 2. Performance Analysis
The application is optimized for responsiveness and minimal data usage:

- **Reactive State**: GetX Controllers (e.g., `DocumentController`, `HomeController`) manage business logic and trigger granular UI updates.
- **Optimistic UI Updates**: Interactions such as likes, dislikes, bookmarks, and comments are updated locally immediately before being synchronized with Supabase, providing a "zero-latency" feel.
- **Data Fetching & Sorting**:
    - **Batching**: The `HomeController` fetches documents in batches of 50 to optimize payload size.
    - **Sticky Sort**: Implements a custom algorithm that prioritizes 'Official' documents at the top of the feed, followed by chronological order.
- **Media Optimization**:
    - **Image Compression**: All cover images are compressed using `flutter_image_compress` (70% quality) before being uploaded to Supabase Storage.
    - **Thumbnail Caching**: `CachedNetworkImage` is used to persist thumbnails locally and reduce redundant network requests.
- **Local Persistence**: `HiveBoxes` (lib/core/helper/hive_boxes.dart) provides static access to:
    - `userBox`: Stores `UserModel` (id, username, profileUrl, counts).
    - `downloadsBox`: Tracks metadata of files downloaded to the device.
- **File Management**:
    - **Direct Upload Limit**: Enforces a strict 10MB limit for direct document uploads to control storage costs.
    - **External Resource Support**: Supports Google Drive/Mega links as an alternative to direct uploads.
    - **Intelligent Caching**: `FileCaching` checks the temporary directory for existing files before initiating a download via `Dio`.

## 3. Design & UI/UX Standards
Serious Study utilizes a modern **Material 3** design with a **Glassmorphism** aesthetic.

- **Branding**: The "Premium Deep Blue" theme is centered around `#0D47A1` (PrimaryColor.shade500 and shade900).
- **Typography**: Uses the "Plus Jakarta Sans" typeface for all headings and body text, managed via `lib/core/config/typography.dart`.
- **Visual Feedback**:
    - **Shimmers**: Integrated into `HomeDocumentSection` and `SearchPage` for smooth asynchronous loading.
    - **Lottie Animations**: Used for empty states and success feedback.
    - **Custom Toasts**: Standardized via the `toastification` package using the `flatColored` style.
- **Layout**:
    - A custom floating navigation bar (`BottomFooter`) with 30.0 corner radius and spread shadows.
    - Modular components like `DocumentCard` and `PostCard` ensure UI consistency across feeds.

## 4. Security & Data Integrity
The platform implements multiple layers of security to protect community content and user data.

- **Authentication**: Managed via **Supabase Auth (JWT)**. Sessions are synced to Hive for instant recovery.
- **Authorization (RLS)**: **Row Level Security** is enabled on all PostgreSQL tables:
    - **Profiles**: Authenticated users can only update their own records.
    - **Documents**: Ownership-based access for modifications.
    - **Public Read**: All community content is publicly viewable by authenticated users.
- **Atomic Operations (RPCs)**: Counter updates (likes, dislikes, bookmarks) are handled via `SECURITY DEFINER` PostgreSQL functions to prevent race conditions and direct table manipulation.
- **Privilege Escalation Prevention**:
    - The `is_official` flag in the `documents` table can only be set to `true` by users with `is_admin = true` in their profile, enforced via the `ensure_official_permission` database trigger.
    - Search-path hijacking is mitigated by explicit `SET search_path = public` directives in database functions.

## 5. Maintenance & QA
- **Zero Warnings Policy**: All code changes must pass `flutter analyze` and `flutter test` from the `notehub/` directory.
- **Linting Rules**:
    - Mandatory use of explicit curly braces in all flow control structures (e.g., inside `Obx` builders).
    - Intentional empty catch blocks must include the `// ignore: empty_catches` annotation on its own line.
- **Modern API Compliance**:
    - Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
    - `Switch` widgets must use `activeThumbColor` (matching branding) instead of the deprecated `activeColor`.
- **Environment**: Target Flutter SDK 3.24+ and Dart 3.5+.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
