# Developer Guide & Master Architecture Manual — Serious Study

## Executive Overview
**Serious Study** (formerly NoteHub) is a high-performance, serverless academic networking and notes-sharing platform engineered specifically for the Mumbai University student community. The application bridges academic peer-to-peer collaboration, verified official announcements, and community discussions.

The application transitioned from a legacy Django/MongoDB monolith to a modern serverless architecture powered by **Flutter** on the mobile frontend and **Supabase (PostgreSQL)** on the backend. This document serves as the developer-centric technical specification and maintenance guide covering system architecture, performance engineering, UI/UX design paradigms, database security, and code maintainability.

---

## 1. System Architecture & Tech Stack

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER FRONTEND                              │
│  ┌───────────────────────┐ ┌────────────────────┐ ┌───────────────────┐ │
│  │   GetX Controllers    │ │    Hive Caching    │ │ Glassmorphic UI   │ │
│  │ (State & Logic Layer) │ │ (NoSQL Local Store)│ │  (Material 3)     │ │
│  └───────────┬───────────┘ └─────────┬──────────┘ └───────────────────┘ │
└──────────────┼───────────────────────┼──────────────────────────────────┘
               │                       │
               ▼                       ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        SUPABASE SERVERLESS BACKEND                      │
│  ┌───────────────────────┐ ┌────────────────────┐ ┌───────────────────┐ │
│  │    Supabase Auth      │ │  PostgreSQL RLS    │ │  Supabase Storage │ │
│  │ (JWT Session Mgmt)    │ │ (7 Relational Tbls)│ │(Docs, Covers, Avs)│ │
│  └───────────────────────┘ └─────────┬──────────┘ └───────────────────┘ │
│                                      │                                  │
│                                      ▼                                  │
│                          ┌────────────────────────┐                     │
│                          │ PostgreSQL RPC & Triggers│                   │
│                          │  (Atomic Counters)     │                     │
│                          └────────────────────────┘                     │
└─────────────────────────────────────────────────────────────────────────┘
```

### Frontend Architecture (Flutter 3.24+ / Dart SDK ^3.5.4)
- **State Management & Dependency Injection**: `GetX` (`get: ^4.6.6`) for reactive controller bindings, routing, and decoupled business logic.
- **Local Persistence & Caching**: `Hive` (`hive_flutter: ^1.1.0`) for instant NoSQL session and user profile caching (`userBox`, `downloadsBox`).
- **Networking & File Delivery**: `supabase_flutter` for database & auth interactions, paired with `dio` (`^5.9.1`) for chunked file downloads and caching.
- **Media Optimization**: `flutter_image_compress` for client-side asset optimization before uploads, and `cached_network_image` for lazy image rendering.
- **Aesthetic Framework**: Material 3 styling enhanced with `glassmorphism` (`^3.0.0`), `lottie` animations, and `shimmer` loading placeholders.

### Backend Architecture (Supabase / PostgreSQL)
- **Database Engine**: PostgreSQL with strict **Row Level Security (RLS)** across all tables.
- **Authentication**: JWT-based session tokens managed by Supabase Auth (Argon2/Bcrypt hash verification).
- **Storage Buckets**: Managed S3-compatible object storage buckets (`documents`, `covers`, `avatars`).
- **Serverless Compute**: PostgreSQL Stored Procedures (`RPCs`) for atomic counter execution and PostgreSQL Triggers for privilege validation.
- **Realtime Pipeline**: `supabase_realtime` publication stream on `documents`, `comments`, `interactions`, and `notifications`.

---

## 2. In-Depth Performance Analysis

### 2.1 Reactive State & Optimistic UI Updates
- **Instant Feedback Loops**: Actions like liking a document (`toggleLike`), disliking (`toggleDislike`), or bookmarking (`toggleBookmark`) execute **optimistic UI updates** locally before network acknowledgment. If the Supabase request fails, state is rolled back seamlessly.
- **Controller State Synchronization**: `DocumentController._syncWithHome()` triggers updates in registered `HomeController` instances to maintain uniform feed metrics across screens without full network refetches.

### 2.2 Local Caching & Instant App Launch
- **Hive NoSQL Key-Value Store**: User metadata and authentication session parameters are persisted in `userBox` (`lib/core/helper/hive_boxes.dart`). App launch checks `HiveBoxes.userId` synchronously, avoiding blocking network calls on boot.
- **Local File Cache**: `FileCachingService` (`lib/service/file_caching.dart`) checks local temporary directory storage using `path_provider` before triggering Dio downloads for PDFs or study materials.

### 2.3 Network Batching & Pagination Strategy
- **Batched Feed Queries**: `HomeController.fetchUpdates()` fetches main feed items in batches limited to 50 records per payload to balance memory consumption and bandwidth.
- **Filtered Official Updates**: `HomeController.fetchOfficialUpdates()` applies a strict limit of 20 records for rapid loading of university updates.

### 2.4 Atomic Counters & Database Concurrency
- **Concurrency Protection**: Document interactions (likes, dislikes, bookmarks) bypass slow read-modify-write client operations by invoking database functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`).
- **Function Definition Example**:
  ```sql
  CREATE OR REPLACE FUNCTION increment_likes(doc_id BIGINT)
  RETURNS VOID AS $$
  BEGIN
    UPDATE public.documents SET likes_count = likes_count + 1 WHERE id = doc_id;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
  ```

