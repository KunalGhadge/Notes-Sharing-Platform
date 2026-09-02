# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides an exhaustive, developer-centric analysis of the **Serious Study** Android application architecture, performance optimizations, UI/UX design patterns, and database security framework following its migration to a serverless **Supabase** backend.

---

## 1. System Architecture & Tech Stack Overview

Serious Study is an academic content sharing and student networking platform designed for the Mumbai University community. The app follows a decoupled MVC-like architectural pattern using Flutter on the frontend and Supabase (PostgreSQL) on the backend.

```
+-----------------------------------------------------------------------+
|                          FLUTTER FRONTEND                             |
|                                                                       |
|  +--------------------+   +---------------------+   +--------------+  |
|  |     UI Views       |<->|   GetX Controllers  |<->| Local Models |  |
|  | (View/Widgets)     |   | (Business Logic)    |   | (User/Doc)   |  |
|  +--------------------+   +---------------------+   +--------------+  |
|            |                         |                     |          |
|            v                         v                     v          |
|  +-----------------------------------------------------------------+  |
|  |             Local Persistence & File Operations                 |  |
|  |         - Hive Storage (userBox, downloadsBox)                  |  |
|  |         - Dio Client & Path Provider Caching                    |  |
|  +-----------------------------------------------------------------+  |
+-----------------------------------||----------------------------------+
                                    || Network Requests (JWT Auth)
                                    v
+-----------------------------------------------------------------------+
|                         SUPABASE BACKEND                              |
|                                                                       |
|  +------------------+   +--------------------+   +-----------------+  |
|  |  Supabase Auth   |   | PostgreSQL Engine  |   | Storage Buckets |  |
|  |   (JWT Tokens)   |   | (RLS & RPC Triggers|   | (Docs & Covers) |  |
|  +------------------+   +--------------------+   +-----------------+  |
+-----------------------------------------------------------------------+
```

### Core Tech Stack
- **Frontend Framework**: Flutter 3.24+ / Dart SDK ^3.5.4 (Targeting Android compileSdk 36, Java 17).
- **State Management**: **GetX** (Reactive state management, dependency injection, and navigation).
- **Local Database**: **Hive** (Key-value local storage for user profile caching and download metadata).
- **Network & I/O**: **Supabase Flutter SDK** (Auth, PostgREST, Realtime) + **Dio** (Chunked file downloads and caching).
- **Backend Infrastructure**: Serverless **Supabase** (PostgreSQL with Row Level Security, RPC functions, and Storage Buckets).

---

## 2. Performance Analysis (Developer Perspective)

### 2.1 Reactive State Management & UI Binding
- **Granular Rebuilds**: Uses `Obx` and `GetBuilder` to minimize widget tree re-renders. UI elements only rebuild when their observed reactive variables (`RxBool`, `RxList`, `RxInt`) change.
- **Cross-Controller Synchronization**: The `DocumentController` implements reactive state sync methods (e.g., `_syncWithHome()`) to propagate interaction updates (likes, dislikes, bookmarks) across `HomeController` and `SearchController` instantly without redundant network re-fetching.

### 2.2 Local Caching & Persistence
- **Hive Boxes (`lib/core/helper/hive_boxes.dart`)**:
  - `userBox`: Caches user session details and profile metadata locally. Eliminates cold-start authentication delay by populating the UI before network validation completes.
  - `downloadsBox`: Maintains local index records of downloaded PDF/document files to prevent duplicate network downloads.
- **File Caching Service (`lib/service/file_caching.dart`)**:
  - Utilizes `Dio` and `path_provider` to check the local app directory before downloading files from Supabase Storage or external URLs.

### 2.3 Media & Asset Optimization Pipeline
- **Image Compression Pipeline (`lib/core/helper/image_helper.dart`)**:
  - Direct cover uploads pass through `flutter_image_compress` (70% JPEG quality target, max 1024x1024 dimensions) prior to upload, reducing storage footprint and bandwidth usage by up to 80%.
