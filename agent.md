# Developer & Maintenance Guide — Serious Study (formerly NoteHub)

This manual provides a detailed, developer-centric analysis of the **Serious Study** repository. Serious Study is a high-performance notes sharing and academic networking mobile platform designed for the Mumbai University student community.

The platform was modernly migrated from a legacy Django/MongoDB stack to a serverless **Supabase (PostgreSQL)** backend with a **Flutter (Dart 3.5.4+ / Flutter 3.24+)** client application.

---

## 1. Architecture Overview

Serious Study follows a reactive MVC-like pattern empowered by **GetX** for state management and dependency injection, alongside **Hive** for ultra-fast local NoSQL persistence and **Supabase Flutter SDK** for cloud real-time data sync and Auth.

```
┌────────────────────────────────────────────────────────────────────────┐
│                          FLUTTER FRONTEND                              │
│                                                                        │
│  ┌──────────────────────┐   ┌───────────────────┐   ┌───────────────┐  │
│  │     UI / Views       │──▶│  GetX Controllers │──▶│ Local Hive Box│  │
│  │ (Material 3 + Glass) │   │ (Reactive State)  │   │  (userBox)    │  │
│  └──────────────────────┘   └─────────┬─────────┘   └───────────────┘  │
└───────────────────────────────────────┼────────────────────────────────┘
                                        │ (JWT Authenticated Requests)
                                        ▼
┌────────────────────────────────────────────────────────────────────────┐
│                         SUPABASE BACKEND                               │
│                                                                        │
│  ┌──────────────────────┐   ┌───────────────────┐   ┌───────────────┐  │
│  │   Supabase Auth      │   │ PostgreSQL Database│  │ Supabase      │  │
│  │   (JWT / Argon2)     │   │ (RLS + RPC Triggers)│ │ Storage       │  │
│  └──────────────────────┘   └───────────────────┘   └───────────────┘  │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Performance Analysis

- **Reactive State Management & Controller Lifecycle**:
  - `GetX` isolates application logic from widget trees. Controllers like `DocumentController`, `ProfileController`, and `HomeController` reactively stream updates without rebuild overhead.
  - `DocumentController` uses optimistic UI updates for likes and bookmarks while syncing background actions via PostgreSQL RPC functions.
  - `HomeController` limits document feeds (e.g., limit of 50 per page, limit 20 for official updates) to optimize bandwidth and initial render latencies.
- **Local Persistent Storage**:
  - `Hive` provides instantaneous local key-value access via boxes (`userBox` and `downloadsBox` initialized in `lib/core/helper/hive_boxes.dart`). This enables zero-latency profile loads upon app launch.
- **Media Optimization & Network Caching**:
  - `CachedNetworkImage` prevents redundant network roundtrips for document cover thumbnails and user avatars.
  - `flutter_image_compress` compresses uploaded images to JPEG format (70% quality, max 1024x1024 resolution) via `ImageHelper.compressImage` before initiating Supabase Storage uploads.
  - `UploadController` enforces a strict **10MB limit** on file uploads to protect backend bandwidth and memory usage.
  - `FileCachingService` leverages `Dio` and `path_provider` to manage document downloads efficiently, checking local temporary storage before starting new network transfers.
- **Database Scalability**:
  - **Atomic Counter Operations**: Counters like `likes_count`, `dislikes_count`, and `bookmarks` are updated via server-side PostgreSQL RPC functions (`increment_likes`, `decrement_likes`, etc.). This eliminates race conditions during high concurrent traffic.
  - **Visual Feedback**: Shimmer loaders (`shimmer` package) and Lottie animations provide feedback during asynchronous fetches.

---

## 3. Design & UI/UX System

- **Design Aesthetics**:
  - **Material 3 Paradigm**: Modernized component specs with rounded geometry, dynamic surface tones, and fluid typography (`GoogleFonts`).
  - **Glassmorphic Elements**: Translucent cards, dynamic backdrops, and navigation overlays utilizing subtle border strokes and white alpha overlays (e.g., `Colors.white.withValues(alpha: 0.15)`).
  - **Color Palette**: Rebranded with **Premium Deep Blue** (`#0D47A1`) as the primary primary branding, supported by subtle background hues (`AppColors`).
- **Modernized API Compliance**:
  - Modernized for Dart SDK 3.5.4+ and Flutter 3.24+:
    - Opacity modifications use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
    - `Switch` components use `activeThumbColor` instead of deprecated `activeColor`.

---

## 4. Security Audit & Database RLS

- **Authentication & Password Security**:
  - Authentication is delegated to **Supabase Auth**, replacing custom session endpoints with JWTs. Passwords are securely hashed with Argon2/Bcrypt on the server.
- **Row Level Security (RLS)**:
  - PostgreSQL Row Level Security is active across all tables (`profiles`, `documents`, `comments`, `interactions`, `bookmarks`, `notifications`, `followers`).
  - **Profiles Policy**: Users can only update their own profile (`auth.uid() = id`). Privilege escalation is prevented by restricting updates to `is_admin` via policy validation (`WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))`).
  - **Documents Policy**: Public read, owner-only mutation (`auth.uid() = user_id`). Setting `is_official = true` is enforced via database trigger `ensure_official_permission` requiring `is_admin = true`.
- **Function Security**:
  - Stored procedures and RPC functions use `SECURITY DEFINER` with explicit `SET search_path = public` directives to prevent search-path hijacking.

---

## 5. Directory & Component Mapping

| Directory / File | Description & Purpose |
| :--- | :--- |
| `lib/main.dart` | Application entry point; initializes Supabase client & global dependencies. |
| `lib/layout.dart` | Core structural layout with custom persistent bottom navbar. |
| `lib/controller/` | GetX controllers managing authentication, document state, feed batching, and profile caching. |
| `lib/core/` | Global configurations (`AppMetaData`, `AppColors`, `AppTypography`), helpers (`HiveBoxes`, `ImageHelper`). |
| `lib/model/` | Data models (`UserModel`, `DocumentModel`, `MiniUserModel`, `PostModel`). |
| `lib/service/` | Infrastructure services for file downloading (`FileDownloadService`), local caching (`FileCachingService`), and local notifications. |
| `lib/view/` | UI screens and widgets (Home, Profile, Upload, Document Details, Auth, Connection, Search). |
| `SUPABASE_SCHEMA.sql` | SQL schema migration script containing table definitions, RLS policies, RPC functions, and triggers. |

---

## 6. QA, Linting & Maintenance

To maintain code quality and 'Zero Warnings' compliance:
1. **Linting Check**:
   ```bash
   cd notehub
   flutter analyze
   ```
2. **Test Suite**:
   ```bash
   cd notehub
   flutter test
   ```
3. **Flow Control & Conventions**:
   - Ensure all conditional statements are enclosed in explicit blocks `{ ... }`.
   - Ensure `// ignore: empty_catches` annotations are placed on their own line inside catch blocks.
