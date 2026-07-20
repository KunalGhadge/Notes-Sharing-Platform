# Developer Guide & System Maintenance Manual - Serious Study (formerly NoteHub)

This manual provides a highly technical, developer-centric analysis and documentation of the **Serious Study** platform. It describes the design patterns, architectural choices, optimizations, database schemas, and security mechanics of the application from first principles.

---

## Technical Architectural Overview

Serious Study is an academic content-sharing and social networking platform built with a **Flutter** client and a **Supabase (PostgreSQL)** serverless backend.

```
       +-------------------------------------------------------+
       |                     FLUTTER UI                        |
       |  (Material 3 / Glassmorphic Custom Widgets & Screens) |
       +----------------------------+--------------------------+
                                    |
                            [Reactive State] (Obx/GetX)
                                    v
       +-------------------------------------------------------+
       |                  GETX CONTROLLERS                     |
       | (AuthController, HomeController, DocController, etc.) |
       +----+----------------------------------------------+---+
            |                                              |
      [Local Storage]                               [API Network Calls]
            v                                              v
  +------------------+                            +------------------+
  |    HIVE NOSQL    |                            |     SUPABASE     |
  |  (userBox/       |                            |    FLUTTER SDK   |
  |   downloadsBox)  |                            +--------+---------+
  +------------------+                                     |
                                                     [Real-time / JWT]
                                                           v
                                                  +--------+---------+
                                                  | SUPABASE BACKEND |
                                                  | (Auth, Storage,  |
                                                  |  PostgreSQL RLS, |
                                                  |  Triggers, RPCs) |
                                                  +------------------+
```

---

## 1. Performance Engineering & Optimization

### 1.1 Reactive State Management via GetX
The application leverages **GetX** for dependency injection and lifecycle-driven state management:
* **Decoupled View/Business Logic**: Controllers manage reactive state independently of the visual presentation. Real-time updates utilize `Rx` types (e.g., `RxList`, `RxBool`) to execute surgical updates on the widget tree via `Obx` or `GetX` builder widgets.
* **Controller Lifetime Management**: Services and controllers are registered globally or dynamically inside specific routes using `Get.put()` or custom tags (e.g., in `ProfileUser` via `tag: widget.username`). This optimizes RAM usage by allowing ephemeral controllers to be disposed of when view routes pop off the navigator stack.

### 1.2 NoSQL Local Persistent Storage with Hive
For immediate responsiveness, Serious Study integrates the high-performance NoSQL database **Hive**:
* **`userBox`**: Persists the serialized `UserModel` data. This allows the application to resolve the session locally and construct the active user's dashboard layout instantly upon app initialization without waiting for remote API queries.
* **`downloadsBox`**: Tracks locally-cached notes metadata. Whenever a PDF document is retrieved via the `FileDownload` engine, its metadata is mapped as a key-value entry under `downloadsBox` using Hive.
* **Performance Impact**: Hive writes are executed with sub-millisecond latencies as it acts as a structured key-value binary store directly mapped to disk.

### 1.3 Media Asset Compression & Caching
* **Client-side Compression**: Direct image and file uploads are processed before being sent over the network. Under `lib/core/helper/image_helper.dart`, JPEG/PNG images selected for cover assets are compressed down to 70% quality and optimized constraints via `flutter_image_compress` before transmission to Supabase buckets.
* **Bandwidth Optimization**: Files exceeding **10MB** are rejected locally via validation inside the `UploadController` to prevent upstream bottlenecking.
* **Caching on Demand**: For document thumbnail renders and avatars, `CachedNetworkImage` intercepts remote URLs and caches the fetched assets inside the local cache directory using path-provider, reducing duplicate network fetch requests.

### 1.4 Database Scale Strategy
* **Batching Limits**: The main feed fetch operation inside `HomeController` uses strict paging boundaries, query-limiting document collections to the top 50 items (`.limit(50)`).
* **Server-side Aggregations & Counters**: Frequent atomic increments/decrements (such as adding/removing document likes or bookmarks) are shifted out of client memory and executed directly on PostgreSQL via Remote Procedure Calls (RPC). This guarantees atomic execution and prevents write conflicts across multiple concurrent sessions.

---

## 2. Platform Design & Architecture

