# Developer Guide & System Manual: Serious Study (Mumbai University Community App)

This document provides an exhaustive developer-centric technical analysis of the Serious Study application, documenting its performance optimizations, design patterns, and security architecture.

## 1. Project Overview & Tech Stack
**Serious Study** is a specialized academic networking platform for Mumbai University students.
- **Frontend**: Flutter (Latest stable SDK ^3.5.4)
- **State Management**: **GetX** (Reactive patterns, Controller-based architecture)
- **Backend**: **Supabase** (Serverless PostgreSQL, Auth, and Storage)
- **Local Cache**: **Hive** (High-performance NoSQL for session persistence)
- **CI/QA**: Strict **Zero Warnings** policy enforced via `flutter analyze`.

---

## 2. Performance Analysis

### 2.1 State Management & UI Reactivity
The app utilizes **GetX** for high-performance reactive updates without the overhead of heavy boilerplate.
- **Optimistic UI Updates**: Interactions like Likes, Dislikes, and Bookmarks (managed in `DocumentController.dart`) reflect immediately in the UI before server confirmation, with automated rollbacks on failure.
- **Lazy Loading**: `HomeController` implements batch fetching (limit 50) and a "Sticky Sort" algorithm to prioritize 'official' documents at the top of the feed.
- **State Sync**: `_syncWithHome()` in `DocumentController` ensures that reactive changes in document details are instantly propagated back to the home feed.

### 2.2 Local Caching & Data Persistence
- **Hive Boxes**: `HiveBoxes.dart` provides static access to `userBox` and `downloadsBox`.
- **Startup Latency**: User metadata is retrieved from Hive during the `SplashScreen`, allowing for near-instant rendering of personalized headers (in `HomeHeader.dart`) without waiting for network requests.
- **File Caching**: The `FileCaching` service uses `Dio` to manage temporary document downloads, checking for existing local files to minimize redundant bandwidth usage.

### 2.3 Media & Asset Optimization
- **Image Compression**: `UploadController` enforces a 10MB limit for direct uploads and utilizes `ImageHelper` (built on `flutter_image_compress`) to compress cover images before they reach Supabase Storage.
- **Network Images**: `CachedNetworkImage` is used globally to prevent flickering and excessive network calls during scrolling.

---

## 3. Design & Architecture

### 3.1 Visual Language
- **Theme**: Premium Deep Blue (#0D47A1) as the primary brand color, implemented via `PrimaryColor.shade500`.
- **Glassmorphism**: Modern aesthetic achieved using the `glassmorphism` package and custom gradients in `BottomFooter` and `PostCard`.
- **Typography**: "Plus Jakarta Sans" serves as the primary typeface for headings and UI text, modularized in `typography.dart`.

### 3.2 Modular Component Design
The UI is broken down into reusable widgets:
- **`PostCard`**: A unified component for rendering both 'Notes' and 'Tweets' (short updates).
- **`UploadForm`**: A complex reactive form supporting both direct file uploads and external link submissions (isExternalLink toggle).
- **`RefresherWidget`**: A standardized wrapper for `LiquidPullToRefresh` across all main feeds.

---

## 4. Security & Database Integrity

### 4.1 Authentication & Authorization
- **Supabase Auth**: JWT-based session management.
- **Row Level Security (RLS)**: Strictly enforced in `SUPABASE_SCHEMA.sql`.
    - Users can only `UPDATE` their own profile.
    - `INSERT/DELETE` on documents is restricted to the owner.
    - `SELECT` policies allow public visibility for academic resources while protecting private user data.

### 4.2 Atomic Database Operations
To prevent race conditions, counter increments (likes, dislikes, views) are handled via **PostgreSQL Functions (RPCs)**:
- `increment_likes(doc_id)`
- `decrement_likes(doc_id)`
- Atomic updates ensure that `likes_count` remains consistent even under high concurrency.

### 4.3 Administrative Safeguards
- **Official Status**: Only users with the `is_admin` flag (verified via a trigger `ensure_official_permission`) can set `is_official = true` on a document.
- **SQL Hardening**: RPCs use `SECURITY DEFINER` and explicit `search_path` to prevent path-hijacking vulnerabilities.

---

## 5. Maintenance & QA Guidelines

### 5.1 Contribution Workflow
- **Zero Warnings**: Every PR must pass `flutter analyze` without any info, warning, or error diagnostics.
- **Modernized APIs**: Use `.withValues(alpha: ...)` instead of `.withOpacity()` to comply with modern Flutter standards.
- **Formatting**: Always use explicit curly braces for flow control (if/else) to maintain code readability and pass linting.

### 5.2 Verification Scripts
- **Visual Audit**: Use Playwright scripts to capture screenshots of key user journeys (Home, Profile, Upload).
- **Automated Modernization**: The `modernize_colors.py` tool (regex-based) can be used for bulk replacement of deprecated color methods.

---
*Analyzed and Documented by Jules (Divine Visionary Agent).*
*Last Updated: June 2026*
