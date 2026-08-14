# Serious Study (formerly NoteHub) - Developer & Maintenance Manual

This manual provides a developer-centric architectural, performance, UX design, and security audit of the **Serious Study** Android/Flutter application. Designed for engineers maintaining and extending the platform, it explains the key technical designs, code-level mechanics, database schemas, and modern QA cleanups.

---

## 1. Architectural Overview

Serious Study is structured around a decoupled, reactive model utilizing the **GetX MVC-like pattern** for state management, combined with **Hive NoSQL local storage** for session/cache operations and **Supabase (PostgreSQL)** for secure, serverless backend functionalities.

```
       +--------------------------------------------+
       |                  VIEW (UI)                 |
       |  (LiquidPullToRefresh, Glassmorphism, M3)  |
       +---------------------+----------------------+
                             |
                   Listens & Triggers
                             |
                             v
       +---------------------+----------------------+
       |               CONTROLLERS (GetX)           |
       |     (Document, Home, Auth Controllers)     |
       +---------------------+----------------------+
                             |
                   Reads / Writes API
                             |
                             v
       +---------------------+----------------------+
       |                SERVICES / HELPERS          |
       |   (HiveBoxes, FileCaching, ImageHelper)    |
       +----------+----------------------+----------+
                  |                      |
            Local Storage           Remote Server
                  |                      |
                  v                      v
           +------+-----+          +-----+------+
           |    Hive    |          |  Supabase  |
           | (NoSQL DB) |          | (Postgres) |
           +------------+          +------------+
```

### 1.1 Directory Structure & File Map
- **`lib/main.dart`**: Entrypoint initializing the Supabase client and setting up primary GetX dependencies.
- **`lib/controller/`**: State containers implementing reactive streams:
  - `auth_controller.dart`: Handles Supabase Auth registration, logins, session syncing, and local `HiveBoxes` profiles.
  - `home_controller.dart`: Manages the real-time activity feed with batching and sticky sorting.
  - `document_controller.dart`: Implements resource lifecycle operations (like, dislike, bookmark, and delete).
  - `upload_controller.dart`: Enforces document validation, image compression, and coordinates uploads.
- **`lib/core/`**: Configuration files:
  - `config/color.dart` & `typography.dart`: Contains color palettes and typography rules.
  - `helper/hive_boxes.dart`: Abstracts Hive interactions.
  - `helper/image_helper.dart`: Compresses high-resolution images.
  - `meta/app_meta.dart`: Houses Supabase keys, application titles, and metadata.
- **`lib/service/`**: Networking and device utility services:
  - `file_caching.dart`: Downloads and caches resources in temp folders using `Dio` and `path_provider`.

---

## 2. Deep-Dive Performance Analysis

High performance is critical to ensuring academic networking is friction-free. We implement specific techniques across state propagation, media caching, and database interaction.

### 2.1 GetX Reactive State Propagation
Rather than rebuilding full widget trees with `setState`, the app registers observers using `Obx` or triggers targeted updates using GetX ID updates. This decreases layout and paint costs substantially on lower-end Android devices.

### 2.2 Optimistic UI Updates in DocumentController
Under `toggleLike` and `toggleDislike` in `document_controller.dart`, we update the model and UI counters **immediately** before firing database queries:
```dart
// Optimistic Update
final wasLiked = doc.isLiked;
final originalLikes = doc.likes;

doc.isLiked = !doc.isLiked;
doc.likes += doc.isLiked ? 1 : -1;
update();
```
If the Supabase call fails, the transaction is caught, reverted, and a toast error is shown. This makes user interactions feel instantaneous.

### 2.3 Hive Local Storage Caching
Session data is read synchronously using Hive's memory-mapped database structure, eliminating startup delays and ensuring "My Profile" screens are rendered instantly.
- `userBox`: Stores `UserModel` representing user configuration.
- `downloadsBox`: Caches downloaded resource metadata to skip redundant database fetches.

### 2.4 Media Compression & Network Optimization
- **Asset Compression**: `ImageHelper.compressImage` uses `flutter_image_compress` to re-encode JPEG graphics at 70% quality, capping assets at 1024x1024 to save storage space and minimize upload times.
- **Network Caching**: `CachedNetworkImage` maintains local disk caches of cover thumbnails.
- **Client Caching**: `FileCaching` checks if the PDF or doc already exists in the device's temporary folder before requesting network downloads:
  ```dart
  // file_caching.dart
  final directory = await getTemporaryDirectory();
  final filePath = "${directory.path}/$name";
  final file = File(filePath);
  if (await file.exists()) return filePath; // instant return
  ```

