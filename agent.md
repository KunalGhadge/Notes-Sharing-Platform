# Developer Guide & Maintenance Manual - Serious Study (formerly NoteHub)

This document provides a complete, developer-centric technical analysis, architecture overview, and maintenance manual for the **Serious Study** Android application (the official academic notes-sharing and student networking platform for Mumbai University).

---

## 1. System Architecture & High-Level Tech Stack

Serious Study follows a modern, serverless, decoupled architecture utilizing Flutter for the cross-platform client and Supabase (PostgreSQL) for cloud computing, real-time data streaming, user authentication, and object storage.

```
+-----------------------------------------------------------------------------------+
|                                FLUTTER FRONTEND                                   |
|                                                                                   |
|   +-----------------------+   +------------------------+   +------------------+   |
|   |   GetX Controllers    |   | Hive Storage Engine    |   | Material 3 UI    |   |
|   | (State & Biz Logic)   |   | (User Session Cache)   |   | (Glassmorphism)  |   |
|   +-----------+-----------+   +-----------+------------+   +--------+---------+   |
+---------------+---------------------------+-------------------------+-------------+
                |                           |                         |
                | Supabase Flutter SDK      | Hive Sync               | Flutter Engine
                v                           v                         v
+-----------------------------------------------------------------------------------+
|                            SUPABASE BACKEND (PostgreSQL)                          |
|                                                                                   |
|   +-------------------+   +--------------------+   +--------------------------+   |
|   |   Supabase Auth   |   | PostgreSQL Tables  |   | Storage & Signed URLs    |   |
|   | (JWT & Sessions)  |   | & RLS Policies     |   | (PDFs & Covers)          |   |
|   +-------------------+   +---------+----------+   +--------------------------+   |
|                                     |                                             |
|                                     v                                             |
|                   +-----------------------------------+                           |
|                   | Database RPC Functions & Triggers |                           |
|                   | (Atomic Counter Updates)          |                           |
|                   +-----------------------------------+                           |
+-----------------------------------------------------------------------------------+
```

### Key Technical Specs
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management & DI**: `GetX` (`GetxController`, `Rx`, `GetBuilder`, `Get.put()`)
- **Local Persistence**: `Hive` (NoSQL key-value store for session fast-loading)
- **Backend Architecture**: Supabase Serverless (PostgreSQL 15+)
- **Network & I/O**: `Supabase Flutter SDK` (Data & Auth) & `Dio` (Specialized file download caching)
- **Media Compression**: `flutter_image_compress` (Client-side JPEG compression)
- **Android Target**: `compileSdk 36`, `targetSdk 36`, Java 17 compatibility with `coreLibraryDesugaring`

---

## 2. Frontend Layer: GetX State Management & Architecture

The application adopts an MVC-like structure where UI components (`lib/view/`) bind reactively to GetX controllers (`lib/controller/`).

### Controller Inventory & Responsibility Matrix

| Controller Name | File Path | Core Responsibilities & Reactive State |
| :--- | :--- | :--- |
| `AuthController` | `lib/controller/auth_controller.dart` | Handles email/password sign-in and sign-up, user session bootstrap, and profile fetching/creation. |
| `DocumentController` | `lib/controller/document_controller.dart` | Manages document lifecycle (fetching, optimistic likes/dislikes, bookmarks, direct/external URL opening, deletion, notifications trigger). |
| `HomeController` | `lib/controller/home_controller.dart` | Manages the main feed, real-time Postgres changes (`public:documents`), official updates tab, batching (50 items/batch), and sticky sorting. |
| `UploadController` | `lib/controller/upload_controller.dart` | Orchestrates cover image compression, PDF direct upload to Supabase Storage bucket `documents`, external link handling, and administrative 'Official' posts. |
| `ProfileController` | `lib/controller/profile_controller.dart` | Controls user profile metadata, bio updates, and local Hive cache synchronization. |
| `CommentController` | `lib/controller/comment_controller.dart` | Handles nested threaded comments, replies, and admin comment deletions. |
| `DownloadController` | `lib/controller/download_controller.dart` | Coordinates file downloading via `Dio`, local temporary directory saving, and metadata tracking in Hive `downloadsBox`. |

---

## 3. Local Storage & Session Persistence (Hive)

To eliminate initial startup latency, user credentials and profile metadata are saved locally using **Hive** (`lib/core/helper/hive_boxes.dart`).

```
+-----------------------------------------------------------------------------+
|                             HIVE BOX STRUCTURE                              |
+------------------------------------+----------------------------------------+
| User Box ('userBox')               | Downloads Box ('downloadsBox')         |
+------------------------------------+----------------------------------------+
| Key: 'data' -> UserModel           | Key: File Name -> Map                  |
|  - id: UUID                        |  - path: Local Disk File Path          |
|  - displayName: String             |  - downloadedAt: Timestamp             |
|  - username: String                |  - documentId: String                  |
|  - institute: String               |                                        |
|  - profile: String                 |                                        |
|  - isAdmin: bool                   |                                        |
+------------------------------------+----------------------------------------+
```

### Static Helper Operations
- **`HiveBoxes.setUser(UserModel user)`**: Saves user session model to `'userBox'`.
- **`HiveBoxes.userId`**: Getter returning active UUID or empty string.
- **`HiveBoxes.resetUser()`**: Clears session upon sign-out.

