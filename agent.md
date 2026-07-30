# Developer Guide & System Architecture Manual - Serious Study (formerly NoteHub)

This document is the primary system manual, maintenance guide, and comprehensive technical architecture review of **Serious Study** (formerly NoteHub). Designed from a senior developer's perspective, this manual details the performance optimizations, design standards, security configurations, database schemas, and codebase patterns implemented in this Flutter/Supabase application.

---

## 1. Executive Summary & Tech Stack Evolution

Serious Study is an academic community and peer-to-peer resource-sharing application designed specifically for Mumbai University students.

The application was successfully modernized and migrated from a legacy **Django / MongoDB** architecture to a highly scalable, serverless **Supabase** backend and modern **Flutter 3.24+ / Dart 3.5.4+** frontend. This transition solved critical architectural pain points:
- **Scalability**: High-throughput file downloads are now backed by globally distributed CDNs (Supabase Storage) instead of synchronous Django server endpoints.
- **Data Integrity**: Transitioned from NoSQL (MongoDB) to a fully normalized relational schema (PostgreSQL) with cascading deletes and atomic database triggers.
- **Latency**: Replaced polling with modern state management (GetX) and real-time database changes (PostgreSQL Realtime change streams).
- **Security**: Closed massive data access flaws by implementing database-level Row Level Security (RLS) instead of trusting client-side parameter boundaries.

---

## 2. Decoupled MVC-like System Architecture

The codebase enforces a decoupled Model-View-Controller (MVC) structure, with reactive state management cleanly dividing logic from rendering.

```
notehub/lib/
├── controller/          # GetX Controllers (Reactive State & Database Operations)
├── core/                # Global Styling, Helper Utilities, and Configurations
│   ├── config/          # Color schemes, Premium Gradients, Material 3 Typography
│   ├── helper/          # Hive local caches, compression utilities, vector icons
│   └── meta/            # Application metadata and Supabase credentials
├── model/               # Immutable serialization data structures & Hive Adapters
├── service/             # Side-effect systems (Notifications, Caching, File Downloads)
├── view/                # Highly modular, conditional-rendering UI components
└── main.dart            # Multi-service bootstrapper and dependency injection registry
```

### Core Controllers Map & Lifecycle Management

1. **`AuthController` (`lib/controller/auth_controller.dart`)**:
   - Manages user lifecycle, registration, and logins.
   - Handshakes with **Supabase Auth** to acquire and process secure JWT tokens.
   - Automatically initializes profile records in the `profiles` table when registering.
   - Integrates with Hive to sync and store user sessions (`UserModel`) locally for immediate app bootstrapping.

2. **`HomeController` (`lib/controller/home_controller.dart`)**:
   - Manages the primary community feed.
   - Implements **PostgreSQL Realtime Streams** (`supabase.channel().onPostgresChanges()`) to dynamically re-fetch documents whenever new notes or tweets are inserted/modified on the database.
   - Optimizes payloads by pulling data in batches (limit 50) and applying a **Sticky Sort** (pinning "Official" administrative content first, followed by newest additions).

3. **`DocumentController` (`lib/controller/document_controller.dart`)**:
   - Powers note and content manipulation (liking, disliking, bookmarking, and deletion).
   - Coordinates state synchronization back to the `HomeController` via `_syncWithHome()` to prevent out-of-sync UI states when multiple widgets read the same reactive datasets.
   - Orchestrates local file caches to save internet bandwidth.

4. **`UploadController` (`lib/controller/upload_controller.dart`)**:
   - Controls multi-step uploads. Handles form validation, image compression pipelines, and dual-upload pathways (direct document PDF/image uploads vs. external resource sharing).
   - Restricts heavy payloads (blocking uploads above 10MB) to preserve resources, guiding users to utilize Google Drive or Mega external links.

---

## 3. Performance & Optimization Engineering

High performance and seamless offline/online state synchronization are realized through several decoupled optimizations:

