# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis and architectural overview of the **Serious Study** project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## 1. Executive Summary
Serious Study is a premium notes-sharing and academic networking platform specifically tailored for the Mumbai University student community. The platform leverages Flutter for a cross-platform frontend and Supabase for a robust, real-time backend.

---

## 2. Technical Stack & Architecture

### Frontend: Flutter
- **Version**: SDK ^3.5.4 (Flutter 3.41.2+)
- **State Management**: **GetX** – Used for reactive state management, dependency injection, and clean MVC separation.
- **Local Persistence**: **Hive** – High-performance NoSQL local storage for session caching (e.g., `userBox`) and offline metadata.
- **Networking**: **Supabase Flutter SDK** & **Dio** – Supabase handles primary data and Auth; Dio is utilized for file downloads and specialized caching.

### Backend: Supabase (Serverless)
- **Database**: **PostgreSQL** – Relational storage with strict **Row Level Security (RLS)**.
- **Authentication**: **Supabase Auth (JWT)** – Secure session management and hashed password storage.
- **Storage**: **Supabase Storage** – Secure object storage for documents (PDFs) and compressed media.
- **Business Logic**: **PostgreSQL RPCs (Functions)** – Atomic operations (likes/dislikes) are handled server-side to ensure data integrity.

---

## 3. Core Features & Implementation Details

### 3.1 Document Management (`DocumentController`)
- **Interaction Logic**: Mutual exclusivity for likes and dislikes is enforced recursively.
- **Optimistic UI**: Interactions (likes/bookmarks) update the UI immediately before syncing with the backend.
- **Atomic Operations**: Uses RPCs like `increment_likes` and `decrement_dislikes` to prevent race conditions in counters.

### 3.2 Media & Performance Optimization
- **Image Compression**: `ImageHelper` uses `flutter_image_compress` (70% quality, 1024px min dimensions) to optimize uploads.
- **Caching**: `CachedNetworkImage` is used for thumbnails; `saveAndOpenFile` (Dio) caches downloaded PDFs locally.
- **Bandwidth Efficiency**: Direct uploads are limited to 10MB; users are encouraged to use external hosting (Google Drive/Mega) for larger files via the `isExternalLink` toggle.

### 3.3 Security Implementation
- **Row Level Security (RLS)**: Policies in `SUPABASE_SCHEMA.sql` ensure users can only modify their own profiles and documents.
- **Admin Controls**: `is_admin` and `is_official` flags allow for moderated content and global announcements.
- **Real-time Security**: `NotificationController` applies granular filters (`receiver_id` or `is_global`) to PostgreSQL Change channels.

---

## 4. UI/UX Design Principles
- **Design System**: Material 3.
- **Aesthetic**: **Glassmorphism** (using the `glassmorphism` package) and "Premium Deep Blue" theme (`#0D47A1`).
- **Typography**: 'Plus Jakarta Sans' via Google Fonts for a clean academic feel.
- **Animations**: **Lottie** for state feedback (e.g., empty searches, success states).

---

## 5. Coding Conventions & Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` without warnings.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Safety**:
    - Always use curly braces for flow control structures.
    - Annotate intentional empty catch blocks with `// ignore: empty_catches`.
- **Android Setup**: Target SDK 36, Java 17, and MultiDex enabled.

---

## 6. Directory Structure
- `lib/controller/`: Business logic and reactive state management (GetX).
- `lib/model/`: Data entities (DocumentModel, UserModel, CommentModel).
- `lib/view/`: Modular UI screens and reusable widgets.
- `lib/service/`: Infrastructure services (Caching, Notifications).
- `lib/core/`: Global configurations, themes, and helper utilities.

---
*Analyzed and Documented by Jules, AI Software Engineer.*
