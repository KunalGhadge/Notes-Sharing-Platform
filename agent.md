# Developer Guide & Maintenance Manual - Serious Study (NoteHub)

This document serves as the highly detailed primary system manual, developer guide, and system-wide analysis of **Serious Study** (formerly NoteHub). It offers deep technical insights into performance, architecture, design patterns, database schemas, security configurations, and maintenance procedures.

---

## 1. Architectural Design & Diagram

Serious Study follows a decoupled, highly reactive architectural model. By combining **Flutter + GetX** with a serverless, database-driven **Supabase** backend, the application bypasses complex middleware layers while preserving strict security boundaries.

### Decoupled GetX MVC & Supabase Serverless Architectural Flow

```
+=============================================================================+
|                          FLUTTER CLIENT SIDE (MVC)                          |
+=============================================================================+
|                                                                             |
|   +---------------------------------------------------------------------+   |
|   |                       VIEW LAYER (UI Screens)                       |   |
|   |   e.g., Home, Document Detail, Profile, Upload, Notifications       |   |
|   +---------------------------------------------------------------------+   |
|                            |                           ^                    |
|                User Action | Triggers                  | Obx / GetBuilder   |
|                (e.g. Like) | Controller                | UI Updates         |
|                            v                           |                    |
|   +---------------------------------------------------------------------+   |
|   |                       CONTROLLER LAYER (GetX)                       |   |
|   |   e.g., HomeController, DocumentController, AuthController, etc.     |   |
|   |   - Manages local state (Rx types / .obs)                           |   |
|   |   - Performs Optimistic UI updates before backend responses         |   |
|   +---------------------------------------------------------------------+   |
|                            |                           ^                    |
|           Supabase Client  | Invokes PostgreSQL RPC /  | Returns Query /    |
|           API/SDK Call     | Real-time Changes         | Real-time Payload  |
|                            v                           |                    |
+============================|===========================|====================+
                             |                           |
+============================|===========================|====================+
|                     SUPABASE SERVERLESS BACKEND (CLOUD)                     |
+============================|===========================|====================+
|                            v                           |                    |
|   +---------------------------------------------------------------------+   |
|   |                        POSTGRESQL DATABASE                          |   |
|   |                                                                     |   |
|   |   [ Row-Level Security (RLS) Engine ] <---------------------------+ |   |
|   |       - Intercepts and filters operations based on JWT payload    | |   |
|   |                                                                   | |   |
|   |   [ Tables & Relations ]                                          | |   |
|   |       - Profiles, Documents, Comments, Interactions, Bookmarks    | |   |
|   |                                                                   | |   |
|   |   [ Functions & RPCs (Security Definer) ]                         | |   |
|   |       - Atomic operators: increment_likes, decrement_dislikes     | |   |
|   |                                                                   | |   |
|   |   [ Triggers ]                                                    | |   |
|   |       - ensure_official_permission (guards official label updates)| |   |
|   +---------------------------------------------------------------------+   |
|                            |                           |                    |
|                Auth Events | JWT Tokens                | Object Operations  |
|                            v                           v                    |
|               +-----------------------+     +------------------------+      |
|               |  SUPABASE AUTH (JWT)  |     |   SUPABASE STORAGE     |      |
|               |  Argon2/Bcrypt Hash   |     |  Documents & Covers    |      |
|               +-----------------------+     +------------------------+      |
|                                                                             |
+=============================================================================+
```

---

## 2. File-by-File & Component Mapping

The notehub codebase is partitioned strictly to adhere to the MVC architecture:

