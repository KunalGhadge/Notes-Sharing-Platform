# Serious Study (formerly NoteHub) - Developer Guide & Technical Reference Manual

Welcome to the **Serious Study** Technical Reference Manual. This document provides a highly detailed developer-perspective analysis of the Serious Study Android application codebase. This manual covers performance metrics and optimizations, structural design patterns, and rigorous security architecture safeguards, reflecting the application's migration from legacy systems to a serverless, real-time-enabled Supabase backend.

---

## Technical Stack & Decoupled MVC Architecture

Serious Study utilizes a modernized serverless stack optimized for speed, scalability, and code maintainability:

- **Frontend (Flutter SDK 3.24+ / Dart SDK 3.5.4+)**: Cross-platform execution layer compiling down to native machine code on Android.
- **State Management (GetX 4.6.6)**: Decoupled business logic from visual layout. Controllers act as reactive state hubs, avoiding boilerplate while managing streams, events, and navigation.
- **Local Persistence (Hive NoSQL)**: Fast local key-value storage engine (`userBox`, `downloadsBox`) for instant offline state retrieval.
- **Serverless Backend (Supabase + PostgreSQL)**: Provides real-time Postgres changes, Row Level Security (RLS), JWT Authentication, database triggers, and RPC functions.

```
       [ USER / VIEW LAYER (Flutter UI) ]
                     │
         Reactive UI binding via Obx()
                     ▼
      [ CONTROLLER LAYER (GetX Controllers) ]
         - Manage Reactive Rx Variables
         - Local Offline Sync (Hive)
                     │
        REST API / RPC / Realtime Streams
                     ▼
      [ BACKEND LAYER (Supabase & PostgreSQL) ]
         - JWT Auth & Table level RLS Validation
         - Atomic RPCs & Search-Path Safeguarded Functions
```

---

## 1. Deep Dive Performance & Resource Optimization

Mobile performance in Serious Study is structured around low latency, efficient memory allocation, offline capabilities, and cellular-friendly payload optimization.

### 1.1 Local Persistent Caching (Hive Engine)
To minimize redundant network roundtrips, user and cache configurations are offloaded to **Hive**. Hive stores records in local binary format, outperforming traditional SQL solutions (like SQLite) and blocking `SharedPreferences` in seek speed.
- **User Cache (`userBox`)**: Stores user metadata locally. Upon application initialization, `AuthController` queries Hive directly to retrieve profile states, facilitating instant landing states rather than loading screens.
- **Download Cache (`downloadsBox`)**: Tracks file names, paths, and statuses of downloaded documents.
- **Memory Efficiency**: Avoids large memory heaps by loading only essential keys into memory and lazy-loading binary attachments.

### 1.2 Specialized Download Management & Cache Validation
The `file_caching.dart` service handles specialized file caching via the **Dio** networking client:
- **Pre-download Check**: When a user attempts to open a document, the caching manager queries `downloadsBox` and verifies file existence inside the device's temporary directory before invoking the native file reader.
- **Bandwidth Reduction**: Avoids redundant network data consumption by utilizing path checks and saving files permanently under specific target keys.

### 1.3 Media Asset Compression & Optimization
Large media assets can degrade network bandwidth and cloud storage capacity. Serious Study incorporates automatic pipeline-level compression:
- **Compress-on-Upload (`image_helper.dart`)**: Image uploads (e.g., PDF cover icons, avatars) undergo lossy compression using `flutter_image_compress` targeting JPEG formats with 70% quality and a maximum 1024x1024 resolution.
- **Cached Network Images**: For UI thumbnails (such as document cards), the app uses `CachedNetworkImage` which caches remote files locally to ensure seamless grid scrolling.

### 1.4 Atomic PostgreSQL Functions (RPC Counters)
When scaling to thousands of concurrent users, traditional "fetch-increment-update" workflows lead to lost updates and database race conditions. Serious Study shifts counter responsibility directly to PostgreSQL:
- **Client Execution**: When a user taps 'Like', the client calls:
  ```dart
  await supabase.rpc('increment_likes', params: {'doc_id': docId});
  ```
- **Database Processing**: The backend executes the atomic calculation:
  ```sql
  UPDATE public.documents SET likes_count = likes_count + 1 WHERE id = doc_id;
  ```
- This ensures absolute data integrity across multiple devices and minimizes network packet payload sizes.

---

## 2. Structural Design, Patterns & UX Architecture

Serious Study utilizes a hybrid MVC design pattern facilitated by the **GetX Framework**, completely isolating business logic from representation.

### 2.1 The GetX Controller Framework
Instead of embedding state in stateful widgets (which triggers unnecessary widget tree rebuilds), GetX controllers isolate operations into clean hooks.
- **Optimistic UI Updates**: Reactive states (such as `RxList` of documents) update locally and instantly trigger UI rebuilds via `Obx` wrappers before server requests resolve. If the network request fails, the controller catches the exception and reverts state, maximizing perceived performance.
- **Cross-Controller Synchronization**: The `_syncWithHome` method in `DocumentController` automatically triggers real-time updates inside `HomeController` to reflect state modifications (likes, bookmarks) seamlessly:
  ```dart
  void _syncWithHome() {
    try {
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().update();
      }
    } catch (e) {
      debugPrint("Sync failed: $e");
    }
  }
  ```

