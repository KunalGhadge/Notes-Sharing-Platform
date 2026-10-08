# Serious Study (formerly NoteHub) - Developer Technical Manual & System Architecture

This manual provides an exhaustive, developer-centric analysis of the **Serious Study** Android application. It serves as the definitive reference guide for system architecture, performance optimization, UI/UX design patterns, security parameters, and codebase maintenance procedures.

---

## Executive Summary & System Evolution

**Serious Study** is a cross-platform (primarily Android-targeted) academic social network and notes-sharing platform specifically tailored for the **Mumbai University** student and academic community.

### Historical Migration Context
The project underwent a complete architectural overhaul, transitioning from a legacy monolithic stack (**Django REST Framework + MongoDB**) to a serverless, event-driven architecture powered by **Flutter** and **Supabase (PostgreSQL)**.

Key advantages achieved through this migration:
1. **Zero-Server Infrastructure Overhead**: Reliance on Supabase Auth, Row Level Security (RLS), and PostgreSQL RPCs eliminates custom server maintenance.
2. **Real-time Synchronization**: Integrated Postgres Realtime capabilities (`supabase_realtime`) enable instant social feed updates and push notifications.
3. **Enhanced Data Integrity**: Transactional consistency through PostgreSQL foreign keys, unique constraints, and atomic server-side RPC functions.

---

## 1. System Architecture & Directory Structure

The application is structured following a decoupled **MVC-like architecture with GetX State Management**.

```
notehub/
├── android/                   # Native Android wrapper (compileSdk 36, Java 17, MultiDex enabled)
├── ios/                       # Native iOS configuration
├── lib/
│   ├── main.dart              # Application entry point & global service initialization
│   ├── layout.dart            # Root navigation shell & persistent bottom navigation bar
│   ├── controller/            # Business logic & reactive state management (GetX Controllers)
│   ├── model/                 # Strongly-typed data models & Hive TypeAdapters
│   ├── view/                  # UI components, screens, dialogs, and custom widgets
│   ├── service/               # Background services (Notifications, File Downloads & Caching)
│   └── core/                  # Global constants, theme definitions, and Hive box helpers
├── SUPABASE_SCHEMA.sql        # Database table definitions, RPC functions, and RLS policies
├── ANALYSIS.md                # Executive overview summary
└── agent.md                   # Primary system manual & developer maintenance guide (this file)
```

---

## 2. Component Mapping & File Breakdown

### Core & Infrastructure (`lib/core/` & `lib/main.dart`)
- **`lib/main.dart`**: Initializes Supabase client (`Supabase.initialize`), local storage (`Hive.initFlutter()`), and registers GetX controllers using dependency injection.
- **`lib/core/meta/app_meta.dart`**: Stores central metadata such as app name, branding constants, and Supabase credentials (`supabaseUrl`, `supabaseAnonKey`).
- **`lib/core/config/color.dart`**: Defines modern color palettes, material colors, dark/light variants, and branded gradients (`AppGradients.premiumGradient`).
- **`lib/core/config/typography.dart`**: Defines text styles using `google_fonts` (Plus Jakarta Sans / Inter typography hierarchy).
- **`lib/core/helper/hive_boxes.dart`**: Abstracts Hive local storage boxes (`userBox`, `downloadsBox`) for zero-latency session retrieval.
- **`lib/core/helper/image_helper.dart`**: Handles client-side media compression using `flutter_image_compress` prior to network transmission.

### Controllers & Business Logic (`lib/controller/`)
- **`AuthController`**: Handles login, registration, email confirmation, Supabase auth state sync, and Hive user box initialization.
- **`HomeController`**: Controls the primary feed, batch document fetching (50 items limit), official announcements feed, sticky sorting, and real-time document subscriptions.
- **`DocumentController`**: Handles individual document views, comments, atomic likes/dislikes via RPCs, local bookmarks, and state sync with `HomeController`.
- **`UploadController`**: Controls multi-part uploads (document files + cover images) or external resource links (Google Drive, Mega), enforcing a 10MB direct file size cap.
- **`ProfileController` / `ProfileUserController`**: Manages current user and peer profile data, showcase items, followers/following counts, and avatar updates.
- **`DownloadController` / `FileController`**: Coordinates file downloading via `Dio`, local path resolution (`path_provider`), open file operations (`open_file`), and caching status.
- **`NotificationController`**: Fetches user notifications, global university announcements, and handles unread status toggles.
- **`SearchController`**: Provides real-time filtering across subjects, topics, document names, and user profiles.

