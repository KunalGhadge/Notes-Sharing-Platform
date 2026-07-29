# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis and developer maintenance guide for the Serious Study repository (Mumbai University Community App) from a senior engineer's perspective. It highlights architecture, reactive performance, UI/UX aesthetics, and security implementations after the serverless **Supabase** migration.

---

## 1. Project Overview & Architecture
Serious Study is a high-performance academic notes-sharing and social networking platform built specifically for the Mumbai University student community. The application uses a decoupled, MVC-like structure combining:
- **Frontend**: Flutter SDK ^3.24+ (running Dart SDK ^3.5.4)
- **State Management**: **GetX** (reactive MVC pattern)
- **Local Storage**: **Hive** (lightweight NoSQL local caching)
- **Backend & Realtime**: **Supabase** (PostgreSQL database, Storage, and Realtime Engine)

---

## 2. Performance Analysis

### 2.1 Reactive State Management (GetX)
The codebase leverages GetX to separate UI layers from controllers, preventing unnecessary widget rebuilds.
- **Optimistic UI Updates**: Actions such as adding a comment, upvoting, downvoting, or bookmarking notes use optimistic state updates. This guarantees the user sees immediate feedback while backend requests are completed asynchronously.
- **Home Feed Management (`HomeController`)**:
  - Automatically fetches updates up to a **limit of 50 documents** to keep initial payload small.
  - Implements **Sticky Sort**: Official posts (`is_official = true`) are prioritized at the top of the feed, followed by the latest chronological documents.
  - Limits official feed fetches (`fetchOfficialUpdates`) to the **20 most recent documents** for visual performance.

### 2.2 Realtime Data Sync
Realtime subscriptions keep feeds fully synchronized across instances:
- The `HomeController` initiates a postgres changes channel subscription:
  ```dart
  _stream = supabase
      .channel('public:documents')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'documents',
        callback: (payload) {
          fetchUpdates();
        },
      )
      .subscribe();
  ```
- Any additions or modifications automatically trigger incremental state synchronization.

### 2.3 High-Performance Local Caching (Hive)
To minimize initial launch latency and preserve mobile bandwidth, two primary local Hive storage boxes are maintained (`lib/core/helper/hive_boxes.dart`):
- `userBox`: Stores the logged-in user's profile metadata (`UserModel`), enabling instant profile retrieval at startup.
- `downloadsBox`: Caches offline downloaded file statuses and paths to bypass expensive redundant server requests.

### 2.4 specialized File Caching & Media Compression
- **File Downloader Caching (`lib/service/file_caching.dart`)**: Checks for existing local files in the temporary directory prior to starting a new download request, preserving device storage and network bandwidth:
  ```dart
  var temporaryDirectory = await getTemporaryDirectory();
  // ...
  if (await ifFileExists(savePath)) {
    return savePath;
  }
  await dio.download(uri, savePath);
  ```
- **Media Optimization**:
  - Image compression is enforced in the upload pipeline using `flutter_image_compress` via `ImageHelper.compressImage` (JPEG, 70% quality, max 1024x1024 resolution) to minimize storage footprints.
  - Image lists and covers utilize the `cached_network_image` library to cache images on disk.

### 2.5 Database Level Performance
- Atomic user interaction counters (likes, dislikes, bookmarks, followers) are handled directly in PostgreSQL via specialized Remote Procedure Calls (RPC functions like `increment_likes`, `decrement_likes`). This offloads computation from client devices and eliminates race conditions.

---

## 3. Design & Architecture

### 3.1 MVC Project Layout
The code is structured as follows:
- `lib/controller/`: Pure GetX Controllers handling core API interaction, business logic, and reactive variables.
- `lib/model/`: Strongly-typed Dart data models (e.g., `DocumentModel`, `UserModel` with its Hive adapter).
- `lib/view/`: Pure UI components structured by features (auth, splash, onboarding, home, profile, upload).
- `lib/core/`: Application constants, configuration (premium deep blue colors, typography), meta specifications, and custom icons.

### 3.2 Premium MU Academic Aesthetics
- **Material 3 UI**: Clean cards, rounded shapes, explicit typography, and dynamic transitions.
- **Rebranding Scheme**: Transitioned to "Premium Deep Blue" (`#0D47A1` primary seed) combined with complementary amber highlights (`#B8860B`) representing academic excellence.
- **Glassmorphism Overlay Layouts**: Glassmorphic styling is embedded in overlays, bottom menus, and badge titles using semi-transparent background values (`.withValues(alpha: ...)` for Dart SDK ^3.5.4 compatibility).
- **Lottie and SVG Feedback**: Seamless vector rendering (`flutter_svg`) and custom state animations (`lottie`) are used for idle, success, and empty pages.

---

## 4. Security Analysis & Mitigation

The serverless migration to Supabase has eliminated major legacy application vulnerabilities by introducing modern, serverless security practices:

### 4.1 Authentication & Password Security
- **Authentication**: Managed securely by Supabase GoTrue Auth using short-lived **JWT (JSON Web Tokens)**.
- **Password Security**: Passwords are never seen or stored in plain-text on application databases; they are securely hashed and stored in internal Supabase `auth.users` tables using Bcrypt/Argon2.

### 4.2 Fine-Grained Row Level Security (RLS)
Every table has strict PostgreSQL RLS policies to prevent malicious manipulation:
- **Profiles (`profiles`)**: Publicly read-accessible, but updates are locked down:
  - Users can only `UPDATE` their own records:
    ```sql
    CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
    ```
- **Documents (`documents`)**: Global select privileges (`USING (true)`) are allowed for read operations, but `INSERT` and `DELETE` actions are strictly constrained to owners (`auth.uid() = user_id`).
- **Notifications / Bookmarks / Interactions**: Protected behind policies limiting visual select and modifications only to the corresponding owner's `auth.uid()`.

### 4.3 Privilege Escalation & Content Integrity
To avoid unauthorized admin escalations or unofficial content verification:
- **Profile Escalation Defense**: RLS on the `profiles` table blocks unauthorized updates of administrative fields. An explicit `WITH CHECK` constraint ensures users cannot elevate their own role status:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
  ```
- **Official Status Guard**: Setting `is_official = true` on a document is restricted via PostgreSQL trigger functions (`ensure_official_permission`) ensuring only users marked as `is_admin = true` inside the database can issue official community labels.

### 4.4 PostgreSQL RPC Function Security
All custom PostgreSQL database functions are created with:
- **`SECURITY DEFINER`**: Allows functions to execute with the privileges of the creator (bypass RLS rules where necessary to manage counter increments safely).
- **Explicit `SET search_path = public`**: Prevents search-path hijacking attacks, securing the backend schema.

---

## 5. Maintenance & QA (Zero-Warnings Policy)

To ensure the repository maintains pristine code standards:
- **SDK Prerequisite**: Ensure Dart SDK `^3.5.4` is configured.
- **Code Modernization Compliance**:
  - Avoid deprecated `.withOpacity(double)`; always use `.withValues(alpha: double)` for color opacity adjustments.
  - Avoid deprecated `activeColor` in standard `Switch` widgets; use `activeThumbColor` instead.
  - Implement explicit curly braces in all flow control structures (`if`, `else`, `for`, `while`).
  - Use `// ignore: empty_catches` for silent catches on their own inner line within the catch block, ensuring the annotation does not comment out surrounding closing brackets.
- **Validation Commands**:
  - Run `flutter analyze` from the `notehub/` folder to check and maintain the project's **Zero Warnings** status.
  - Run `flutter test` to verify build integrity and regression safety.

---
*Maintained and curated by Jules, AI Software Engineer.*