### 2.2 Rebranded UI Aesthetics
The application implements **Material 3 Design Guidelines** overlayed with a premium **Glassmorphism** visual hierarchy:
- **Brand Palette**: Styled in a Premium Deep Blue theme (`#0D47A1`), representing the academic focus of the Mumbai University audience.
- **Visual Depth**: Uses glass-like panels blending high-alpha white highlights (`Color.withValues(alpha: 0.15)`) over rich gradients to render cards and navigation anchors.
- **Visual Feedback**:
    - **Shimmer Placeholders**: Simulates list card grids during data retrieval to reduce cognitive load.
    - **Lottie Animations**: Provides micro-interactions for empty search queries, errors, and success states.

---

## 3. Security Architecture & Threat Vector Mitigations

Moving from legacy, session-less servers to Supabase requires a zero-trust architecture model. This section details how Serious Study mitigates risks.

### 3.1 Authentication & Token-Based Authorization (JWT)
- **Auth Protocol**: Secure JSON Web Tokens (JWT) manage session variables. No custom password hashes are handled in-app; user authentication is delegated entirely to Supabase Auth utilizing BCrypt/Argon2 hashing standards.
- **Session Lifecycles**: Tokens are automatically refreshed by the Supabase Client SDK, securely storing state on-device.

### 3.2 Granular Row Level Security (RLS)
Every PostgreSQL table implements explicit Row Level Security rules to prevent unauthorized reads and writes:

| Database Table | Select Policy (Read) | Insert Policy (Write) | Update / Delete Policy |
| :--- | :--- | :--- | :--- |
| **`profiles`** | Publicly readable (`USING (true)`) | Authenticated Owner (`WITH CHECK (auth.uid() = id)`) | Owner only (`USING (auth.uid() = id)`) with **Admin Safeguard** |
| **`documents`** | Publicly readable | Authenticated Creator (`WITH CHECK (auth.uid() = user_id)`) | Creator only (`USING (auth.uid() = user_id)`) / Admins |
| **`comments`** | Publicly readable | Authenticated Creator (`WITH CHECK (auth.uid() = user_id)`) | Creator only |
| **`interactions`**| Publicly readable | Owner only | Owner only |
| **`bookmarks`** | Owner only (`auth.uid() = user_id`) | Owner only | Owner only |
| **`notifications`**| Private to Receiver (`auth.uid() = receiver_id`) | Any Authenticated user | Receiver only (status flags) |

### 3.3 Mitigation of Privilege Escalation & Search-Path Hijacking
A major security concern in serverless environments is user-end role modification (e.g., escalating a profile's `is_admin` state to bypass validations). Serious Study utilizes key defenses:

1. **Immutable Checks via `WITH CHECK`**:
   The update policy for `profiles` prevents users from updating their own `is_admin` column to `true`.
   ```sql
   CREATE POLICY "Users can update own profile" ON public.profiles
     FOR UPDATE
     USING (auth.uid() = id)
     WITH CHECK (
       is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
     );
   ```
   This prevents a user from appending `is_admin: true` during update requests.

2. **Official Verification Constraint**:
   Setting `is_official = true` on a document is restricted via an database-level trigger, which queries the posting user's profile and validates their `is_admin` flag.
   ```sql
   CREATE OR REPLACE FUNCTION check_official_permission()
   RETURNS TRIGGER AS $$
   BEGIN
     IF NEW.is_official = true AND (SELECT is_admin FROM public.profiles WHERE id = auth.uid()) = false THEN
       RAISE EXCEPTION 'Access Denied: Only Admins can publish official content.';
     END IF;
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
   ```
   - **SECURITY DEFINER** ensures the function runs with creator privileges to check tables bypassable by client RLS.
   - **`SET search_path = public`** blocks search-path hijacking attacks, preventing malicious users from creating decoy functions inside temporary schemas.

---

## 4. Database Schema Structure (PostgreSQL)

```sql
-- Profiles: Core User Accounts
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

-- Documents: Core Academic Resource Uploads
CREATE TABLE public.documents (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  topic TEXT,
  description TEXT,
  document_url TEXT, -- Nullable to support tweet-style posts
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

## 5. Maintenance Guide & Developer QA Protocol

To maintain code standards, developers must strictly adhere to the following QA procedures:

### 5.1 Project Prerequisites
- **Flutter SDK**: `v3.24+` (Channel Stable)
- **Dart SDK**: `^3.5.4` (mandatory for modern API support, e.g., `.withValues()` and `activeThumbColor` properties in Switches).

### 5.2 Zero-Warnings Policy Compliance
To prevent visual regressions and compile issues, avoid deprecated elements:
- Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
- Use `activeThumbColor: ...` in `Switch` components instead of deprecated `activeColor`.
- For silent catch blocks, ensure `// ignore: empty_catches` is on its own line inside the block to avoid commenting out closing structures:
  ```dart
  try {
     ...
  } catch (e) {
     // ignore: empty_catches
  }
  ```

### 5.3 Automated CLI Analysis & Verification
Always execute these scripts locally inside the `notehub/` subdirectory before submitting any code:
```bash
# 1. Fetch updated packages
flutter pub get

# 2. Run static linter (Must resolve with 0 errors/0 warnings)
flutter analyze

# 3. Run localized unit/widget test suites
flutter test
```

---
*Maintained and documented by AI Software Engineer, Jules.*