---

## 3. Design & UI/UX Analysis

### 3.1 Design System & Aesthetic Foundation
- **Primary Rebranded Palette**: "Premium Deep Blue" (`#0D47A1` primary, `#1976D2` secondary) representing Mumbai University's academic identity.
- **Glassmorphism Overlay**: Floating elements (e.g., `BottomFooter`, `PostCard` overlay headers) utilize `GlassmorphicContainer` and custom linear gradients (`AppGradients.glassGradient` with `.withValues(alpha: ...)` transparency).
- **Typography Matrix**: Structured hierarchy defined in `AppTypography` using Google Fonts for clean legibility across low and high-DPI Android screens.

### 3.2 Visual Component Matrix
- **Shimmer Loading Feedback**: Placeholder skeletons (`Shimmer.fromColors`) prevent layout shifting during asynchronous network operations.
- **Lottie Feedback**: Lottie asset animations (`notes.json`) provide friendly empty states in search and notification screens.
- **Verified Admin Badging**: Verified administrators and official postings are badged with custom linear gradient indicators (`AdminBadge`) in `#FFD700` and `#FFA500` tones.

---

## 4. Security Analysis & Audit

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SECURITY LAYER ARCHITECTURE                     │
│                                                                        │
│  [Client Request] ───► [JWT Auth Validation] ───► [PostgreSQL RLS]     │
│                                                         │              │
│                                                         ▼              │
│  [Database Trigger / RPC] ◄─── [WITH CHECK Clause] ◄────┼──────────────┤
│           │                                             │              │
│           ▼                                             ▼              │
│  [Privilege Escalation Check]                     [Table Access]       │
└────────────────────────────────────────────────────────────────────────┘
```

### 4.1 Authentication & Session Management
- **Token Security**: Supabase Auth handles JWT issuance, auto-refresh, and cryptographic token verification. No plain-text credentials reside in local memory or persistent storage.
- **Profile Bootstrapping**: `AuthController.fetchAndStoreProfile()` ensures missing profiles are automatically created from JWT metadata during sign-up.

### 4.2 Row Level Security (RLS) Policy Audit
All 7 public database tables enforce strict RLS enabled via `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`:

1. **`profiles`**:
   - `SELECT`: Public access (`USING (true)`).
   - `INSERT`: Verified ownership (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Owner restricted (`USING (auth.uid() = id)`).
2. **`documents`**:
   - `SELECT`: Public access (`USING (true)`).
   - `INSERT`: Owner restricted (`WITH CHECK (auth.uid() = user_id)`).
   - `ALL` (Update/Delete): Owner restricted (`USING (auth.uid() = user_id)`).
   - `UPDATE` (Admin override): Admin role checked via `auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true)`.
3. **`comments`**:
   - `SELECT`: Public viewable.
   - `INSERT`: Restricted to comment creator (`auth.uid() = user_id`).
4. **`interactions` & `bookmarks`**:
   - Access restricted strictly to the user matching `user_id`.
5. **`notifications`**:
   - `SELECT`: Restricted to receiver (`auth.uid() = receiver_id`).
6. **`followers`**:
   - `SELECT`: Public viewable.
   - `INSERT/DELETE`: Restricted to active follower (`auth.uid() = follower_id`).

### 4.3 Mitigation of Privilege Escalation
- **Admin Flag Protection**: regular users are prevented from elevating their role to `is_admin = true`. SQL policy checks and trigger functions prevent unauthorized modifications to the `is_admin` column in `profiles`.
- **Official Content Guarding**: Setting `is_official = true` on `documents` requires administrator privileges verified against `public.profiles`.

### 4.4 SQL Injection & Search Path Hijacking Mitigation
- All PostgreSQL procedures are declared with explicit search paths:
  ```sql
  SECURITY DEFINER SET search_path = public
  ```
  This prevents search-path hijacking vulnerabilities in database RPC executions.

---

## 5. Directory & File-by-File Developer Reference

### 5.1 Root & Core Entry Points
- `notehub/lib/main.dart`: Application entry point. Initializes Supabase SDK, Hive local storage, and injects global controllers (`Get.put()`).
- `notehub/lib/layout.dart`: Core scaffold managing index switching across the bottom navigation bar.

### 5.2 Controllers (`lib/controller/`)
- `auth_controller.dart`: Handles registration, login, session sync, profile creation, and sign-out.
- `bottom_navigation_controller.dart`: Reactive tab index state manager (`0` to `4`).
- `comment_controller.dart`: Fetches nested comments, posts parent/reply comments, and manages deletion logic.
- `connection_controller.dart`: Monitors internet connectivity and network availability states.
- `document_controller.dart`: Manages notes/tweets fetching, likes, dislikes, bookmarks, optimistic updates, and deletion.
- `download_controller.dart`: Tracks active PDF and resource download progress.
- `file_controller.dart`: Manages local file selection and file picker interactions.
- `home_controller.dart`: Powers main feed, implements batching (50 limit), sticky sorting, and official updates fetching (20 limit).
- `notification_controller.dart`: Fetches user notifications and handles "mark as read" batch operations.
- `post_controller.dart`: Business logic for tweet/post interactions and view model rendering.
- `profile_controller.dart`: Current authenticated user profile state manager linked with Hive.
- `profile_user_controller.dart`: Target user profile state manager for viewing peer profiles and follow/unfollow logic.
- `remote_config_controller.dart`: Loads dynamic app parameters from `public.remote_config`.
- `search_controller.dart`: Implements resource search filtering by title, topic, or subject.
- `showcase_controller.dart`: Manages profile showcase tabs (user created posts vs. saved/bookmarked resources).
- `upload_controller.dart`: Manages upload form state, file size limits (10MB max), image compression pipeline, external link posts, and official tagging.

### 5.3 Models (`lib/model/`)
- `user_model.dart` / `user_model.g.dart`: Data model for user profile with Hive TypeAdapter annotation (`TypeAdapter<UserModel>`).
- `document_model.dart`: Primary document/note entity including metrics, user relation, post type ('note'/'tweet'), and official status flags.
- `post_model.dart`: Representation of social update posts.
- `mini_user_model.dart`: Lightweight user profile snippet model for avatars and list views.

### 5.4 Services (`lib/service/`)
- `file_caching.dart`: Manages resource download caching using Dio and local temporary file system access.
- `file_download.dart`: Handles download execution and triggers native Android system notifications via `flutter_local_notifications`.
- `notification_service.dart`: Native notification channel setup and local push notification dispatcher.

### 5.5 Core Utilities (`lib/core/`)
- `config/color.dart`: Color definitions (`PrimaryColor`, `DangerColors`, `GrayscaleWhiteColors`, `GrayscaleGrayColors`, `GrayscaleBlackColors`, `OtherColors`, `AppGradients`).
- `config/typography.dart`: Text style definitions (`AppTypography`).
- `helper/hive_boxes.dart`: Abstraction over Hive boxes (`userBox`, `downloadsBox`).
- `helper/image_helper.dart`: JPEG compression utility using `FlutterImageCompress` (70% quality, 1024x1024 max dimensions).
- `helper/custom_icon.dart` / `custom_avatar.dart`: Reusable SVG rendering and avatar widgets.
- `meta/app_meta.dart`: Global configurations, Supabase URL, anon keys, and branding strings.

### 5.6 View Layer Matrix (`lib/view/`)
- `auth_screen/`: Login and sign-up interfaces (`Login`, `LoginForm`, `LoginHeader`).
- `bottom_footer/`: Custom glassmorphic navigation bar (`BottomFooter`).
- `document_screen/`: Note detail screen, PDF viewer trigger, and comment section (`Document`, `CommentSection`, `CommentTile`).
- `home_screen/`: Main activity feed, header card, and official section (`Home`, `HomeHeader`, `HomeDocumentSection`).
- `notification_screen/`: Activity notifications view (`NotificationView`).
- `official_screen/`: Dedicated feed screen for verified Mumbai University announcements.
- `onboarding_screen/`: Welcome walkthrough for first-time users.
- `profile_screen/`: Authenticated and peer profile views (`Profile`, `ProfileUser`, `ProfileHeader`, `ProfileShowcase`).
- `search_screen/`: Dynamic resource search page (`SearchView`).
- `settings_screen/`: App settings, about page (`AboutPage`), and project credits.
- `splash_screen/`: Animated splash screen (`Splash`).
- `upload_screen/`: Resource and tweet creation interface (`UploadScreen`, `UploadForm`, `UploadFooter`).
- `widgets/`: Reusable UI components (`AdminBadge`, `DocumentCard`, `PostCard`, `PrimaryButton`, `SecondaryButton`, `RefresherWidget`, `Loader`, `Toasts`).

---

## 6. Database Schema Reference (`SUPABASE_SCHEMA.sql`)

```sql
-- Core Table Definitions Summary

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