- **Network Image Caching**:
  - Uses `CachedNetworkImage` with memory cache limitations for document covers and user avatars, avoiding repeated HTTP image requests.

### 2.4 Database Performance & RPC Counter Offloading
- **Atomic Server-Side RPC Operations**:
  - Counters for likes, dislikes, and bookmarks are modified using atomic PostgreSQL Remote Procedure Calls (`increment_likes`, `decrement_likes`, `increment_bookmarks`, etc.) defined in `SUPABASE_SCHEMA.sql`. This prevents client-side race conditions and offloads atomic calculation overhead from the mobile client.
- **Paginated Batching**:
  - `HomeController` fetches feed records in paginated batches (50 items limit) with sticky sorting, minimizing initial payload size and memory usage.

---

## 3. Design & UI/UX Architecture

### 3.1 Aesthetic & Visual Foundations
- **Design Paradigm**: Modern **Material 3** coupled with **Glassmorphism** depth effects.
- **Color Palette & Brand Identity**:
  - **Primary Brand Color**: "Premium Deep Blue" (`#0D47A1` / `0xFF0D47A1`), symbolizing Mumbai University academic integrity.
  - **Secondary Accent**: Deep Blue Light (`#1565C0`), Dark Surface (`#121212`), Off-White background overlays.
  - **Modern Color API**: Uses `.withValues(alpha: ...)` across UI components to satisfy Dart 3.5+ color precision standards.

```dart
// Modern Material 3 Glassmorphism Overlay Standard
Container(
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1.5,
    ),
  ),
);
```

### 3.2 UI Components & Feedback Systems
- **Skeleton Screen Placeholders**: Implemented via `shimmer` package in document grids and lists to maintain continuous visual stability during asynchronous network calls.
- **Empty & Error State Feedback**: Custom `Lottie` vector animations and vector graphics (`flutter_svg`) are rendered during empty search results or network disconnections.
- **Toast Messaging**: Non-blocking `toastification` toasts communicate success, warning, or error messages to the user contextually.

---

## 4. Security Audit & Backend Integrity

### 4.1 Authentication & Session Management
- **Supabase Auth (JWT)**: Authenticates requests using JSON Web Tokens.
- **Password Security**: Managed on Supabase infrastructure via industry-standard hashing (Argon2 / Bcrypt). No raw password strings pass through local application storage.
- **Deep Linking Verification**: Secure OAuth / registration email callback handler (`io.supabase.flutternotehub://login-callback`).

### 4.2 Database Security & Row Level Security (RLS)
Every table in `SUPABASE_SCHEMA.sql` enforces Row Level Security (RLS) to ensure data isolation.

| Table Name | SELECT Policy | INSERT Policy | UPDATE / DELETE Policy |
| :--- | :--- | :--- | :--- |
| `profiles` | Public (`true`) | Authenticated Self (`auth.uid() = id`) | Authenticated Self (`auth.uid() = id`) |
| `documents` | Public (`true`) | Authenticated Self (`auth.uid() = user_id`) | Document Owner or Admin |
| `comments` | Public (`true`) | Authenticated Self (`auth.uid() = user_id`) | Comment Owner (`auth.uid() = user_id`) |
| `interactions` | Public (`true`) | Authenticated Self (`auth.uid() = user_id`) | Interaction Owner |
| `bookmarks` | Private Self (`auth.uid() = user_id`) | Authenticated Self (`auth.uid() = user_id`) | Bookmark Owner |
| `notifications`| Receiver Only (`auth.uid() = receiver_id`) | System / Authenticated Sender | Receiver Only |

### 4.3 Privilege Escalation Prevention
1. **Profile Role Protection**:
   - `profiles` table update policy is restricted to self updates, while administrative flags (`is_admin`) are guarded against self-promotion via explicit `WITH CHECK` conditions:
     ```sql
     CREATE POLICY "Users can update own profile" ON public.profiles
       FOR UPDATE USING (auth.uid() = id)
       WITH CHECK (
         is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
       );
     ```
