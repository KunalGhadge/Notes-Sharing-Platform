# Serious Study (formerly NoteHub) - Developer Technical Manual & System Architecture

This document serves as the comprehensive, developer-perspective technical specification, system architecture overview, performance audit, design system manual, and security audit for the **Serious Study** Android application.

---

## 1. Executive System Overview & Stack Architecture

Serious Study is a high-performance notes-sharing and academic networking platform specifically tailored for the Mumbai University student community. The application provides seamless sharing of study resources, previous year question papers (PYQs), important question sets (IMPs), official announcements, and peer-to-peer discussions.

The system was migrated from a legacy Django/MongoDB architecture to a modern, serverless **Supabase (PostgreSQL)** backend paired with a **Flutter** client.

```
+-----------------------------------------------------------------------+
|                          FLUTTER FRONTEND                             |
|  +---------------------+  +---------------------+  +-----------------+  |
|  |  GetX Controllers   |  |     Hive NoSQL      |  | Glassmorphism / |  |
|  | (Reactive Business) |  |   (Local Storage)   |  |   Material 3    |  |
|  +----------+----------+  +----------+----------+  +--------+--------+  |
+-------------|------------------------|----------------------|---------+
              |                        |                      |
              v                        v                      v
+-----------------------------------------------------------------------+
|                       SUPABASE BACKEND (PostgreSQL)                   |
|  +---------------------+  +---------------------+  +-----------------+  |
|  |    Supabase Auth    |  | Row Level Security  |  | Atomic RPCs &   |  |
|  |     (JWT / OAuth)   |  |     (RLS Engine)    |  | PostgreSQL Trigg|  |
|  +---------------------+  +---------------------+  +-----------------+  |
|  +---------------------------------------------------------------+  |
|  |                   Supabase Storage Buckets                     |  |
|  +---------------------------------------------------------------+  |
+-----------------------------------------------------------------------+
```

### Tech Stack Breakdown
- **Client Framework**: Flutter 3.24+ (Dart SDK ^3.5.4) targeting Android (compileSdk 36, Java 17).
- **State Management & DI**: `GetX` for reactive state, dependency injection, and decoupled route management.
- **Local Storage / Caching**: `Hive` NoSQL database for instant startup session hydration and metadata storage.
- **Backend Infrastructure**: Supabase (Serverless PostgreSQL, Realtime, Managed Auth, Storage).
- **Networking & I/O**: `supabase_flutter` for API/Auth queries, `dio` for chunked media downloads and file caching, `flutter_image_compress` for media optimization.

---

## 2. File-by-File Component & Architectural Mapping

The codebase enforces a decoupled, modular MVC-like architecture separated into `controller`, `core`, `model`, `service`, and `view` layers inside `notehub/lib/`.

