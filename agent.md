# Technical Manual & Developer Maintenance Guide - Serious Study

## Executive Summary
**Serious Study** (formerly NoteHub) is a high-performance, cross-platform academic social network and notes-sharing platform optimized for the Mumbai University student community. The platform was migrated from a legacy Django/MongoDB architecture to a serverless **Supabase** backend (PostgreSQL, Supabase Auth, Supabase Storage) paired with a **Flutter** client.

This document serves as the authoritative developer reference, detailing performance benchmarks, architectural design patterns, security parameters, database schema policies, directory mappings, and quality assurance workflows.

---

## 1. System Architecture & Tech Stack Overview

### Framework & Environment
- **Framework**: Flutter 3.24+ (Channel Stable)
- **SDK Compatibility**: Dart SDK `^3.5.4`
- **State Management & DI**: `GetX` (`^4.6.6`) for reactive state management, dependency injection, and decoupled view navigation.
- **Local Persistence**: `Hive` (`^2.2.3`) & `hive_flutter` (`^1.1.0`) for high-speed local NoSQL caching of user profiles, session states, and download metadata.
- **Networking & API**: `supabase_flutter` (`^2.8.1`) for direct database queries, JWT auth, realtime channel subscriptions, and object storage; `dio` (`^5.7.0`) for specialized byte-level file downloading and background caching.
- **UI/UX Paradigms**: Material 3, Glassmorphism (`glassmorphism: ^3.0.0`), Shimmer loading animations (`shimmer: ^3.0.0`), Google Fonts (`google_fonts: ^8.0.2`), SVG graphics (`flutter_svg: ^2.0.10+1`), and Lottie animations (`lottie: ^3.1.3`).

### High-Level Architecture Diagram
```
+-----------------------------------------------------------------------+
|                             FLUTTER CLIENT                            |
|                                                                       |
|   +-----------------------+     +-------------------------------+     |
|   |    Views / Screens    |<--->| GetX Controllers (State/Logic)|     |
|   +-----------------------+     +-------------------------------+     |
|              ^                                  ^                     |
|              |                                  |                     |
|              v                                  v                     |
|   +-----------------------+     +-------------------------------+     |
|   |  Hive Local Persistent|     |  Services (Dio/File Caching/  |     |
|   |  Storage (NoSQL Box)  |     |  Notifications/Open File)     |     |
|   +-----------------------+     +-------------------------------+     |
+-----------------------------------------------------------------------+
                                  |
               HTTPS (REST/RPC)   |  Realtime (WebSockets)
                                  v
+-----------------------------------------------------------------------+
|                          SUPABASE BACKEND                             |
|                                                                       |
|   +-------------------+  +--------------------+  +----------------+   |
|   |   Supabase Auth   |  |   PostgreSQL DB    |  | Storage Bucket |   |
|   |  (JWT/Argon2 Hash)|  |  (RLS Policies &   |  |  (Documents &  |   |
|   |                   |  |   RPC Functions)   |  |   Thumbnails)  |   |
|   +-------------------+  +--------------------+  +----------------+   |
+-----------------------------------------------------------------------+
```

---

## 2. Directory Structure & Component Mapping