2. **Official Verification Trigger**:
   - Setting `is_official = true` on `documents` is validated by the `check_official_permission` database function and trigger, ensuring non-admin users cannot upload or flag documents as official.
3. **RPC Function Hijacking Mitigation**:
   - All PostgreSQL functions in `SUPABASE_SCHEMA.sql` specify `SET search_path = public` to prevent search-path hijacking attacks during execution with `SECURITY DEFINER` privileges.

### 4.4 File Upload Security
- **File Constraints**:
  - `UploadController` enforces a **10MB maximum file size limit** on direct document uploads.
  - Users are encouraged to share Google Drive / Mega external links for larger media assets (`is_external = true`), keeping backend storage lean.

---

## 5. Codebase Component & Directory Mapping

```
notehub/
├── android/                   # Android native code, Manifest, Gradle build configs
├── assets/                    # Lottie animations, SVG icons, imagery
├── lib/
│   ├── controller/            # GetX Business Logic Controllers
│   │   ├── auth_controller.dart          # User authentication & session setup
│   │   ├── document_controller.dart      # Notes fetching, liking, downloading logic
│   │   ├── home_controller.dart          # Feed management & real-time updates
│   │   ├── upload_controller.dart        # Direct PDF & external link post creation
│   │   ├── profile_controller.dart       # Profile viewing, followers, user docs
│   │   ├── comment_controller.dart       # Comments and nested replies
│   │   ├── notification_controller.dart # Activity notifications feed
│   │   └── search_controller.dart        # Real-time note filtering
│   ├── core/                  # Infrastructure configurations
│   │   ├── config/                       # Colors, Gradients, App Themes
│   │   ├── helper/                       # Hive boxes, Image compression helpers
│   │   └── meta/                         # Supabase URLs, App Metadata
│   ├── model/                 # Data Transfer Objects & Deserializers
│   │   ├── document_model.dart
│   │   ├── user_model.dart
│   │   ├── comment_model.dart
│   │   └── notification_model.dart
│   ├── service/               # Dio caching and storage interaction services
│   ├── view/                  # UI Widgets & Screen Pages
│   │   ├── auth_screen/                  # Login & Registration views
│   │   ├── home_screen/                  # Feed, headers, category filters
│   │   ├── document_screen/              # Note detail page, previewer, comments
│   │   ├── upload_screen/                # Document upload & external link form
│   │   ├── profile_screen/               # User profile, bookmarks, settings
│   │   ├── notification_screen/          # Real-time notifications
│   │   └── widgets/                      # Shared Cards, Badges, Toasts, Inputs
│   ├── layout.dart            # Main bottom navigation container
│   └── main.dart              # App entrypoint & Supabase initialization
└── SUPABASE_SCHEMA.sql        # Database schema, RLS policies, RPCs, and Triggers
```

---

## 6. QA, Testing & Developer Maintenance

### 6.1 Code Quality Policy ("Zero Warnings")
All code strictly adheres to modern Dart 3.5+ linting rules:
- **Deprecated Color Calls**: `.withOpacity()` is replaced by `.withValues(alpha: ...)`.
- **Switch Widgets**: `activeColor` replaced with `activeThumbColor`.
- **Flow Control Syntax**: Mandatory curly braces on all flow control blocks (`curly_braces_in_flow_control_structures`).
- **Catch Blocks**: Explicit exception handling or properly formatted `// ignore: empty_catches` annotations on separate lines within block scopes.

### 6.2 Maintenance & Testing Commands
```bash
# 1. Fetch dependencies
cd notehub && flutter pub get

# 2. Run static analysis (Verify Zero Warnings compliance)
flutter analyze

# 3. Execute unit test suite
flutter test
```

---
*Analyzed and Documented for Serious Study Engineering Team.*
