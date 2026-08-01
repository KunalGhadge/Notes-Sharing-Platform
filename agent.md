# Developer Technical Manual - Serious Study (formerly NoteHub)

This document provides an exhaustive, developer-centric architectural, performance, design, and security audit of the **Serious Study** Android application (the Mumbai University student community platform). It serves as the primary technical system reference, maintenance guide, and QA checklist.

---

## 1. System & Technology Stack Architecture

Serious Study utilizes a decoupled, modern architecture optimized for high performance, ease of maintenance, and reliable serverless cloud operations.

```
       +--------------------------------------------------------+
       |                  Flutter Mobile Client                 |
       |  (Material 3 / Glassmorphism / Premium Deep Blue UI)  |
       +----------------------------+---------------------------+
                                    |
                                    | [HTTP Requests / WebSocket]
                                    v
       +----------------------------+---------------------------+
       |               Supabase Serverless Cloud                 |
       |                                                        |
       |  +------------------+ +-----------------------------+  |
       |  |  Supabase Auth   | |      Supabase Storage       |  |
       |  |   (JWT / HMAC)   | |  (Document PDFs / Images)  |  |
       |  +------------------+ +-----------------------------+  |
       |  |                       PostgreSQL                |  |
       |  |  (RLS Policies, Triggers, RPC Atomic Counters)   |  |
       |  +-------------------------------------------------+  |
       +--------------------------------------------------------+
```

### 1.1 Core Technologies
- **Flutter SDK**: ^3.24.0 (Channel Stable)
- **Dart SDK**: ^3.5.4 (Strictly Modern Dart APIs)
- **State Management**: **GetX** — Handles high-frequency, highly reactive page streams, declarative layout routing, and lifecycle events.
- **Local Storage / Caching**: **Hive NoSQL** — A high-performance local key-value box database.
- **Backend Database**: **Supabase (PostgreSQL)** — Manages real-time sync, schema relational structures, secure file-handling buckets, and administrative RPC functions.
- **Network Client**: **Supabase Dart SDK** & **Dio Client** — High-performance networking with advanced interceptor and chunk-upload capabilities.

---

## 2. Performance Engineering & Optimization Design

High responsiveness, low data payloads, and buttery-smooth user interaction animations are vital for a campus mobile community. The following systems guarantee high efficiency under peak usage:

### 2.1 Reactive State Management & View Decoupling
The application avoids UI rebuild bottlenecks by adopting **GetX Reactive Controller Bindings**:
- Views listen to reactive state streams (`.obs`) and are automatically rebuilt only when concrete, localized values change.
- Business logical controllers (e.g. `DocumentController`, `ProfileController`, `CommentController`) execute asynchronously, isolated from the rendering tree thread.

### 2.2 Local Caching Architecture (Hive)
To prevent redundant database polling, high-speed local binary caching is implemented:
- **`userBox`** (`HiveBoxes.userBox`): Stores authenticated user profiles and permissions. Loads instantly during application startup, preventing visual flicker or loading overlays.
- **`downloadsBox`** (`HiveBoxes.downloadsBox`): Manages local file paths and cache indexes of downloaded PDFs/documents, reducing cellular data payloads for repetitive views.

### 2.3 Real-Time Network Sync & Postgres Subscriptions
- **Postgres Realtime Changes**: Real-time elements such as document notifications, feedback changes (likes/dislikes), and comment threads are kept up-to-date using persistent WebSocket channels:
  ```dart
  supabase.channel('public:documents').onPostgresChanges(...)
  ```
- **Sticky Sorted Batches**: Main feeds are fetched in dynamic size-limited partitions (`LIMIT 50`) and sorted with a sticky hierarchy (Official Announcements, then chronological posts) to reduce network and render burdens.

### 2.4 Media and Payload Optimization
- **On-the-fly Image Compression**: Cover arts and profile avatars are optimized using `flutter_image_compress` in `ImageHelper.compressImage()` (compressing to JPEG at 70% quality, max resolution 1024x1024) prior to upload.
- **Size Bounds Guarding**: Direct uploads are validated against a strict `10MB` limit. If files exceed this threshold, the system guides users to post a cloud-hosted external URI (such as Google Drive/Mega) instead.
- **Cached Asset Pipelines**: Avatars and document thumbnails rely entirely on `CachedNetworkImage` with custom disk/memory cache boundaries.