```
notehub/
├── android/                   # Native Android configuration (compileSdk 36, Java 17 compatibility)
├── assets/                    # High-quality Vector Graphics (SVGs) & Lottie assets
├── lib/
│   ├── main.dart              # Application Bootstrapper (Configures Supabase, local Hive, GetX, & Local Notifications)
│   ├── layout.dart            # Standard shell layout handling bottom navigation switches
│   ├── controller/            # Business Logic Controllers (GetX Dependency-Injected States)
│   │   ├── auth_controller.dart          # Directs User Auth & registration flow; default college value 'Mumbai University'
│   │   ├── bottom_navigation_controller.dart # Oversees shell navigation indices
│   │   ├── comment_controller.dart       # Handles comment creation, fetching, and nested parent-child replies
│   │   ├── connection_controller.dart    # Coordinates followers/following state updates
│   │   ├── document_controller.dart      # Standard controller handling note interactions (Likes, bookmarks, deletions)
│   │   ├── download_controller.dart      # Controls current local downloads registry
│   │   ├── file_controller.dart          # Governs native file-picking processes
│   │   ├── home_controller.dart          # Supplies global home feeds, limiting official docs stream to 20 elements
│   │   ├── notification_controller.dart  # Updates users on real-time activity indicators
│   │   ├── post_controller.dart          # Manages individual user feed structures
│   │   ├── profile_controller.dart       # Coordinates logged-in user profile changes
│   │   ├── profile_user_controller.dart  # Tracks detailed screens of foreign profiles
│   │   ├── remote_config_controller.dart # Holds dynamic operational parameters fetched from database key-value stores
│   │   ├── search_controller.dart        # Implements on-the-fly and localized query processing
│   │   ├── showcase_controller.dart      # Runs overlay walkthroughs for first-time onboarding
│   │   └── upload_controller.dart        # Manages content submissions with size limitations and fields validity rules
│   ├── core/                  # Core Constants and System-Wide Helpers
│   │   ├── config/
│   │   │   ├── color.dart                # Central Palette Definition (Primary: Premium Deep Blue Color #0D47A1)
│   │   │   └── typography.dart           # Uniform font styling based on system standards
│   │   ├── helper/
│   │   │   ├── custom_icon.dart          # Standard custom icon set
│   │   │   ├── hive_boxes.dart           # Instantiates 'userBox' (auth tokens/profile caches) and 'downloadsBox' (download records)
│   │   │   └── image_helper.dart         # Downscales uploaded images to JPG, 70% quality, 1024x1024 max dimensions
│   │   └── meta/
│   │       └── app_meta.dart             # Project name, Supabase instance URL, and publishable Anon Keys
│   ├── model/                 # Data parsing objects incorporating serializable adapters
│   │   ├── document_model.dart           # Models academic notes, post types, likes, external sources flags
│   │   ├── mini_user_model.dart          # Lightweight profile objects for quick loads
│   │   ├── post_model.dart               # Models feed posts and social metadata
│   │   ├── user_model.dart               # Complete user model generated by Hive (user_model.g.dart)
│   ├── service/               # External Operations Engine
│   │   ├── file_caching.dart             # Utilizes Dio and path_provider to check local temp storage before downloading
│   │   ├── file_download.dart            # Directly interacts with hardware storage to download/save academic documents
│   │   └── notification_service.dart     # Emits local and remote system events through local notification plug-ins
│   └── view/                  # Modular User Interface Widgets & Screens
│       ├── auth_screen/                  # Handles user registration and login
│       ├── bottom_footer/                # Standardized global navigation footer bar (Glassmorphism inspired)
│       ├── connection_screen/            # Displays networks of academic friends and followers
│       ├── document_screen/              # Implements the note viewer page with likes, descriptions, and comments
│       ├── home_screen/                  # Displays the community activity streams and recent uploaded documents
│       ├── notification_screen/          # Shows recent interactions (such as likes and custom comment replies)
│       ├── official_screen/              # Feeds strictly vetted academic documents (limited to 20 for optimized latency)
│       ├── onboarding_screen/            # Introductory sliding screens
│       ├── profile_screen/               # Renders standard user configuration tabs and submitted documents
│       ├── search_screen/                # Multi-faceted index querying system
│       ├── settings_screen/              # General legal compliance, system configuration options, and "About" screen
│       ├── splash_screen/                # Immediate bootstrap loading placeholder
│       ├── upload_screen/                # Upload forms with "Official" toggle restricted by administrative flags
│       └── widgets/                      # Global UI building blocks (Lottie renderers, Shimmer elements, Toasts)
```

---

## 3. Performance Audit

Serious Study is highly optimized to run efficiently on low-tier mobile devices and under constrained cellular network environments.

