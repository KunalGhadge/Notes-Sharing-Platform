# Developer Guide & Maintenance Manual - Serious Study (NoteHub)

This manual provides a detailed technical deep dive into the architectural patterns, security controls, and performance enhancements implemented in the **Serious Study** application (formerly NoteHub). It is designed to act as a system-wide reference for current and future maintainers.

---

## 1. System Architecture & Codebase Map

Serious Study is an academic content-sharing and social networking platform built with **Flutter 3.24+** (utilizing **Dart SDK 3.5.4+**) and backed by **Supabase**. The frontend uses a highly structured MVC-like pattern via the **GetX** ecosystem.

```
notehub/
├── android/               # Android native configuration (MultiDex, Java 17, target SDK 36)
├── assets/                # App assets (Animations, SVGs, high-res images)
└── lib/
    ├── controller/        # Business logic controllers (GetX state management)
    ├── core/
    │   ├── config/        # Colors, Gradients, Typography definitions
    │   ├── helper/        # Local persistent database helpers (Hive, storage)
    │   └── meta/          # App metadata (branding name, Supabase endpoints)
    ├── model/             # Data models for deserialization (User, Document, etc.)
    ├── service/           # System level helpers (Local Notifications, File Caching/Download)
    ├── view/              # Feature UI screens (Auth, Feed, Profile, Settings, Upload)
    └── main.dart          # Application bootstrap entry point
```

### 1.1 MVC via GetX
The application avoids tight coupling between UI widgets and system states by leveraging GetX:
- **UI Screen (`lib/view/`)**: Defines the presentation layer. Listens to state changes reactively via `Obx` or standard bindings.
- **GetxController (`lib/controller/`)**: Exposes reactive streams (`.obs`) and contains business logic, networking pipelines, and integration endpoints.
- **Dependency Injection**: Dependencies are registered at startup using `Get.put()` or `Get.lazyPut()`, allowing immediate, context-less dependency retrieval across any widget.

---

## 2. High-Performance Design & Cache Strategy

To ensure fluid responsiveness on device screens and keep mobile data usage low, Serious Study integrates persistent local databases, optimized media pipelines, and atomic network updates.

### 2.1 Persistent Local Databases with Hive
For high-efficiency session management and off-grid performance, the app implements **Hive**:
- **`HiveBoxes.userBox`**: High-speed user session caching. Caches standard user metadata (ID, display name, username, institution, profile picture URL) on login, allowing the home screen and settings page to draw user profiles instantaneously without hitting the Supabase Auth or database endpoints on launch.
- **`HiveBoxes.downloadsBox`**: Metadata store mapping all downloaded documents to local storage file structures. Ensures offline readability by registering all completed downloads.

### 2.2 Network & Download Optimization
- **`FileCachingService` (specialized Dio integration)**: Checks the local application cache for existing file names before requesting media downloads. If a document hash matches local storage, it returns the local file immediately rather than consuming network bandwidth.
- **Image Compression**: `flutter_image_compress` reduces high-resolution user photos to lightweight, 70% quality JPEGs of 1024x1024 resolution before pushing uploads to the Supabase Storage Bucket, saving bandwidth and cloud storage costs.
- **Lazy Loading**: Main feed queries are restricted to a size limit (default 50) and official feed feeds to a limit of 20, optimizing load speed and memory pressure.

### 2.3 Optimistic UI & Local Sync
In the `DocumentController`, interactions like liking, disliking, or bookmarking are updated **optimistically** on the UI. The state registers the updated counters and highlights immediately, while the server sync call happens asynchronously.
- **Reversion on Failure**: If the network call or database constraint fails, the controller automatically reverts the localized variables and alerts the user with error-themed alerts.
- **Synchronized State**: `_syncWithHome()` updates `HomeController` real-time values whenever reactive interaction changes occur inside localized document view hierarchies.

---

## 3. UI/UX Aesthetics & Design Framework

Serious Study implements standard **Material 3** guidelines combined with customized modern styling techniques.

### 3.1 Styling Themes & Palettes
- **Branding**: Rebranded from the original purple palette to the MU Academic **Premium Deep Blue** theme (`#0D47A1`).
- **Typography**: Integrates modern typography via Google Fonts to achieve neat, high-contrast, professional text blocks.
- **Glassmorphism Overlay**: Multi-layered Glassmorphic cards are achieved via customized LinearGradients, combining slightly transparent white hues (using `.withValues(alpha: ...)` to satisfy Dart SDK 3.5.4 deprecation requirements for `.withOpacity`) and subtle blur backdrops.

### 3.2 Visual Smoothness Components
- **Shimmer Effects**: Renders loading placeholders in place of static spinners, creating an expectation of dynamic data rendering.
- **Lottie Assets**: Uses Lottie animations to replace generic empty state alerts and confirm success states (e.g., upload confirmation).

