# Developer Guide & System Architecture Manual - Serious Study (formerly NoteHub)

This document provides an exhaustive, developer-centric analysis of the **Serious Study** platform (a modern academic notes-sharing and peer networking platform for Mumbai University students). It serves as the primary technical manual, system design guide, and maintenance documentation.

---

## 1. Executive Technical Overview & Architecture

### 1.1 Architecture Pattern
Serious Study adopts a decoupled, highly responsive **GetX Model-View-Controller (MVC)** architecture operating on top of a serverless **Supabase (PostgreSQL)** backend and local **Hive NoSQL** caching.

```
       ┌────────────────────────────────────────────────────────┐
       │                   Flutter UI Views                     │
       │  (Material 3 / Glassmorphic Layouts / Reactive Views)  │
       └──────────────────────────┬─────────────────────────────┘
                                  │ Reactive Obx / GetBuilder
                                  ▼
       ┌────────────────────────────────────────────────────────┐
       │                   GetX Controllers                     │
       │ (AuthController, DocumentController, HomeController, etc)│
       └──────────────┬──────────────────────────┬──────────────┘
                      │                          │
        Local Cache   │                          │ Network / RPCs
                      ▼                          ▼
       ┌────────────────────────┐      ┌────────────────────────┐
       │   Hive Local Storage   │      │    Supabase Server     │
       │ (userBox, downloads)   │      │ (Auth JWT, RLS, RPCs)  │
       └────────────────────────┘      └────────────────────────┘
```

### 1.2 Tech Stack Summary
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management & DI**: GetX v4.6.6
- **Local Persistent Storage**: Hive v2.2.3 & Hive Flutter v1.1.0
- **Network & Asset Caching**: Dio v5.7.0, CachedNetworkImage v3.4.1, Http v1.2.2
- **Backend Service**: Supabase Flutter SDK v2.8.1 (PostgreSQL, Auth JWT, Row Level Security, Storage Buckets, Postgres Realtime)
- **Media Compression**: `flutter_image_compress` v2.3.0
- **UI Engine**: Material 3, Glassmorphism v3.0.0, Google Fonts v8.0.2, Flutter SVG v2.0.10, Lottie v3.1.3

---

## 2. File & Component Architecture Mapping

### 2.1 Entry Point & Root Layer
- `notehub/lib/main.dart`: Application bootstrapping. Initializes Hive boxes (`userBox`, `downloadsBox`), configures Supabase with project URL and anonymous key, registers global controllers (`ConnectionController`, `AuthController`, `RemoteConfigController`), and sets up the GetMaterialApp route tree.
- `notehub/lib/layout.dart`: Core container holding the bottom navigation bar and page persistent view switcher managed by `BottomNavigationController`.

### 2.2 Controller Layer (`notehub/lib/controller/`)
- `auth_controller.dart`: Manages login, registration, password resets, profile bootstrapping, and session token persistence with Supabase Auth and Hive `userBox`.
- `bottom_navigation_controller.dart`: Handles index state and smooth navigation across main bottom bar tabs.
- `comment_controller.dart`: Coordinates fetch, creation, and nested reply hierarchy for document comments.
- `connection_controller.dart`: Monitors network connectivity state using real-time ping/connectivity checks.
- `document_controller.dart`: Core domain controller managing note fetching, like/dislike interactions via Supabase RPCs, bookmarking, and synchronizing state across `HomeController`.
- `download_controller.dart`: Manages local document download state, progress tracking, and file opening via `OpenFile`.
- `file_controller.dart`: Local file browser controller for accessing cached and downloaded document assets.
- `home_controller.dart`: Powers the main feed, supporting infinite scroll/pagination (50 batch size), sticky sorting, real-time Postgres changes listening, and fetching official university updates.
- `notification_controller.dart`: Handles user notification feeds, marking items as read, and global announcement broadcasting.
- `post_controller.dart`: Supports tweet-style academic micro-posts and short update interactions.
- `profile_controller.dart`: Controls current user profile updates, profile image uploads, academic interest tagging, and follower metrics.
- `profile_user_controller.dart`: Handles public profile viewing for other users across the platform.
- `remote_config_controller.dart`: Fetches dynamic dynamic key-value configurations from Supabase `remote_config` table without requiring application updates.
- `search_controller.dart`: Implements real-time filtering, topic searching, and document query execution.
- `showcase_controller.dart`: Manages first-time user onboarding tours and feature highlighting.
- `upload_controller.dart`: Handles document/tweet creation workflows, file validation (10MB limit), cover image compression, and external link handling.

