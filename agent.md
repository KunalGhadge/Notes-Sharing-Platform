# Developer Technical Manual & System Architecture — Serious Study

This manual provides an exhaustive, developer-centric technical analysis of the **Serious Study** (formerly NoteHub) mobile platform. It covers system architecture, performance engineering, UI/UX design patterns, database security, and QA guidelines following its migration from a legacy Django/MongoDB backend to a serverless **Supabase** infrastructure paired with **Flutter 3.24+** (Dart SDK `^3.5.4`).

---

## 1. Executive Overview & Architecture

Serious Study is an academic social and resource-sharing network for the Mumbai University student community. The application utilizes a reactive, decoupled Model-View-Controller (MVC) paradigm implemented via **GetX**, local offline caching via **Hive**, and backend data orchestration via **Supabase**.

```
+-----------------------------------------------------------------------+
|                          FLUTTER FRONTEND                             |
|                                                                       |
|  [ View / UI Layer ]  <--->  [ GetX Controller / Business Logic ]     |
|         ^                                   |                         |
|         |                                   v                         |
|         |                       +----------------------+              |
|         +-----------------------| Local Cache (Hive)   |              |
|                                 +----------------------+              |
|                                             |                         |
|                                             v                         |
|                                 +----------------------+              |
|                                 | Network / Caching    |              |
|                                 | (Dio / Storage)      |              |
|                                 +----------------------+              |
+---------------------------------------------|-------------------------+
                                              | HTTPS / WebSockets (JWT)
                                              v
+-----------------------------------------------------------------------+
|                         SUPABASE BACKEND                              |
|                                                                       |
|   +-------------------+  +-------------------+  +-----------------+   |
|   |   Supabase Auth   |  | PostgreSQL (RLS)  |  | Storage Buckets |   |
|   |   (JWT / Argon2)  |  | & RPC Functions   |  | (Docs & Images) |   |
|   +-------------------+  +-------------------+  +-----------------+   |
+-----------------------------------------------------------------------+
```

### Core Stack Components
- **Frontend Framework**: Flutter 3.24+ / Dart SDK ^3.5.4 targeting Android (compileSdk 36, Java 17).
- **State Management & DI**: `GetX` (`GetxController`, `Rx` primitives, `Get.put()`, `Get.find()`).
- **Local Persistent Storage**: `Hive` (high-performance NoSQL key-value store for user sessions and download records).
- **Backend Infrastructure**: Supabase (PostgreSQL 15+ with Row Level Security, Supabase Auth, Storage Buckets).
- **Networking & Media Caching**: `supabase_flutter`, `dio` (for byte-range file downloads), `cached_network_image`.

---

## 2. Component Mapping & Directory Structure

The repository source code is structured under `notehub/lib/` as follows:

```
notehub/lib/
├── main.dart                       # App entry point, Supabase & Hive initialization
├── layout.dart                     # Bottom navigation shell & tab switching
├── controller/                     # GetX Controllers (Business Logic & State)
│   ├── auth_controller.dart        # Authentication, profile sync, session management
│   ├── document_controller.dart    # Interactions, optimistic likes/bookmarks, deletion
│   ├── home_controller.dart        # Feed pagination, realtime subscription, official feed
│   ├── upload_controller.dart      # File/link post creation, media compression, validation
│   ├── profile_controller.dart     # User profile, follower management, interests update
│   ├── search_controller.dart      # Keyword filtering & query processing
│   ├── notification_controller.dart# Notification feed & unread counts
│   ├── connection_controller.dart  # Peer networks & follower feeds
│   ├── download_controller.dart    # Offline files tracker via Hive
│   └── remote_config_controller.dart# Dynamic feature toggles via Supabase Remote Config
├── core/                           # System Configurations & Utilities
│   ├── config/
│   │   ├── color.dart              # Material 3 palette, Deep Blue primary (#0D47A1)
│   │   └── typography.dart         # Google Fonts (Poppins / Inter) design tokens
│   ├── helper/
│   │   ├── hive_boxes.dart         # Hive box wrappers ('userBox', 'downloadsBox')
│   │   ├── image_helper.dart       # JPEG image compression (70% quality, 1024x1024)
│   │   └── custom_icon.dart        # SVG vector mappings
│   └── meta/
│       └── app_meta.dart           # Metadata & Supabase project credentials
├── model/                          # Strongly-Typed Data Models
│   ├── user_model.dart             # User profile model & Hive adapter
│   ├── document_model.dart         # Post/Document model with interaction state
│   └── post_model.dart             # Social post / tweet representation
├── service/                        # System Services
│   ├── file_caching.dart           # Dio download manager & local temp path provider
│   ├── file_download.dart          # Local storage file writer
│   └── notification_service.dart   # Flutter Local Notifications configuration
└── view/                           # Modular UI Components & Screens
    ├── auth_screen/                # Login & Registration views
    ├── home_screen/                # Feed screen, shimmer loaders, document cards
    ├── document_screen/            # Detail view, PDF previewer, comment section
    ├── upload_screen/              # File upload & external link submission forms
    ├── profile_screen/             # My Profile & Peer Profile screens
    ├── search_screen/              # Search bar & filtered result list
    ├── notification_screen/        # Activity feed & global announcements
    └── widgets/                    # Reusable UI controls (Buttons, Cards, Toasts)
```

