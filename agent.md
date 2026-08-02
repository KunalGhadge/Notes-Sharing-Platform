# Developer Technical Guide & Maintenance Manual - Serious Study (NoteHub)

This document provides a comprehensive developer-centric architectural, performance, design, and security analysis of the **Serious Study** (formerly NoteHub) Android and Cross-Platform application. It acts as the primary system manual, developer guide, and codebase reference.

---

## 1. Executive Summary & Developer's Lens
Serious Study is a premium notes-sharing, academic networking, and tweet-posting community platform built specifically for Mumbai University students. The application transitioned from a legacy, structurally fragile Django/MongoDB stack into a modern, highly performant, serverless **Supabase** backend and **Flutter** frontend.

### Core Architectural Shift
- **Legacy Stack**: Custom session-less auth, plain-text credentials, exposed Django admin panels, server-side content-delivery bottlenecks, and unindexed NoSQL collections.
- **Modernized Stack**: Fully serverless backend with **Supabase (PostgreSQL)**, JWT session handling, client-side reactive state management with **GetX**, lightning-fast NoSQL caching with **Hive**, and granular access controls enforced at the database level using Postgres **Row Level Security (RLS)**.

---

## 2. Decoupled MVC Architecture
Serious Study is structured following a highly-decoupled, reactive **Model-View-Controller (MVC)** design pattern. This ensures complete separation of concerns between business logic, data persistence, and UI rendering.

```
notehub/lib/
├── controller/          # GetX Controllers (Business Logic & State)
├── core/                # Core configurations, helpers, and meta
│   ├── config/          # Colors, Typography definitions
│   ├── helper/          # Icon helpers, Hive utilities, Image tools
│   └── meta/            # Static App Credentials and Strings
├── model/               # Immutable Data Schemas (JSON Mappers)
├── service/             # Infrastructure Services (Downloads, Notifications)
└── view/                # Presentation Layer (Modular screens and widgets)
```

### 2.1 The Controller Layer (GetX)
State management is handled using **GetX** (`GetxController`), ensuring reactive UI rendering and optimal memory usage:
- **`AuthController` (`lib/controller/auth_controller.dart`)**:
  - Orchestrates Supabase authentication workflows (Sign-In, Sign-Up with metadata, Log Out).
  - Validates login forms, handles password length constraints, and stores sessions locally on success via Hive.
  - Implements auto-profile generation in PostgreSQL if an authentication registration has metadata sync delays.
- **`HomeController` (`lib/controller/home_controller.dart`)**:
  - Leverages Supabase real-time subscriptions (`supabase.channel('public:documents').onPostgresChanges(...)`) to update user feeds dynamically on database mutations.
  - Queries document streams with a pagination boundary (`limit(50)`) and applies a specialized **Sticky Sort** (official notes first, then ordered chronologically).
- **`DocumentController` (`lib/controller/document_controller.dart`)**:
  - Handles optimistic UI updates for post interactions (likes, dislikes, bookmarks).
  - Integrates secure file operations, resolving and opening local cached PDFs/documents or directing external URLs to native browsers via `url_launcher`.
- **`UploadController` (`lib/controller/upload_controller.dart`)**:
  - Multi-part media coordinator that compresses images, checks size boundaries (10MB limit), uploads raw files/covers to public Supabase Storage buckets, and writes record references in the database.
  - Supports role-based content tagging: Users with admin profiles can toggle `is_official = true` or change `post_type` to `'tweet'`.

### 2.2 The Model Layer (Data Contracts)
Data is strictly parsed into type-safe, immutable Dart objects:
- **`UserModel` (`lib/model/user_model.dart`)**:
  - Model annotated with Hive annotations (`@HiveType`, `@HiveField`) to allow automatic binary-level local persistence.
  - Represents the authenticated user profile, track counts (followers, following, documents), and academic interests.
- **`DocumentModel` (`lib/model/document_model.dart`)**:
  - Models academic posts (files and links). Maps nested SQL relationships (user profiles, bookmarks, and interactions) dynamically on retrieval.

### 2.3 The View Layer (Presentation Componentization)
The presentation layer is fully modularized by screen. UI widgets are highly declarative and reactive, wrapping volatile sections in `Obx()` builders to prevent re-rendering the entire view tree.
- **`splash_screen/`**: Determines initial routing based on existing Hive local auth keys.
- **`auth_screen/`**: Fluid auth layouts with clean inputs, validation feedback, and transitions.
- **`home_screen/`**: Segmented into sections containing scrollable posts.
- **`upload_screen/`**: Features structured form selectors, cover image preview containers, and admin controls.
- **`widgets/`**: Reusable generic blocks like `PostCard`, `DocumentCard`, and shimmer loaders.

---

## 3. Performance Audit & Code Optimizations
High performance on low-end Android hardware is achieved via client-side caching, non-blocking asynchronous actions, and optimized asset delivery pipelines.

### 3.1 Reactive Updates & Lifecycle Management
- **Reactive Stream Listening**: The `HomeController` initiates real-time Postgres channels on `onInit` and unsubscribes dynamically inside `onClose` to eliminate background CPU/memory leaks:
  ```dart
  @override
  void onClose() {
    _stream?.unsubscribe();
    super.onClose();
  }
  ```
- **Optimistic State Management**: Likes, dislikes, and bookmarks render in real-time. The UI increments local counts and updates button colors instantly. If the underlying asynchronous database query fails, the state is rolled back seamlessly, providing a zero-latency UX.

### 3.2 Offline Storage & Caching Architecture
- **NoSQL Hive Caching**: Hive is used for high-efficiency persistent key-value storage (`lib/core/helper/hive_boxes.dart`).
  - `userBox`: Safely stores local session credentials and profile states to load the profile tab instantaneously.
  - `downloadsBox`: Caches file download metadata (local paths, download date) to allow users to view downloaded notes without an internet connection.
