# Developer Guide & System Manual - Serious Study (NoteHub)

This document serves as the authoritative, developer-centric technical manual for **Serious Study** (formerly NoteHub), an academic notes-sharing and community platform built for Mumbai University students. This manual provides a deep-dive technical analysis across Performance, Design & UI/UX, Security & Database Infrastructure, and Codebase Architecture.

---

## 1. System Architecture & Tech Stack

```
                                  +---------------------------------------+
                                  |            FLUTTER FRONTEND           |
                                  |   (Material 3 + Glassmorphism UI)     |
                                  +-------------------+-------------------+
                                                      |
                                   GetX State Management & Routing
                                                      |
             +----------------------------------------+----------------------------------------+
             |                                        |                                        |
             v                                        v                                        v
  +--------------------+                   +--------------------+                   +--------------------+
  |    LOCAL CACHE     |                   |  NETWORK / DIO     |                   |  SUPABASE SDK      |
  |  (Hive Storage)    |                   | (File Downloader)  |                   | (Auth / DB / RPC)  |
  +--------------------+                   +--------------------+                   +--------------------+
             |                                        |                                        |
      Offline Sessions                         Cached Downloads                         PostgreSQL & RLS
```

### Core Stack
- **Frontend Framework**: Flutter 3.24+ / Dart SDK ^3.5.4
- **State Management & DI**: `GetX` (`GetxController`, `Get.put()`, `Obx`, `GetX<Controller>`)
- **Local Persistence**: `Hive` (NoSQL key-value database for user session caching and download metadata)
- **Networking & Auth**: `supabase_flutter` 2.12.0 (Managed JWT authentication, PostgREST queries, Realtime subscriptions)
- **Specialized Networking**: `Dio` 5.9.1 (chunked downloads, file caching, progress tracking)
- **Media Processing**: `flutter_image_compress` (client-side image compression prior to upload)
- **Native Android Engine**: Android `compileSdk 36`, `targetSdk 36`, Java 17 compatibility (`coreLibraryDesugaring` enabled for background notifications)

---

## 2. Directory & File-by-File Component Mapping

### Root & Configuration Files
- `agent.md`: Primary system manual and maintenance guide for AI agents and human developers.
- `ANALYSIS.md`: High-level executive analysis and tech stack summary.
- `SUPABASE_SCHEMA.sql`: Production PostgreSQL schema, Row Level Security (RLS) policies, RPC counter functions, triggers, and Realtime publications.
- `notehub/pubspec.yaml`: Package dependencies and asset declarations.
- `notehub/android/app/build.gradle`: Android application build configuration (`compileSdk 36`, Java 17, `multiDexEnabled`, `coreLibraryDesugaring`).

### Application Source (`notehub/lib/`)

#### Central Initialization & Configuration
- `main.dart`: Initializes Flutter bindings, Hive boxes, and Supabase client using credentials from `AppMetaData`.
- `layout.dart`: Core bottom navigation container managing tab switching via `BottomNavigationController`.
- `core/meta/app_meta.dart`: App metadata, Supabase credentials, and avatar generator endpoints.
- `core/config/color.dart`: Color palettes (Primary Deep Blue `#0D47A1`, Grayscale, Danger, and `AppGradients` using `.withValues(alpha: ...)`).
- `core/config/typography.dart`: Standardized Material 3 text styles (`AppTypography`).

#### Controllers (`lib/controller/`)
- `auth_controller.dart`: Manages login, registration, session sync, profile creation, and Hive session storage.
- `document_controller.dart`: Handles note/tweet feed fetching, optimistic like/dislike/bookmark toggles, document deletion, and external link launching.
- `upload_controller.dart`: Multi-part content upload workflow (Cover Image + Document), 10MB file limit enforcement, and admin official content flag handling.
- `home_controller.dart`: Main feed state, batch fetching (limit 50), category filtering, sticky official notes, and Postgres Realtime subscription.
- `profile_controller.dart` & `profile_user_controller.dart`: Current user and peer profile data management, follower/following count tracking.
- `comment_controller.dart`: Comment thread fetching, nested reply posting, and real-time discussion state updates.
- `notification_controller.dart`: Activity notification fetching and mark-as-read RPC sync.
- `search_controller.dart`: Query-based document search and filter logic.
- `download_controller.dart`: File download state management and local file caching coordination.
- `bottom_navigation_controller.dart`: Bottom navigation bar state management.
- `connection_controller.dart`: User follow/unfollow and peer connection state management.

#### Local Storage & Helpers (`lib/core/helper/` & `lib/service/`)
- `core/helper/hive_boxes.dart`: Hive box definitions (`userBox`, `downloadsBox`) providing typed getters/setters for offline user state.
- `core/helper/image_helper.dart`: Image compression utility utilizing `flutter_image_compress` (70% quality, max 1024x1024).
- `service/file_caching.dart`: Downloads and caches network files locally using `Dio` and `path_provider`.
- `service/file_download.dart`: Platform-specific file saving and opening helpers.
- `service/notification_service.dart`: Native notification setup using `flutter_local_notifications`.

#### Data Models (`lib/model/`)
- `user_model.dart` & `user_model.g.dart`: Hive-annotated `UserModel` class for local persistence.
- `document_model.dart`: Data model representing notes and tweets (including `is_external`, `is_official`, and `post_type`).
- `mini_user_model.dart`: Compact profile representations for cards and comment headers.

