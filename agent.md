# Serious Study (formerly NoteHub) - Developer Technical Guide & System Architecture Manual

This document provides an exhaustive, developer-perspective technical analysis of the **Serious Study** Android application (repository path: `notehub/`). It details the app's architecture, state management, security model, performance strategies, design aesthetics, database schemas, and developer maintenance procedures following its migration from a legacy Django/MongoDB stack to a serverless **Supabase** backend.

---

## 1. Architectural Overview & System Design

Serious Study is structured around a decoupled **MVC-like (Model-View-Controller)** pattern implemented via Flutter and GetX. Business logic and remote/local data fetching are completely separated from the presentation layer.

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           PRESENTATION LAYER                            │
│           (Views, Widgets, Custom UI Components, Glassmorphism)         │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ Reactive Bindings / Obx
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                             CONTROLLER LAYER                            │
│    (GetxController: AuthController, DocumentController, HomeController) │
└──────────────────┬──────────────────────────────────┬───────────────────┘
                   │ Cache & Local Session            │ Async RPC & Queries
                   ▼                                  ▼
┌─────────────────────────────────────┐  ┌────────────────────────────────┐
│             LOCAL STORAGE           │  │         REMOTE BACKEND         │
│  (Hive NoSQL: userBox, downloadsBox)│  │ (Supabase Auth, Postgres RLS,  │
│                                     │  │  Storage Buckets, Realtime)    │
└─────────────────────────────────────┘  └────────────────────────────────┘
```

### File Hierarchy & Component Mapping

#### Configuration & Metadata (`lib/core/`)
- `lib/core/meta/app_meta.dart`: Global static metadata including backend credentials (`supabaseUrl`, `supabaseAnonKey`), default avatars, and app identity.
- `lib/core/config/color.dart`: Palette definitions featuring **Premium Deep Blue (`#0D47A1`)**, primary/secondary color scales, and surface colors. Uses modern `.withValues(alpha: ...)` for transparency.
- `lib/core/config/typography.dart`: Text style definitions building upon `GoogleFonts`.
- `lib/core/helper/hive_boxes.dart`: Hive local box accessors for `userBox` (session info) and `downloadsBox` (downloaded document metadata).
- `lib/core/helper/image_helper.dart`: Image utility using `flutter_image_compress` to compress media assets (JPEG 70% quality, max dimensions 1024x1024) prior to cloud storage upload.
- `lib/core/helper/custom_icon.dart`: Vector icon loader mapped to local SVG assets.

#### State Controllers (`lib/controller/`)
- `lib/controller/auth_controller.dart`: Handles Supabase Auth (Sign In / Sign Up with metadata payload), profile creation/retrieval, and local session sync with `userBox`.
- `lib/controller/document_controller.dart`: Governs document management, optimistic likes/dislikes/bookmarks toggling, document deletion (with bucket cleanup), and PostgreSQL RPC invocations.
- `lib/controller/home_controller.dart`: Manages the primary document feed, sticky search filtering, topic pagination (limit 50), and official announcements feed.
- `lib/controller/upload_controller.dart`: Manages file picking, 10MB direct upload constraints, external link posting (Drive/Mega), and thumbnail compression upload pipeline.
- `lib/controller/profile_controller.dart` & `profile_user_controller.dart`: Handles profile viewing, edit dialogs, follower/following count tracking, and social relationships.
- `lib/controller/comment_controller.dart`: Manages nested comment threads, parent/child replies, and realtime updates.
- `lib/controller/notification_controller.dart`: Fetches and marks activity notifications (likes, comments, replies).
- `lib/controller/download_controller.dart`: Manages local storage file downloads, progress tracking, and metadata persistence in `downloadsBox`.
- `lib/controller/bottom_navigation_controller.dart`: Manages bottom tab navigation index state.
- `lib/controller/remote_config_controller.dart`: Dynamically fetches server configurations without client application updates.

#### Services & Storage (`lib/service/`)
- `lib/service/file_caching.dart`: High-efficiency file download service utilizing `Dio` and `path_provider`. Checks temporary directories prior to re-initiating network downloads.
- `lib/service/file_download.dart`: Platform-specific file opening and saving handlers.
- `lib/service/notification_service.dart`: Local notifications via `flutter_local_notifications` for background alerts.

#### Presentation & UI (`lib/view/`)
- `lib/view/auth_screen/`: Login and registration screens with interactive mode switches.
- `lib/view/home_screen/`: Main dashboard featuring `HomeHeader`, category selectors, feed lists, and shimmer placeholders.
- `lib/view/document_screen/`: Document detailed view, cover image display, external URL launcher, and comment thread widget (`CommentSection`).
- `lib/view/upload_screen/`: Upload form with direct document picker, external URL options, topic inputs, and admin official toggle (`activeThumbColor: const Color(0xFFB8860B)`).
- `lib/view/profile_screen/`: Profile page showcasing user notes, stats counters, showcase items, and profile editing.
- `lib/view/official_screen/`: Curated official announcements and administrative postings feed.
- `lib/view/widgets/`: Reusable components including `DocumentCard`, `PostCard`, `AdminBadge`, `Toasts` (toastification wrapper), `RefresherWidget`, `PrimaryButton`, and `SecondaryButton`.

---

## 2. Technical Performance Analysis

### 2.1 Reactive State & Memory Management
- **GetX Architecture**: Business logic is separated into singletons registered or instantiated per view lifecycle. Re-renders are localized using `Obx(() => ...)` blocks or `GetBuilder` updates, avoiding expensive full-widget tree rebuilds.
- **Optimistic UI Updates**: Asynchronous user interactions (such as liking, disliking, or bookmarking a document in `DocumentController`) immediately update local state observables (`doc.isLiked`, `doc.likes`) before initiating network RPC calls. On network failure, state is automatically reverted and error notifications are triggered.