---

## 3. UI/UX Design Aesthetics & Visual Paradigms

The visual scheme is meticulously built around the premium academic branding of Serious Study:

- **Branding Color Palette**: Transited from generic hues to the prestigious **Premium Deep Blue** theme (`#0D47A1`), aligning visually with the corporate and scholastic identity of Mumbai University.
- **Visual Design - Glassmorphism**: Utilized on elevated containers, bottom navigation bars, and top-header menus to establish clear layered hierarchy. Implemented using backdrop filters:
  ```dart
  BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(color: Colors.white.withValues(alpha: 0.15)),
  )
  ```
- **Asynchronous UX Comfort - Shimmers**: Shimmering grey layouts appear during active asynchronous HTTP/RPC tasks to mimic layout geometry, eliminating disruptive visual transitions.
- **Rich Vector & Physics Lottie Animations**: Interactive elements leverage scalable vectors (`flutter_svg`) and highly detailed Lottie file streams for dynamic state reactions (e.g. Empty searches, document creation, error feedbacks).

---

## 4. Comprehensive Security & Authorization Architecture

Migrating to the Serverless Supabase structure eliminated a wide variety of security flaws present in the legacy Django stack. Security is now audited, strict, and hardened.

### 4.1 Strict Row-Level Security (RLS) policies
Every PostgreSQL database table operates with Row-Level Security enabled. Direct, malicious database querying is completely mitigated:

- **`profiles` table**:
  - `SELECT`: Publicly accessible (`FOR SELECT USING (true)`).
  - `INSERT`: Enforced owner identity check: `auth.uid() = id`.
  - `UPDATE` (Privilege Escalation Protected): System prevents malicious role modifications using an explicit `WITH CHECK` constraint:
    ```sql
    CREATE POLICY "Users can update own profile" ON public.profiles
      FOR UPDATE USING (auth.uid() = id)
      WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
    ```
- **`documents` table**:
  - `INSERT` / `UPDATE` / `DELETE`: Verified against owning author context (`auth.uid() = user_id`).
- **`interactions` / `bookmarks`**:
  - Private writes only; verified owner matching before operations succeed.

### 4.2 Security Definer & RPC Protections
- **Counter Invariance**: Users are restricted from updating table-level counters like `likes_count` or `dislikes_count` directly. Instead, they trigger secure PostgreSQL RPC functions defined with `SECURITY DEFINER`. This runs under administrative database privileges to securely update specific rows safely.
- **Search Path Protection**: To prevent search-path hijacking attacks, critical PostgreSQL functions and triggers explicitly declare their search paths:
  ```sql
  CREATE OR REPLACE FUNCTION check_official_permission()
  RETURNS TRIGGER AS $$ ... $$
  LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
  ```

### 4.3 Content Verification & Privilege Guarding
- **Official Status Guard**: Setting `is_official = true` in the `documents` table is blocked for standard profiles. The backend runs a database-level trigger (`ensure_official_permission`) that checks if the executing profile possesses `is_admin = true`. Unauthorized actions fail instantly.

---

## 5. Maintenance, Linting & QA Guidelines

To maintain "Zero Warnings" on CI/CD systems, development procedures must strictly respect the following code-quality requirements:

1. **Modern Color Formatting**: Avoid using deprecated `.withOpacity(alpha)` on Color targets. Always use modern Dart API `.withValues(alpha: ...)` to prevent floating-point precision loss.
2. **Switch Widget Configuration**: To resolve standard compiler deprecation warnings, do not configure `activeColor` directly inside Switch controls. Program the state with `activeThumbColor` instead.
3. **Robust Try-Catch & Silent Ignores**: When using empty catch structures, never place comments on the same line as closing brackets. Place the lint-suppressor on its own line:
   ```dart
   try {
     // logical code
   } catch (e) {
     // ignore: empty_catches
   }
   ```
4. **Flow Control Braces**: Always enclose flow control blocks (including simple one-liner `if` statements) inside explicit curly braces (`{ }`) to pass static analysis:
   ```dart
   if (doc.isLiked) {
     await toggleLike(doc);
   }
   ```
5. **Static Checks & Testing Commands**: Run the following commands from the `notehub/` subdirectory before committing changes:
   ```bash
   flutter analyze
   flutter test
   ```

---
*Maintained and Verified by Jules, AI Software Engineer.*