#### Views & UI Components (`lib/view/`)
- `splash_screen/splash.dart`: Startup animation and session verification.
- `auth_screen/login.dart`: Glassmorphic login and registration interface.
- `home_screen/home.dart` & `widget/home_header.dart`: Main activity feed featuring search bar, category chips, and document list.
- `upload_screen/upload_screen.dart` & `widget/upload_form.dart`: Content creation form with direct file / external link toggles and admin 'Official' switch.
- `document_screen/document.dart` & `widget/comment_section.dart`: Detailed document view with interactive comment threads and reply preview.
- `profile_screen/profile.dart` & `profile_user.dart`: User profile views displaying uploaded documents, connection counts, and bio.
- `notification_screen/notifications.dart`: Activity notification feed with read/unread visual styling.
- `official_screen/official_screen.dart`: Filtered view for official university updates and verified academic notes.
- `widgets/`: Reusable widgets (`document_card.dart`, `post_card.dart`, `admin_badge.dart`, `primary_button.dart`, `upload_text_field.dart`, `refresher_widget.dart`).

---

## 3. Deep-Dive Performance Analysis

### Reactive State Management (GetX)
- **Fine-Grained UI Updates**: Business logic is separated into GetX controllers. UI widgets use `Obx` or `GetX<Controller>` to listen only to necessary reactive fields (`.obs`), minimizing widget rebuilds.
- **Optimistic UI Updates**: User interactions (e.g., likes, dislikes, bookmarks) immediately reflect in `DocumentController` state before the backend RPC completes. In case of network failure, the controller gracefully reverts to the original state and displays an error toast.

### Caching Strategy & Offline Support
- **Session Caching via Hive**: `HiveBoxes` caches user credentials and profile metadata in local NoSQL storage (`userBox`). App launch profile loading is instantaneous without waiting for network roundtrips.
- **Media & File Caching**:
  - `cached_network_image`: Network images and cover thumbnails are cached on disk to eliminate duplicate network requests.
  - `file_caching.dart`: `Dio` handles file downloads by checking local temporary storage first before opening network streams.

### Bandwidth & Storage Optimization
- **Client-Side Compression**: `ImageHelper.compressImage` automatically compresses upload images to 70% quality JPEG format before transmission to Supabase Storage, saving up to 80% bandwidth.
- **Batching & Query Optimization**: `HomeController` fetches documents in pages (limit 50) ordered by `created_at DESC`, preventing large payload delays on initial app startup.
- **Atomic Database Functions (RPCs)**: Interactive counters (`likes_count`, `dislikes_count`) are updated using atomic PostgreSQL RPC functions (`increment_likes`, `decrement_likes`) executed on the database server. This eliminates race conditions and client-side recalculation overhead.

---

## 4. UI/UX & Design Paradigm Analysis

### Design System
- **Theme Philosophy**: Material 3 combined with a modern **Glassmorphism** visual language.
- **Primary Palette**: Rebranded with **Premium Deep Blue** (`#0D47A1`), complemented by soft blue accents (`#E3F2FD`) and gold highlights (`#FFD700`) for verified admin content.
- **Modern Color Alpha Compliance**: All transparent overlays and glass effects utilize modern Dart `.withValues(alpha: ...)` APIs (e.g., `Colors.white.withValues(alpha: 0.15)`), guaranteeing full compatibility with Dart SDK ^3.5.4.

### UX & Feedback Mechanics
- **Shimmer Visual Placeholders**: Animated shimmer skeletons (`shimmer` package) maintain visual structure while asynchronous network queries complete.
- **Lottie Feedback**: Lottie vector animations provide engaging feedback during empty search results and successful file uploads.
- **Interactive UI Components**: Custom toggles, `AdminBadge` indicators, and responsive comment thread trees enhance readability.

---

## 5. Security & Database RLS Audit

### Managed Authentication & Passwords
- **JWT Authentication**: User identity is managed by Supabase Auth using JSON Web Tokens (JWT). Client requests automatically attach bearer tokens.
- **Industry-Standard Hashing**: Passwords are saved in Supabase Auth's protected storage using Argon2/Bcrypt password hashing algorithms; no plain-text passwords exist in application storage or databases.

### Row Level Security (RLS) Policy Audit
Every table in `SUPABASE_SCHEMA.sql` enforces strict Row Level Security policies:

```sql
-- Profiles: Public read, owner-only update
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Documents: Public read, owner update/delete
CREATE POLICY "Documents are viewable by everyone" ON public.documents FOR SELECT USING (true);
CREATE POLICY "Users can insert their own documents" ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update/delete their own documents" ON public.documents FOR ALL USING (auth.uid() = user_id);

-- Privilege Escalation Safeguard on Admin Content
CREATE POLICY "Admins can update documents" ON public.documents
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
```

### PostgreSQL Functions & RPC Security
- **Atomic Increment RPCs**: Counter modifications execute through server-side functions defined with explicit `SECURITY DEFINER` and `SET search_path = public` to mitigate search-path hijacking.
- **Trigger-Based Permission Enforcement**: Setting `is_official = true` on document posts requires `is_admin = true` on the authenticated user profile, enforced at the database trigger level.

---

## 6. QA, Build & Maintenance Guidelines

### Prerequisites
- Flutter SDK: 3.24+
- Dart SDK: ^3.5.4
- Android SDK: `compileSdk 36`, `targetSdk 36`, Java 17

### Code Quality & 'Zero Warnings' Policy
All code modifications must strictly adhere to the repository's 'Zero Warnings' standard:
1. **Flow Control**: All `if`/`else` control structures must be wrapped in explicit curly braces (`curly_braces_in_flow_control_structures`).
2. **Color Manipulation**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
3. **Switch Components**: Use `activeThumbColor` instead of deprecated `activeColor` on `Switch` widgets.
4. **Catches**: Place `// ignore: empty_catches` on its own line inside empty catch blocks.

### QA Verification Commands
Developers and automated agents must verify codebase health using:
```bash
cd notehub
flutter analyze   # Must report 'No issues found!'
flutter test      # Must execute and pass test suite
```

---
*Maintained and Documented by Jules, AI Software Engineer.*