---

## 3. Deep Performance Analysis

### 3.1 Optimistic State Management
`DocumentController` implements client-side optimistic UI updates for high-frequency interactions (`toggleLike`, `toggleDislike`, `toggleBookmark`).
- **Execution Flow**:
  1. Immediately mutates the local observable `DocumentModel` state (`isLiked`, `likes` count) and calls `update()`.
  2. Dispatches asynchronous PostgreSQL RPC functions (`increment_likes`, `decrement_likes`) via Supabase.
  3. Automatically catches network/database errors, rolls back the local state to original values, and displays error feedback via `Toasts`.

### 3.2 Concurrency-Safe Database RPCs
To eliminate race conditions when multiple users interact with popular documents simultaneously, counter mutations are offloaded to PostgreSQL atomic RPC functions rather than raw update queries:

```sql
CREATE OR REPLACE FUNCTION increment_likes(doc_id BIGINT)
RETURNS VOID AS $$
BEGIN
  UPDATE public.documents
  SET likes_count = likes_count + 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

### 3.3 Feed Pagination & Batching
- **Batching**: `HomeController` fetches feed items in pages of 50 documents (`.range(offset, offset + 50)`), minimizing payload size and database memory footprint.
- **Sticky Sort**: Feeds are ordered strictly by `created_at DESC` with index backing on `documents(created_at)`.
- **Realtime Listener**: Listens to `supabase.channel('public:documents')` for live postgres changes without full re-fetches.

### 3.4 Multi-Tier Media Optimization
1. **Network Image Caching**: All avatar and thumbnail widgets use `cached_network_image` with memory and disk cache limits.
2. **File Compression**: Pre-upload pipeline processes image assets through `FlutterImageCompress.compressAndGetFile()` targeting 70% quality JPEG format with max bounds of 1024x1024.
3. **Download Caching**: `FileCachingService` leverages `Dio` to check for cached files in the device directory before initiating duplicate network transfers.

### 3.5 App Launch Hydration
User profile and session identifiers are stored locally in Hive (`userBox`). Upon app launch, `HiveBoxes.userId` hydrates the application state synchronously, enabling instant render of the home shell while network sync occurs in the background.

---

## 4. Design System & Visual Architecture

### 4.1 UI Paradigm
The application implements **Material 3** guidelines fused with **Glassmorphism** depth overlays:
- **Primary Color**: Rebranded "Premium Deep Blue" (`#0D47A1`).
- **Glass Elements**: `GlassmorphicContainer` overlays with subtle white borders (`Colors.white.withValues(alpha: 0.15)`) for navigation bars and modal sheets.
- **Color Opacity**: Strictly uses modern Dart 3 color API `.withValues(alpha: 0.x)` instead of deprecated `.withOpacity()`.

### 4.2 Visual Feedback & Motion
- **Shimmer Placeholders**: Used in `HomeDocumentSection` during initial state fetching to prevent layout shifts.
- **Animations**: `Lottie` vector animations represent empty search queries, upload success states, and network errors.
- **Pull-to-Refresh**: `LiquidPullToRefresh` wrapped around document feeds triggers background controller re-fetches.

---

## 5. Database Security Analysis & RLS Compliance

The database architecture defined in `SUPABASE_SCHEMA.sql` establishes a strict Zero Trust model using PostgreSQL Row Level Security (RLS) and custom triggers.