### A. Optimistic UI Updates & Latency Compensation
To make the app feel exceptionally fast, `DocumentController` updates likes, dislikes, and bookmarks optimistically on the UI thread before calling the network.
- **The Pattern**:
  1. The user taps the 'Like' icon.
  2. The controller immediately updates `doc.isLiked = !doc.isLiked`, adjusts the reactive count, and calls GetX `update()`.
  3. The controller fires off the asynchronous RPC `/interactions` mutation.
  4. If the database returns a connection error or a `PostgrestException`, the catch-block triggers, **reverts** the state back to its original value, alerts the user with an elegant toast message, and calls `update()` to repaint the UI safely.

### B. High-Performance Persistent NoSQL Local Caching
The application integrates **Hive** for lightning-fast disk-backed key-value caching.
- **Session Caching (`userBox`)**: Stores user metadata (username, display name, profile picture, academic interests, follower/following metrics). Upon cold startup, `HiveBoxes` provides immediate access to user context so the main layout can render immediately without waiting for authentication requests to finish.
- **Offline Download Manager (`downloadsBox`)**: Caches document metadata and maps it to downloaded local file paths. If a user tries to access a previously downloaded note, `FileCachingService` checks this NoSQL directory, immediately opening the document locally instead of invoking network requests.

### C. Resource Preservation & Asset Compression
- **File Caching Services (`lib/service/file_caching.dart`)**: Uses `Dio` combined with `path_provider` to securely stream document binaries to the device's temporary storage directory.
- **Pre-Upload Asset Compression (`lib/core/helper/image_helper.dart`)**: Cover images are often taken with high-resolution mobile cameras (5MB+). To optimize bandwidth and storage fees, `ImageHelper` intercepts selected assets, compressing them to JPEG at 70% quality with a maximum boundary of 1024x1024 pixels before sending them to the Supabase Storage Bucket.
- **Network Image Caching**: UI layouts utilize `cached_network_image` to cache note cover thumbnails and profile pictures in memory and disk, completely eliminating redundant HTTP requests while scrolling feeds.