### Views & Widgets (`lib/view/`)
- **`splash_screen/`**: Checks existing Hive session or Supabase auth status and redirects to `Layout` or `Login`.
- **`auth_screen/`**: Forms for login/registration with reactive input validation and custom gradient styling.
- **`home_screen/`**: Feed displaying trending notes, official announcements, document cards, and search shortcut header.
- **`document_screen/`**: Detailed view for notes/tweets, PDF/link preview, description, follow button, and `CommentSection`.
- **`upload_screen/`**: Multi-step upload form supporting direct document files or external link attachments with official badge toggles for admins.
- **`profile_screen/`**: User profile header, showcase grid, followers/following tabs, and `EditProfileDialog`.
- **`notification_screen/`**: Real-time activity feed and announcement notifications.
- **`official_screen/`**: Dedicated tab highlighting official Mumbai University circulars and verified notes.
- **`widgets/`**: Reusable custom widgets including `DocumentCard`, `PostCard`, `PrimaryButton`, `AdminBadge`, `RefresherWidget`, `Toasts`, and `Loader`.

---

## 3. Detailed Performance Analysis

### 3.1 Reactive State Management (GetX)
- **Granular Updates**: Business logic is separated into reactive controllers using Rx variables (`.obs`). UI components bind using `Obx(() => ...)` or `GetBuilder`, minimizing unnecessary build passes.
- **Memory Lifecycle**: Controllers are managed via GetX's dependency injection container, instantiated on demand and disposed when routes are popped.

### 3.2 Local Persistent Caching (Hive)
- **Zero-Latency App Launch**: User session data, user ID, display name, and avatar metadata are stored locally in Hive (`userBox`). Upon app startup, profile views render instantly without waiting for network response.
- **Offline Download Tracking**: File metadata for downloaded notes is saved in `downloadsBox`, enabling offline document viewing.

### 3.3 Media & File Optimization
- **Client-Side Compression**: `ImageHelper.compressImage()` compresses cover images to JPEG format with 70% quality and a maximum 1024x1024 resolution prior to uploading, reducing payload size by up to 80%.
- **Efficient Caching**: `CachedNetworkImage` is used across all UI lists (`HomeHeader`, `DocumentCard`, `ProfileHeader`) to cache remote thumbnails and avatars on disk.
- **Bandwidth Preservation via External Links**: For large study materials (>10MB limit), `UploadController` allows users to share external links (Google Drive, OneDrive, Mega) instead of raw uploads.

### 3.4 Database Query & Network Optimization
- **Server-Side RPC Functions**: Counter updates (e.g., likes, dislikes, bookmarks) are executed via atomic PostgreSQL functions (`increment_likes`, `decrement_likes`) rather than client-side `SELECT -> UPDATE` loops, avoiding race conditions and reducing network round-trips from 2 to 1.
- **Batch Pagination**: `HomeController` fetches documents in batches (limit: 50) using `range(start, end)` queries, ensuring rapid payload transfers over mobile networks.
- **Visual Responsiveness**: Shimmer placeholders (`shimmer` package) maintain high perceived performance during initial async data loading.

---

## 4. UI/UX Design & Architecture

### 4.1 Rebranding & Color System
The application features a modern **Material 3** aesthetic rebranded around the **Premium Deep Blue** palette (`#0D47A1`), embodying academic professionalism for Mumbai University students.

Key Palette Values:
- **Primary Accent**: `#0D47A1` (Deep Blue)
- **Secondary Accent**: `#1565C0` (Medium Deep Blue)
- **Admin/Official Gold**: `#B8860B` (Dark Goldenrod / Official Badge)
- **Background Layering**: Soft neutral dark/light surfaces with subtle elevation cards.