---

## 4. Supabase Integration & Database Schema

The database model is mapped directly in **PostgreSQL** in Supabase. It relies on strict foreign keys, atomic transactional counts, and Postgres Realtime changes to serve updates to clients securely.

### 4.1 Schema Layout (`SUPABASE_SCHEMA.sql`)
The backend consists of several key tables:
1. **`profiles`**: Tied directly to Supabase Auth UUIDs. Stores educational details, interests, and profile photo directories.
2. **`documents`**: Main content catalog. Supports both direct uploads (with non-null document URLs) and shared links (`is_external: true` with nullable names). Features a constraints constraint: `post_type IN ('note', 'tweet')` allowing micro-blogging besides files.
3. **`comments`**: Threaded replies mapped using a parent-child hierarchical identifier (`parent_id` references `comments.id` with cascade deletion).
4. **`interactions`**: Restricts likes and dislikes to a single vote per user per document.

### 4.2 Database Triggers, Functions & RPCs
To avoid state corruption and race conditions common in multi-user environments, Serious Study offloads calculation counts to atomic database RPC functions:
- `increment_likes(doc_id)` / `decrement_likes(doc_id)`
- `increment_dislikes(doc_id)` / `decrement_dislikes(doc_id)`
- `increment_bookmarks(doc_id)` / `decrement_bookmarks(doc_id)`

These are defined as database-side operations executing atomically within database transactions, ensuring consistent statistics.

### 4.3 Real-time Data Sync
The `HomeController` registers listener subscriptions:
```dart
supabase.channel('public:documents').onPostgresChanges(...)
```
This forces immediate local feed hydration whenever files or updates are pushed to PostgreSQL, enabling immediate feed reactivity without polling.

---

## 5. Security Posture & Access Controls

Security is implemented globally using Supabase JWT authorization headers and deep Row-Level Security (RLS) rules in PostgreSQL.

### 5.1 Authorization & Token Management
Authentication is validated using modern JSON Web Tokens (JWT). All requests are verified by Supabase API gateways before accessing any custom database table.

### 5.2 Row Level Security (RLS) Policies
Every relational model is locked down using fine-grained RLS profiles:
- **`profiles` RLS**:
  - `FOR SELECT`: `true` (Profiles are publicly readable for social mapping).
  - `FOR INSERT`: `auth.uid() = id` (Users can only build their own profiles).
  - `FOR UPDATE`: `auth.uid() = id WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))` (Prevents self-promotion/escalation to admin role).
- **`documents` RLS**:
  - `FOR SELECT`: `true` (Open read access).
  - `FOR INSERT / UPDATE / DELETE`: `auth.uid() = user_id` (Ensures only verified document authors can alter document structures).
- **`notifications` RLS**:
  - `FOR SELECT`: `auth.uid() = receiver_id` (Restricts notification access exclusively to the target recipient).

### 5.3 Security Definer & Privilege Containment
Counter operations utilize `SECURITY DEFINER` constraints on database functions. This lets lower-privileged users increment counters atomically without granting them write privileges over other columns or rows.
- **Search-Path Hijack Mitigation**: To prevent search-path hijacking exploits inside administrative database execution scopes, all functions are locked to search public directories explicitly:
  ```sql
  CREATE OR REPLACE FUNCTION check_official_permission()
  RETURNS trigger SECURITY DEFINER
  SET search_path = public
  AS ...
  ```

---

## 6. Zero Warnings QA & Clean Code Guide

The Serious Study project enforces a strict "Zero Warnings" standard. Every pull request must pass analyzer criteria and unit test checks without errors.

### 6.1 Flutter Linting & Code Hygiene
- **Braces Control**: Ensure flow control clauses are enclosed in curly braces to satisfy code hygiene standards (`curly_braces_in_flow_control_structures`).
- **Color Methods**: Avoid the deprecated `.withOpacity()` for coloring. Use `.withValues(alpha: ...)` to preserve compatibility with Dart SDK 3.5.4+ updates.
- **Switch Widgets**: Use `activeThumbColor` instead of the deprecated `activeColor` in Switch components to satisfy modernized Flutter standards.
- **Error Handling**: Silent catch blocks should include standard annotations like `// ignore: empty_catches` or explicitly dump logs using `debugPrint`. Ensure `// ignore: empty_catches` is placed on its own line inside the catch body to avoid comment truncation of any trailing `finally` blocks.

### 6.2 CI/CD Verification Commands
Developers must execute and pass the following checks locally before committing code:
```bash
# 1. Clean build configurations and artifacts
flutter clean
flutter pub get

# 2. Run static analysis to verify compliance
flutter analyze

# 3. Execute unit and controller tests
flutter test
```

---
*Maintained with excellence by Jules, AI Software Engineer.*