### 2.2 Local Caching & Media Optimization
- **Hive Cache (`HiveBoxes`)**: High-performance binary NoSQL storage. Profile info (`userBox`) is retrieved synchronously on startup to allow instant UI rendering without waiting for Supabase network calls.
- **Image Compression Pipeline**: `ImageHelper.compressImage()` compresses selected images down to 70% quality JPEG before uploading to Supabase Storage, dramatically reducing storage overhead and downstream network load.
- **Network Image Caching**: `CachedNetworkImage` is implemented across profile headers, avatars, and document covers to cache media locally on mobile disk.

### 2.3 Database Counter Atomic Operations
- Direct incrementing/decrementing of counts (e.g., `likes_count`, `dislikes_count`) on client devices can result in race conditions. The backend executes atomic PostgreSQL functions (`increment_likes`, `decrement_dislikes`, etc.) to process updates safely under concurrency.

---

## 3. Design & Aesthetic System

### 3.1 Visual Language
- **Theme Paradigm**: Material 3 design augmented with **Glassmorphism** overlays.
- **Brand Palette**:
  - Primary Accent: **Premium Deep Blue (`#0D47A1`)**
  - Dark Surface: Deep slate blue shades (`#06152B`, `#0A2342`)
  - Accent Gold (Admin/Official): `#B8860B` / `#FFD700`
- **Modern API Compliance**: Modern Flutter standards are strictly applied: `.withValues(alpha: ...)` replaces deprecated `.withOpacity()`, and `Switch` widgets use `activeThumbColor`.

### 3.2 UI State Feedback
- **Shimmer Placeholders**: `Shimmer.fromColors` is utilized during async data loading to present subtle UI skeletons rather than abrupt loading spinners.
- **Lottie Animations**: Vector animations handle empty search results and confirmation screens.

---

## 4. Security Model & Database Audit

### 4.1 Authentication & Authorization
- **JWT Authentication**: Managed by **Supabase Auth**. No plain-text passwords or custom session tokens pass through intermediate servers.
- **Row Level Security (RLS)**: Enforced on all PostgreSQL tables in `SUPABASE_SCHEMA.sql`.

| Table | SELECT Policy | INSERT Policy | UPDATE/DELETE Policy |
| :--- | :--- | :--- | :--- |
| `profiles` | Public (`true`) | `auth.uid() = id` | `auth.uid() = id` (WITH CHECK `is_admin = profile.is_admin`) |
| `documents` | Public (`true`) | `auth.uid() = user_id` | `auth.uid() = user_id` OR Admin role |
| `comments` | Public (`true`) | `auth.uid() = user_id` | `auth.uid() = user_id` |
| `interactions`| Owner (`auth.uid() = user_id`) | `auth.uid() = user_id` | Owner only |
| `bookmarks` | Owner (`auth.uid() = user_id`) | `auth.uid() = user_id` | Owner only |
| `notifications`| Receiver (`auth.uid() = receiver_id`)| Sender/System | System/Receiver |

### 4.2 Security Vulnerability Hardening
1. **Privilege Escalation Prevention**: The `profiles` table update policy requires a `WITH CHECK` clause ensuring non-admin users cannot self-promote by setting `is_admin = true`.
2. **Official Post Verification**: The trigger `ensure_official_permission` verifies that setting `is_official = true` on `documents` can only be performed by authenticated users whose `profiles.is_admin` is true.
3. **RPC Search Path Isolation**: PostgreSQL functions are created with explicit `SET search_path = public` directives to guard against search-path hijacking.

---

## 5. Database Schema Reference (`SUPABASE_SCHEMA.sql`)

```sql
-- Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  profile_url TEXT,
  institute TEXT,
  academic_interests TEXT[],
  bio TEXT,
  is_admin BOOLEAN DEFAULT false,
  followers INT DEFAULT 0,
  following INT DEFAULT 0,
  documents INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Documents Table
CREATE TABLE IF NOT EXISTS public.documents (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  topic TEXT,
  description TEXT,
  document_url TEXT,
  document_name TEXT,
  cover_url TEXT,
  icon_name TEXT,
  likes_count INT DEFAULT 0,
  dislikes_count INT DEFAULT 0,
  is_external BOOLEAN DEFAULT false,
  is_official BOOLEAN DEFAULT false,
  post_type TEXT DEFAULT 'note' CHECK (post_type IN ('note', 'tweet')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Atomic Counter RPC Sample
CREATE OR REPLACE FUNCTION increment_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents
  SET likes_count = likes_count + 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 6. Development & Zero-Warnings QA Procedures

### 6.1 Prerequisites
- **Flutter SDK**: 3.24+
- **Dart SDK**: ^3.5.4
- **Java**: 17 (Android `compileSdk 36`, `multiDexEnabled true`)

### 6.2 Code Quality Standards
To maintain **Zero Warnings** status across the repository, developer contributions must adhere to:
1. **Flow Control Braces**: Always enclose single-line `if` bodies in curly braces (`curly_braces_in_flow_control_structures`).
2. **Modern Color Methods**: Use `.withValues(alpha: 0.x)` instead of `.withOpacity(0.x)`.
3. **Switch Component Colors**: Use `activeThumbColor` instead of deprecated `activeColor`.
4. **Empty Catches**: Annotate necessary empty catch blocks with `// ignore: empty_catches` placed on its own line inside the catch block.

### 6.3 QA Check Commands
Run the following commands inside `notehub/` prior to committing:
```bash
# 1. Check static analysis and linting
flutter analyze

# 2. Run test suite
flutter test
```

---
*Analyzed, Modernized, and Documented by Jules, AI Software Engineer.*