### 3.1 Reactive State Management (GetX)
- Rather than forcing screen-wide rebuilds, GetX leverages reactive observables (`.obs`) and `Obx` wrappers.
- Database listener channels directly stream to precise controller variables, minimizing UI lag and saving processing cycles on both Android and iOS devices.

### 3.2 High-Performance Local NoSQL Cache (Hive)
- Traditional relational SQLite instances suffer high overhead for simple key-value reads. Hive stores structured user details (`userBox`) as binary data, returning session variables with sub-millisecond response times.
- Document and attachment identifiers are cataloged in `downloadsBox`. When a user attempts to open a document, the application instantly verifies if the asset is already stored locally on the device, eliminating unnecessary network round-trips.

### 3.3 Network Payload Minimization
- **Lazy Fetching and Batching**: The `HomeController` limits document fetching queries to increments of 50 documents to prevent payload bloat.
- **Official Streams Pagination**: To avoid slowing down the main feed, the `fetchOfficialUpdates` method restricts high-priority vetted official updates to the 20 most recent documents.
- **External Redirection**: To save Supabase storage bandwidth, `UploadController` enables external URL routing (e.g., GDrive/Mega link uploads), preventing direct file transfers when possible.

### 3.4 Active Asset Optimization
- **CachedNetworkImage**: Network graphics use disk-based cache structures to avoid redundant downloads on scroll events.
- **Image Compression Pipeline**: The `ImageHelper.compressImage` routine intercepts picture uploads, converting them to compressed JPEG formats at 70% quality and scaling them to a maximum resolution of 1024x1024 pixels. This prevents large high-resolution images from bloating remote storage and slowing down client-side rendering.

### 3.5 Database-Level Computations (PostgreSQL RPCs)
- Direct client-side increments (e.g. `likes = likes + 1` followed by a database update) are highly vulnerable to race conditions and consume extra API resources.
- Serious Study offloads this processing to the backend by utilizing PostgreSQL RPC functions (`increment_likes`, `decrement_dislikes`, etc.) defined in `SUPABASE_SCHEMA.sql`. This ensures atomic operations with a single lightweight API call.

---

## 4. UI/UX & Rebranding Design Analysis

The application features a modern, premium design system tailored to the academic community of Mumbai University.

```
       [ Premium Color Accent ]           [ Glassmorphic Visuals ]
       #0D47A1 - Premium Deep Blue        Backdrop Gradients (15% Alpha)
       #FFD700 - Premium Gold             Clean UI Layering Separators
```

### 4.1 Modern Material 3 & Glassmorphism Aesthetic
- The layout is styled after **Material 3** guidelines, prioritizing soft rounded corners, high contrast ratios, and accessible typography.
- Glassmorphism is integrated using semi-transparent overlay borders (`Colors.white.withValues(alpha: 0.15)`) coupled with customized color transitions (`AppGradients.premiumGradient`). This provides a smooth, premium visual experience.

### 4.2 Seamless Content Navigation
- The navigation drawer and header bars use modern blur patterns to separate contents without adding visual clutter.
- High-visibility badges, such as the `AdminBadge` and verified official icons, draw users to important content.

### 4.3 Visual Feedback and Placeholders
- **Shimmer Indicators**: Complex modules (e.g. `HomeDocumentSection` or Search results) render animated shimmer skeletons rather than static loaders during data fetching. This keeps users engaged and improves perceived load times.
- **Lottie Animators**: Dynamic empty states and successful uploads are rendered using lightweight, high-performance Lottie animations.

---

## 5. Security Audit & Supabase Migration

The migration of the platform from a legacy Django/MongoDB stack to a serverless Supabase configuration addressed several critical security vulnerabilities:

### 5.1 Authentication Integrity
- **Legacy Stack**: Simple, unhashed custom session storage.
- **Supabase Stack**: Integrated **Supabase Auth (JWT)**. Authenticators validate JSON Web Tokens directly, securing communications across all layers. Passwords are securely hashed on the server using modern hashing algorithms (Argon2/Bcrypt).

### 5.2 Row Level Security (RLS) Policy Audit
Every table in the `public` schema has Row-Level Security enabled. This ensures that users can only access or modify data they are authorized to see:

