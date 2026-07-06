# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a Supabase (PostgreSQL) backend.

## 1. Technical Architecture & State Management
The application follows a decoupled architecture using **GetX** for state management, ensuring a clear separation between UI and business logic.

### Key Controllers:
- **`DocumentController`**:
    - **Optimistic UI**: Implements optimistic updates for `toggleLike`, `toggleDislike`, and `toggleBookmark`, providing immediate visual feedback before server confirmation.
    - **Atomic Counters**: Uses PostgreSQL RPCs (`increment_likes`, etc.) to ensure data integrity during concurrent interactions.
    - **Lifecycle Management**: Handles document deletion, including Storage cleanup and database cascades.
- **`HomeController`**:
    - **Real-time Sync**: Utilizes Supabase `PostgresChangeEvent.all` to listen for document updates and refresh the feed automatically.
    - **Sticky Sort**: Implements a custom sorting algorithm that prioritizes 'Official' documents at the top of the feed, followed by chronological order.
    - **Batch Fetching**: Limits initial document fetching to 50 items to optimize network performance.
- **`UploadController`**:
    - **File Validation**: Enforces a 10MB limit for direct document uploads and requires a cover image for all 'Note' type posts.
    - **Hybrid Content**: Supports both direct file uploads and external links (Google Drive, Mega), as well as 'Tweet' style text-only posts.

## 2. Performance & Optimization Strategies
- **Local Persistence**: **Hive** is used for high-performance NoSQL local caching. User profile metadata is stored in `userBox` for instant UI rendering on launch.
- **Asset Management**:
    - **Image Compression**: `flutter_image_compress` is integrated into the upload pipeline (`ImageHelper.compressImage`) to optimize assets (JPEG, 70% quality, 1024x1024 max) before storage.
    - **Thumbnail Caching**: `CachedNetworkImage` is used in components like `HomeHeader` and `DocumentCard` to minimize redundant network requests.
    - **Lazy Loading**: Implements shimmer placeholders and batch fetching to maintain high responsiveness.
- **Service Layer**:
    - **`FileCachingService`**: Efficiently manages downloaded documents by checking the temporary directory before initiating new network requests via `Dio`.

## 3. Design & UI Implementation
The application implements **Material 3** with a refined **Glassmorphism** aesthetic, tailored for a premium academic experience.

- **Brand Identity**: Rebranded with a "Premium Deep Blue" theme (`#0D47A1`), consistent across `PrimaryColor.shade500` and `AppGradients.premiumGradient`.
- **UI Paradigm**:
    - **Glassmorphism**: Semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`) and custom gradients are used for navigation and profile cards.
    - **Typography**: Standardized using "Plus Jakarta Sans" for all headings and body text.
- **Visual Feedback**: Integration of `Lottie` animations for state feedback and `LiquidPullToRefresh` for intuitive content discovery.

## 4. Security Audit Findings
The migration to Supabase has addressed critical legacy vulnerabilities through a robust implementation of PostgreSQL features.

- **Authentication**: JWT-based session management via Supabase Auth.
- **Row Level Security (RLS)**:
    - **Authorization**: Strict policies ensure users can only update their own profiles and delete their own documents.
    - **Privilege Escalation Protection**: The `profiles` table `FOR UPDATE` policy prevents users from modifying their own `is_admin` status. Similarly, `is_official` flags in `documents` are restricted via RLS and backend triggers.
    - **Data Isolation**: Notifications and bookmarks are private to the recipient/owner.
- **Database Integrity**:
    - **Atomic RPCs**: Critical interaction counters are updated via server-side functions with `SECURITY DEFINER`, preventing client-side data manipulation.
    - **Idempotent Schema**: `SUPABASE_SCHEMA.sql` uses `IF NOT EXISTS` and explicit `search_path` settings to ensure consistent and secure database deployments.

## 5. Development & QA
- **Prerequisites**: Dart SDK 3.6+ (Dart 3.5.4+ verified for modern API compatibility), Flutter 3.44.4+ (Stable).
- **Compliance**: Adheres to a "Zero Warnings" policy. Always run `flutter analyze` and `flutter test` within the `notehub/` directory before submission.
- **Android Support**: Target SDK 34, requires `MANAGE_EXTERNAL_STORAGE` and `INTERNET` permissions.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
