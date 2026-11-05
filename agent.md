# Serious Study (formerly NoteHub) - Developer Technical Manual & System Architecture Guide

This document is the authoritative, developer-centric technical manual for **Serious Study** (formerly NoteHub). It provides a deep architectural breakdown, codebase audit, performance benchmark review, design system specification, security audit, and maintenance instructions across all layers of the Android application and its backend infrastructure.

---

## 1. System Overview & Architectural Topology

Serious Study is an academic content sharing, peer-to-peer collaboration, and educational networking mobile platform engineered specifically for the Mumbai University student ecosystem. The platform was migrated from a legacy Django/MongoDB monolithic backend to a fully serverless, real-time, event-driven architecture powered by **Supabase (PostgreSQL 15+)** and **Flutter (Material 3)**.

### Architectural Blueprint
```
┌─────────────────────────────────────────────────────────────────────────┐
│                    FLUTTER FRONTEND CLIENT (GetX MVC)                   │
├─────────────────────────────────────────────────────────────────────────┤
│ Views & Widgets (Glassmorphic Material 3 / GoogleFonts.plusJakartaSans) │
│       │                               ▲                                 │
│       ▼                               │                                 │
│ GetxControllers (State, Business Logic, Optimistic UI Updates)          │
│   ├── AuthController         ├── UploadController                       │
│   ├── HomeController         ├── ShowcaseController                     │
│   ├── DocumentController     ├── NotificationController                 │
│   └── ProfileController      └── RemoteConfigController                 │
│       │                               ▲                                 │
├───────┼───────────────────────────────┼─────────────────────────────────┤
│       ▼                               │                                 │
│ Core Services & Storage Helpers       │                                 │
│   ├── HiveBoxes (NoSQL user session & download metadata box)            │
│   ├── FileCaching & FileDownload (Dio + path_provider + OpenFile)       │
│   ├── ImageHelper (flutter_image_compress 70% JPEG)                     │
│   └── NotificationService (flutter_local_notifications)                 │
└───────┬───────────────────────────────┬─────────────────────────────────┘
        │ REST / Realtime Websocket     │ Signed URLs / Chunked Uploads
        ▼                               ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         SUPABASE SERVERLESS CLOUD                       │
├───────────────────────────────────┬─────────────────────────────────────┤
│ Supabase Auth (JWT Argon2/Bcrypt) │ Supabase Storage ('documents' bucket)│
├───────────────────────────────────┼─────────────────────────────────────┤
│ PostgreSQL Database Engine        │ Realtime Engine (Postgres Changes)  │
│   ├── profiles                    │   ├── public:documents              │
│   ├── documents (Notes/Tweets)    │   ├── public:notifications          │
│   ├── comments (Nested Tree)      │   ├── public:interactions           │
│   ├── interactions (Likes/Dislikes│   └── public:remote_config          │
│   ├── bookmarks & followers       │                                     │
│   └── Stored Procedures (RPCs)    │ Row Level Security (RLS) Policies   │
└───────────────────────────────────┴─────────────────────────────────────┘
```

---

## 2. Directory & File-by-File Technical Audit

### 2.1 Entrypoint & App Configuration
- **`notehub/lib/main.dart`**:
  - Initializes Flutter bindings (`WidgetsFlutterBinding.ensureInitialized()`).
  - Bootstraps Supabase Client using singleton credentials (`AppMetaData.supabaseUrl`, `AppMetaData.supabaseAnonKey`).
  - Initializes `FlutterLocalNotificationsPlugin` for Android foreground notifications.
  - Initializes `Hive.initFlutter()`, registers `UserModelAdapter()`, and pre-opens `user` and `downloads` NoSQL boxes.
  - Injects global singleton controllers: `BottomNavigationController`, `ShowcaseController`, `NotificationController`.
  - Wraps the application inside `ToastificationWrapper` and `GetMaterialApp` targeting Material 3 with primary seed `#0D47A1`.
- **`notehub/lib/layout.dart`**:
  - Central bottom navigation scaffold connecting 5 tabs: Home, Search, Upload, Official, and Profile.
  - Dynamically registers tab-level GetX controllers on `initState`: `ProfileController`, `ProfileUserController`, `DocumentController`, `DownloadController`, `RemoteConfigController`.
  - Triggers initial profile synchronization via `HiveBoxes.username`.