---

## 4. Backend Architecture: Supabase Database Schema, RPCs & RLS

The database (`SUPABASE_SCHEMA.sql`) uses PostgreSQL with **Row Level Security (RLS)** to enforce strict server-side access controls.

### 4.1 Relational Schema Diagram

```
+------------------------+          +---------------------------+
|        profiles        |          |         documents         |
+------------------------+          +---------------------------+
| id (PK, UUID)          |<---------| id (PK, BIGINT)           |
| username (TEXT, UNIQUE)|          | user_id (FK -> profiles)  |
| display_name (TEXT)    |          | name (TEXT)               |
| institute (TEXT)       |          | topic (TEXT)              |
| profile_url (TEXT)     |          | description (TEXT)        |
| is_admin (BOOLEAN)     |          | document_url (TEXT)       |
| created_at (TIMESTAMPTZ|          | cover_url (TEXT)          |
+------------------------+          | likes_count (INT)         |
            ^                       | dislikes_count (INT)      |
            |                       | is_external (BOOLEAN)     |
            |                       | is_official (BOOLEAN)     |
            |                       | post_type ('note'/'tweet')|
            |                       +---------------------------+
            |                                     ^
            |                                     |
+-----------+------------+          +-------------+-------------+
|        comments        |          |       interactions        |
+------------------------+          +---------------------------+
| id (PK, UUID)          |          | id (PK, BIGINT)           |
| document_id (FK) ------+--------->| document_id (FK)          |
| user_id (FK) ----------+          | user_id (FK)              |
| parent_id (FK -> self) |          | type ('like'/'dislike')   |
| content (TEXT)         |          +---------------------------+
+------------------------+
```

### 4.2 Row Level Security (RLS) Rules & Vulnerability Protection

All database access from Flutter is filtered through Supabase JWT user tokens:

1. **`profiles` table**:
   - `SELECT`: Publicly readable (`USING (true)`).
   - `INSERT`: Allowed only when `auth.uid() = id`.
   - `UPDATE`: Enforced via `WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))` to prevent privilege escalation.
2. **`documents` table**:
   - `SELECT`: Publicly readable.
   - `INSERT`: Enforced `auth.uid() = user_id`.
   - `UPDATE`/`DELETE`: Restricted to creator (`auth.uid() = user_id`) or users with `is_admin = true`.
3. **`interactions` & `bookmarks`**:
   - Unique composite constraint (`document_id`, `user_id`) prevents duplicate votes/bookmarks.

### 4.3 PostgreSQL Atomic RPCs (Remote Procedure Calls)

To avoid concurrency issues when multiple users vote simultaneously, counters are incremented/decremented at the database level using `SECURITY DEFINER` functions:

```sql
CREATE OR REPLACE FUNCTION increment_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents
  SET likes_count = likes_count + 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

*(Identical RPCs exist for `decrement_likes`, `increment_dislikes`, and `decrement_dislikes`)*.

---

## 5. UI/UX Paradigm: Material 3 & Glassmorphism Design System

The application features a modern visual interface tailored for Mumbai University branding:

- **Primary Color Palette**: Premium Deep Blue (`#0D47A1` - `PrimaryColor.shade500`).
- **Accent & Admin Gold**: Metallic Gold (`#FFD700`) used for `AdminBadge` widgets and verified content borders.
- **Glassmorphism Layer**: Implemented using `glassmorphism` and custom semi-transparent color overlays (`.withValues(alpha: ...)`) over linear gradients (`AppGradients.premiumGradient`).
- **Modern Color API**: Modernized for Flutter 3.24+ / Dart SDK 3.5.4; uses `.withValues(alpha: 0.15)` instead of deprecated `.withOpacity()`.
- **Switch Controls**: Uses `activeThumbColor: const Color(0xFFB8860B)` in administrative forms to ensure compliance with updated Flutter lints.

---

## 6. Android Native Build Configuration

Located in `notehub/android/app/build.gradle`:

```groovy
android {
    namespace = "com.divinevisionary.notehub"
    compileSdk = 36

    compileOptions {
        coreLibraryDesugaringEnabled true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.divinevisionary.notehub"
        minSdkVersion = flutter.minSdkVersion
        targetSdk = 36
        multiDexEnabled true
    }
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
}
```

---

## 7. QA, Linting & Zero Warnings Policy

The repository maintains a strict **Zero Warnings Policy** across the codebase.

### Essential Developer Verification Commands

To perform continuous integration checks locally, execute the following from the `notehub/` directory:

```bash
# 1. Run static analysis (must report "No issues found!")
flutter analyze

# 2. Run unit and integration test suite
flutter test
```

### Critical Linting Rules
1. **Flow Control Braces**: Enforce `curly_braces_in_flow_control_structures` for all `if`/`else` statements.
2. **Empty Catch Annotations**: When catching exceptions silently, format the annotation on its own line:
   ```dart
   try {
     // operation
   } catch (e) {
     // ignore: empty_catches
   }
   ```
3. **Color Modernization**: Never use `.withOpacity()`. Always use `.withValues(alpha: ...)`.
4. **Switch Thumb Color**: Use `activeThumbColor` instead of deprecated `activeColor`.

---
*Maintained and documented by Jules, AI Software Engineer.*
