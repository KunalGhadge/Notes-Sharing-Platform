# Developer Manual & System Architecture Guide - Serious Study (formerly NoteHub)

> **Repository Standard & AI Maintenance Manual**
> This document serves as the primary technical reference and architectural guide for developers and AI agents maintaining the **Serious Study** codebase.

---

## 1. Executive Summary & Core Stack

**Serious Study** is a high-performance, community-driven academic networking and notes-sharing platform engineered specifically for Mumbai University students and faculty. The platform was migrated from a legacy Django/MongoDB monolithic stack to a serverless, decoupled architecture.

### Technology Stack Overview
- **Frontend Framework**: Flutter 3.24+ / Dart SDK ^3.5.4
- **State Management**: GetX (v4.6.6) for reactive dependency injection, state management, and navigation routing.
- **Local Storage / Offline Caching**: Hive NoSQL (v2.2.3) for high-speed local session persistence and file metadata storage.
- **Backend Infrastructure**: Supabase (PostgreSQL 15 serverless backend).
  - **Authentication**: Supabase Auth using managed JSON Web Tokens (JWT) and Bcrypt/Argon2 password hashing.
  - **Database**: PostgreSQL with Row Level Security (RLS) policies.
  - **Storage**: Supabase Storage buckets for document PDFs, external links, and compressed thumbnail assets.
  - **Realtime**: Postgres Realtime pub/sub subscriptions for instant document feed updates and notifications.
- **Networking & Utilities**: Dio 5.7, CachedNetworkImage 3.4, FlutterImageCompress 2.3, Toastification 3.0, Lottie 3.1, Glassmorphism 3.0.

---

## 2. Directory Structure & File Mapping (Developer Perspective)

### Root Directory Layout
```
/
├── .github/workflows/dart.yml   # CI pipeline executing flutter analyze & flutter test
├── ANALYSIS.md                 # High-level executive overview and stack highlights
├── SUPABASE_SCHEMA.sql         # Idempotent database schema, triggers, RPCs & RLS policies
├── agent.md                    # Primary developer system manual (this document)
└── notehub/                    # Flutter project root
```

### Flutter Codebase Component Mapping (`notehub/lib/`)

#### 1. Core Config & Utilities (`notehub/lib/core/`)
- **`config/color.dart`**: Defines design tokens including `PrimaryColor` (Premium Deep Blue `#0D47A1`), `DangerColors`, grayscale scales, and `AppGradients` (`premiumGradient`, `glassGradient`). Utilizes `.withValues(alpha: ...)` for Dart SDK 3.5.4+ compatibility.
- **`config/typography.dart`**: Centralized text typography system (`AppTypography`).
- **`helper/hive_boxes.dart`**: High-performance Hive box wrapper managing `userBox` (user profiles, auth tokens, admin flags) and `downloadsBox` (cached download metadata).
- **`helper/image_helper.dart`**: Image optimization utility using `flutter_image_compress` (70% quality JPEG compression target at 1024x1024 max dimensions).
- **`helper/custom_icon.dart`**: SVG/PNG vector icon helper widget and `CustomAvatar` component.
- **`meta/app_meta.dart`**: App metadata constants (app name, default avatar generator API URLs, Supabase credentials).

#### 2. Models (`notehub/lib/model/`)
- **`user_model.dart`**: Primary user data model equipped with Hive annotations (`@HiveType(typeId: 0)`) for binary serialization.
- **`document_model.dart`**: Encapsulates notes and short update posts (tweets), tracking likes, dislikes, bookmarks, external link flags, and official labels.
- **`post_model.dart`**: Legacy post wrapper representation.
- **`mini_user_model.dart`**: Compact user snippet for list views and comment authorship.

