# Developer & Technical Maintenance Manual — Serious Study (formerly NoteHub)

This manual provides an in-depth, developer-centric architectural, performance, design, security, and Android-native breakdown of **Serious Study**, an academic content-sharing and student networking platform tailored for the Mumbai University community.

---

## 1. Executive Summary & Architecture Overview

**Serious Study** operates on a modern serverless stack replacing legacy Django/MongoDB implementations with a decoupled **Flutter + Supabase** architecture.

### Key Architectural Pillars
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management & DI**: **GetX** (`GetxController`, `Rx` types, dynamic dependency injection).
- **Backend Infrastructure**: Serverless **Supabase** (PostgreSQL relational engine, managed Auth JWT, Object Storage, and Postgres Realtime).
- **Local Caching & Persistence**: **Hive** (lightweight NoSQL key-value database for user profiles and offline download metadata).
- **Networking**: Dual networking layer — `supabase_flutter` for relational queries/RPCs/Auth, and `Dio` for file downloads and bandwidth-optimized streaming.

```
+---------------------------------------------------------------------------------+
|                                Flutter Frontend                                 |
|  +--------------------+   +-----------------------+   +----------------------+  |
|  |    GetX Views      |   |   GetX Controllers    |   | Hive Caching / Boxes |  |
|  | (UI & Components)  | < | (Business Logic / Rx) | < | (User Session / Data)|  |
|  +--------------------+   +-----------------------+   +----------------------+  |
+--------------------------------------|------------------------------------------+
                                       |
                   +-------------------+-------------------+
                   |                                       |
                   v                                       v
     +---------------------------+           +---------------------------+
     |   Supabase Client / SDK   |           |    Dio Networking Client  |
     | (Auth JWT / PostgREST /   |           | (File Download & Caching) |
     | Realtime / Storage RPCs)  |           +---------------------------+
     +---------------------------+                         |
                   |                                       v
                   +-------------------+-------------------+
                                       |
                                       v
+---------------------------------------------------------------------------------+
|                                Supabase Backend                                 |
|  +--------------------+   +-----------------------+   +----------------------+  |
|  |   Supabase Auth    |   | PostgreSQL (RLS / RPC)|   |   Supabase Storage   |  |
|  |   (JWT Sessions)   |   |   (Realtime & Rules)  |   | (Documents & Covers) |  |
|  +--------------------+   +-----------------------+   +----------------------+  |
+---------------------------------------------------------------------------------+
```

---

## 2. Performance Analysis & Optimization Strategies

### 2.1 Reactive State & Controller Lifecycle
- **Decoupled Architecture**: UI components depend strictly on GetX reactive controllers (`DocumentController`, `HomeController`, `UploadController`, `ProfileController`).
- **Reactive Synchronization**: When a user likes, dislikes, or bookmarks a document in `DocumentController`, it synchronizes state back to `HomeController` (`_syncWithHome()`) without forcing full list re-fetches.

### 2.2 Dual Caching Engine
- **Hive NoSQL Storage (`lib/core/helper/hive_boxes.dart`)**:
  - `userBox`: Encapsulates local user session data (`id`, `username`, `displayName`, `profileUrl`, `institute`). Allows zero-latency startup rendering of personal profiles without waiting for remote server roundtrips.
  - `downloadsBox`: Maintains offline metadata for cached study documents.
- **Media & File Caching (`lib/service/file_caching.dart`)**:
  - `Dio` download pipeline checks local temporary disk storage (`ifFileExists`) prior to initiating HTTP GET downloads to conserve bandwidth.
  - `CachedNetworkImage` prevents redundant fetching of author avatars and document thumbnails.

### 2.3 Media & Bandwidth Optimization
- **Image Compression (`lib/core/helper/image_helper.dart`)**: Uses `flutter_image_compress` to re-encode high-resolution uploaded images into JPEG format at 70% quality and standard dimensions (1024x1024) prior to cloud upload.
- **Upload Constraints & External Link Support**: `UploadController` enforces a 10MB limit on direct file uploads and supports external links (Google Drive, Mega, OneDrive) to reduce storage consumption.