- **`notehub/lib/core/meta/app_meta.dart`**:
  - Central static configuration storing `appName` ("Serious Study"), asset paths, Supabase credentials, and avatar fallback generators.
- **`notehub/lib/core/helper/hive_boxes.dart`**:
  - Encapsulates low-latency key-value read/writes using Hive binary storage.
  - Provides getters: `username`, `userId`, `displayName`, `profileUrl`.
  - Manages session lifecycle (`setUser`, `resetUser`) and offline download persistence (`addDownload`, `getDownloads`).

### 2.2 Controllers (`notehub/lib/controller/`)
- **`auth_controller.dart`**:
  - Handles authentication workflows: `loginWithEmail`, `registerWithEmail`, `logout`.
  - Validates user input before network transmission (`verifyForm`).
  - Performs post-auth profile auto-provisioning with exponential retry mechanism (`fetchAndStoreProfile`).
  - Aggregates relational metrics (`documents`, `followers`, `following`) via exact count queries and saves them directly to `HiveBoxes`.
- **`home_controller.dart`**:
  - Manages the primary community feed, official announcements, and dynamic topic filtering (`All`, `Engineering`, `BSc IT`, `BMS`, etc.).
  - Batches document queries with `.limit(50)` and sticky sorting by `created_at DESC`.
  - Realtime subscription via `supabase.channel('public:documents').onPostgresChanges(...)` to auto-fetch when new notes are created.
  - Implements `fetchOfficialUpdates` capped at 20 documents for high-priority broadcast display.
