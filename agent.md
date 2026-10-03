# Serious Study (formerly NoteHub) - Developer Technical Manual & System Architecture

This document serves as the primary system manual and developer guide for **Serious Study**, an academic resource-sharing and networking platform tailored for the Mumbai University student community. It provides a deep technical analysis covering system architecture, performance optimizations, UI/UX design paradigms, database schemas, security posture, and QA maintenance procedures.

---

## 1. Executive Summary & Architecture Overview

Serious Study transitioned from a legacy Django/MongoDB backend to a modern, serverless **Supabase** (PostgreSQL) architecture integrated with a **Flutter** cross-platform client.

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER FRONTEND (UI/UX)                        │
│  GetX Reactive Controllers  │  Material 3 + Glassmorphism  │  Hive Caching │
└────────────────────────────────────┬────────────────────────────────────┘
                                     │ Supabase Flutter SDK / Dio
                                     ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        SUPABASE SERVERLESS BACKEND                       │
│  ┌────────────────────────┐  ┌───────────────────────┐  ┌─────────────┐  │
│  │     Supabase Auth      │  │ PostgreSQL + RLS      │  │  Storage    │  │
│  │ (JWT / Argon2 / Bcrypt)│  │ (Tables, RPCs, Triggers)│ (Buckets)   │  │
│  └────────────────────────┘  └───────────────────────┘  └─────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
```

### Architectural Component Mapping

| Directory / File | Technical Role & Description |
| :--- | :--- |
| **`lib/main.dart`** | Entry point; initializes Supabase client, configures GetX controller bindings, and sets up global Material 3 theme configurations. |
| **`lib/layout.dart`** | Primary shell container with custom glassmorphism bottom navigation (`BottomFooter`), routing indexed views (`HomeScreen`, `OfficialScreen`, `SearchView`, `UploadScreen`, `ProfileScreen`). |
| **`lib/controller/`** | GetX business logic layer: |
| ├── `auth_controller.dart` | Authentication lifecycle (login, register, session persistence in Hive, profile fetching/upserting). |
| ├── `document_controller.dart` | Document/Tweet actions (likes, dislikes, bookmarks, optimistic UI updates, delete, launch external/local files). |
| ├── `home_controller.dart` | Primary resource feed, pagination (50-item batches), Realtime Postgres listeners, official posts feed fetching. |
| ├── `upload_controller.dart` | Resource creation pipeline, 10MB direct file guardrails, image compression, external link handling, official content toggling. |
| ├── `profile_controller.dart` | Current user profile state management, Hive local storage synchronization. |
| ├── `comment_controller.dart` | Nested comment trees, parent-child reply relationships, comment deletion. |
| ├── `search_controller.dart` | Dynamic resource and user discovery queries. |
| └── `download_controller.dart` | Local file download tracking, Dio background task management. |
| **`lib/model/`** | Strongly typed data transfer objects (`UserModel`, `DocumentModel`, `PostModel`, `MiniUserModel`). |
| **`lib/core/`** | Centralized configurations and helper utilities: |
| ├── `config/color.dart` | Rebranded design tokens ("Premium Deep Blue" `#0D47A1`), gradients, and modern `.withValues(alpha: ...)` color methods. |
| ├── `config/typography.dart` | AppTypography style scale built on Google Fonts. |
| ├── `helper/hive_boxes.dart` | Persistent NoSQL local boxes (`userBox`, `downloadsBox`) for zero-latency app initialization. |
| └── `helper/image_helper.dart` | `flutter_image_compress` utility (JPEG format, 70% quality target). |
| **`lib/service/`** | Services: `file_caching.dart` (Dio path provider caching), `file_download.dart` (downloading and local notification dispatching), `notification_service.dart`. |
| **`lib/view/`** | Modular UI screens and component widgets (`home_screen/`, `upload_screen/`, `document_screen/`, `profile_screen/`, `auth_screen/`, `search_screen/`, `official_screen/`, `notification_screen/`, `widgets/`). |
| **`SUPABASE_SCHEMA.sql`** | Source of truth for PostgreSQL database tables, RPC functions, triggers, constraints, Realtime subscriptions, and Row Level Security (RLS) policies. |