#### 3. Controllers (`notehub/lib/controller/`)
- **`auth_controller.dart`**: Manages email/password registration and login, profile sync with Supabase `profiles` table, and Hive session persistence.
- **`document_controller.dart`**: Handles note interactions (optimistic likes, dislikes, bookmarks), document downloads, and deletion with cascading cleanup.
- **`home_controller.dart`**: Drives main feed document querying with batch limits (50 items), pull-to-refresh integration, and Postgres Realtime listener subscriptions.
- **`upload_controller.dart`**: Multi-stage upload controller handling document picker, cover image compression, 10MB size limit enforcement, and external link posts.
- **`profile_controller.dart`**: Manages current user profile state, Hive synchronization, and bio/interests updates.
- **`profile_user_controller.dart`**: Dynamic controller bound by username tag for viewing third-party student profiles and tracking follow states.
- **`showcase_controller.dart`**: Fetches user-created posts and bookmarked resources for profile tabs.
- **`comment_controller.dart`**: Manages comment threads, nested replies (`parent_id`), and admin comment deletions.
- **`notification_controller.dart`**: Fetches user notifications (likes, comments, replies) and updates `is_read` status.
- **`search_controller.dart`**: Real-time debounce searching across document titles, topics, and author display names.
- **`connection_controller.dart`**: Fetches followers and following user lists.
- **`download_controller.dart`**: Tracks local file storage and offline document accessibility.
- **`file_controller.dart`**: Low-level file picker helper for document and thumbnail selection.
- **`remote_config_controller.dart`**: Dynamically syncs remote app config settings without requiring APK reinstalls.
- **`bottom_navigation_controller.dart`**: Controls active tab index in `BottomFooter`.

#### 4. Views & Widgets (`notehub/lib/view/`)
- **`splash_screen/splash.dart`**: Splash screen displaying Lottie animation (`notes.json`) and directing users based on Hive session state.
- **`auth_screen/login.dart`**: Glassmorphic auth screen supporting switching between Sign In and Sign Up modes.
- **`home_screen/home.dart`**: Main feed view with header (`HomeHeader`), official announcements ticker, document section (`HomeDocumentSection`), and shimmer placeholders.
- **`official_screen/official_screen.dart`**: Curated view dedicated exclusively to official university updates (`is_official = true`).
- **`document_screen/document.dart`**: Detailed document viewer featuring cover image display, download trigger, external link launcher, and comment section (`CommentSection`).
- **`upload_screen/upload_screen.dart`**: Resource upload hub with post type toggle (Note vs Tweet), file pickers, admin toggles (`AdminBadge`), and upload progress indication.
- **`profile_screen/profile.dart` & `profile_user.dart`**: Profile dashboards showing follower counts, university details, admin badges, and resource showcases.
- **`search_screen/search.dart`**: Live resource and user search interface.
- **`notification_screen/notifications.dart`**: Notification feed detailing peer interactions.
- **`connection_screen/connection.dart`**: Follower/Following management list.
- **`settings_screen/about.dart`**: App information, vision statement, and developer credits.
- **`bottom_footer/bottom_footer.dart`**: Glassmorphic bottom navigation bar with active tab highlights.
- **`widgets/`**: Reusable components (`document_card.dart`, `post_card.dart`, `admin_badge.dart`, `loader.dart`, `primary_button.dart`, `secondary_button.dart`, `toasts.dart`, `refresher_widget.dart`).

#### 5. Services (`notehub/lib/service/`)
- **`file_caching.dart`**: Dio-powered file caching service checking temporary directories prior to downloading network files.
- **`file_download.dart`**: Local notification-integrated file download helper.
- **`notification_service.dart`**: Local notification channel initialization.

---

## 3. Deep Technical Analysis: Performance, Design, & Security

### A. Performance Engineering
1. **Optimistic UI & Reactive Bindings**:
   - `DocumentController` utilizes optimistic updates for likes, dislikes, and bookmarks. UI state (`doc.isLiked`, `doc.likes`) updates instantly before network requests complete; state automatically reverts upon network or database failure.
2. **Local Caching via Hive**:
   - User profile data is cached in `userBox` using Hive binary serialization. App initialization reads profile data synchronously, eliminating blank loading screens on startup.
3. **Bandwidth & Storage Optimization**:
   - Image assets are compressed client-side using `FlutterImageCompress` to 70% quality JPEG before uploading to Supabase Storage.
   - Upload controller blocks direct uploads larger than 10MB while supporting lightweight external link sharing (Google Drive, Mega, OneDrive).
   - `CachedNetworkImage` prevents redundant HTTP GET requests for document thumbnails across feed scrolls.
