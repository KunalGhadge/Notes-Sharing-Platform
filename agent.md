# Developer Technical Guide & System Manual - Serious Study (formerly NoteHub)

This manual provides an exhaustive, developer-centric technical analysis of **Serious Study** (formerly NoteHub). It documents the complete system architecture, file-by-file component mappings, performance optimizations, design paradigms, security audits, database schemas, and quality assurance workflows following the migration to a serverless **Supabase** backend.

---

## 1. System Architecture & High-Level Overview

Serious Study is an academic resource sharing and social networking platform engineered specifically for the Mumbai University student community. The application utilizes a decoupled, serverless architecture that pairs a reactive **Flutter** frontend with a **Supabase (PostgreSQL)** backend and high-performance **Hive** local storage.

### 1.1 Architectural Blueprint

```
+-----------------------------------------------------------------------+
|                           FLUTTER FRONTEND                            |
|                                                                       |
|  +-------------------+    +--------------------+    +--------------+  |
|  |   UI Views &      |    |  GetX Controllers  |    | Hive Storage |  |
|  | Component Widgets | <->| (Business Logic)   | <->| (Local Cache)|  |
|  +-------------------+    +--------------------+    +--------------+  |
|                                     ^                                 |
+-------------------------------------|---------------------------------+
                                      | Supabase Flutter SDK / Dio
                                      v
+-----------------------------------------------------------------------+
|                          SUPABASE BACKEND                             |
|                                                                       |
|  +-------------------+    +--------------------+    +--------------+  |
|  |   Supabase Auth   |    |  PostgreSQL Database|   | Object Storage|  |
|  |   (JWT Sessions)  |    | (RLS & RPC Triggers)|   | (Media/Files) |  |
|  +-------------------+    +--------------------+    +--------------+  |
|                                     ^                                 |
|                                     | Postgres Realtime               |
|                                     v                                 |
|                      Realtime Event Notification                      |
+-----------------------------------------------------------------------+
```

---

## 2. Comprehensive File-by-File Component Mapping

The `notehub/lib/` directory is organized into a modular structure separating state, domain models, services, UI views, and core utilities.

### 2.1 Core Infrastructure (`lib/core/`)
- **`lib/core/config/color.dart`**: Centralized color tokens defining `PrimaryColor` ("Premium Deep Blue" `#0D47A1`), `DangerColors`, `GrayscaleWhiteColors`, `GrayscaleGrayColors`, `GrayscaleBlackColors`, `OtherColors`, and `AppGradients` (`premiumGradient` and `glassGradient`).
- **`lib/core/config/typography.dart`**: Standardized typography scale using Google Fonts (Inter/Roboto), exposing `heading1` through `heading6`, `subHead1` through `subHead3`, and `body1` through `body4`.
- **`lib/core/meta/app_meta.dart`**: Holds runtime application metadata (`appName = "Serious Study"`), Supabase endpoint URLs, anon keys, and fallback UI avatar templates.
- **`lib/core/helper/hive_boxes.dart`**: Provides type-safe static access to Hive storage boxes (`userBox` for session metadata and `downloadsBox` for offline file records).
- **`lib/core/helper/image_helper.dart`**: Contains media compression utility (`ImageHelper.compressImage`) leveraging `flutter_image_compress` to compress target images to JPEG format with 70% quality and 1024x1024 maximum resolution.
- **`lib/core/helper/custom_icon.dart`**: Reusable SVG rendering component built on `flutter_svg` and custom avatar fallback renderer (`CustomAvatar`).