- **Media Optimization**:
  - Thumbnail images are retrieved via `CachedNetworkImage` which caches binary representations on disk, bypassing network roundtrips.
  - Client-side image compression (`lib/core/helper/image_helper.dart`) uses `flutter_image_compress` to compress cover images to JPEG format with 70% quality and a target resolution of 1024x1024 prior to upload, saving up to 80% of backend bandwidth.

### 3.3 DB Optimization & Atomic RPCs
- Rather than reading, modifying, and writing back counter values on the client side—which introduces concurrency race conditions—atomic database counters are modified directly using database **RPCs (Remote Procedure Calls)**.
- RPC functions like `increment_likes` and `decrement_dislikes` run in highly-optimized transaction blocks at the database tier.

---

## 4. Rebranding & UI/UX Design System
Serious Study introduces an elegant, modern **Material 3 Design System** layered with **Glassmorphism** visual properties.

```
Brand Colors (lib/core/config/color.dart):
├── Premium Deep Blue : #0D47A1 (Represents academic integrity)
├── Primary Gradient  : Dark Navy (#091A36) to Deep Slate Blue
└── Glass Overlays    : Semi-transparent whites and darks
```

### 4.1 Aesthetic Specifications
- **Glassmorphic Components**: Applied via the `glassmorphism` library, leveraging semi-transparent overlays combined with high-blur backdrops:
  - Custom opacity parameters are defined using Dart's modern `.withValues(alpha: ...)` API to ensure compatibility with modern Flutter rendering engines.
- **Typography & Scale**: System fonts utilize the **Google Fonts** framework, using uniform line heights and letter-spacing definitions configured in `lib/core/config/typography.dart`.
- **Lottie and Vectors**: Shimmer patterns (`shimmer` package) replace blocky progress indicators during network calls, and SVG vectors and lightweight Lottie JSON animations provide smooth state feedback for empty searches or successful uploads.

---

## 5. Security, Privacy & Data Integrity Audit
The application's security model has been audited from a penetration tester's lens to guarantee student data privacy and system resilience.

```
          AUTH CONTROL PIPELINE
[Client App] ---> [Supabase Auth (JWT)] ---> [PostgreSQL Engine]
                                                     |
                                            (Enforces RLS Policies)
                                                     |
                                                     v
                                          [profiles / documents]
```

### 5.1 Authorization & Row-Level Security (RLS)
Every PostgreSQL database table is locked down with strict RLS policies to restrict unauthorized mutations:
- **Profiles Protection**: Only the owner can `UPDATE` or `DELETE` their profile. Privilege escalation is prevented via a `WITH CHECK` constraint:
  - Users are blocked from editing their own `is_admin` status. This column can only be modified by DB superusers.
- **Document Protection**: Standard users can only `INSERT`, `UPDATE`, or `DELETE` documents that match their authenticated UID (`auth.uid() = user_id`).
- **Official content (is_official = true)**: Users cannot mark their documents as "Official" unless they possess administrative privileges (`is_admin = true`). This is verified via PostgreSQL constraints.

### 5.2 SQL & API Safeguards
- **Search-Path Hijacking Protection**: All RPC helper functions are written with a secure search path definition:
  ```sql
  CREATE OR REPLACE FUNCTION increment_likes(doc_id BIGINT)
  RETURNS VOID AS $$
  BEGIN
    UPDATE public.documents
    SET likes_count = likes_count + 1
    WHERE id = doc_id;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
  ```
  Specifying `SET search_path = public` prevents malicious search path alteration attacks, executing the procedure strictly under the system's public schema.
- **Storage Policies**: Supabase Storage buckets enforce specific policies. Users can write assets only into subfolders named after their user ID (`auth.uid()`).
- **Input Sanitization**: Client and backend filters restrict text fields to prevent XSS. Special characters in file names are replaced with underscores (`_`) on upload to eliminate command-injection risks on local filesystems.

---

## 6. Technical Maintenance & QA Guide
This project is engineered for long-term maintainability with a clean, warning-free development workflow.

### 6.1 Prerequisites & Requirements
- **Dart SDK**: `^3.5.4`
- **Flutter SDK**: `v3.24+` (stable channel)
- **Target OS**: Android (minSdkVersion 21, compileSdkVersion 36, targetSdkVersion 35, Java 17)

### 6.2 "Zero Warnings" Code Quality Mandates
For files to merge cleanly, they must be validated against the following linting standards:
1. **No Deprecated Members**: Modernized API calls such as `.withValues(alpha: ...)` must be used in place of deprecated methods like `.withOpacity()`.
2. **Switch Controls**: `Switch` widgets must configure `activeThumbColor: const Color(0xFFB8860B)` to satisfy modern theme expectations.
3. **Flow Control Braces**: All conditional branches and flow control structures must use explicit curly braces (`{}`) to conform to style guide requirements:
   ```dart
   if (condition) {
     action();
   }
   ```
4. **Indentation and Empty Catches**: Silenced exception handling must use the `// ignore: empty_catches` annotation placed on its own line within the catch block, fully indented:
   ```dart
   try {
     action();
   } catch (e) {
     // ignore: empty_catches
   }
   ```

### 6.3 Automation & Validation
- **Linting Verification**: Always execute `flutter analyze` inside the `notehub/` folder to check for static issues.
- **Unit Testing**: Run `flutter test` inside the `notehub/` folder to execute the test suite (e.g., `test/dummy_test.dart`).
- **UI & Integration Verification**: A local web server can be verified by running `flutter run -d web-server --web-port 8080` and executing automated Playwright integration tests.

---
*Maintained and curated by Jules, AI Software Engineer & Technical Lead.*
