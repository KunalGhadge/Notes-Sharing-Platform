# Developer Guide & System Architecture Manual - Serious Study (formerly NoteHub)

> **Document Classification**: Comprehensive Technical Analysis & Developer Maintenance Guide
> **Audience**: Core Developers, System Architects, Security Engineers, and QA Specialists
> **Application Target**: Android (`compileSdk 36`, `Java 17`, Flutter 3.24+ / Dart SDK ^3.5.4)
> **Backend Architecture**: Serverless PostgreSQL via Supabase (Auth, RLS, RPCs, Storage, Realtime)

---

## Table of Contents
1. [Executive Summary & Evolution](#1-executive-summary--evolution)
2. [High-Level Architecture & Layer Decomposition](#2-high-level-architecture--layer-decomposition)
3. [File-by-File Technical Directory Audit](#3-file-by-file-technical-directory-audit)
4. [In-Depth Performance Engineering](#4-in-depth-performance-engineering)
5. [UI/UX & Design System Architecture](#5-uiux--design-system-architecture)
6. [Security Architecture & Database Audits](#6-security-architecture--database-audits)
7. [Developer Maintenance, Build Pipeline & QA Protocol](#7-developer-maintenance-build-pipeline--qa-protocol)

---

## 1. Executive Summary & Evolution

**Serious Study** (migrated from NoteHub) is a mobile community and academic networking application engineered for students at Mumbai University (MU). The application allows students to publish notes, share external educational resources (Google Drive, Mega, etc.), broadcast micro-posts ("tweets"), follow peers, bookmark study materials, and engage through threaded discussions and real-time notifications.

### Historical Context & Architectural Migration
The platform underwent an architectural migration from a legacy **Django REST + MongoDB (GridFS)** stack to a serverless **Flutter + Supabase (PostgreSQL)** architecture:
- **Authentication**: Replaced custom, stateful, session-less cookie authentication with cryptographically signed, managed **JWTs (JSON Web Tokens)** via Supabase GoTrue Auth.
- **Data Layer**: Migrated unstructured MongoDB documents to relational PostgreSQL tables with strict schema constraints, foreign key cascades, and atomic functions.
- **File Management**: Transitioned from open MongoDB GridFS endpoints to Supabase Storage with storage bucket policies and pre-upload client compression.
- **Rebranding**: Shifted from generic violet accents to an academic **"Premium Deep Blue" (`#0D47A1`)** identity adhering to Material 3 with Glassmorphic styling.

---

## 2. High-Level Architecture & Layer Decomposition

The application adopts a decoupled **Model-View-Controller (MVC)** architectural paradigm driven by **GetX** reactive state management and **Hive** local key-value persistence:

```
+-------------------------------------------------------------------------+
|                               Presentation Layer                         |
|  (lib/view/: Material 3 Views, Custom Glass Widgets, Shimmer Loaders)    |
+------------------------------------+------------------------------------+
                                     | Event Triggers & Obx Bindings
                                     v
+-------------------------------------------------------------------------+
|                               Controller Layer                          |
|  (lib/controller/: GetxController, .obs State, Optimistic UI Updates)   |
+------------------+------------------------------------+-----------------+
                   | Local Writes / Caching             | Asynchronous API Calls
                   v                                    v
+-----------------------------------+  +----------------------------------+
|           Persistence Layer       |  |          Services & API          |
|  (Hive: userBox, downloadsBox)    |  |  (Supabase Flutter SDK, Dio)     |
+-----------------------------------+  +-----------------+----------------+
                                                         |
                                                         v
                                       +----------------------------------+
                                       |      Serverless PostgreSQL       |
                                       |  (Supabase Auth, RLS, RPCs)      |
                                       +----------------------------------+
```

### Core Architectural Layers:
1. **Presentation Layer (`lib/view/`)**:
   - Pure UI widgets driven by `Obx()` listeners.
   - Decoupled from direct data manipulation; actions delegate strictly to GetX controllers.
   - Implements responsive styling using `MediaQuery` and custom design utilities (`AppTypography`, `PrimaryColor`).
2. **Controller Layer (`lib/controller/`)**:
   - Extends `GetxController` to encapsulate state, business logic, asynchronous data operations, and navigation.
   - Utilizes Rx types (`RxBool`, `RxList`, `RxInt`) and reactive workers (`ever`, `debounce`).
3. **Data & Persistence Layer (`lib/model/`, `lib/core/helper/hive_boxes.dart`)**:
   - `DocumentModel`, `UserModel`, `MiniUserModel`, and `PostModel` serialize data to and from PostgreSQL JSON structures.
   - Hive acts as an ultra-fast local binary store (Box adapters) for user profile sessions and download indexing.
4. **Backend Infrastructure (`SUPABASE_SCHEMA.sql`)**:
   - Relational database schema with strict constraints (`CHECK (post_type IN ('note', 'tweet'))`).
   - PostgreSQL RPCs (`SECURITY DEFINER`) enforce transactional atomicity for counter mutations.
   - Row Level Security (RLS) policies enforce zero-trust access control.

---

## 3. File-by-File Technical Directory Audit

Every source file in `notehub/lib/` has a distinct structural responsibility. The breakdown below details implementation mechanics from a developer's perspective.

### 3.1 Entry Point & Root Application
- **`lib/main.dart`**:
  - Initializes Flutter bindings (`WidgetsFlutterBinding.ensureInitialized()`).
  - Initializes Supabase client with parameters from `AppMetaData`.
  - Configures `FlutterLocalNotificationsPlugin` for Android foreground alert channels (`@mipmap/ic_launcher`).
  - Initializes Hive binary storage, registers `UserModelAdapter` (TypeID: 1), and opens persistent boxes (`user`, `downloads`).
  - Injects global singletons: `BottomNavigationController`, `ShowcaseController`, `NotificationController`.
  - Wraps root in `ToastificationWrapper` and mounts `GetMaterialApp` configured for Material 3.
- **`lib/layout.dart`**:
  - The master scaffold hosting the top-level bottom navigation bar (`BottomFooter`).
  - Dynamically renders pages indexed by `BottomNavigationController.currentIndex`:
    - Index 0: `HomeScreen`
    - Index 1: `SearchPage`
    - Index 2: `UploadScreen`
    - Index 3: `OfficialScreen`
    - Index 4: `ProfileScreen`

### 3.2 Core Utilities & Configurations (`lib/core/`)
- **`core/meta/app_meta.dart`**: Central static repository storing app title, asset icon paths, Supabase project URL, Anon/Publishable API keys, and UI Avatar fallback endpoints.
- **`core/config/color.dart`**: Complete color tokens including Primary Deep Blue (`#0D47A1` shades 100–900), Danger/Error palettes, Grayscale palettes, and gradient presets (`premiumGradient`, `glassGradient`).
- **`core/config/typography.dart`**: Typographic hierarchy styled with `GoogleFonts.inter()`, defining token sizes from Display/H1 (28sp bold) down to caption/label typography (10sp).
- **`core/helper/hive_boxes.dart`**: Typed encapsulation for local Hive boxes. Exposes static getters (`userId`, `username`, `displayName`, `profileUrl`), transactional setters (`setUser()`, `resetUser()`), and download index storage.
- **`core/helper/image_helper.dart`**: Pre-upload compression pipeline utilizing `flutter_image_compress`. Dynamically downsizes images with 70% JPEG quality to mitigate cellular bandwidth overhead.
- **`core/helper/custom_icon.dart`**: Icon catalog mapping academic and subject assets (mathematics, science, engineering, code).

### 3.3 Controllers (`lib/controller/`)
- **`controller/auth_controller.dart`**:
  - Controls authentication lifecycle (`loginWithEmail`, `registerWithEmail`, `logout`).
  - Validates forms client-side (regex email checks, minimum 6-character passwords).
  - Handles profile synchronization (`fetchAndStoreProfile`) with recursive backoff retry logic.
  - Computes exact profile statistics (`getCounts` for documents, followers, following) using count queries.
- **`controller/home_controller.dart`**:
  - Manages primary feed consumption (`fetchDocuments`, `fetchOfficialUpdates`).
  - Enforces batching (limit: 50 records) ordered descending by upload timestamp (`created_at`).
  - Subscribes to Supabase Postgres Realtime (`public:documents`) to ingest real-time feed updates without manual polling.
- **`controller/document_controller.dart`**:
  - Controls document interaction lifecycle: `toggleLike`, `toggleDislike`, `toggleBookmark`, `deleteDocument`.
  - Implements **Optimistic UI Updates**: Instantly mutates local Rx counters and button states; reverts on network failure.
  - Calls PostgreSQL RPCs (`increment_likes`, `decrement_likes`, etc.) for race-free database state.
  - Maintains feed cross-synchronization via `_syncWithHome()`.
- **`controller/upload_controller.dart`**:
  - Handles multi-part note and tweet creation (`uploadDocument`).
  - Enforces 10MB file limit for native document uploads.
  - Orchestrates cover thumbnail compression via `ImageHelper` and parallel upload to Supabase Storage.
  - Validates external links (Mega, Google Drive) vs native binary file uploads.
- **`controller/comment_controller.dart`**:
  - Manages threaded and flat document discussion trees (`fetchComments`, `addComment`, `deleteComment`).
  - Supports nested comment replies via `parent_id` foreign keys.
- **`controller/search_controller.dart`**:
  - Handles document search queries against document names and topic indices with debouncing.
- **`controller/profile_controller.dart` & `controller/profile_user_controller.dart`**:
  - Manages authenticated user profile updates (bio, academic interests, avatar) and public peer profile inspection (follow/unfollow actions, document listings).
- **`controller/notification_controller.dart`**:
  - Pulls user-specific and global broadcast notifications (`is_global = true`).
  - Listens to Postgres Realtime changes on `public:notifications` and routes alerts to local system notifications.
- **`controller/download_controller.dart` & `controller/file_controller.dart`**:
  - Reactive progress indicators (`downloadProgress.obs`) tracking active byte streaming.
- **`controller/bottom_navigation_controller.dart` & `controller/showcase_controller.dart`**:
  - Tab state management and onboarding feature discovery walkthrough state.

### 3.4 Services (`lib/service/`)
- **`service/file_caching.dart`**:
  - Implements filesystem caching using `Dio` and `path_provider`. Verifies whether cached file hash exists in temporary storage before initiating network downloads.
- **`service/file_download.dart`**:
  - Downloads documents to application storage using Dio byte streaming.
  - Updates `DownloadController.downloadProgress` and emits foreground Android notifications (`flutter_local_notifications`).
  - Registers completed downloads in Hive `downloadsBox` and triggers `OpenFile.open()` on user notification interaction.
- **`service/notification_service.dart`**:
  - Configures high-importance Android notification channels (`notes_channel`, `download_channel`).

### 3.5 Models (`lib/model/`)
- **`model/user_model.dart` & `model/user_model.g.dart`**: Hive-annotated (`@HiveType(typeId: 1)`) model representing the student profile, academic interests, follower counters, and admin status.
- **`model/document_model.dart`**: Domain model encapsulating note metadata, metrics (likes, dislikes), post type (`note` or `tweet`), external URL markers, and official verification badges.
- **`model/mini_user_model.dart` & `model/post_model.dart`**: Lightweight models for connection grids, social mentions, and legacy discussion bindings.

### 3.6 Views & Presentation Widgets (`lib/view/`)
- **`view/splash_screen/splash.dart`**: Verifies Supabase session validity and Hive cache presence to route immediately to `Layout` or `Login`.
- **`view/auth_screen/`**: Glassmorphic authentication portal (`login.dart`, `login_form.dart`, `login_fields.dart`, `login_header.dart`).
- **`view/home_screen/`**: Primary activity hub featuring `HomeHeader`, dynamic filter carousels, and `HomeDocumentSection` with shimmer placeholders.
- **`view/document_screen/`**: Document detail viewer (`document.dart`, `comment_section.dart`, `comment_tile.dart`, `doc_description.dart`, `follow_button.dart`).
- **`view/upload_screen/`**: Publishing studio (`upload_screen.dart`, `upload_form.dart`, `upload_button.dart`) supporting file attachments or external link insertion.
- **`view/profile_screen/`**: User profile portfolio (`profile.dart`, `profile_user.dart`, `profile_header.dart`, `post_renderer.dart`, `edit_profile_dialog.dart`).
- **`view/official_screen/`**: Dedicated verified academic updates feed (`official_screen.dart`) filtered by `is_official = true`.
- **`view/widgets/`**: Reusable design system primitives (`DocumentCard`, `PostCard`, `PrimaryButton`, `SecondaryButton`, `NormalButton`, `OptionButton`, `UploadTextField`, `AdminBadge`, `RefresherWidget`, `Toasts`, `Loader`).

---

## 4. In-Depth Performance Engineering

### 4.1 Reactive State Management (GetX)
- **Granular Widget Re-rendering**: The app avoids monolithic `setState()` calls. UI elements are selectively wrapped in `Obx(() => ...)` listening directly to minimal Rx primitives (`RxInt`, `RxBool`, `RxString`).
- **Memory Footprint & Disposals**: Controllers are bound to widget lifecycles using GetX route bindings or lazy injection (`Get.lazyPut`), releasing heavy resources upon route dismissal.

### 4.2 Optimistic UI Updates
In `DocumentController`:
1. When a user taps "Like", the local `isLiked` state toggles immediately and `likes` increments synchronously.
2. The UI renders the updated state without network latency.
3. The controller fires the asynchronous RPC to Supabase in the background.
4. If an exception occurs, the controller reverts the local counter and button state, displaying an error toast via `Toasts.showTostError()`.

### 4.3 Persistent Caching Architecture (Hive vs Network)
- **Zero-Latency Profile Startup**: `HiveBoxes.userBox` stores the serialized `UserModel`. On app launch, user info renders immediately without waiting for network authentication queries.
- **Download Tracking**: Downloaded documents are indexed locally in `HiveBoxes.downloadsBox`, allowing instant offline file lookup without re-querying the database.

### 4.4 Media Optimization & Storage Caching
- **Dynamic Compression Pipeline**: `ImageHelper.compressImage()` downscales image dimensions and compresses file byte streams to 70% quality JPEG before binary upload.
- **Memory-Efficient Image Display**: `cached_network_image` is used globally with disk caching and thumbnail size capping to minimize RAM usage.
- **Batching & Network Throttling**: The main feed in `HomeController` limits document requests to batches of 50 (`.limit(50)`), ordering by timestamp to avoid massive payload spikes.

---

## 5. UI/UX & Design System Architecture

### 5.1 Design Paradigm: Material 3 & Glassmorphism
- **Color Identity**: Standardized on **Premium Deep Blue** (`#0D47A1`), complemented by light blues (`#E3F2FD`–`#64B5F6`) and dark contrast backgrounds.
- **Glassmorphic Overlays**: Custom frosted-glass visual styling implemented via `BackdropFilter` and translucent backgrounds (`Colors.white.withValues(alpha: 0.15)`), paired with `AppGradients.glassGradient`.
- **Modern Color Modernization**: Migrated away from deprecated `.withOpacity()` to `.withValues(alpha: ...)`, ensuring precision in color compositing and zero analyzer warnings.
- **Control Consistency**: Switch widgets use `activeThumbColor` to align with modern Flutter SDK specifications.

### 5.2 Micro-Interactions & Perceived Performance
- **Shimmer Placeholders**: `HomeDocumentSection` and search views use animated `Shimmer.fromColors()` layouts mimicking card geometries to eliminate jarring blank loading states.
- **Empty State Feedback**: Lottie vector animations (`assets/animations/`) provide expressive user feedback during empty search results or offline network drops.
- **Toastification**: Non-intrusive, customizable toast alerts (`ToastificationType.success`, `.error`, `.warning`) handle notification feedback across async operations.

---

## 6. Security Architecture & Database Audits

### 6.1 Authentication & Token Lifecycle
- **Managed JWT Sessions**: Handled via Supabase GoTrue Auth. The client maintains access and refresh tokens securely in platform keystores/shared preferences.
- **Session Auto-Refresh**: Supabase Flutter SDK handles automated token refreshing on 401 expiration.

### 6.2 Row Level Security (RLS) Policy Audit
Every table in `SUPABASE_SCHEMA.sql` has Row Level Security explicitly enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`):

| Table | Operation | Scope / Policy Rule | Protection Objective |
| :--- | :--- | :--- | :--- |
| **`profiles`** | `SELECT` | `USING (true)` | Public profile visibility |
| **`profiles`** | `INSERT` | `WITH CHECK (auth.uid() = id)` | Prevents user impersonation |
| **`profiles`** | `UPDATE` | `USING (auth.uid() = id)` | Restricts updates to account owner |
| **`documents`** | `SELECT` | `USING (true)` | Public feed accessibility |
| **`documents`** | `INSERT` | `WITH CHECK (auth.uid() = user_id)` | Prevents posting on behalf of other users |
| **`documents`** | `UPDATE/DELETE` | `USING (auth.uid() = user_id)` | Restricts modification to author |
| **`documents`** | `UPDATE (Admin)`| `USING (auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true))` | Grants admin moderation control |
| **`comments`** | `SELECT` | `USING (true)` | Public comment inspection |
| **`comments`** | `INSERT` | `WITH CHECK (auth.uid() = user_id)` | Restricts author injection |
| **`notifications`**| `SELECT` | `USING (auth.uid() = receiver_id)` | Restricts private user notifications |
| **`interactions`** | `ALL` | `USING (auth.uid() = user_id)` | Enforces unique like/dislike attribution |
| **`bookmarks`** | `ALL` | `USING (auth.uid() = user_id)` | Protects saved library confidentiality |

### 6.3 Privilege Escalation Safeguards
1. **Admin Escalation Defense**:
   - `is_admin` is managed in `profiles`.
   - A critical security policy ensures regular users cannot escalate their own privilege via general profile updates.
2. **Official Post Verification**:
   - Only users with verified `is_admin = true` status are permitted to publish or update documents with `is_official = true`.
3. **Atomic RPCs & Security Definer**:
   - PostgreSQL RPCs (`increment_likes`, `decrement_likes`, etc.) are declared with `SECURITY DEFINER` and an explicit search path (`SET search_path = public`) to prevent search-path hijacking attacks.

---

## 7. Developer Maintenance, Build Pipeline & QA Protocol

### 7.1 Environment Prerequisites
- **Flutter SDK**: `^3.24.0` (channel stable)
- **Dart SDK**: `^3.5.4`
- **Java Development Kit**: JDK 17
- **Android Target**: `compileSdk 36`, `targetSdk 36`, `multiDexEnabled true`

### 7.2 Zero-Warnings Code Quality Policy
The repository strictly enforces a **Zero Warnings** standard under static analysis.

Key coding practices:
1. **Flow Control Braces**: Always use curly braces for all flow control statements (`if`, `else`, `for`, `while`) to comply with `curly_braces_in_flow_control_structures`.
2. **Modern Color Manipulation**: Never use deprecated `.withOpacity(x)`. Use `.withValues(alpha: x)` to avoid precision loss.
3. **Switch Thumb Color**: Use `activeThumbColor` instead of deprecated `activeColor` on Flutter `Switch` widgets.
4. **Empty Catch Handling**: Where empty catch blocks are intentional, place `// ignore: empty_catches` on its own distinct line inside the block to prevent commenting out trailing syntax.

### 7.3 Continuous Integration (CI) Workflow
The GitHub Actions workflow (`.github/workflows/dart.yml`) enforces automated verification on every pull request and push to `main`:
```bash
# 1. Fetch package dependencies
cd notehub && flutter pub get

# 2. Execute static analysis
flutter analyze

# 3. Execute unit & widget test suite
flutter test
```

---
*Maintained by the Serious Study Engineering & Architecture Core.*
