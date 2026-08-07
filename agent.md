# Developer Technical Guide & Maintenance Manual - Serious Study

This is the definitive developer guide, system architecture blueprint, and maintenance manual for **Serious Study** (formerly NoteHub), the premium academic networking and notes-sharing platform tailored for the Mumbai University student community.

---

## 1. High-Level System Architecture Diagram

```
                 +-------------------------------------------------------------+
                 |                         Flutter UI                          |
                 |  (Material 3 UI, Glassmorphic effects, Premium Deep Blue)   |
                 +---------------------------------+---------------------------+
                                                   |
                                                   v
                 +-------------------------------------------------------------+
                 |                    GetX State Management                     |
                 |      (Controllers: Auth, Home, Upload, Document, etc.)      |
                 +--------+------------------------+-------------------+-------+
                          |                        |                   |
                          | (Read/Write Sessions)  | (Local Files)     | (API/Realtime)
                          v                        v                   v
                 +-----------------+      +-----------------+ +----------------+
                 |   Hive Cache    |      |  File Caching   | | Supabase Client|
                 | (User profile,  |      |   (Dio + Path   | | (JWT Auth, DB, |
                 | download list)  |      |    Provider)    | | Storage, RLS)  |
                 +-----------------+      +-----------------+ +--------+-------+
                                                                       |
                                                                       v
                                                              +----------------+
                                                              |  PostgreSQL DB  |
                                                              | (RPCs, Triggers|
                                                              |  RLS, Schema)  |
                                                              +----------------+
```

---

## 2. Comprehensive File-by-File Technical Directory

Below is the structured mapping of all principal components across the notehub repository:

### 2.1 Core Architectural Layers (`lib/core/` and `lib/main.dart`)
- **`lib/main.dart`**: Entrypoint for the application. Initializes Supabase connection parameters asynchronously using `Supabase.initialize()`. Registers global Hive boxes for persistence, sets up standard SystemChrome overlays, and launches the GetX router targeting the `SplashView`.
- **`lib/layout.dart`**: Handles the root layout, coordinating screen transitions via the `BottomNavigationController` and linking the main application tabs.
- **`lib/core/meta/app_meta.dart`**: Centralized metadata dictionary. Declares static final global configurations such as database connection parameters, default support email, and constants like `AppMetaData.appName`.
- **`lib/core/config/color.dart`**: Defines the premium rebranding guidelines. Swaps generic colors with the academic **Premium Deep Blue** (`#0D47A1`). Utilizes modern `.withValues(alpha: ...)` conversions for glassmorphic elements to ensure zero compilation warnings.
- **`lib/core/config/typography.dart`**: Hosts global GoogleFonts implementations. Configures typography scales for headlines, subheadings, body text, and caption hierarchies to enforce UI uniformity.
- **`lib/core/helper/hive_boxes.dart`**: Exposes the key high-performance, synchronous database containers for offline and immediate startup responsiveness.
  - `userBox`: Local cache storing user registration and active session profile attributes.
  - `downloadsBox`: Maintains key-value mapping of local downloaded path mappings of resource documents.
- **`lib/core/helper/image_helper.dart`**: Image pre-processing utility. Leverages `flutter_image_compress` to compress uploads targeting a maximum resolution of 1024x1024 and 70% JPEG quality.

### 2.2 Core Business Controllers (`lib/controller/`)
- **`AuthController`**: Manages auth workflows including Sign In, Registration, JWT extraction, and registration profiles sync. Initializes profile creations and defaults the institution to `Mumbai University`.
- **`HomeController`**: Core orchestrator for feed presentation. Directs infinite scrolls, content caching, and real-time subscription channels (`public:documents`). Fetches official content and supports `fetchOfficialUpdates` capped to the top 20 documents.
- **`DocumentController`**: Handles detailed view states for documents, downvotes, upvotes, and bookmarks. Discharges actions through PostgreSQL Remote Procedure Calls (RPCs) to ensure synchronization. Executes `_syncWithHome()` to synchronize states.
- **`UploadController`**: Enforces strict payload validation rules (mandatory document title, topic description, and cover assets). Applies a **10MB upload threshold** for local resource documents and handles direct external links (e.g., GDrive or Mega) seamlessly.
- **`CommentController`**: Orchestrates nested/hierarchical dialogue interfaces underneath individual documents. Employs optimistic rendering techniques to present responses prior to DB roundtrip completion.
- **`NotificationController`**: Monitors, counts, and lists pending global and specific notifications.
- **`SearchController`**: Provides low-latency multi-filter queries utilizing debounce techniques to restrict excessive backend lookups.
- **`DownloadController`**: Manages real-time progression tracking for background download tasks.