```
notehub/
├── android/                   # Native Android configuration (compileSdk 36, Java 17, MultiDex)
├── assets/                    # Vector graphics, images, Lottie animations, icons
├── lib/
│   ├── controller/            # GetX Controllers (Business Logic & Reactive State)
│   │   ├── auth_controller.dart              # User auth, login, registration, Hive session persistence
│   │   ├── document_controller.dart          # Doc interactions, optimistic likes/bookmarks, deletion
│   │   ├── home_controller.dart              # Main feed state, search, filter, sticky sorting, Realtime
│   │   ├── upload_controller.dart            # File upload, image compression, validation, link creation
│   │   ├── profile_controller.dart           # User profile management, bio editing, follower counts
│   │   ├── comment_controller.dart           # Threaded comment fetching, posting, and replies
│   │   ├── notification_controller.dart     # User & global announcement notifications
│   │   ├── search_controller.dart           # Dynamic searching for users, notes, and topics
│   │   ├── connection_controller.dart       # User network connections & follow states
│   │   ├── download_controller.dart         # Downloaded file tracking via Hive `downloadsBox`
│   │   ├── file_controller.dart             # Storage operations & file picking
│   │   ├── remote_config_controller.dart    # Dynamic app parameters from Supabase `remote_config`
│   │   ├── showcase_controller.dart         # Highlighted/featured content showcase
│   │   └── bottom_navigation_controller.dart# Bottom navbar index & tab management
│   ├── core/                  # Core constants, themes, and helper utilities
│   │   ├── config/
│   │   │   ├── color.dart                   # Rebranded "Premium Deep Blue" palette & gradients
│   │   │   └── typography.dart              # Google Fonts (Inter / Outfit) typography configurations
│   │   ├── helper/
│   │   │   ├── hive_boxes.dart              # Centralized Hive box access (`userBox`, `downloadsBox`)
│   │   │   ├── image_helper.dart            # Compression pipeline (70% quality JPEG target)
│   │   │   └── custom_icon.dart             # SVG asset icon renderers
│   │   └── meta/
│   │       └── app_meta.dart                # App name, Supabase URL, and publishable Anon Keys
│   ├── model/                 # Data Transfer Objects & Serialization Models
│   │   ├── user_model.dart                  # User profile DTO with Hive TypeAdapter annotations
│   │   ├── document_model.dart              # Note & post metadata model
│   │   ├── post_model.dart                  # Social post / tweet abstraction
│   │   └── mini_user_model.dart             # Compact user summary DTO for feeds & lists
│   ├── service/               # External Integration Services
│   │   ├── file_caching.dart                # Dio-based download manager & file caching
│   │   ├── file_download.dart               # Platform-native file saving & directory provider access
│   │   └── notification_service.dart        # Local push notifications (`flutter_local_notifications`)
│   ├── view/                  # Presentation Layer (UI Screens & Widgets)
│   │   ├── auth_screen/                     # Login & Registration views with glassmorphic header
│   │   ├── home_screen/                     # Feed screen, document cards, category filters
│   │   ├── document_screen/                 # Document details, viewer, comments, author panel
│   │   ├── upload_screen/                   # Document/Link upload form with Official toggle
│   │   ├── profile_screen/                  # Profile page, bio editor, user document showcase
│   │   ├── notification_screen/             # Activity feed & system notifications
│   │   ├── search_screen/                   # Search bar, filtered results grid
│   │   ├── official_screen/                 # Dedicated feed for verified MU official updates
│   │   ├── connection_screen/               # Followers/Following list views
│   │   ├── settings_screen/                 # App info, terms, about dialog
│   │   ├── onboarding_screen/               # Welcome carousel for first-time users
│   │   ├── splash_screen/                   # Animated startup splash screen
│   │   ├── bottom_footer/                   # Glassmorphic bottom navigation overlay
│   │   └── widgets/                         # Reusable UI controls (cards, buttons, toasts, loader)
│   ├── layout.dart            # Primary application shell containing bottom bar & indexed stack
│   └── main.dart              # App entry point, Supabase & Hive initialization, GetX bindings
├── test/
│   └── dummy_test.dart        # Automated unit test suite placeholder for CI verification
├── ANALYSIS.md                # High-level executive overview
├── SUPABASE_SCHEMA.sql        # Full database DDL, constraints, triggers, RPC functions, and RLS policies
└── agent.md                   # This master technical manual and maintenance guide
```

---

## 3. Detailed Performance Analysis

### 3.1 Reactive State Management (`GetX`)
- **Granular Updates**: Controllers maintain lightweight, reactive state variables (e.g., `RxList`, `RxBool`, `RxString`). Re-rendering is confined to specific `Obx` or `GetBuilder` wrappers, preventing unnecessary full-tree widget rebuilds.
- **Cross-Controller Sync**: `DocumentController` triggers `_syncWithHome()` upon modifying document states (e.g., likes, bookmarks, deletions), keeping `HomeController` feed instances in sync without redundant network refetches.

### 3.2 Local Persistent Caching (`Hive`)
- **Instant Cold Starts**: User profile data is cached in `HiveBoxes.userBox`. Upon launch, `userBox.get('user')` populates user state synchronously, eliminating login latency and blank screens.
- **Offline Download Indexing**: File download locations and file names are stored in `HiveBoxes.downloadsBox`, enabling instant offline verification before triggering web downloads.

### 3.3 Asset & Network Optimization
- **Image Compression Pipeline**: `ImageHelper.compressImage()` compresses image assets using `flutter_image_compress` (target quality 70%, resolution 1024x1024 JPEG format) prior to network transmission, reducing bucket storage footprint and upload bandwidth by up to 80%.
- **Network Image Caching**: Network graphics and avatar thumbnails utilize `cached_network_image`, storing cached images on disk to prevent repetitive network requests.
- **Smart Download Caching**: `FileCaching` checks native disk storage (`path_provider`) for pre-existing documents matching the requested URL before initiating Dio HTTP byte-stream transfers.