### 2.3 Core Layer (`notehub/lib/core/`)
- `config/color.dart`: Rebranded color palette containing Premium Deep Blue (`#0D47A1`), glassmorphic background overlays, and status gradients.
- `config/typography.dart`: Text style definitions using `GoogleFonts.poppins` for clean, academic readability.
- `helper/custom_icon.dart`: Custom vector icon definitions and mapping tools.
- `helper/hive_boxes.dart`: Centralized accessors for Hive boxes (`userBox`, `downloadsBox`).
- `helper/image_helper.dart`: Compression utility using `flutter_image_compress` (70% quality target JPEG compression).
- `meta/app_meta.dart`: Application metadata, version declarations, and Supabase credentials.

### 2.4 Model Layer (`notehub/lib/model/`)
- `document_model.dart`: Data model for notes/documents including metadata, like counts, download URLs, external link flags, and official badges.
- `user_model.dart` & `user_model.g.dart`: Hive-annotated profile model for fast serialization/deserialization into local cache.
- `mini_user_model.dart`: Lightweight user profile snippet used in comment sections and follower lists.
- `post_model.dart`: Model representation for micro-posts (tweets) vs standard document uploads.

### 2.5 Service Layer (`notehub/lib/service/`)
- `file_caching.dart`: Dio-powered local cache manager ensuring files aren't re-downloaded if already present in temporary storage.
- `file_download.dart`: Platform file downloader saving files to application document directories and updating `downloadsBox`.
- `notification_service.dart`: Integrates `flutter_local_notifications` for local push notifications and background activity alerts.

### 2.6 View Layer (`notehub/lib/view/`)
- `auth_screen/`: Login, registration, and password recovery screens.
- `home_screen/`: Main feed view with tabbed sections (All, Official Updates, Top Liked).
- `document_screen/`: Detailed document viewer with preview, download actions, and comment threads.
- `upload_screen/`: Form view for publishing direct PDF notes or external Drive/Mega links.
- `profile_screen/`: User profile, academic bio, document grid, and follower stats.
- `notification_screen/`: Notifications list with real-time update indicators.
- `search_screen/`: Dynamic document and subject filter screen.
- `official_screen/`: Filtered feed showing verified university notices and materials.
- `widgets/`: Reusable Glassmorphic cards, custom text inputs, shimmer loaders, and action buttons.

---

## 3. Comprehensive Analysis by Technical Pillar

### 3.1 Performance Analysis

#### 1. Reactive State Management & Memory Efficiency
- **GetX Dependency Injection**: Controllers are lazily injected or registered on-demand, preventing memory leaks on non-active views.
- **Selective UI Rendering**: Views use `Obx` or `GetBuilder` to re-render only modified sub-trees (e.g., updating a like counter re-renders only the action button rather than the entire document list item).

#### 2. Caching Strategy & Local Persistence
- **Hive NoSQL Storage**: Reading user profile metadata from `userBox` happens synchronously in < 2ms, enabling instant app startup without splash screen delay.
- **Two-Tier File Caching**: `FileCachingService` checks local disk storage via `path_provider` before initiating network requests via `Dio`.

#### 3. Database Query & Asset Optimization
- **Atomic Database Counter RPCs**: Counter increments (`increment_likes`, `decrement_dislikes`) run on PostgreSQL via `_supabase.rpc()`, eliminating race conditions and avoiding costly full-row update queries.
- **Asset Compression**: `ImageHelper.compressImage` enforces JPEG compression with 70% quality and 1024x1024 constraint, reducing upload size by up to 80%.
- **Feed Pagination**: `HomeController` loads documents in distinct batches of 50 records to maintain constant low memory overhead regardless of database size.

---

### 3.2 Design & UI/UX Paradigm

#### 1. Visual Aesthetic
- **Material 3 Foundation**: Built using Material 3 specifications with adaptive light/dark adjustments.
- **Glassmorphic Layering**: Uses the `glassmorphism` package and modern color opacities (`.withValues(alpha: ...)`) to create clean frosted-glass cards over deep blue academic gradients.
- **Theme Color Palette**:
  - Primary Accent: Premium Deep Blue (`#0D47A1`)
  - Secondary Accent: Harvest Gold (`#B8860B`) for Official MU Verification Badges
  - Background: Glass-overlay white/dark neutrals

#### 2. User Experience & Motion Design
- **Shimmer Placeholders**: Network loading states use smooth shimmer skeletons matching exact card layout dimensions to eliminate content layout shifts.
- **Lottie & SVG Animations**: Vector graphics (`flutter_svg`) and animated empty-state micro-interactions (`lottie`) communicate app state seamlessly.