### 2.2 Controllers (`lib/controller/`)
- **`lib/controller/auth_controller.dart`**: Manages email/password authentication via Supabase Auth (`signInWithPassword`, `signUp`), profile synchronization (`fetchAndStoreProfile`), and session persistence in Hive (`userBox`).
- **`lib/controller/home_controller.dart`**: Handles the main activity feed, fetching documents in batches (limit 50), filtering official content (`fetchOfficialUpdates`), and subscribing to Supabase Realtime changes on `public:documents`.
- **`lib/controller/document_controller.dart`**: Controls document operations, including optimistic UI handling for likes, dislikes, and bookmarks, executing PostgreSQL RPC counter functions (`increment_likes`, `decrement_likes`), document deletion with storage cleanup, and launching external URLs or local file views.
- **`lib/controller/upload_controller.dart`**: Orchestrates resource uploads (Notes and Short Updates/Tweets). Handles file selection, file size enforcement (< 10MB limit), image compression, and admin toggle states (`is_official`).
- **`lib/controller/profile_controller.dart`**: Manages the logged-in user's profile state, profile updates (display name, bio, interests), and local Hive cache synchronization.
- **`lib/controller/profile_user_controller.dart`**: Fetches public profile metadata and follower/following metrics for external users.
- **`lib/controller/showcase_controller.dart`**: Manages tabbed showcases on user profiles (Uploaded Notes, Short Updates, Bookmarked Notes).
- **`lib/controller/comment_controller.dart`**: Fetches, posts, and deletes hierarchical nested comments (`parentId` support) for documents.
- **`lib/controller/notification_controller.dart`**: Manages user notifications, fetching unread activity alerts and providing mark-as-read RPC calls.
- **`lib/controller/connection_controller.dart`**: Manages follower/following relationships and user search listings for social connections.
- **`lib/controller/download_controller.dart`**: Tracks local file download metadata stored in `downloadsBox`.
- **`lib/controller/file_controller.dart`**: Handles file selection using `file_picker`.
- **`lib/controller/post_controller.dart`**: Handles short update/tweet interactions.
- **`lib/controller/search_controller.dart`**: Powers multi-parameter document search filtering by subject, topic, and post type.
- **`lib/controller/remote_config_controller.dart`**: Reads dynamic key-value parameters from the `remote_config` PostgreSQL table.
- **`lib/controller/bottom_navigation_controller.dart`**: Controls tab index navigation across the main app bottom bar.

### 2.3 Models (`lib/model/`)
- **`lib/model/user_model.dart`**: Domain model representing user profiles, annotated with Hive annotations (`@HiveType`, `@HiveField`) for local persistence (`user_model.g.dart`). Includes fields for `id`, `username`, `displayName`, `profile`, `institute`, `documents`, `followers`, `following`, and `isAdmin`.
- **`lib/model/document_model.dart`**: Domain model for shared notes and short updates. Encapsulates `documentId`, `name`, `topic`, `description`, `documentUrl`, `coverUrl`, `likes`, `dislikes`, `isLiked`, `isDisliked`, `isBookmarked`, `isExternal`, `isOfficial`, and `postType` (`note` or `tweet`).
- **`lib/model/mini_user_model.dart`**: Lightweight representation of user profiles for list views and comment tiles.
- **`lib/model/post_model.dart`**: Model representing short updates.

### 2.4 Services (`lib/service/`)
- **`lib/service/file_download.dart`**: Manages file downloads using Dio, calculates progress, triggers local system notifications via `flutter_local_notifications`, and registers saved files in `downloadsBox`.
- **`lib/service/file_caching.dart`**: Intercepts document requests to determine if a local cached file exists in temporary storage before initiating a network request.
- **`lib/service/notification_service.dart`**: Encapsulates initialization and channel configuration for `flutter_local_notifications`.

### 2.5 Views & Component Modules (`lib/view/`)
- **`lib/layout.dart`**: Root container providing bottom navigation bar integration (`BottomFooter`) and indexing across main screens.
- **`lib/main.dart`**: Application entry point. Initializes Supabase SDK, registers global GetX bindings, initializes Hive boxes, and launches `Splash`.
- **`lib/view/splash_screen/splash.dart`**: Displays branded Lottie animation (`notes.json`) and evaluates Hive session status for routing to `Layout` or `Login`.
- **`lib/view/auth_screen/`**: Authentication module featuring `Login`, `LoginHeader`, `LoginForm`, and `LoginFields`.
- **`lib/view/home_screen/`**: Feed interface composed of `HomeHeader` (welcome card with glassmorphism, notifications trigger, search trigger), `HomeDocumentSection` (infinite list of notes and posts), and filter chips.
- **`lib/view/official_screen/official_screen.dart`**: Curated feed displaying content verified with `is_official = true`.
- **`lib/view/document_screen/`**: Detailed note viewer screen incorporating `DocDescription`, `IconViewer`, `FollowButton`, `CommentSection`, and `CommentTile` (supporting nested reply threads and admin badges).
- **`lib/view/profile_screen/`**: User profiles featuring `ProfileHeader`, `FollowerWidget`, `ProfileShowcase`, `EditProfileDialog`, and `PostRenderer`.
- **`lib/view/upload_screen/`**: Resource contribution interface containing `UploadForm`, `UploadButton`, and admin toggle switches.
- **`lib/view/notification_screen/notifications.dart`**: Real-time notification feed.
- **`lib/view/search_screen/search.dart`**: Interactive query and topic filter screen.
- **`lib/view/settings_screen/about.dart`**: Information screen displaying app vision, MU branding, and developer credits.
- **`lib/view/widgets/`**: Common component library including `DocumentCard`, `PostCard`, `AdminBadge`, `PrimaryButton`, `SecondaryButton`, `NormalButton`, `OptionButton`, `RefresherWidget`, `Loader`, `UploadTextField`, and `Toasts`.