```
notehub/lib/
├── main.dart                          # Application entry point, Supabase & GetX initialization
├── layout.dart                        # Master Scaffold wrapper with Bottom Navigation bar
├── controller/                        # GetX Reactive Business Logic Controllers
│   ├── auth_controller.dart           # User authentication, registration, session sync
│   ├── bottom_navigation_controller.dart # Bottom bar tab index state
│   ├── comment_controller.dart        # Comment threads, nested replies, deletion
│   ├── connection_controller.dart     # Peer connections and follow/unfollow logic
│   ├── document_controller.dart       # Note interactions (like, dislike, bookmark, delete, open)
│   ├── download_controller.dart       # Track local file downloads
│   ├── file_controller.dart           # File selection and picking
│   ├── home_controller.dart           # Feed fetching, real-time subscription, pagination
│   ├── notification_controller.dart   # Real-time activity notifications and read status
│   ├── post_controller.dart           # Short update (tweet) content management
│   ├── profile_controller.dart        # User profile state and current session profile
│   ├── profile_user_controller.dart   # Other users' profiles and follow actions
│   ├── remote_config_controller.dart # Dynamic server configuration and feature flags
│   ├── search_controller.dart         # Query filtering and search history
│   ├── showcase_controller.dart       # Profile content tabs (uploaded docs vs bookmarked)
│   └── upload_controller.dart         # Document/Tweet upload pipeline and compression
├── core/                              # Global Configurations, Design System, & Helpers
│   ├── config/
│   │   ├── color.dart                 # Color palette, Premium Deep Blue, Glass gradients
│   │   └── typography.dart            # Standardized typography scale
│   ├── helper/
│   │   ├── custom_icon.dart           # SVG vector icon renderer and avatar helper
│   │   ├── hive_boxes.dart            # Hive box initialization (`userBox`, `downloadsBox`)
│   │   └── image_helper.dart          # Image compression pipeline using `flutter_image_compress`
│   └── meta/
│       └── app_meta.dart              # Global constants, API endpoints, Supabase keys
├── model/                             # Strongly Typed Data Models
│   ├── document_model.dart            # Notes, Tweets, metadata, and user interactions
│   ├── mini_user_model.dart           # Lightweight user preview data
│   ├── post_model.dart                # Social feed post representations
│   ├── user_model.dart                # Complete profile data model with Hive TypeAdapter
│   └── user_model.g.dart              # Generated Hive serialization code
├── service/                           # Core Low-Level System Services
│   ├── file_caching.dart              # Dio-based local file download and temp storage manager
│   ├── file_download.dart             # Local notifications integrated download service
│   └── notification_service.dart      # Flutter Local Notifications configuration
└── view/                              # Material 3 & Glassmorphism UI Views
    ├── auth_screen/                   # Login, Registration, and Auth header/form widgets
    ├── bottom_footer/                 # Floating glassmorphic bottom navigation bar
    ├── connection_screen/             # Community members & peer discovery list
    ├── document_screen/               # Detailed document view, PDF launcher, comment thread
    ├── home_screen/                   # Feed view, official updates, shimmer skeletons
    ├── notification_screen/           # User notification center
    ├── official_screen/               # Filtered feed showing official university updates
    ├── onboarding_screen/             # New user onboarding screens
    ├── profile_screen/                # User profile, follower counts, document showcase tabs
    ├── search_screen/                 # Real-time document/user search with filters
    ├── settings_screen/               # App configuration and About Serious Study view
    ├── splash_screen/                 # Startup splash with Lottie vector animation
    ├── upload_screen/                 # Resource upload form with official toggle & progress
    └── widgets/                       # Reusable UI elements (cards, buttons, toasts, admin badge)
```

---

## 3. Deep-Dive Performance Engineering Analysis

### 3.1 Reactive UI State Management (GetX)
- **Granular Updates**: The app uses `Obx`, `GetX`, and targeted `update()` calls rather than broad `setState()` invocations. Controller states (e.g., `DocumentController.userDocs`, `HomeController.documents`) trigger updates only in dependent UI subtrees.
- **Optimistic UI Updates**: Interactions such as likes, dislikes, and bookmarks immediately mutate local UI state before awaiting network responses from Supabase. In the event of a network failure or Postgrest error, state is seamlessly rolled back to ensure UI consistency without screen flickering.

### 3.2 High-Performance Caching Layer (Hive NoSQL & Dio)
- **Startup Hydration**: Session data and user profile metadata are stored in Hive (`userBox`, accessed via `HiveBoxes.dart`). Startup screens read directly from local storage, eliminating startup blocking and rendering user profiles instantaneously.
- **File Download Management**: The `file_caching.dart` service uses `Dio` with custom headers to download resources into local temporary directories. Before requesting files over the network, it checks local cache directories to prevent unnecessary bandwidth consumption.
- **Media Caching**: All external images and user avatars utilize `CachedNetworkImage` with memory and disk cache limits, minimizing network overhead during continuous scroll.

### 3.3 Media Compression Pipeline
- Direct image uploads pass through `ImageHelper.compressImage()` (`lib/core/helper/image_helper.dart`).
- Compression converts images to high-efficiency JPEG format with 70% quality and caps dimensions at 1024x1024, reducing network payload sizes by up to 80% prior to uploading to Supabase Storage.

### 3.4 Database Query & Counter Optimization
- **Atomic Database Functions (RPCs)**: Instead of read-modify-write patterns on the client (which suffer from race conditions under concurrent load), counter mutations (likes, dislikes) execute PostgreSQL RPCs (`increment_likes`, `decrement_likes`, etc.).
- **Batching & Pagination**: Feed queries fetch in batches (50 items limit) sorted by `created_at DESC` to keep payload sizes predictable.

---

## 4. UI/UX System Paradigm & Aesthetics

```
+-----------------------------------------------------------------+
|                       DESIGN SYSTEM PALETTE                     |
|                                                                 |
|  [ #0D47A1 ]  Premium Deep Blue  - Primary Branding Accent       |
|  [ #1976D2 ]  Royal Blue        - Secondary Gradient Stop       |
|  [ #FFD700 ]  Gold              - Admin & Official Badges       |
|  [ #FFFFFF ]  Glass Overlay     - Alpha 0.1 / 0.15 Transparency |
+-----------------------------------------------------------------+
```