### D. Server-Side Scalability & Atomic Calculations
When thousands of users interact with the same document, concurrency race conditions are highly likely. To prevent incorrect like/dislike counts:
- The app avoids incrementing counters client-side.
- Client-side controllers call secure PostgreSQL Database Functions (RPCs) like `increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, and `decrement_bookmarks`.
- These database operations are fully transactional and atomic, securing exact values at the database layer.

---

## 4. UI/UX Aesthetics & Design System

The app follows a modern **Material 3** specification wrapped in a bespoke **Glassmorphism** visual theme.

```
┌────────────────────────────────────────────────────────┐
│  Premium Deep Blue Palette (#0D47A1)                   │
├────────────────────────────────────────────────────────┤
│  Glassmorphism Navigation with custom blur overlays   │
├────────────────────────────────────────────────────────┤
│  Shimmer State Placeholders for async feed loading    │
├────────────────────────────────────────────────────────┤
│  Lottie Motion feedback for empty streams & successes │
└────────────────────────────────────────────────────────┘
```

### Theme, Typography & Visual Rules
- **Color Palette**: Engineered around `PrimaryColor.shade500` (Premium Deep Blue `#0D47A1`), conveying security, focus, and Mumbai University's academic integrity.
- **Glassmorphic Gradients**:
  - Implements customized transparent layered gradients like `AppGradients.glassGradient` inside bottom navigation panels and headers.
  - Transparent white overlays (such as `Colors.white.withValues(alpha: 0.15)`) coupled with blurred backdrops create a modern, layered visual weight.
- **Micro-Animations**:
  - Empty search screens and success dialogs display `Lottie` vector animations.
  - Document heart reactions employ an explicit micro-scale animation controller (`LikesWithHeart`) to provide a delightful user response.
  - Shimmer placeholder layouts block cumulative layout shifts (CLS) by aligning with standard card dimensions during initial content loads.

---

## 5. Security & Authorization Hardening

The serverless architecture enforces a zero-trust model, transferring critical security layers directly to the database.

### A. JWT-Backed Session Security
The app bypasses custom session management, relying strictly on **Supabase Auth**. Authenticated sessions generate signed JWTs. All subsequent database operations automatically forward this token in their headers, where the PostgreSQL engine evaluates permissions.

### B. Row Level Security (RLS) Policies
Every single table in `SUPABASE_SCHEMA.sql` has Row Level Security strictly enforced (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`). This blocks unauthorized cross-user modifications:

| Table | SELECT Policy | INSERT Policy | UPDATE Policy | DELETE Policy |
| :--- | :--- | :--- | :--- | :--- |
| **`profiles`** | `true` (Publicly viewable) | `auth.uid() = id` | `auth.uid() = id` (Owner only) | No public delete |
| **`documents`**| `true` (Publicly viewable) | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` |
| **`comments`** | `true` (Publicly viewable) | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` |
| **`interactions`**| `auth.uid() = user_id` | `auth.uid() = user_id` | No updates | `auth.uid() = user_id` |
| **`bookmarks`**| `auth.uid() = user_id` | `auth.uid() = user_id` | No updates | `auth.uid() = user_id` |
| **`notifications`**| `auth.uid() = receiver_id`| `true` | No updates | `auth.uid() = receiver_id` |

### C. Privilege Escalation Prevention
- **Profile Moderation Protection**: A critical privilege escalation vector in profiles was closed. The RLS update policy for the `profiles` table is strictly protected to verify that regular users cannot modify their own `is_admin` column. This is verified by enforcing the RLS validation clause:
  ```sql
  WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))
  ```
- **Official Label Constraints**: Setting a document as `is_official = true` grants it high visibility and a verified badge. Only users with verified `is_admin = true` status are authorized to mark documents as official. This is enforced at the database level using a Postgres trigger before insertion and update (`ensure_official_permission`).
- **Database Path Hijacking Mitigation**: To prevent search-path hijacking attacks, PostgreSQL stored functions (RPCs) are compiled with explicit search-path restrictions:
  ```sql
  SET search_path = public
  ```

---

## 6. Developer Playbook: Zero Warnings & Maintenance Guide

Developers must adhere to strict maintenance guidelines to prevent regressions, maintain codebase legibility, and satisfy CI pipelines.

### A. Environment Prerequisites
- **Flutter SDK**: `v3.24+` (Stable Channel)
- **Dart SDK**: `^3.5.4`
- **Target Target API (Android)**: `compileSdk 36`, `Java 17`
- **Flutter Web Port**: Visual screenshots and automated driver checks use port `8080`.

### B. Static Analysis and Code Hygiene Rules
Our `analysis_options.yaml` file forces strict type and syntactic patterns. Run the analyzer inside the Flutter root directory:
```bash
cd notehub
flutter analyze
```

#### Key Directives to Maintain "Zero Warnings":

1. **Modern Color Utilities**:
   - **Do not use** `Color.withOpacity(value)`. It is deprecated under modern Dart/Flutter SDKs.
   - **Always use** `.withValues(alpha: value)` for opacity adjustment:
     ```dart
     // Correct
     Colors.white.withValues(alpha: 0.15)
     ```

2. **Flow Control Structuring**:
   - Every control structure (including simple `if` checks returning or launching sub-methods) **must** utilize explicit block curly braces:
     ```dart
     // Correct
     if (doc.isLiked) {
       await toggleLike(doc);
     }
     ```

3. **Switch Component deprecations**:
   - The modern Flutter Switch widget deprecates `activeColor`.
   - **Always use** `activeThumbColor` instead to ensure full compiler satisfaction:
     ```dart
     Switch(
       value: controller.isOfficial.value,
       onChanged: (v) => controller.isOfficial.value = v,
       activeThumbColor: const Color(0xFFB8860B),
     )
     ```

4. **Correct Catch Block Lint Annotations**:
   - If writing empty catch blocks for silently tolerated exceptions, place the `// ignore: empty_catches` annotation inside the block on its own line:
     ```dart
     // Correct
     try {
       _syncWithHome();
     } catch (e) {
       // ignore: empty_catches
     }
     ```
   - *Never* merge the annotation on the same line as the closing bracket, as it may accidentally comment out the `finally` block or other executable syntax.

5. **Re-Generating Build Artifacts**:
   - For changes made to immutable models (e.g., `UserModel`), always re-run build runner to regenerate artifacts (`user_model.g.dart`):
     ```bash
     dart run build_runner build --delete-conflicting-outputs
     ```

---
*Maintained and curated by Jules, Lead AI Software Engineer.*
*Revised: July 2026.*