1. **`profiles` Table**:
   - `SELECT`: Public access, allowing users to view other students' profiles.
   - `INSERT`: Restricted to users whose authenticated UID matches the target ID (`auth.uid() = id`).
   - `UPDATE`: Restricted to users whose authenticated UID matches the target ID (`auth.uid() = id`).

2. **`documents` Table**:
   - `SELECT`: Public access, so students can browse shared notes.
   - `INSERT`: Restricted to authenticated users submitting files under their own account (`auth.uid() = user_id`).
   - `UPDATE` & `DELETE`: Restricted to the document's creator (`auth.uid() = user_id`).
   - **Admin Access**: Standard administrative overrides (such as updating documents) are protected using a database verification query:
     ```sql
     CREATE POLICY "Admins can update documents" ON public.documents
       USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
     ```

3. **`comments` Table**:
   - `SELECT`: Public read access for social threads.
   - `INSERT`: Restricted to authenticated users commenting under their own ID.

4. **`notifications` Table**:
   - `SELECT`: Restricted to the message recipient (`auth.uid() = receiver_id`).

### 5.3 Preventing Privilege Escalation (Content Verification)
- **Problem**: Unauthorized users could try to set `is_official = true` on their posts to bypass quality reviews.
- **Mitigation**: The database schema uses a PostgreSQL trigger (`ensure_official_permission`) that checks if the author has `is_admin` set to `true` in their user profile. If a non-admin tries to create or update a document with `is_official` set to `true`, the operation is aborted directly at the database level.

### 5.4 Preventing Search-Path Hijacking
- All security-critical Postgres triggers and functions (such as `check_official_permission`) are declared with an explicit search path:
  ```sql
  SET search_path = public;
  ```
  This prevents search-path hijacking attacks, which could occur if the database search path was manipulated to point to malicious schemas.

---

## 6. Development, QA, & Maintenance Guide

To maintain a healthy, warning-free codebase, developers must adhere to the following standards:

### 6.1 System Requirements & SDK Versioning
- **Flutter SDK**: `^3.24.0` (Channel Stable)
- **Dart SDK**: `^3.5.4` (Ensures compatibility with modernized features like `.withValues()` and `activeThumbColor` properties)
- **Java SE Development Kit**: `17` (Targeting compileSdk version 36 on Android)

### 6.2 "Zero Warnings" Policy & Code Quality Standards
To keep the codebase clean and maintainable, all code must pass the project's static analysis rules:
1. **Color Modernization**: Do not use deprecated `.withOpacity()` calls on Colors. Instead, use `.withValues(alpha: ...)` for color transparency:
   ```dart
   // DO:
   Colors.white.withValues(alpha: 0.15)

   // DON'T:
   Colors.white.withOpacity(0.15)
   ```
2. **Switch Controls**: When defining `Switch` elements (such as the "Official Document" toggle), always set `activeThumbColor` to resolve the deprecation of `activeColor`:
   ```dart
   Switch(
     value: isOfficial,
     activeThumbColor: const Color(0xFFB8860B),
     onChanged: (val) { ... },
   )
   ```
3. **Structured Flow Control**: Avoid using inline single-statement loops or if-blocks without braces. Always enclose blocks in curly braces:
   ```dart
   // DO:
   if (condition) {
     doSomething();
   }

   // DON'T:
   if (condition) doSomething();
   ```
4. **Exception Handling**: Avoid leaving catch-blocks completely empty. If an error must be ignored, place the `// ignore: empty_catches` annotation on its own line *inside* the block to keep the code readable and maintain the "Zero Warnings" standard:
   ```dart
   try {
     performOperation();
   } catch (e) {
     // ignore: empty_catches
   }
   ```

### 6.3 QA Checks & Verification
Before pushing changes to production, developers must run the following checks to verify codebase health:
- **Lint Verification**: Run `flutter analyze` inside the `notehub` directory. This command must return **zero warnings** or errors.
- **Unit Testing**: Run `flutter test` inside the `notehub` directory to verify core logic and catch regressions.

---
*Verified and Documented by Jules, AI Software Engineer.*
*Updated: August 2026*