---

## 3. Technical Deep-Dive: Performance Analysis

### 3.1 State Management & Reactivity Strategy
- **Decoupled Business Logic**: GetX controllers manage state using reactive primitives (`RxBool`, `RxList`, `Rxn`). UI components subscribe to state streams using `Obx` or `GetBuilder`.
- **Optimistic UI Updates**: Interactions such as likes, dislikes, and bookmarks employ optimistic UI updates. Client state mutates immediately upon user interaction, providing sub-10ms UI feedback. If the network request fails, the state automatically reverts to its previous snapshot and alerts the user via toast notification.

```dart
// Example Optimistic UI Pattern in DocumentController
Future<void> toggleLike(DocumentModel doc) async {
  final wasLiked = doc.isLiked;
  final originalLikes = doc.likes;

  // Immediate UI Mutation
  doc.isLiked = !doc.isLiked;
  doc.likes += doc.isLiked ? 1 : -1;
  update();

  try {
    if (wasLiked) {
      await supabase.from('interactions').delete().match({'user_id': userId, 'document_id': doc.documentId});
      await supabase.rpc('decrement_likes', params: {'doc_id': doc.documentId});
    } else {
      await supabase.from('interactions').upsert({'user_id': userId, 'document_id': doc.documentId, 'type': 'like'});
      await supabase.rpc('increment_likes', params: {'doc_id': doc.documentId});
    }
  } catch (e) {
    // Revert state on network error
    doc.isLiked = wasLiked;
    doc.likes = originalLikes;
    update();
    Toasts.showTostError(message: "Could not update like: $e");
  }
}
```

### 3.2 Offline Storage & Caching
- **Hive NoSQL Storage**: Local session storage (`userBox`) bypasses disk I/O bottlenecks by maintaining user session models in memory.
- **Media Compression**: Direct image uploads are processed through `ImageHelper.compressImage`, drastically reducing upload payloads and cloud storage costs:

```dart
static Future<File?> compressImage(File file) async {
  final filePath = file.absolute.path;
  final outPath = "${filePath.substring(0, filePath.lastIndexOf('.'))}_compressed.jpg";
  return await FlutterImageCompress.compressAndGetFile(
    filePath,
    outPath,
    quality: 70,
    minWidth: 1024,
    minHeight: 1024,
  );
}
```

- **Network Image Caching**: Network images use `cached_network_image` with local disk caching to prevent redundant HTTP GET calls.
- **External Link Optimization**: Uploaders can attach external resource links (Google Drive, Mega, OneDrive) rather than direct PDF files, reducing server bandwidth requirements.