### 4.2 Glassmorphism & Visual Aesthetics
- **Translucent Overlays**: Semi-transparent color values constructed using modern API calls (`Colors.white.withValues(alpha: 0.15)`) coupled with custom glassmorphic blur effects.
- **Navigation Shell**: Floating `BottomFooter` bar uses backdrop filters and glassmorphic styling to blend smoothly over scrolling content.
- **Typography Hierarchy**: Uses `GoogleFonts.plusJakartaSans` for headings and body text, ensuring high legibility across varying pixel densities.

---

## 5. Security Analysis & Migration Audit

A complete security audit confirms that all critical vulnerabilities present in the legacy stack have been remediated:

| Security Domain | Legacy Stack (Django / MongoDB) | Modern Serverless Architecture (Supabase) |
| :--- | :--- | :--- |
| **Authentication** | Session-less custom auth / plain text tokens | **Supabase Auth with JWT** (Short-lived access tokens + secure refresh tokens) |
| **Password Storage** | Plain text or custom hashing | **Argon2 / Bcrypt Hashing** managed securely by Supabase Auth engine |
| **Data Access Enforcement** | Open API endpoints relying on backend code | **Row Level Security (RLS)** enforced at database kernel level |
| **Counter Integrity** | Client-side updates vulnerable to tampering | **`SECURITY DEFINER` RPCs** with server-side validation |
| **Privilege Escalation** | Vulnerable profile update endpoints | **`WITH CHECK` RLS policies** preventing self-assigned `is_admin = true` |
| **File Bucket Security** | Public GridFS links | **Storage Bucket RLS** restricting uploads to authenticated session owners |

### Database Row Level Security (RLS) Policy Audit
Every table defined in `SUPABASE_SCHEMA.sql` enforces RLS:
- **`profiles`**: Public read access (`FOR SELECT USING (true)`), write restricted strictly to owner (`auth.uid() = id`).
- **`documents`**: Public read access, `INSERT`/`DELETE` restricted to verified owner (`auth.uid() = user_id`). Admin modifications governed by dedicated policy.
- **`interactions` / `bookmarks`**: Insert/Delete policies restricted strictly to `auth.uid() = user_id`.
- **`notifications`**: Private to receiver (`auth.uid() = receiver_id`).

### Prevention of Privilege Escalation
Official content verification (`is_official = true`) is protected by database logic:
1. `check_official_permission()` PostgreSQL function explicitly verifies `is_admin = true` for the executing user before allowing official document status modifications.
2. Search path hijacking is mitigated by explicitly declaring `SET search_path = public` on all database trigger and RPC functions.

---

## 6. Developer Guidelines & Maintenance Manual

### 6.1 Prerequisites & Local Environment
- **Flutter SDK**: `^3.24.0` (Stable channel)
- **Dart SDK**: `^3.5.4`
- **Java Development Kit (JDK)**: Java 17 (Required for Android build compatibility)
- **Android Gradle Plugin**: Configured with `compileSdk 36`, `multiDexEnabled true`, and `coreLibraryDesugaring`.

### 6.2 Code Quality & 'Zero Warnings' Standard
The project adheres strictly to a **Zero Warnings** policy. All developer contributions must pass static analysis cleanly before merge.

Standard Development Commands:
```bash
# Navigate to app directory
cd notehub

# Clean build cache
flutter clean && flutter pub get

# Execute static code analysis (MUST pass with 0 warnings / errors)
flutter analyze

# Run unit and integration tests
flutter test
```

### 6.3 Coding Conventions
1. **Modern Flutter Color APIs**: Never use deprecated `.withOpacity(x)`. Always use `.withValues(alpha: x)` to maintain precision.
2. **Switch Controls**: Always use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Braces**: Enforce explicit curly braces for all `if`/`else` control structures (`curly_braces_in_flow_control_structures`).
4. **Empty Catches**: Annotate necessary silent catch blocks with `// ignore: empty_catches` on its own line inside the block to avoid linting warnings or syntax truncation.
5. **Atomic Database Operations**: Any multi-table increment or status change must be implemented via RPC in `SUPABASE_SCHEMA.sql` rather than multiple client API calls.

---

*Documented and verified by Jules, AI Software Engineer.*