### 2.1 File System & Folder Layout
The codebase is structured cleanly to segregate concerns into standard logical tiers:
* **`lib/controller/`**: State processors and business layers (e.g. `HomeController`, `DocumentController`, `UploadController`).
* **`lib/core/`**: Central application declarations and configurations.
  * **`config/`**: Styling, palettes (`color.dart`), and standard text style definitions (`typography.dart`).
  * **`helper/`**: Low-level database bridges and compression engines (`hive_boxes.dart`, `image_helper.dart`).
  * **`meta/`**: Global environment declarations (`app_meta.dart`).
* **`lib/model/`**: JSON schema structures and type definitions (e.g. `DocumentModel`, `UserModel`).
* **`lib/view/`**: Declarative UI layer, modular screens, and specialized components.

### 2.2 Branding & Aesthetic Identity
The serious academic spirit is reflected in every visual component:
* **Premium Deep Blue Theme**: Uses `#0D47A1` (`PrimaryColor.shade500`) as the defining primary tone to evoke trust, focus, and scholarship.
* **Glassmorphic Composites**: Implemented in components like the `BottomFooter` and overlapping header panels using `GlassmorphicContainer` to create premium, layered visual depth.
* **User Feedback Utilities**: Interactive transitions use high-framerate vector elements (`Lottie`) to visually reinforce actions like empty state search queries and file upload cycles. Loading states use skeleton `Shimmer` widgets to minimize perceived latency during asynchronous resource hydration.

---

## 3. High-Security Environment Review

### 3.1 Session Identity & Token Protection
* **Supabase JWT Integration**: The app discards legacy plain-text password systems and utilizes **Supabase Auth**. Authenticated users are issued a cryptographically signed JSON Web Token (JWT) managed securely within the Supabase client SDK.
* **Cryptographic Password Standards**: Passwords are never sent or exposed in plain-text format across public networks. Supabase Auth processes and stores credentials using advanced hashing mechanisms such as Bcrypt or Argon2.

### 3.2 Row Level Security (RLS) Mechanics
Row Level Security is enabled on every transaction-critical PostgreSQL relation to isolate and protect user namespaces:

```sql
-- Profiles table security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);
```

* **Data Tampering Prevention**: To enforce strict access privileges, tables like `documents` restrict write access (`INSERT`, `UPDATE`, `DELETE`) to the resource's owner matching `auth.uid() = user_id`.
* **Private Namespaces**: Table objects under `notifications` and `bookmarks` are explicitly hidden behind policies that restrict reading exclusively to the active authenticated subscriber (`auth.uid() = receiver_id`).

### 3.3 Protection Against Privilege Escalation
A critical vulnerability vector—where a malicious user could attempt an SQL injection or direct metadata update to set their own `is_admin` or `is_official` flags—is proactively mitigated:
* **Admin Verification**: The `documents` table update policies validate admin roles on-demand by executing deep checks:
  ```sql
  CREATE POLICY "Admins can update documents" ON public.documents
    USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
  ```
* **Privilege Validation Triggers**: The database enforces security policies that prevent standard users from marking their shared notes as "Official". The table structures require an elevated profile match, preventing standard clients from sending payload data with `is_official = true` through standard API overrides.

### 3.4 RPC Isolation Patterns
All counter transformations on relational schema objects (such as liking, disliking, or bookmarking) are executed behind secure Postgres RPC functions declared with `SECURITY DEFINER`.
* This setup isolates database tables from direct client modifications. Standard clients cannot directly alter integer counts like `likes_count` or `dislikes_count` in the database, restricting modification privileges exclusively to certified backend procedures.

---

## 4. Development Operations & Technical Verification

### 4.1 Required Prerequisites
* **Environment Target**: Flutter SDK version `v3.24+` and Dart SDK version `^3.5.4` (channel stable).
* **Modern Color API Compliance**: Standard code configurations must enforce the `.withValues(alpha: ...)` API instead of the deprecated `.withOpacity(...)` to prevent precision loss and maintain zero-compiler-warning standards.
* **Switch Thumb Theme Compliance**: Switch input controls must override the active path color using the `activeThumbColor` attribute to address deprecation warnings associated with `activeColor`.

### 4.2 Maintenance Commands
Developers should execute the following operations inside the workspace before committing code:

```bash
# 1. Check for syntax, linting, and static analysis warnings
cd notehub && flutter analyze

# 2. Execute unit and integration tests to verify platform correctness
cd notehub && flutter test
```

---
*Maintained and Verified by Serious Study Engineering.*