- **`document_controller.dart`**:
  - Manages document detail lifecycle, user-specific document queries, likes, dislikes, bookmarks, and deletions.
  - **Optimistic UI Engine**: Immediately toggles client boolean flags (`isLiked`, `isDisliked`, `isBookmarked`) and increments/decrements numeric counters before firing network mutations, reverting state upon failure.
  - Calls PostgreSQL stored procedures (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`) to guarantee atomic counters.
  - Implements `_syncWithHome()` to synchronize state across active controllers.
- **`upload_controller.dart`**:
  - Handles multi-part content submissions (Notes vs. Tweets).
  - Enforces a 10MB direct upload ceiling (`selectedDocument.value!.size > 10 * 1024 * 1024`), redirecting oversized items to cloud links (Google Drive/Mega).
  - Integrates `ImageHelper.compressImage()` on cover images prior to Supabase Storage dispatch.
  - Handles administrative verification tag assignment (`is_official`) for verified admin users.
- **`comment_controller.dart`**:
  - Powers threaded discussion sections supporting top-level comments and nested replies (`parent_id`).
  - Optimistic local list insertion with temporary client IDs (`temp_<timestamp>`) replaced seamlessly upon server response.
  - Triggers asynchronous user interaction notifications for note authors.
- **`notification_controller.dart`**:
  - Manages real-time alerts using Supabase Realtime Channels (`public:notifications`).
  - Subscribes to database `INSERT` events, checking if incoming notifications are global announcements or targeted to `auth.uid()`.
  - Interacts with `flutter_local_notifications` to pop system heads-up notifications.
  - Supports administrative global announcement broadcasting (`broadcastAnnouncement`).
- **`search_controller.dart`**:
  - Executes dynamic queries against `documents` using SQL ILIKE pattern matching (`ilike('name', '%query%')`) and topic filters.
  - Maps relational joins with safe profile fallbacks.
- **`connection_controller.dart`**:
  - Queries bidirectional user social graphs (`follows` table) for follower/following listings.
- **`showcase_controller.dart`**:
  - Fetches user-uploaded documents and bookmarked documents using relational filters (`filter('id', 'in', docIds)`).
- **`remote_config_controller.dart`**:
  - Listens to `public:remote_config` table for dynamic, over-the-air feature flags and announcements (`maintenance_mode`, `global_announcement`) without requiring APK redeployment.

### 2.3 Services & Data Layer
- **`service/file_caching.dart`**:
  - Temporary download manager using `Dio` and `path_provider`. Checks `ifFileExists(savePath)` before initiating network transfer.
- **`service/file_download.dart`**:
  - Persistent document storage service. Downloads assets to application documents directory with real-time download percentage notifications and `open_file` intent launches.
- **`service/notification_service.dart`**:
  - System notification channel initialization (`notes_channel`, high priority).
- **`model/`**:
  - `user_model.dart` / `user_model.g.dart`: Hive-serialized user entity (TypeID: 0).
  - `document_model.dart`: Notes/Tweets schema representation with interaction state flags.
  - `mini_user_model.dart`: Lightweight follower/following social entity.
  - `post_model.dart`: Social feed entity.

---

## 3. In-Depth Performance Analysis

### 3.1 State Management & UI Reactivity
- **GetX Reactive Flow (`Rx`, `Obx`, `GetBuilder`)**:
  - UI components isolate rebuild boundaries using targeted `Obx()` listeners (e.g., `upload_screen.dart` loading overlay, `home_document_section.dart` shimmer/list switches).
  - `DocumentController` utilizes `GetBuilder` for low-overhead re-renders during rapid user interactions (likes/dislikes), minimizing widget tree traversal.
  - Automatic memory deallocation: Ephemeral controllers are cleaned up on route changes, while core controllers (`BottomNavigationController`, `ShowcaseController`) are retained globally via `Get.put()`.

### 3.2 Local Persistence & Caching
- **Hive Binary Storage**:
  - Instantaneous cold starts: User session data and authorization tokens are read synchronously from `HiveBoxes.userBox`, eliminating splash screen latency.
  - Downloaded document index is tracked locally in `downloadsBox` to enable instant offline access without redundant network metadata queries.

### 3.3 Media Pipeline & Compression
- **Image Pre-Processing**:
  - `ImageHelper.compressImage()` compresses user-selected cover graphics to JPEG format at 70% quality, reducing average upload payload from ~4MB to ~250KB before dispatching to Supabase Storage.
- **Network Image Caching**:
  - `cached_network_image` with memory and disk LRU caching is utilized across all card components (`DocumentCard`, `HomeHeader`, `CustomAvatar`), eliminating duplicate asset fetching and preventing frame drops during list scrolling.

### 3.4 Database Query Efficiency & Atomic Operations
- **Pagination and Batching**:
  - Home feed queries enforce `.limit(50)`, bounding memory consumption and payload transit time.
  - Official update queries enforce `.limit(20)`.
- **Atomic Counter Integrity (RPCs)**:
  - User interaction counters are not updated client-side via table updates. Instead, PostgreSQL functions (`increment_likes`, `decrement_likes`, etc.) execute atomic `SET likes_count = likes_count + 1` operations within database transactions, preventing race conditions during concurrent upvoting.

---

## 4. Design System & UI/UX Architecture

### 4.1 Theme & Aesthetics
- **Material 3 Paradigm**:
  - Dynamic color scheme seeded from **Premium Deep Blue** (`#0D47A1`), representing the formal academic identity of Mumbai University.
- **Glassmorphism**:
  - Translucent layers with subtle linear gradients (`AppGradients.glassGradient`) and border outlines (`Colors.white.withValues(alpha: 0.15)`) applied to navigation headers, bottom footer, and modal dialogs.
- **Color Tokenization (`lib/core/config/color.dart`)**:
  - Primary shades (`PrimaryColor.shade100` through `shade900`).
  - Danger/Destructive shades (`DangerColors.shade100` through `shade900`).
  - Monochromatic grayscale tokens (`GrayscaleWhiteColors`, `GrayscaleGrayColors`, `GrayscaleBlackColors`).
  - Semantic accents (`OtherColors.premiumGold`, `royalBlue`, `tigerLily`).

### 4.2 Typography Hierarchy (`lib/core/config/typography.dart`)
- Integrated **Plus Jakarta Sans** via `google_fonts`:
  - Headings 1 through 8 (`fontSize: 40` down to `18`, weights `FontWeight.bold` / `w800`).
  - Subheadings 1 through 3 (`fontSize: 16` down to `12`, weight `FontWeight.w600`).
  - Body styles 1 through 4 (`fontSize: 16` down to `10`, weights `FontWeight.w500` / `w600`).

### 4.3 Micro-Interactions & Feedback
- **Shimmer Placeholders**: `Shimmer.fromColors` mimics real document cards during asynchronous PostgREST requests.
- **Heart Pop Animation**: `LikesWithHeart` widget in `DocumentCard` runs an elastic scale sequence (`1.0 -> 1.3 -> 1.0`) over 200ms when liked.
- **Toasts**: Standardized notifications via `toastification` (`Toasts.showTostSuccess`, `showTostError`, `showTostWarning`).

---

## 5. Comprehensive Security Audit

### 5.1 Authentication & Session Integrity
- **JWT Architecture**:
  - User authentication is delegated entirely to **Supabase Auth** using cryptographically signed JSON Web Tokens (RS256).
  - Passwords are encrypted on Supabase infrastructure using Bcrypt/Argon2 password hashing; no raw password values are stored or logged client-side.
  - Deep link redirection configured via Android intent filters (`io.supabase.flutternotehub://login-callback`).

### 5.2 Row Level Security (RLS) Policy Audit
Every database table in `SUPABASE_SCHEMA.sql` has Row Level Security enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`):

| Table | Policy Name | Command | Rule / Definition | Security Implication |
| :--- | :--- | :--- | :--- | :--- |
| `profiles` | Public viewable | `SELECT` | `USING (true)` | Open directory for student networking |
| `profiles` | Insert own profile | `INSERT` | `WITH CHECK (auth.uid() = id)` | Prevents user impersonation |
| `profiles` | Update own profile | `UPDATE` | `USING (auth.uid() = id)` | Prevents editing other student accounts |
| `documents` | Public viewable | `SELECT` | `USING (true)` | Unrestricted discovery of open study notes |
| `documents` | Insert own documents | `INSERT` | `WITH CHECK (auth.uid() = user_id)` | Enforces authentic authorship |
| `documents` | Update/delete own | `ALL` | `USING (auth.uid() = user_id)` | Prevents unauthorized content tampering |
| `documents` | Admin document update | `UPDATE`| `USING (auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true))` | Allows moderation by verified admins |
| `comments` | Public viewable | `SELECT` | `USING (true)` | Open academic discourse |
| `comments` | Insert own comments | `INSERT` | `WITH CHECK (auth.uid() = user_id)` | Strict author verification |
| `notifications` | Receiver read only | `SELECT` | `USING (auth.uid() = receiver_id)` | Guarantees notification privacy |

### 5.3 Privilege Escalation & Content Integrity
- **Administrative Rights**:
  - The `is_admin` attribute on `profiles` is protected from client-side alteration by explicit RLS check constraints and database rules.
  - Official badges (`is_official = true`) are restricted in UI triggers and database checks to verified administrative identities.
- **Storage Bucket Access**:
  - The `documents` bucket enforces folder separation (`auth.uid()/*`), preventing users from deleting or overwriting assets belonging to other contributors.

### 5.4 Android Native Security Configuration
- **Android Manifest (`notehub/android/app/src/main/AndroidManifest.xml`)**:
  - `android:exported="true"` strictly bounded to `MainActivity` with explicit `LAUNCHER` and `VIEW` deep-link intent filters.
  - Text processing queries restricted via `<queries><intent><action android:name="android.intent.action.PROCESS_TEXT"/></intent></queries>`.
- **SDK Compilation**:
  - `compileSdk = 36`, `targetSdk = 36`, `minSdkVersion = 21`.
  - Java 17 compatibility with `coreLibraryDesugaringEnabled true` (`desugar_jdk_libs:2.1.4`) and `multiDexEnabled true`.

---

## 6. Maintenance, QA & Zero-Warnings Compliance

### 6.1 Prerequisites
- **Flutter SDK**: 3.24+ (Channel Stable)
- **Dart SDK**: ^3.5.4
- **Java**: JDK 17 (Temurin recommended)
- **Android SDK**: Build Tools 36.0.0, Platform API 36

### 6.2 Code Quality Standards
To ensure zero warnings under `flutter analyze`:
1. **Color Alpha Compatibility**: Use `.withValues(alpha: <0.0 - 1.0>)` instead of the deprecated `.withOpacity()`.
2. **Switch Controls**: Use `activeThumbColor` instead of the deprecated `activeColor` on `Switch` widgets.
3. **Flow Control**: Enforce explicit curly braces on all `if`, `else`, `for`, and `while` control blocks.
4. **Exception Handling**: Avoid silent empty `catch` blocks without proper annotations (`// ignore: empty_catches`) or loggers.

### 6.3 Automated CI/CD Workflows
- **`flutter-build.yml`**:
  - Compiles the release APK (`flutter build apk --release`) under Android SDK 36 and Java 17.
  - Uploads generated artifact (`app-release.apk`) to GitHub Actions release storage.
- **`dart.yml`**:
  - Executes `flutter pub get`, `flutter analyze`, and `flutter test` inside the `notehub/` directory on every push and pull request to `main`.

---
*Manual compiled and verified for Serious Study development team.*