---

### 3.3 Security & Backend Infrastructure Audit

#### 1. Authentication & Session Security
- **Supabase Auth JWT**: Session tokens are cryptographically signed using JWTs. Sensitive credentials are never sent or stored in plain text.
- **Auto Refresh**: Token refreshing is managed automatically by `supabase_flutter`.

#### 2. Database Row Level Security (RLS)
Row Level Security is strictly enforced across all PostgreSQL tables in `SUPABASE_SCHEMA.sql`:

| Table | Policy Type | Enforcement Rule |
| :--- | :--- | :--- |
| `profiles` | SELECT | Publicly viewable (`true`) |
| `profiles` | INSERT / UPDATE | `auth.uid() = id` (User can only write own profile) |
| `documents` | SELECT | Publicly viewable (`true`) |
| `documents` | INSERT / UPDATE / DELETE | `auth.uid() = user_id` (Owner only) |
| `comments` | INSERT | `auth.uid() = user_id` |
| `notifications` | SELECT | `auth.uid() = receiver_id` (Private to recipient) |
| `interactions` | ALL | `auth.uid() = user_id` |
| `bookmarks` | ALL | `auth.uid() = user_id` |

#### 3. Privilege Escalation Prevention & Search Path Hijacking
- **Admin Verification**: The `documents` update policy verifies admin privileges against the `profiles` table:
  ```sql
  CREATE POLICY "Admins can update documents" ON public.documents
    USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
  ```
- **RLS Update WITH CHECK Clause**: Prevents normal users from updating their own `is_admin` flag.
- **SQL Search Path Security**: PostgreSQL functions use explicit `SET search_path = public` directives to guard against search-path hijacking attacks.

---

## 4. Database Schema Breakdown (`SUPABASE_SCHEMA.sql`)

### Key Tables & Constraints
1. **`profiles`**: Primary user directory referencing `auth.users(id)`. Includes `is_admin`, `institute`, and array of `academic_interests`.
2. **`documents`**: Metadata repository for uploaded PDFs and external links. Supports post types (`note`, `tweet`) and official verification status (`is_official`).
3. **`comments`**: Threaded discussion hierarchy with self-referencing `parent_id UUID REFERENCES public.comments(id)`.
4. **`interactions`**: Unique composite constraint `(document_id, user_id)` tracking likes and dislikes.
5. **`bookmarks`**: Unique user bookmark mappings for quick reference lists.
6. **`notifications`**: Private and global platform notifications with real-time replication.
7. **`remote_config`**: JSONB key-value store for live dynamic configuration.

### Postgres Realtime Channels
Realtime replication (`supabase_realtime` publication) is enabled on key tables:
- `documents` (Instant feed refresh)
- `notifications` (Real-time bell alerts)
- `interactions` (Dynamic counter updates)
- `comments` (Live conversation updates)

---

## 5. Android & Build Configuration Analysis

### 5.1 Android Configuration (`notehub/android/app/build.gradle`)
- **Application ID**: `com.divinevisionary.notehub`
- **Target SDK**: 36
- **Compile SDK**: 36
- **Java Compatibility**: Version 17 (Source & Target)
- **MultiDex**: Enabled (`multiDexEnabled true`) to support large dependency trees.
- **Desugaring**: `coreLibraryDesugaringEnabled true` using `com.android.tools:desugar_jdk_libs:2.1.4` to enable modern Java APIs on older Android devices.

### 5.2 Build Dependencies (`pubspec.yaml`)
- **SDK Range**: Dart SDK `^3.5.4` / Flutter SDK `3.24+`
- **Lint Engine**: `flutter_lints: ^6.0.0`

---

## 6. Developer Guidelines & Quality Assurance

### 6.1 Zero-Warnings Code Compliance
When developing features or refactoring components:
1. **Modern Color API**: Always use `.withValues(alpha: X)` instead of deprecated `.withOpacity(X)`.
2. **Switch Controls**: Always use `activeThumbColor` instead of deprecated `activeColor` on `Switch` widgets.
3. **Flow Control Braces**: Always enforce curly braces `{}` on single-line `if`, `else`, and `for` control flow structures.
4. **Catch Block Annotations**: When using silent catches, place `// ignore: empty_catches` on its own line inside the block to avoid syntax issues.

### 6.2 Pre-Commit & Verification Workflow
Before submitting changes, developers must run the static analysis and test suite from the `notehub/` directory:

```bash
# 1. Analyze code for zero warnings
cd notehub
flutter analyze

# 2. Run test suite
flutter test
```

---
*Maintained by AI Software Engineering Agent (Jules).*