CREATE TABLE IF NOT EXISTS public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.interactions (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(document_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.bookmarks (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(document_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.notifications (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  content TEXT,
  is_read BOOLEAN DEFAULT false,
  is_global BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE IF NOT EXISTS public.followers (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(follower_id, following_id)
);
```

---

## 7. Developer Maintenance & Quality Assurance

### 7.1 Prerequisite Technical Stack
- **Flutter SDK**: `>=3.24.0`
- **Dart SDK**: `^3.5.4`
- **Android Target API**: `compileSdk 36`, `minSdkVersion 21`, `targetSdkVersion 34`
- **Java Platform**: Java 17 compatibility configured in `notehub/android/app/build.gradle`.

### 7.2 Zero Warnings Code Quality Policy
To maintain codebase health and prevent CI regressions, all code must strictly follow the **Zero Warnings Policy**:
- **Modern Color Opacities**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
- **Modern Switch Widgets**: Use `activeThumbColor` instead of deprecated `activeColor`.
- **Flow Control Syntax**: Enforce `curly_braces_in_flow_control_structures` for all `if`/`else` control paths.
- **Empty Catch Blocks**: Place required `// ignore: empty_catches` or handle logs via `debugPrint` inside catch bodies.

### 7.3 QA Execution Commands
Execute static analysis and test validation inside the `notehub/` root directory:

```bash
# 1. Run static code analyzer
cd notehub
flutter analyze

# 2. Run automated unit/widget test suite
flutter test
```

### 7.4 Continuous Integration Workflow
The GitHub Actions workflow defined in `.github/workflows/dart.yml` automatically triggers on push and pull requests to `main`:
1. Sets up Java 17 and Flutter SDK stable.
2. Runs `flutter pub get` inside `notehub/`.
3. Executes `flutter analyze` to enforce zero lint warnings.
4. Executes `flutter test` to verify software correctness.

---
*Maintained by Jules, Senior AI Software Engineer.*