### 2.3 Services (`lib/service/`)
- **`file_caching.dart`**: Implements efficient localized file check routines using a combination of `Dio` downloaders and standard `path_provider` directory caches, preventing duplicate asset pulls over high-cost cellular connections.
- **`file_download.dart`**: Invokes native Android Download Manager APIs and issues platform notifications upon file completion.
- **`notification_service.dart`**: Configures native system notification hooks utilizing the `flutter_local_notifications` library.

### 2.4 Views & Widgets (`lib/view/`)
- **`lib/view/auth_screen/`**: Houses user access screens (login/registration) implementing standard input fields.
- **`lib/view/home_screen/`**: Render engine for student feeds, containing the top banner, topic filters, and list views.
- **`lib/view/upload_screen/`**: Composes the upload wizard. Employs the administrative "Official" toggle governed by `activeThumbColor: const Color(0xFFB8860B)` to satisfy standard modern Switch deprecation warnings.
- **`lib/view/document_screen/`**: Displays document details, interactive counters, and nested comments using `CommentSection`.
- **`lib/view/profile_screen/`**: Profile presentation workspace for user details, document tallies, followers, and bio options.

---

## 3. Deep-Dive Performance Profile & Optimization Strategies

To maintain an agile, low-resource profile on student smartphones, Serious Study implements several strategic optimization design choices:

1. **State Partitioning (GetX MVC)**: Rather than invoking monolithic parent rebuilds, screens are split into atomic visual nodes enclosed in `Obx(() => ...)` wrappers. Only relevant segments of the widget tree (e.g., likes/dislikes counts) rebuild upon state changes.
2. **Local Persisted State**: Using Hive as a synchronous key-value layer eliminates asynchronous delays during initial loading, allowing immediate render of critical user elements (avatar, name, academic interests) from `userBox` before checking network state.
3. **Optimistic Updates**: Action interfaces like likes, dislikes, and bookmarks trigger immediate visual state increments on the local client thread. If the background Supabase API requests fail, states are gracefully rolled back.
4. **Batch Fetching & Sticky Sorts**: Document feeds use pagination with page bounds capped to 50 items. Sort operations and official content filters are executed on the PostgreSQL server, returning pre-filtered sets and conserving mobile CPU.
5. **Pre-upload Compression & Validation**: High-resolution image files are compressed before upload to minimize network payload. The client enforces a strict 10MB limit on PDF uploads.

---

## 4. Rebranding Design Guidelines & Aesthetic Standards

The visual identity of Serious Study balances technical capability and modern aesthetics.

- **Brand Theme - Premium Deep Blue**:
  - Primary Theme Color: Deep academic blue `#0D47A1` (Material 3 standard).
  - Surface Overlays: Glassmorphism backing, leveraging semitransparent layers (`Colors.white.withValues(alpha: 0.15)`) coupled with subtle blur backdrops (`BackdropFilter`).
  - Dark Mode Adapters: Background elements shift to deep slate palettes (`#121212`) paired with stark neon blue typography accents.
- **Modern Color Manipulations**:
  - Legacy `withOpacity(x)` methods are deprecated. All code must utilize the modern `.withValues(alpha: x)` method from Flutter's upgraded color engine to prevent precision loss.
- **Modern Input Components**:
  - Switches must use `activeThumbColor` instead of the legacy `activeColor` to avoid deprecated API warnings.
  - Interactive elements must implement clear visual feedback, using Shimmer placeholders during network requests and Lottie animations for empty states.