### 3.3 Database Operations & RPCs
- **Atomic CounterRPCs**: Atomic operations (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`) run as PostgreSQL RPC functions inside the database, avoiding read-modify-write race conditions.
- **Feed Batching**: Queries against the `documents` table specify explicit batch limits (`limit(50)`) and select only required relational columns (`profiles:user_id(...)`) to optimize network traffic.

---

## 4. Technical Deep-Dive: Design & Aesthetic Standards

### 4.1 Visual Identity & Rebranding
- **Color Palette**: Shifted to "Premium Deep Blue" (`#0D47A1`) as the primary brand anchor, representing Mumbai University's academic identity.
- **Accent Tokens**:
  - `PrimaryColor.shade500`: `#0D47A1` (Primary Deep Blue)
  - `PrimaryColor.shade100`: `#E3F2FD` (Soft Blue Tint)
  - Admin Accent (`premiumGold`): `#FFFFD700`
  - Danger Red: `#FF3728`

```
  +-------------------------------------------------------+
  |                   COLOR PALETTE                       |
  |                                                       |
  |  [ #0D47A1 ]  Primary Deep Blue (Brand Main)          |
  |  [ #E3F2FD ]  Soft Blue Tint (Background Containers)  |
  |  [ #FFFFD700 ] Premium Gold (Admin Badges/Highlights) |
  |  [ #FF3728 ]  Danger Red (Delete/Error States)        |
  +-------------------------------------------------------+
```

### 4.2 Material 3 & Glassmorphism Paradigm
- **Glassmorphic Overlays**: Applied across navigation footers and image overlays using `GlassmorphicContainer` and `AppGradients.glassGradient` with `.withValues(alpha: ...)` opacity layers:

```dart
static LinearGradient glassGradient = LinearGradient(
  colors: [
    Colors.white.withValues(alpha: 0.1),
    Colors.white.withValues(alpha: 0.05),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
```

- **Perceptual Motion & Feedback**: Lottie asset animations (`assets/animations/notes.json`) provide state feedback during splash initialization, empty searches, and file uploads.
- **Shimmer Placeholders**: Skeletal shimmer layouts (`shimmer`) are displayed during asynchronous document fetching.

---

## 5. Technical Deep-Dive: Security Analysis & Migration Audit

### 5.1 Legacy vs. Serverless Security Matrix

| Vulnerability Domain | Legacy Stack (Django / MongoDB) | Modern Stack (Supabase / PostgreSQL) |
| :--- | :--- | :--- |
| **Authentication** | Session-less basic credentials | **Supabase Auth with Signed JWTs** |
| **Password Storage** | Plain text / simple hashes | **Argon2 / Bcrypt Managed Key Hashing** |
| **Database Authorization** | Unprotected custom API routes | **PostgreSQL Row Level Security (RLS)** |
| **Privilege Escalation** | Vulnerable to client-side role manipulation | **RLS WITH CHECK Policies & Trigger Verification** |
| **Search Path Hijacking** | N/A | **RPC `SET search_path = public` Directives** |
| **Asset Access** | Unrestricted static links | **Signed Storage Bucket Policies** |

### 5.2 Row Level Security (RLS) Policy Audit

All public schema tables enforce `ROW LEVEL SECURITY`.

#### 1. Profiles Table
```sql
-- Public Read Access
CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

-- Owner Insert Access
CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Owner Update Access with Role Escalation Guard
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id AND
    is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
  );
```

#### 2. Documents Table & Official Content Restriction
```sql
-- Public Read Access
CREATE POLICY "Documents are viewable by everyone"
  ON public.documents FOR SELECT USING (true);

-- Owner Insert Access
CREATE POLICY "Users can insert their own documents"
  ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Owner / Admin Update/Delete Access
CREATE POLICY "Admins can update documents"
  ON public.documents
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
```

#### 3. Database Trigger for Official Verification Guard
To prevent non-admin users from setting `is_official = true` during document creation or update, a PostgreSQL trigger enforces privilege checking:

```sql
CREATE OR REPLACE FUNCTION public.check_official_permission()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_official = true THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    ) THEN
      RAISE EXCEPTION 'Only administrators can mark content as official.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER ensure_official_permission
  BEFORE INSERT OR UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION public.check_official_permission();
```

---

## 6. Database Schema & RPC Technical Specification

### 6.1 Database Schema DDL (`SUPABASE_SCHEMA.sql`)

```sql
-- 1. Profiles Table
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

-- 2. Documents Table
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

-- 3. Comments Table
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Interactions Table (Likes/Dislikes)
CREATE TABLE IF NOT EXISTS public.interactions (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT CHECK (type IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(document_id, user_id)
);

-- 5. Bookmarks Table
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(document_id, user_id)
);

-- 6. Notifications Table
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

-- 7. Followers Table
CREATE TABLE IF NOT EXISTS public.followers (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  UNIQUE(follower_id, following_id)
);
```

### 6.2 Atomic Counter RPC Functions

```sql
CREATE OR REPLACE FUNCTION increment_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET likes_count = likes_count + 1 WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION decrement_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET likes_count = GREATEST(0, likes_count - 1) WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION increment_dislikes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET dislikes_count = dislikes_count + 1 WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION decrement_dislikes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET dislikes_count = GREATEST(0, dislikes_count - 1) WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 7. Development, Maintenance & QA Standards

### 7.1 Prerequisites & Toolchain
- **Flutter SDK**: `v3.24+` (Stable)
- **Dart SDK**: `^3.5.4`
- **Android Target**: `compileSdk 36`, `Java 17` compatibility
- **Build Configuration**: MultiDex enabled with core library desugaring in `notehub/android/app/build.gradle`:

```groovy
android {
    compileSdk 36
    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
    defaultConfig {
        multiDexEnabled true
    }
}
```

### 7.2 Zero Warnings Compliance Policy
All code modifications must maintain zero static analysis warnings under `flutter analyze`:

1. **Modern Color API**: Always use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
2. **Switch Controls**: Always use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Braces**: Enforce explicit curly braces `{}` around single-line `if`/`else` control structures.
4. **Silent Error Blocks**: Add `// ignore: empty_catches` on its own line inside empty catch blocks.

### 7.3 QA Verification Commands
Execute the following commands in `notehub/` prior to submitting any code changes:

```bash
# 1. Verify Static Analysis (Must return 0 issues)
flutter analyze

# 2. Execute Test Suite
flutter test
```

---
*Maintained and verified by Jules, AI Software Engineer.*