- **Material 3 Paradigm**: Built on Material 3 guidelines using customized `ThemeData` and typography scale (`lib/core/config/typography.dart`).
- **Glassmorphism & Gradients**: Uses `GlassmorphicContainer` and custom `AppGradients.glassGradient` with modern `.withValues(alpha: ...)` transparency overlays for bottom navigation and floating card Headers.
- **Rebranding**: Standardized on **Premium Deep Blue** (`#0D47A1`) to project academic credibility for the Mumbai University community.
- **Asynchronous Feedback**: Shimmer placeholders (`Shimmer.fromColors`) prevent layout shifts during asynchronous network fetches. Lottie animations (`assets/animations/notes.json`) provide responsive feedback for splash screens and empty states.

---

## 5. Security Audit & Database Architecture

### 5.1 Relational Schema (`SUPABASE_SCHEMA.sql`)
1. `profiles`: Extends Supabase `auth.users` with `username`, `display_name`, `institute`, `is_admin`, `followers`, `following`, `documents`.
2. `documents`: Stores notes and short updates (`post_type` IN `'note'`, `'tweet'`). Includes `is_external` for links and `is_official` for university verified posts.
3. `comments`: Supports nested discussions using self-referencing foreign keys (`parent_id REFERENCES comments(id)`).
4. `interactions`: Uniquely tracks user reactions (`like` / `dislike`) per document.
5. `bookmarks`: Tracks saved documents per user.
6. `notifications`: Powers real-time notification feeds.
7. `followers`: Maps peer-to-peer user follow relationships.
8. `remote_config`: Key-value JSON storage for feature flags.

### 5.2 Security Mechanisms & Row Level Security (RLS)

| Vulnerability Vector | Legacy Django/MongoDB State | Modern Serious Study State |
| :--- | :--- | :--- |
| **Authentication** | Session-less custom auth | **Supabase Auth (JWT)** with secure token storage |
| **Password Storage** | Plain text / basic hash | **Argon2 / Bcrypt Hashing** managed in isolated auth schema |
| **Privilege Escalation** | Client-side role checks | **RLS WITH CHECK** validation on profile and document updates |
| **Atomic Counter Integrity** | Vulnerable client updates | **PostgreSQL SECURITY DEFINER RPCs** |
| **Search Path Hijacking** | N/A | Functions explicitly enforce `SET search_path = public` |

```sql
-- Profile Update Policy Enforcement (Prevents Admin Escalation)
CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
  );

-- Official Post Permission Enforcement
CREATE OR REPLACE FUNCTION check_official_permission()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_official = true THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    ) THEN
      RAISE EXCEPTION 'Only administrators can create official posts.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 6. Android Platform Engineering & Build Configurations

The Android build setup in `notehub/android/` is engineered for modern Android SDK compatibility and smooth local notification execution:

- **Target & Compile SDK**: `compileSdk = 36`, `targetSdk = 36`.
- **Java Compatibility**: Configured for Java 17 source and target compatibility (`JavaVersion.VERSION_17`) in `app/build.gradle`.
- **Desugaring**: Enabled `coreLibraryDesugaringEnabled true` with `com.android.tools:desugar_jdk_libs:2.1.4` to support modern Java APIs across older Android versions.
- **MultiDex**: `multiDexEnabled true` configured to prevent dex method limits caused by notification and Supabase dependencies.
- **Permissions (`AndroidManifest.xml`)**:
  - `INTERNET`: For Supabase REST and Realtime WebSocket communication.
  - `POST_NOTIFICATIONS`: For local download progress notifications.
  - `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE`: Managed dynamically for document downloading and opening.

---

## 7. Developer & QA Operations (Zero Warnings Policy)

### 7.1 Verification & Analysis Commands
Developers working on this repository must enforce strict code quality rules:

1. **Static Analysis**:
   ```bash
   cd notehub && flutter analyze
   ```
   *Requirement*: Must return `No issues found!`. All color opacities must use `.withValues(alpha: ...)`, all flow control statements must have curly braces, and Switch controls must use `activeThumbColor`.

2. **Unit & Integration Tests**:
   ```bash
   cd notehub && flutter test
   ```
   *Requirement*: All tests in `test/` (e.g., `dummy_test.dart`) must pass successfully.

3. **Visual Verification Procedure**:
   To visually verify frontend UI changes:
   ```bash
   cd notehub && flutter run -d web-server --web-port 8080
   ```
   Use Playwright scripts or automated browser checks to capture screenshots or record user journeys.

---
*Maintained and documented by Jules, AI Software Engineer.*