---

## 5. Security Architecture, RLS Policy Analysis, & Privilege Escalation Audit

The migration from a legacy custom-auth Django stack to a serverless Supabase environment introduces several key security enhancements:

```
                    +------------------------------------+
                    |        Client Request              |
                    | (Contains User JWT + Operation)    |
                    +-----------------+------------------+
                                      |
                                      v
                    +------------------------------------+
                    |      Supabase Gateway              |
                    | (Validates JWT, Checks Expiry)     |
                    +-----------------+------------------+
                                      |
                                      v
                    +------------------------------------+
                    |      Row Level Security (RLS)      |
                    |   (Evaluates Table SQL Policies)   |
                    +--------+------------------+--------+
                             |                  |
               [Passes policy]                  [Fails policy]
                             v                  v
                    +----------------+  +----------------+
                    | Execute Action |  | Access Denied  |
                    | (Read/Write DB)|  |  (401/403)     |
                    +----------------+  +----------------+
```

### 5.1 RLS Security Blueprint
Every transaction targeting the database is evaluated against explicit Postgres Row Level Security (RLS) rules:
1. **Profiles (`public.profiles`)**:
   - `SELECT`: Allowed globally (`USING (true)`).
   - `INSERT`: Restriced to owner profiles matching the authenticated user's ID (`auth.uid() = id`).
   - `UPDATE`: Restriced to owner profiles matching the authenticated user's ID (`auth.uid() = id`). Includes a `WITH CHECK` constraint to prevent standard users from escalating their privileges to `is_admin = true`.
2. **Documents (`public.documents`)**:
   - `SELECT`: Allowed globally.
   - `INSERT`: Restricted to owners matching the document's `user_id`.
   - `UPDATE`/`DELETE`: Restricted to the document's creator (`auth.uid() = user_id`) or administrative accounts with `is_admin = true` verified in their profile.
3. **Bookmarks & Interactions**:
   - Only the creator of a bookmark/interaction can view or manage it, preventing unauthorized scrapers from analyzing other users' reading patterns.

### 5.2 Protection Against Privilege Escalation
- **Security Definer Database Functions**: High-traffic atomic updates (e.g., `increment_likes`) run via dedicated PostgreSQL RPC functions configured with `SECURITY DEFINER`. This runs the logic with administrative database privileges to update global totals, but prevents users from directly editing document records.
- **Search Path Protection**: To prevent search-path hijacking attacks, all `SECURITY DEFINER` procedures are explicitly declared with `SET search_path = public`.
- **Administrative Content Verification**: Setting `is_official = true` on a document is restricted via an database trigger (`ensure_official_permission`) that checks the `is_admin` status of the posting profile before committing.

---

## 6. Maintenance, Quality Assurance, & Clean Compilation Guidelines

To keep the Serious Study repository reliable and maintainable, development must adhere to the following maintenance procedures:

### 6.1 Prerequisites & Toolchains
- **Required Flutter SDK**: `^3.24.0` (Dart SDK `^3.5.4` on the stable channel).
- **Target Platform Details**:
  - Android API Targets: `compileSdk 36`, utilizing `Java 17` source and target compilation standards.
  - Gradle Modules: Enabled with `multiDexEnabled` and `coreLibraryDesugaring` for broad Android backwards compatibility.

### 6.2 Zero-Warnings Policy
Developers must run static analysis before pushing code to avoid compile errors:
```bash
cd notehub && flutter analyze
```
Any warnings regarding deprecated members (`withOpacity`, `activeColor`), missing curly braces in flow structures, or empty catch blocks must be corrected immediately. If an empty catch block is explicitly necessary, document it using the `// ignore: empty_catches` annotation placed on its own line inside the block to avoid parsing errors.

### 6.3 Automated Verification Suite
Ensure all changes compile cleanly and do not break existing functionality by executing the test suite:
```bash
cd notehub && flutter test
```

---
*Maintained and curated by the Serious Study Developer Community.*