### 2.4 Database Atomic Operations (RPCs)
- **Eliminating Race Conditions**: Instead of client-side increment/decrement operations, post counters (`likes_count`, `dislikes_count`, `followers`, `following`) use PostgreSQL Functions (`SECURITY DEFINER`) for atomic execution.

---

## 3. Design Paradigm & UX System

### 3.1 Visual Aesthetics
- **Color Palette**: Rebranded to **Premium Deep Blue** (`#0D47A1`) with sleek modern accents, conveying academic trustworthiness and visual authority.
- **Glassmorphic Elements**: Utilizes translucent white overlays (`.withValues(alpha: 0.15)`) combined with backdrop effects across navigation bars (`BottomFooter`) and cards (`DocumentCard`, `PostCard`).
- **Typography & Icons**: Material 3 typography guidelines with SVG vectors (`flutter_svg`) and custom icon helpers (`lib/core/helper/custom_icon.dart`).

### 3.2 Visual Feedback & Dynamic States
- **Shimmer Placeholders**: Used in loading states for document feeds and profile headers to maintain perceived performance.
- **Lottie State Animations**: Integrated for empty search results, missing document states, and onboarding flows.
- **Toast Notifications (`Toasts`)**: Standardized alert system for user notifications (`Toasts.showTostSuccess`, `Toasts.showTostError`, `Toasts.showTostWarning`).

---

## 4. Security & Database Analysis

### 4.1 Authentication & Session Management
- **Managed JWT Auth**: Uses Supabase Auth (`supabase.auth`) with standard JWT tokens.
- **Password Security**: Managed by Supabase backend using industry-standard password hashing (Argon2/Bcrypt).

### 4.2 Database Schema & Row Level Security (RLS)
The database structure defined in `SUPABASE_SCHEMA.sql` strictly enforces data isolation through Row Level Security (RLS):

- **Profiles Table (`public.profiles`)**:
  - Public `SELECT` allowed for community interaction.
  - `INSERT` restricted to authenticated user ID: `WITH CHECK (auth.uid() = id)`.
  - `UPDATE` strictly restricted to profile owners: `USING (auth.uid() = id)`.
- **Documents Table (`public.documents`)**:
  - Public `SELECT` allowed.
  - Owners can `INSERT`, `UPDATE`, and `DELETE` their own documents: `WITH CHECK (auth.uid() = user_id)`.
  - Admin Role Policy: Admins can update/verify official materials. Privilege escalation to set `is_official = true` is controlled via database check constraints and triggers.
- **Interactions & Bookmarks (`public.interactions`, `public.bookmarks`)**:
  - Unique composite constraints `(document_id, user_id)` prevent duplicate interactions.
  - Access restricted to entity owners.

---

## 5. Android Native Configuration

The Android application is configured for modern performance and compatibility in `notehub/android/app/build.gradle`:

- **Compile SDK & Target SDK**: Configured for `compileSdk = 36` and `targetSdk = 36`.
- **Java Compatibility**: Set to **Java 17** source and target compatibility (`JavaVersion.VERSION_17`).
- **Core Library Desugaring**: Enabled (`coreLibraryDesugaringEnabled true`) with `com.android.tools:desugar_jdk_libs:2.1.4` to support Java 8+ APIs required by notification plugins on older Android SDK versions.
- **Multidex Support**: Enabled (`multiDexEnabled true`) to handle large dependency graphs without DEX method limit issues.

---

## 6. Development, QA & Maintenance

### 6.1 Prerequisites & Setup
- **Flutter SDK**: `^3.24.0` (Channel stable).
- **Dart SDK**: `^3.5.4`.

### 6.2 Code Quality & Static Analysis Guidelines
To maintain code quality and adhere to standard Flutter/Dart recommendations:
- **Color Opacity Modernization**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
- **Switch Thumb Controls**: Use `activeThumbColor` instead of deprecated `activeColor` on `Switch` widgets.
- **Flow Control Syntax**: Ensure flow control structures (`if`, `else`, `for`) use explicit curly braces `{}`.
- **Verification Command**:
  ```bash
  cd notehub && flutter analyze
  ```
- **Test Execution**:
  ```bash
  cd notehub && flutter test
  ```

---
*Maintained by Jules, AI Software Engineer & System Architect.*