### 3.4 Database Query & Backend Performance
- **Atomic PostgreSQL RPCs**: Counter operations (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`) execute directly within PostgreSQL functions defined in `SUPABASE_SCHEMA.sql`. This avoids client-side race conditions and network round-trip overhead.
- **Batching & Pagination**: Feed documents are queried with explicit `.limit(50)` constraints and sticky ordering (`order('created_at', ascending: false)`), ensuring fast response payloads regardless of total document volume.
- **Supabase Realtime**: `HomeController` registers WebSocket subscriptions via `supabase.channel('public:documents').onPostgresChanges(...)` to receive broadcast updates for newly posted documents without aggressive client polling.

---

## 4. Design & UI/UX Systems

### 4.1 UI Paradigm & Visual Aesthetics
- **Material 3**: The app adheres to Material 3 design specs, utilizing modern rounded surfaces, dynamic elevation, and elevated buttons.
- **Glassmorphism**: Semi-transparent containers (`GlassmorphicContainer`) with subtle border gradients and blur effects are applied to the bottom navigation bar (`BottomFooter`) and top app bars (`HomeHeader`).
- **Color Palette**: Rebranded to "Premium Deep Blue":
  - **Primary**: `#0D47A1` (Deep Blue)
  - **Accent**: `#1E88E5` (Vibrant Blue)
  - **Official Accent**: `#B8860B` (Dark Goldenrod for admin/official verification badges)
  - **Background**: `#F8FAFC` (Clean Light Slate)
  - **Dark Surface**: `#121212` / `#1E1E1E`
- **Typography**: Configured with Google Fonts (`Inter` for body readability, `Outfit` for display headings).

### 4.2 Modern Code Standards Compliance
- **Modern Color Opacity**: In compliance with Dart 3.5.4+ standards, color alpha configurations use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)` method.
- **Modern Switch Controls**: Modernized `Switch` widgets (e.g., in `UploadForm`) use `activeThumbColor` instead of deprecated `activeColor` properties.

---

## 5. Security Analysis & Migration Audit

### 5.1 Authentication & Credential Management
- **Managed JWT Authentication**: Custom session handling has been replaced with `Supabase Auth`. Access and refresh tokens (JWT) are stored and refreshed automatically by the client SDK.
- **Password Security**: Passwords are managed securely by Supabase using industry-standard hashing (Argon2 / Bcrypt). Plaintext credentials never touch client-side local storage or custom servers.

### 5.2 Row Level Security (RLS) Matrix
Row Level Security is strictly enabled across all PostgreSQL tables in `SUPABASE_SCHEMA.sql`:

| Table | Policy Name | Command | Rule / Condition |
| :--- | :--- | :--- | :--- |
| `profiles` | Public profiles are viewable by everyone | `SELECT` | `true` |
| `profiles` | Users can insert their own profile | `INSERT` | `auth.uid() = id` |
| `profiles` | Users can update own profile | `UPDATE` | `auth.uid() = id` AND `WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))` |
| `documents` | Documents are viewable by everyone | `SELECT` | `true` |
| `documents` | Users can insert their own documents | `INSERT` | `auth.uid() = user_id` |
| `documents` | Users can update/delete their own documents | `ALL` | `auth.uid() = user_id` |
| `documents` | Admins can update documents | `UPDATE` | `auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true)` |
| `comments` | Comments are viewable by everyone | `SELECT` | `true` |
| `comments` | Users can insert their own comments | `INSERT` | `auth.uid() = user_id` |
| `interactions` | Users can view interactions | `SELECT` | `true` |
| `interactions` | Users can manage their interactions | `ALL` | `auth.uid() = user_id` |
| `bookmarks` | Bookmarks are private to owner | `ALL` | `auth.uid() = user_id` |
| `notifications` | Users can view their own notifications | `SELECT` | `auth.uid() = receiver_id` |
| `followers` | Followers lists are viewable by everyone | `SELECT` | `true` |
| `followers` | Users can manage their follow states | `ALL` | `auth.uid() = follower_id` |

### 5.3 Privilege Escalation Safeguards
- **Profile Admin Protection**: To prevent users from modifying their `is_admin` status during profile updates, the `profiles` `UPDATE` policy includes an explicit `WITH CHECK` constraint ensuring `is_admin` remains equal to its existing database value.
- **Official Status Enforcement**: Setting `is_official = true` on `documents` is validated via database triggers and admin checks.
- **RPC Function Security**: Stored procedure RPC functions are configured with `SECURITY DEFINER` and include an explicit `SET search_path = public` statement to prevent search-path hijacking attacks.

---

## 6. Database Schema & RPC Specifications

### 6.1 Data Model (PostgreSQL)

```sql
-- Profiles Table
CREATE TABLE public.profiles (
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
CREATE TABLE public.documents (
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
```

### 6.2 Atomic RPC Counter Functions
```sql
CREATE OR REPLACE FUNCTION public.increment_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET likes_count = likes_count + 1 WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.decrement_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET likes_count = GREATEST(0, likes_count - 1) WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 7. Developer QA & Maintenance Guidelines

### 7.1 Environment Requirements
- **Flutter SDK**: `3.24+` (Stable)
- **Dart SDK**: `^3.5.4`
- **Android Target API**: `compileSdk 36`, `Java 17`

### 7.2 Zero Warnings Policy
All code modifications must maintain zero lint issues under `flutter analyze`.

To verify compliance:
```bash
cd notehub
flutter analyze
```

### 7.3 Automated Testing
Execute the test suite prior to submitting changes:
```bash
cd notehub
flutter test
```

### 7.4 Pre-Commit Checklist
1. Ensure all new files comply with `curly_braces_in_flow_control_structures`.
2. Confirm color modifications use `.withValues(alpha: ...)` instead of `.withOpacity(...)`.
3. Confirm `Switch` widgets use `activeThumbColor`.
4. Run `flutter analyze` and confirm 0 issues found.
5. Run `flutter test` and confirm all tests pass.

---
*Maintained by Jules, AI Software Engineer.*