4. **Database Counter RPCs**:
   - Atomic RPC functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`) run directly inside PostgreSQL. This prevents concurrency issues and race conditions when multiple users like a resource simultaneously.
5. **Lazy Fetching & Pagination**:
   - Feed documents are fetched in batches of 50 items. `fetchOfficialUpdates` isolates official resources to the top 20 items for rapid rendering.

### B. UI/UX Design Architecture
1. **Material 3 & Glassmorphic Aesthetic**:
   - Modern visual language utilizing semi-transparent containers (`Colors.white.withValues(alpha: 0.15)`), subtle box shadows, and blurred backdrops (`GlassmorphicContainer`).
2. **Rebranded Color Palette**:
   - **Primary Palette**: Premium Deep Blue (`#0D47A1` - `PrimaryColor.shade500`) symbolizing Mumbai University's academic prestige.
   - **Accent Palette**: Premium Gold (`#FFD700`) gradient used exclusively for verified `AdminBadge` components.
3. **Visual Feedback & Micro-Interactions**:
   - Shimmer animations during network data fetching (`Shimmer.fromColors`).
   - Lottie vector animations for empty states and splash screen.
   - Heart scale micro-animations on document like actions (`LikesWithHeart`).

### C. Security Analysis & Mitigation Audit

| Security Domain | Legacy Stack (Django/MongoDB) | Modern Stack (Supabase Serverless) | Implementation Details |
| :--- | :--- | :--- | :--- |
| **Authentication** | Custom sessionless creds | **Supabase Auth (JWT)** | Secure token exchange handled automatically by Supabase SDK; tokens persisted securely. |
| **Password Hashing** | Plain text / custom hash | **Argon2 / Bcrypt Hashing** | Passwords handled exclusively by Supabase Auth with industry-standard hashing. |
| **Authorization & RLS** | Vulnerable API endpoints | **Row Level Security (RLS)** | PostgreSQL RLS enabled on all 7 public tables (`profiles`, `documents`, `comments`, `interactions`, `bookmarks`, `notifications`, `followers`). |
| **Privilege Escalation** | Unprotected fields | **Enforced RLS `WITH CHECK`** | RLS update policy on `profiles` validates `is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())` to prevent user escalation. |
| **Search Path Hijacking** | N/A | **Explicit `search_path`** | PostgreSQL RPC functions explicitly declare `SET search_path = public` to prevent function search-path hijacking vulnerabilities. |
| **Official Content Control** | Unrestricted flags | **PostgreSQL Triggers** | `ensure_official_permission` trigger verifies `is_admin = true` before allowing `is_official = true` on `documents`. |

---

## 4. PostgreSQL Schema & Database Architecture (`SUPABASE_SCHEMA.sql`)

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

-- Interactions Table (Likes / Dislikes)
CREATE TABLE IF NOT EXISTS public.interactions (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(document_id, user_id)
);
```

---

## 5. Maintenance, Testing & QA Procedures

### Prerequisites
- **Dart SDK**: `^3.5.4`
- **Flutter Framework**: `3.24+`
- **Android Target**: `compileSdk 36`, `Java 17` compatibility (`notehub/android/app/build.gradle`).

### Developer QA Checklist ("Zero Warnings" Policy)
Before submitting code or pushing changes, run the following commands inside the `notehub/` directory:

1. **Static Code Analysis**:
   ```bash
   cd notehub
   flutter analyze
   ```
   *Requirement: Must return "No issues found!".*
   - Avoid deprecated `.withOpacity()`; use `.withValues(alpha: ...)` instead.
   - Use `activeThumbColor` for Flutter `Switch` widgets.
   - Ensure all `if` statements employ explicit flow-control curly braces `{}`.

2. **Unit Test Suite**:
   ```bash
   cd notehub
   flutter test
   ```
   *Requirement: All unit tests must pass.*

---
*Analyzed and Documented by AI Engineering Team.*
