# Serious Study (formerly NoteHub) - Developer & System Technical Manual

## Executive Overview
**Serious Study** is a high-performance, serverless mobile application built with **Flutter** and **Supabase (PostgreSQL)**, designed specifically for the Mumbai University academic community. It enables students and faculty to share notes, access study materials, publish short updates ("tweets"), bookmark resources, and build academic networks.

This document serves as the developer-centric technical reference, architectural guide, and security audit manual for the codebase.

---

## 1. System Architecture & Tech Stack

```
+-------------------------------------------------------------------+
|                        PRESENTATION LAYER                         |
|  Material 3 UI | Glassmorphism | GetX Reactive Bindings & Views   |
+-------------------------------------------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                         BUSINESS LOGIC                            |
| 16 GetX Controllers (Auth, Document, Upload, Home, Profile, etc.) |
+-------------------------------------------------------------------+
             |                                    |
             v                                    v
+--------------------------+        +-------------------------------+
|      LOCAL STORAGE       |        |        REMOTE SERVICES        |
| Hive NoSQL (userBox,     |        | Supabase Flutter SDK (Auth,   |
| downloadsBox)            |        | Postgrest, Storage, Realtime) |
+--------------------------+        | Dio (Custom file streaming)   |
                                    +-------------------------------+
                                                  |
                                                  v
                                    +-------------------------------+
                                    |     SUPABASE POSTGRESQL DB    |
                                    | RLS Policies | RPCs | Triggers|
                                    +-------------------------------+
```

### Key Technologies
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management & DI**: `GetX` (^4.6.6)
- **Backend Infrastructure**: Supabase Serverless (PostgreSQL + Postgrest)
- **Authentication**: Supabase Auth (JWT, Argon2/Bcrypt password hashing)
- **Local Persistence**: `Hive` (^2.2.3) NoSQL database
- **Networking & File Processing**: `dio` (^5.7.0), `flutter_image_compress` (^2.3.0), `cached_network_image` (^3.4.1)

---

## 2. File-by-File & Module Technical Analysis

### 2.1 Core Modules (`lib/core/`)
- `lib/core/config/color.dart`: Defines color palettes including `PrimaryColor` (Premium Deep Blue `#0D47A1`), `DangerColors`, `GrayscaleColors`, and `AppGradients` (glassmorphism gradients using modern `.withValues(alpha: ...)` API).
- `lib/core/config/typography.dart`: Centralized `AppTypography` text styles utilizing `GoogleFonts` (Inter/Roboto) with responsive scale factors.
- `lib/core/meta/app_meta.dart`: Configuration constants (`appName`, `supabaseUrl`, `supabaseAnonKey`, `avatarUrl`).
- `lib/core/helper/hive_boxes.dart`: Abstraction for Hive storage. Manages `userBox` (caching `UserModel` for instant app launch) and `downloadsBox`.
- `lib/core/helper/image_helper.dart`: Utility for compressing user uploads (`FlutterImageCompress`) to JPEG format with 70% quality and 1024x1024 maximum dimensions to reduce network bandwidth.
- `lib/core/helper/custom_icon.dart`: Custom SVG icon viewer (`flutter_svg`) and user avatar renderer.

### 2.2 Controllers (`lib/controller/`)
- `auth_controller.dart`: Handles Supabase Auth email login, registration, metadata sync, and local session persistence via Hive.
- `home_controller.dart`: Manages the main feed, real-time updates via `supabase.channel('public:documents')`, batch fetching (50 items limit), and official feed filtering.
- `document_controller.dart`: Manages reactive document interactions (likes, dislikes, bookmarks, deletion). Executes database RPCs (`increment_likes`, `decrement_likes`) with optimistic UI updates. Syncs state with `HomeController`.
- `upload_controller.dart`: Orchestrates multi-part post uploads (Cover Image + PDF/Image Document or External Link). Handles client-side validation, 10MB size limits, image compression, and admin 'Official' content marking.
- `profile_controller.dart`: Handles current user profile fetching, bio updates, and profile picture modifications.
- `profile_user_controller.dart`: Handles viewing peer user profiles and toggling follow/unfollow status.
- `comment_controller.dart`: Manages nested comment threads and replies on posts.
- `notification_controller.dart`: Fetches and marks activity notifications (likes, comments, follows) as read.
- `search_controller.dart`: Dynamic document and user search filtering.
- `download_controller.dart`: Manages file download status and cached metadata.
- `connection_controller.dart`: Peer-to-peer connection listing (followers/following).
- `file_controller.dart`: Handles file selection via `file_picker`.
- `showcase_controller.dart`: Manages user post showcase grids on profile screens.
- `post_controller.dart`: Specialized controller for short update post interactions.
- `remote_config_controller.dart`: Dynamically fetches system features and announcements from `remote_config` table.
- `bottom_navigation_controller.dart`: Controls bottom tab selection.

### 2.3 Services (`lib/service/`)
- `file_caching.dart`: Manages local storage of downloaded PDF and document files using `Dio` and `path_provider`. Checks temporary directory cache before downloading.
- `file_download.dart`: Downloads documents with system notifications (`flutter_local_notifications`).
- `notification_service.dart`: Initializes local push notifications.

### 2.4 Models (`lib/model/`)
- `document_model.dart`: Data model for notes and tweets, including interaction flags (`isLiked`, `isBookmarked`, `isOfficial`).
- `user_model.dart` & `user_model.g.dart`: Hive-adaptable user model for persistent session caching.
- `mini_user_model.dart`: Lightweight user reference model for lists and avatars.
- `post_model.dart`: Specialized post data model.

