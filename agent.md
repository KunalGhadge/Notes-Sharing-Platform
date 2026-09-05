# Developer Technical Guide & Maintenance Manual - Serious Study (NoteHub)

This manual provides an in-depth, developer-centric technical analysis of the **Serious Study** platform (formerly NoteHub). It details system architecture, performance engineering, UI/UX design systems, database security parameters, and maintenance procedures following the migration from a legacy Django/MongoDB stack to a serverless **Flutter + Supabase** architecture.

---

## Executive Overview & Tech Stack Summary

Serious Study is an academic networking and resource-sharing platform engineered specifically for higher education communities.

- **Frontend Framework**: Flutter 3.24+ / Dart SDK ^3.5.4 (Cross-platform Android target with Java 17 / compileSdk 36)
- **State Management**: GetX (Reactive `Rx` streams & Dependency Injection)
- **Local Persistence**: Hive NoSQL (Low-latency binary local storage)
- **Backend Architecture**: Serverless Supabase (PostgreSQL 15+ with Realtime engine & RPCs)
- **Authentication**: Supabase Auth (JWT with PKCE flow & persistent session storage)
- **File & Asset Storage**: Supabase Storage Buckets with RLS policies

---

## 1. System Architecture & Layering

The codebase follows a decoupled, reactive **MVC-like** architectural pattern in `notehub/lib/`:

```
lib/
├── controller/        # Business logic & reactive state management (GetX)
├── core/              # Global constants, themes, metadata, and Hive helpers
│   ├── config/        # Color, AppGradients, and AppTypography definitions
│   ├── helper/        # HiveBoxes local cache adapters
│   └── meta/          # AppMetaData constants
├── model/             # Immutable Data Models & JSON serializable entities
├── service/           # Platform & OS Level Services (File Caching, Image Compression)
└── view/              # UI Component taxonomy & screen layouts
    ├── auth_screen/   # Login & Registration flows
    ├── document_screen/ # Note details, comments, and action triggers
    ├── home_screen/   # Feed rendering with real-time updates
    ├── upload_screen/ # Document & Tweet post publishing
    └── widgets/       # Reusable Material 3 & Glassmorphism UI components
```

---

## 2. Deep-Dive Performance Analysis

### 2.1 Reactive State Management (GetX)
- **Granular Observers**: UI widgets selectively consume state updates using `Obx(() => ...)` or `GetX<Controller>()` observers. This limits re-renders strictly to modified DOM nodes rather than entire screen subtrees.
- **Optimistic UI Updates**: User actions (e.g., toggling likes or bookmarks in `DocumentController`) immediately modify the local reactive model state before awaiting network completion. In the event of a Supabase RPC or network failure, state is automatically reverted and error notifications (`Toasts`) are surfaced.
- **Cross-Controller Synchronization**: `DocumentController` invokes `_syncWithHome()` upon modifying document metadata, signaling `HomeController` to update active feeds synchronously without triggering full network re-fetches.

### 2.2 Local Caching Engine (Hive)
- **Zero-Latency App Bootstrapping**: User identity and session metadata are persisted locally via `HiveBoxes.userBox` (`lib/core/helper/hive_boxes.dart`). During initialization, cached credentials allow instant UI rendering while background validation executes.
- **Downloaded File Metadata**: `HiveBoxes.downloadsBox` stores local file system paths and checksums for offline document access.

### 2.3 Network & Asset Optimization
- **On-Device Image Compression**: Before uploading to Supabase Storage, images are processed via `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`), resizing them to max 1024x1024 resolution and JPEG quality 70%, reducing network payload sizes by ~75%.
- **File Download Management**: `FileCachingService` (`lib/service/file_caching.dart`) checks local OS temp/cache storage before starting `Dio` downloads, preventing redundant HTTP bandwidth consumption.
- **Smart Asset Caching**: Network images leverage `cached_network_image` with memory caching headers to eliminate flicker during list scrolling.