---

## 2. In-Depth Performance Analysis

### 2.1 State Management & Reactive Lifecycle
- **Framework**: `GetX` reactive state management.
- **Granular Rebuilds**: Uses fine-grained reactive primitives (`RxBool`, `RxString`, `RxList`, `Obx`) and `GetBuilder` to limit widget subtree rebuilds strictly to modified UI elements.
- **Optimistic UI Updates**: Operations such as toggling likes, dislikes, or bookmarks in `DocumentController` immediately alter UI state while asynchronously dispatching backend updates. If the RPC call fails, state is automatically reverted to ensure client consistency.

### 2.2 Local Storage & Offline-First Metadata Caching
- **Engine**: `Hive` NoSQL database (`hive_flutter`).
- **User Session Persistence**: Profile metadata is cached in `userBox` upon login (`lib/core/helper/hive_boxes.dart`), allowing instant rendering of the user's profile and drawer without waiting for network responses on app launch.
- **Download Tracking**: Downloaded file paths and metadata are stored in `downloadsBox` to enable offline document viewing.

### 2.3 Network, Bandwidth & Media Pipeline
- **File Download Engine**: Handled via `Dio` combined with `path_provider`. Existing downloaded files in temporary storage are reused before initiating network calls.
- **Pre-Upload Asset Compression**: All cover art and image uploads are piped through `ImageHelper.compressImage` (`flutter_image_compress`), converting raw images into optimized JPEGs at 70% quality with a maximum target dimension of 1024x1024.
- **File Upload Limits**: Direct uploads enforce a strict 10MB limit. For larger documents, the app provides seamless support for **External Links** (Google Drive, Mega, OneDrive).

### 2.4 Pagination & Realtime Postgres Subscriptions
- **Chunked Pagination**: `HomeController` fetches resources in batches of 50 items (`.range(start, end)`), sorted chronologically to optimize database query performance and payload size.
- **Postgres Realtime Integration**: `HomeController` initializes a Realtime channel listener (`supabase.channel('public:documents').onPostgresChanges(...)`), automatically injecting newly uploaded notes into the client feed without full page refreshes.

### 2.5 Database Concurrency & Atomic Counters
- **PostgreSQL RPCs**: User interactions (likes, dislikes) trigger database-level RPC functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`) defined in `SUPABASE_SCHEMA.sql`. This delegates concurrency handling to PostgreSQL, preventing race conditions and counter desynchronization.

---

## 3. Design System & UI/UX Aesthetics

### 3.1 Material 3 Paradigm & Glassmorphism Aesthetics
- **Visual Design**: Blends **Material 3** components with a custom **Glassmorphism** aesthetic.
- **Frosted Glass Components**: `GlassmorphicContainer` and translucent overlays (`Colors.white.withValues(alpha: 0.15)`) create a modern, layered visual identity.
- **App Bar & Bottom Navigation**: Floating frosted glass navigation bar (`BottomFooter`) featuring custom rounded corner radii (`30.0`), subtle box shadows, and responsive tab indicators.

### 3.2 Palette & Color Tokens
- **Primary Rebrand Theme**: "Premium Deep Blue" (`#0D47A1` primary, `#1565C0` secondary accent, `#0A192F` dark surface variant).
- **Modern API Compliance**: Standardized on `.withValues(alpha: ...)` across all UI components and theme files, eliminating deprecated `.withOpacity()` usage in Dart SDK 3.5.4+.