```
+-----------------------------------------------------------------------------------+
|                            POSTGRESQL SECURITY MODEL                              |
|                                                                                   |
|  [ Client (JWT Authenticated) ]                                                   |
|                |                                                                  |
|                v                                                                  |
|  +-----------------------------------------------------------------------------+  |
|  | ROW LEVEL SECURITY (RLS) POLICIES                                          |  |
|  |                                                                             |  |
|  |  • profiles: SELECT true | INSERT auth.uid()=id | UPDATE auth.uid()=id       |  |
|  |    * WITH CHECK prevents is_admin tampering                                  |  |
|  |  • documents: SELECT true | INSERT/UPDATE auth.uid()=user_id               |  |
|  |  • interactions/bookmarks/notifications: Scoped to owner user_id             |  |
|  +-----------------------------------------------------------------------------+  |
|                |                                                                  |
|                v                                                                  |
|  +-----------------------------------------------------------------------------+  |
|  | SECURITY TRIGGERS & RPCs                                                    |  |
|  |                                                                             |  |
|  |  • ensure_official_permission: Prevents setting is_official = true          |  |
|  |    unless requester possesses is_admin = true in public.profiles.           |  |
|  |  • Atomic RPCs (increment_likes, etc.): SECURITY DEFINER                     |  |
|  |    with explicit SET search_path = public.                                  |  |
|  +-----------------------------------------------------------------------------+  |
+-----------------------------------------------------------------------------------+
```

### 5.1 RLS Table Policy Matrix

| Table | SELECT | INSERT | UPDATE | DELETE |
| :--- | :--- | :--- | :--- | :--- |
| `profiles` | Public (`true`) | `auth.uid() = id` | `auth.uid() = id` * | `id = auth.uid()` |
| `documents` | Public (`true`) | `auth.uid() = user_id` | `auth.uid() = user_id` OR Admin | `auth.uid() = user_id` |
| `comments` | Public (`true`) | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` |
| `interactions` | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` | `auth.uid() = user_id` |
| `bookmarks` | `auth.uid() = user_id` | `auth.uid() = user_id` | - | `auth.uid() = user_id` |
| `notifications`| `auth.uid() = receiver_id` | System / Trigger | `auth.uid() = receiver_id` | `auth.uid() = receiver_id` |

### 5.2 Critical Vulnerability Mitigations

1. **Privilege Escalation via Profile UPDATE**:
   - *Threat*: Users calling `.update({'is_admin': true})` on their profile row.
   - *Mitigation*: The `UPDATE` policy on `profiles` enforces a `WITH CHECK` clause validating that `is_admin` cannot be changed unless the requester is already an admin:
     ```sql
     CREATE POLICY "Users can update own profile" ON public.profiles
       FOR UPDATE USING (auth.uid() = id)
       WITH CHECK (
         auth.uid() = id AND
         is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
       );
     ```

2. **Official Content Verification Spoofing**:
   - *Threat*: Non-admin users creating documents with `is_official = true`.
   - *Mitigation*: Trigger `ensure_official_permission` intercepts all document inserts/updates and verifies admin status in `public.profiles`.

3. **Search Path Hijacking Protection**:
   - *Threat*: Malicious users overriding PostgreSQL functions by altering the function `search_path`.
   - *Mitigation*: All `SECURITY DEFINER` procedures explicitly declare `SET search_path = public`.

---

## 6. Developer Manual & QA Guidelines

### 6.1 Prerequisites & Target Versions
- **Dart SDK**: `^3.5.4`
- **Flutter SDK**: `3.24+`
- **Android Target SDK**: `36` (Java 17 compatibility enabled)

### 6.2 Mandatory Code Quality Rules
1. **Zero Warnings Standard**: Run `flutter analyze` inside `notehub/` to verify zero static analysis errors or warnings.
2. **Color API Deprecation**: Do not use `.withOpacity()`. Always use `.withValues(alpha: double)`.
3. **Switch Widget Control**: `Switch` controls must use `activeThumbColor` instead of the deprecated `activeColor`.
4. **Flow Control Braces**: Always enclose conditional blocks in explicit curly braces (`if (...) { ... }`).
5. **Catch Block Annotations**: Silent catch blocks must include `// ignore: empty_catches` on its own line within the block.

### 6.3 QA Verification Commands
```bash
# Navigate to app directory
cd notehub

# Resolve dependencies
flutter pub get

# Run static analysis
flutter analyze

# Run unit and dummy test suite
flutter test
```

---
*Maintained by AI Software Engineering Agent — Serious Study Platform.*
