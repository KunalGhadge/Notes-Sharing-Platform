# Developer Guide & Maintenance Manual - Serious Study

This document serves as the primary technical reference for the Serious Study Android application (formerly NoteHub). It provides a deep-dive analysis from a developer's perspective, covering performance, design, and security architectures.

## 1. Project Prerequisite & Environment
- **Flutter SDK**: ^3.24.0 (Stable Channel)
- **Dart SDK**: ^3.5.4
- **State Management**: GetX (^4.6.6)
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **Primary Namespace**: `com.divinevisionary.notehub`
- **Android Target**: SDK 36 (Java 17 compatibility)

---

## 2. Technical Architecture & Performance Analysis

### 2.1 State Management (GetX)
The application utilizes a reactive MVC pattern. Controllers in `lib/controller/` encapsulate business logic and interact with the Supabase client.
- **Optimistic UI Updates**: Implemented in `DocumentController` for likes, dislikes, and bookmarks to provide instantaneous feedback.
- **Dependency Injection**: Controllers are lazily loaded using `Get.put()` or `Get.lazyPut()` to optimize memory usage.

### 2.2 Local Persistence & Caching
- **Hive NoSQL**: Used for high-speed local storage.
  - `userBox`: Stores the current `UserModel` for instant profile loading.
  - `downloadsBox`: Tracks local file metadata for offline access.
- **File Caching**: `lib/service/file_caching.dart` manages network downloads, checking the local temporary directory before initiating new requests.
- **Media Optimization**: Images are compressed using `flutter_image_compress` (70% quality) before upload to Supabase Storage, reducing bandwidth and storage costs.

### 2.3 Backend Performance (PostgreSQL RPCs)
Atomic operations are offloaded to the database to ensure consistency and minimize client-side logic:
- `increment_likes` / `decrement_likes`
- `increment_dislikes` / `decrement_dislikes`
- `increment_bookmarks` / `decrement_bookmarks`
These are called via `supabase.rpc()` from the `DocumentController`.

### 2.4 Feed Management
- **Batching**: `HomeController` fetches documents in batches of 50 to balance network load.
- **Sticky Sort**: Official content is prioritized at the top of the feed using a custom sorting algorithm that weighs the `is_official` flag higher than the chronological `created_at` timestamp.

---

## 3. Design & UI Implementation

### 3.1 Design Language
- **Paradigm**: Material 3 with Premium Glassmorphism overlays.
- **Typography**: "Plus Jakarta Sans" is the primary typeface, configured modularly in `lib/core/config/typography.dart`.
- **Branding**: "Premium Deep Blue" (`#0D47A1`) serves as the core brand color.

### 3.2 Key Components
- **Glassmorphism**: Applied to the `BottomFooter` and high-level UI cards using the `glassmorphism` package.
- **Shimmer**: Integrated in `HomeDocumentSection` to provide visual placeholders during data fetching.
- **Lottie**: Used for empty states and search feedback to enhance the UX "delight" factor.

### 3.3 Modern API Compliance
The codebase strictly adheres to modern Flutter standards (v3.24+):
- **Colors**: `.withValues(alpha: ...)` is used instead of the deprecated `.withOpacity()`.
- **Switches**: `activeThumbColor` is used to resolve deprecated `activeColor` warnings.

---

## 4. Security Architecture

### 4.1 Authentication & Authorization
- **JWT (JSON Web Tokens)**: Managed entirely by Supabase Auth.
- **Row Level Security (RLS)**: The most critical security layer. Every table in `SUPABASE_SCHEMA.sql` has enforced policies:
  - **Profiles**: `UPDATE` restricted to `auth.uid() = id`.
  - **Documents**: `INSERT`/`DELETE` restricted to the owner (`user_id`).
  - **Official Content**: A `WITH CHECK` trigger/policy prevents non-admins from setting `is_official = true`.

### 4.2 Database Security
- **Security Definer**: PostgreSQL functions (RPCs) use the `SECURITY DEFINER` attribute to allow controlled updates to counters (e.g., `likes_count`) without exposing the entire table to direct public updates.
- **Search Path Protection**: RPC functions explicitly set the `search_path` to `public` to mitigate potential search-path hijacking.

---

## 5. Maintenance & QA Procedures

### 5.1 Zero Warnings Policy
The project maintains a strict 'Zero Warnings' policy. Developers **must** run the following before any submission:
```bash
cd notehub
flutter analyze
flutter test
```

### 5.2 Common Fixes
- **Syntax Corruption**: `AuthController` is prone to a recurring `qaWSQA` prefix corruption; always verify the top of the file if analysis fails.
- **Empty Catches**: Silent errors are documented using the `// ignore: empty_catches` annotation on a separate line inside the block to avoid syntax errors with `finally` blocks.
- **Flow Control**: All `if`/`else` statements must use explicit curly braces.

### 5.3 Real-time Integration
The app uses Postgres Realtime for live updates. Ensure the `supabase_realtime` publication includes the `documents`, `notifications`, and `interactions` tables in the Supabase Dashboard.

---
*Maintained by Jules, AI Software Engineer.*
*Last Technical Audit: June 2026*