### 3.3 Micro-Interactions & Feedback
- **Skeleton Shimmers**: Integrated `shimmer` loaders (`Shimmer.fromColors`) across headers and document feeds during data fetching states.
- **Micro-Animations**: Vector animations (`lottie`) handle empty search states and loading transitions.
- **Scale Animations**: Reactive heart icon scale transition (`ScaleTransition` with `AnimationController`) triggers smooth spring-like animations on document likes.

---

## 4. Security Audit & Risk Assessment

### 4.1 Authentication & Token Lifecycle
- **Provider**: **Supabase Auth** utilizing **JSON Web Tokens (JWT)**.
- **Password Hashing**: Passwords are managed directly by Supabase Auth using industry-standard hashing algorithms (Argon2 / Bcrypt). No plain-text passwords exist in the application layer.
- **Redirect Protocols**: Deep link callback integration (`io.supabase.flutternotehub://login-callback`) for secure authentication handling.

### 4.2 Row Level Security (RLS) Audit
Every table in PostgreSQL has Row Level Security explicitly enabled (`ENABLE ROW LEVEL SECURITY`). Policies enforce strict authorization:

| Table | Policy Type | Enforced Constraint |
| :--- | :--- | :--- |
| **`profiles`** | `SELECT` | Public (`USING (true)`) |
| | `INSERT` | `WITH CHECK (auth.uid() = id)` |
| | `UPDATE` | `USING (auth.uid() = id)` |
| **`documents`** | `SELECT` | Public (`USING (true)`) |
| | `INSERT` | `WITH CHECK (auth.uid() = user_id)` |
| | `UPDATE / DELETE` | Owner or Admin (`USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true))`) |
| **`comments`** | `SELECT` | Public (`USING (true)`) |
| | `INSERT` | `WITH CHECK (auth.uid() = user_id)` |
| **`notifications`** | `SELECT` | Receiver only (`USING (auth.uid() = receiver_id)`) |

### 4.3 Defense Against Privilege Escalation
1. **Profile Role Protection**: To prevent regular users from elevating themselves to admin status, the profile update RLS policy includes an explicit check:
   ```sql
   CREATE POLICY "Users can update own profile" ON public.profiles
     FOR UPDATE USING (auth.uid() = id)
     WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
   ```
2. **Official Document Authorization**: Setting `is_official = true` on documents is guarded at the database layer by an explicit trigger:
   ```sql
   CREATE OR REPLACE FUNCTION public.check_official_permission()
   RETURNS TRIGGER AS $$
   BEGIN
     IF NEW.is_official = true AND (OLD.is_official IS NULL OR OLD.is_official = false) THEN
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
   ```

### 4.4 Search-Path Hijacking Protection
All PostgreSQL functions and RPCs are declared with `SECURITY DEFINER` and explicitly pinned with `SET search_path = public` to protect against search-path injection attacks.

---

## 5. Backend Database Schema (PostgreSQL)

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

-- Comments Table
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
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

## 6. Developer Setup & QA Maintenance

### 6.1 Prerequisites
- **Flutter SDK**: `^3.24.0` (Stable Channel)
- **Dart SDK**: `^3.5.4`
- **Android Configuration**:
  - `compileSdk`: 36
  - `minSdk`: 21
  - `targetSdk`: 34
  - Java 17 toolchain compatibility configured in `notehub/android/app/build.gradle`.

### 6.2 Zero-Warnings Compliance & Code Quality Procedures
The project enforces a strict **Zero Warnings** policy under `flutter analyze`.

1. **Lint Execution**:
   ```bash
   cd notehub
   flutter analyze
   ```
2. **Test Execution**:
   ```bash
   cd notehub
   flutter test
   ```
3. **Coding Standards**:
   - Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
   - Use `activeThumbColor` for modern `Switch` widgets.
   - Enforce curly braces around all flow control structures (`curly_braces_in_flow_control_structures`).
   - Add `// ignore: empty_catches` on its own line inside catch blocks intended to fail silently.

---
*Maintained & Documented by Jules, AI Software Engineer.*