### 2.4 Database Scalability & RPC Counter Operations
- **Atomic Concurrency Control**: High-frequency operations like liking/disliking notes bypass standard `UPDATE` operations and call dedicated PostgreSQL Functions (`RPCs`): `increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, and `decrement_bookmarks`. This prevents race conditions and lock contention under concurrent load.
- **Batching & Sticky Pagination**: Feeds fetch documents in optimized page batches (`limit(50)`) sorted by `created_at DESC` with index backing.

---

## 3. Design System & UX Architecture

### 3.1 Material 3 Paradigm & Glassmorphism
- **Color Palette**: Centered on "Premium Deep Blue" (`#0D47A1` primary), balanced with soft light backgrounds (`#E3F2FD` shade 100).
- **Glassmorphic Overlays**: Modern visual layering utilizes semi-transparent linear gradients (`AppGradients.glassGradient`) paired with `Colors.white.withValues(alpha: ...)` for backdrop blurring.
- **Typography Standard**: Standardized typography hierarchy (`AppTypography`) defined in `lib/core/config/typography.dart` using Google Fonts for consistent cross-platform text rendering.

### 3.2 UI Component Taxonomy
- **`DocumentCard`**: Universal media card presenting metadata badges (Official status, PDF page indicator, author handle, like/dislike counts).
- **`PostCard`**: Minimalist card variant tailored for short updates ("Tweets") without attached file payloads.
- **`AdminBadge`**: Distinctive gold badge (`#FFD700`) rendered for verified institutional or official administrative updates.

---

## 4. Security Architecture & Audit

### 4.1 Authentication & Session Integrity
- **JWT Architecture**: Standardized on Supabase Auth. Auth tokens are stored securely in local storage and refreshed automatically via background client interceptors.
- **Password Security**: Managed exclusively by Supabase backend using Bcrypt/Argon2 password hashing; plain-text credentials never touch application memory or custom logging endpoints.

### 4.2 Row Level Security (RLS) Policy Audit
Every table in the PostgreSQL database enforces strict Row Level Security policies:

| Table | Operations | RLS Rule / Policy Expression |
| :--- | :--- | :--- |
| `profiles` | `SELECT` | `USING (true)` (Publicly readable) |
| `profiles` | `INSERT` | `WITH CHECK (auth.uid() = id)` |
| `profiles` | `UPDATE` | `USING (auth.uid() = id)` with `WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))` |
| `documents` | `SELECT` | `USING (true)` |
| `documents` | `INSERT` | `WITH CHECK (auth.uid() = user_id)` |
| `documents` | `UPDATE/DELETE`| `USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true))` |
| `comments` | `SELECT` | `USING (true)` |
| `comments` | `INSERT` | `WITH CHECK (auth.uid() = user_id)` |
| `interactions`| `ALL` | `USING (auth.uid() = user_id)` |
| `bookmarks` | `ALL` | `USING (auth.uid() = user_id)` |
| `notifications`| `SELECT` | `USING (auth.uid() = receiver_id)` |

### 4.3 Privilege Escalation & Definer Security
- **Role Enforcement Trigger**: The system prevents non-admin users from escalating privileged content flags (`is_official = true`) via database trigger checks (`ensure_official_permission`).
- **Search Path Hijacking Protection**: All database functions defined with `SECURITY DEFINER` explicitly include `SET search_path = public` to protect against search-path hijacking attacks in PostgreSQL.

---

## 5. Database Schema Specification

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

---

## 6. Developer Operations & QA Maintenance

### 6.1 Requirements & Prerequisites
- **Flutter SDK**: `^3.24.0` (Stable channel)
- **Dart SDK**: `^3.5.4`
- **Android Target**: SDK Version 36 (`compileSdk 36`), Java 17 compatibility.

### 6.2 Mandatory QA Validation Commands
To maintain the repository's strict **"Zero Warnings"** code quality policy, developers must execute the following commands before submitting code:

```bash
# 1. Navigate to flutter root
cd notehub

# 2. Run static code analyzer (Must yield "No issues found!")
flutter analyze

# 3. Run unit and integration test suite
flutter test
```

### 6.3 Code Quality Guidelines
1. **Flow Control Braces**: Always use explicit curly braces `{}` for single-line `if`/`else` control flow blocks (`curly_braces_in_flow_control_structures`).
2. **Silent Catch Annotations**: When intentionally ignoring errors in non-critical asynchronous catch blocks, format the annotation on its own line:
   ```dart
   try {
     await _doNonCriticalWork();
   } catch (e) {
     // ignore: empty_catches
   }
   ```
3. **Color Value Modernization**: Avoid deprecated `.withOpacity(val)`. Always use `.withValues(alpha: val)`.
4. **Switch Customization**: Always use `activeThumbColor` instead of deprecated `activeColor` on Flutter `Switch` widgets.

---
*Maintained by Jules, Software Engineering Specialist.*