### 2.5 Views (`lib/view/`)
- `splash_screen/splash.dart`: Lottie-animated boot screen; checks Hive session to route to `Layout` or `Login`.
- `auth_screen/login.dart`: Login/Registration form with input validation.
- `home_screen/home.dart`: Main feed with sticky header, shimmer loading placeholders, liquid pull-to-refresh, and `DocumentCard` feed items.
- `official_screen/official_screen.dart`: Verified academic updates feed posted by admins.
- `document_screen/document.dart`: Document detail view with full description, document opener, and nested comment thread (`CommentSection`, `CommentTile`).
- `upload_screen/upload_screen.dart` & `upload_form.dart`: Resource upload form supporting direct PDF upload or external links, cover image picker, and admin 'Official' toggle.
- `profile_screen/`: Current user and peer profile view (`ProfileUser`), showcasing documents, followers/following counts, and edit profile dialog.
- `search_screen/search.dart`: Real-time query search interface.
- `notification_screen/notifications.dart`: User activity feed with read state highlights.
- `settings_screen/about.dart`: Platform vision and developer credits.
- `widgets/`: Reusable components including `AdminBadge`, `DocumentCard`, `PostCard`, `PrimaryButton`, `RefresherWidget`, and `Toasts`.

---

## 3. Performance Analysis

1. **Reactive State Management**:
   - `GetX` eliminates unnecessary widget rebuilds by wrapping dynamic UI regions in fine-grained `Obx` and `GetX` builders.
2. **Local Session Caching**:
   - `Hive` NoSQL database provides instant startup by loading cached user profiles from `userBox` without blocking for network authorization responses.
3. **Optimistic UI Updates**:
   - `DocumentController` updates like/dislike/bookmark UI states instantly before the network call finishes. On network error, state is seamlessly reverted.
4. **Media Optimization Pipeline**:
   - Cover images are automatically compressed via `FlutterImageCompress` (JPEG 70% quality, max 1024x1024).
   - Network thumbnails are cached on disk via `CachedNetworkImage`.
5. **Database Concurrency & RPCs**:
   - Atomic functions (`increment_likes`, `decrement_likes`) eliminate race conditions on high-traffic posts.
6. **Network Efficiency**:
   - Batching feed responses (`.limit(50)`) and caching file downloads locally via `Dio` prevents redundant server bandwidth consumption.

---

## 4. Design & UI/UX Architecture

- **Visual Theme**: Rebranded to **Premium Deep Blue** (`#0D47A1`), instilling academic authority and clarity.
- **Glassmorphism Aesthetic**:
  - Semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`) and dynamic gradients (`AppGradients.premiumGradient`).
  - Implemented in `HomeHeader`, `PostCard`, and `BottomFooter`.
- **Material 3 UI Guidelines**:
  - Rounded container geometry (12pt to 24pt corner radii).
  - Clean typographic hierarchy using `AppTypography`.
- **User Feedback & Smooth Transitions**:
  - Shimmer placeholders (`Shimmer.fromColors`) indicate loading states.
  - Custom `Lottie` vector animations for empty states and splash screen.

---

## 5. Security Analysis & Database Audit

### 5.1 Authentication & Authorization
- **Managed JWTs**: Auth handled by Supabase Auth with secure JSON Web Tokens.
- **Password Security**: Managed server-side with Argon2/Bcrypt hashing; plain-text credentials are never stored or logged.

### 5.2 Row Level Security (RLS) (`SUPABASE_SCHEMA.sql`)
Every table enforces RLS to guarantee data isolation:

```sql
-- Profiles: Public read, owner update
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Documents: Public read, owner write
CREATE POLICY "Documents are viewable by everyone" ON public.documents FOR SELECT USING (true);
CREATE POLICY "Users can insert their own documents" ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Privilege Escalation Prevention: Admin RPC and Trigger Validation
CREATE OR REPLACE FUNCTION check_official_permission() RETURNS trigger AS $$
BEGIN
  IF NEW.is_official = true AND NOT (SELECT is_admin FROM public.profiles WHERE id = auth.uid()) THEN
    RAISE EXCEPTION 'Only administrators can mark content as official.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

### 5.3 Storage & API Security
- **File Upload Limits**: Direct document uploads are enforced to <= 10MB client-side.
- **Storage Bucket Policies**: Supabase Storage buckets enforce RLS, allowing users to write only to their respective upload folders while permitting public read for verified assets.

---

## 6. Android Configuration & Deployment

- **Target SDK**: Android 36 (`compileSdk 36`).
- **Java Compatibility**: Java 17 source & target compatibility in `notehub/android/app/build.gradle`.
- **MultiDex & Desugaring**: `multiDexEnabled true` and `coreLibraryDesugaring` enabled to support `flutter_local_notifications`.

---

## 7. QA & Maintenance Guidelines

### Prerequisites
- Flutter SDK 3.24+ (Dart SDK ^3.5.4)

### Verification Commands
1. **Static Analysis**:
   ```bash
   cd notehub
   flutter analyze
   ```
   *Requirement: Must return "No issues found!" under Zero Warnings policy.*

2. **Unit Tests**:
   ```bash
   cd notehub
   flutter test
   ```
   *Requirement: All tests must pass.*

---
*Maintained and Documented by Jules, AI Software Engineer.*