### 2.5 Feed Batching & Sticky Sort
- **Batching**: The `HomeController` fetches feeds with a default limit of 50 documents to keep payloads lightweight.
- **Sticky Sort**: The main feed implements a sticky sorting mechanism where official verified updates are pinned or given higher visibility, and latest documents are organized in descending chronological order (`order('created_at', ascending: false)`).

---

## 3. UX Design & Rebranding Aesthetics

The application's design system adheres to modern **Material 3** guidelines, augmented with **Glassmorphism** parameters to achieve a sophisticated, premium academic ambiance.

### 3.1 Premium Deep Blue Palette (`#0D47A1`)
The application has transitioned away from a generic purple to **Premium Deep Blue** (`#0D47A1`).
- `PrimaryColor.shade500` and `PrimaryColor.shade900` define this brand identity.
- Primary gradients (`AppGradients.premiumGradient`) combine Deep Blue with lighter indigo shades to establish depth.

### 3.2 Glassmorphic Elements
The visual interfaces implement semi-transparent glass layers with blurring backdrops using the `glassmorphism` package.
- Overlays leverage white values with micro alphas (e.g. `Colors.white.withValues(alpha: 0.15)` or `0.05` for glass gradients) and subtle border lines.

### 3.3 Shimmer Loading States
To preserve UX flow and prevent jarring skeleton flashes during lazy fetches, we use custom `shimmer` blocks in sections like `HomeDocumentSection`.

---

## 4. Security Audit & RLS Protocols

By migrating from a legacy MongoDB/Django environment to Supabase, we eliminated high-risk vulnerabilities such as plain-text passwords and open endpoints. Row Level Security (RLS) is now enforced directly inside PostgreSQL.

### 4.1 Schema Overview & Relationship Constraints
- `profiles`: Inherited primary key (`id UUID REFERENCES auth.users`) ensures users are tied to unique authentication credentials.
- `documents`: References `profiles(id)` via foreign key cascade deletions. Nullable constraints on URLs allow lightweight tweets alongside notes.
- `interactions` and `bookmarks`: Restrict duplicates via unique compound indexes: `UNIQUE(document_id, user_id)`.

### 4.2 Row Level Security (RLS) Policies
Every relational database table strictly implements authorization checks:
- **Profiles Table**:
  - `SELECT`: Publicly readable (`USING (true)`).
  - `INSERT`: Restricts creation to own profile (`WITH CHECK (auth.uid() = id)`).
  - `UPDATE`: Restricts modifications to profile owner (`USING (auth.uid() = id)`) with a strict `WITH CHECK` clause to prevent self-elevation of `is_admin`.
- **Documents Table**:
  - `SELECT`: Viewable by everyone.
  - `INSERT` / `UPDATE` / `DELETE`: Restricts write operations to document owner (`auth.uid() = user_id`).
  - Admins can override updating actions (`USING (auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true))`).

### 4.3 Atomic Operations & Database RPCs
To prevent concurrent race conditions on counters (e.g. multiple users liking a document at the same instant), we use database-level RPC functions defined in `SUPABASE_SCHEMA.sql`:
- `increment_likes` / `decrement_likes`
- `increment_dislikes` / `decrement_dislikes`
These functions execute atomically on the server via `SECURITY DEFINER` constraints, maintaining correct counts while restricting users from directly altering high-privilege columns.

### 4.4 Privilege Escalation Prevention
Content verification is strictly restricted. The `ensure_official_permission` trigger verifies that only authenticated users with `is_admin = true` inside `profiles` can mark documents as `is_official = true`.

---

## 5. Maintenance, Linting & QA Workflows

A key requirement for long-term project stability is adhering to a **Zero Warnings** policy.

### 5.1 Project Prerequisites
- **Flutter SDK**: `v3.24+` (Channel Stable)
- **Dart SDK**: `^3.5.4`
- **Android Target**: Targets Android API levels up to compileSdk 36.

### 5.2 Linting Rules Cleanups
Static analysis runs on every pull request. The project defines rules under `analysis_options.yaml`.
- **Deprecation Updates**: Calls to old color APIs like `.withOpacity(x)` are completely replaced with `.withValues(alpha: x)` to align with Dart 3.5.4 syntax requirements.
- **Switch Controls**: Deprecated `activeColor` in Switch widgets was modernized to use `activeThumbColor` to ensure zero-warning compilation.
- **Curly Braces**: Strict control structures enforce curly braces on multi-line flow controls (`curly_braces_in_flow_control_structures`).
- **Silent Catch Blocks**: Any empty catch statements must use a clean comment line annotation (`// ignore: empty_catches`) placed safely inside the brackets.

### 5.3 Automated Verification Tasks
To run local health checks before deploying code:
```bash
# Verify static code health
cd notehub
flutter analyze

# Run dummy and integration unit tests
flutter test
```

---
*Maintained and curated by Jules, Software Engineer.*
