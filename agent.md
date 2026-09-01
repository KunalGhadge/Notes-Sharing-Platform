# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis and developer guide for **Serious Study**, a modern academic networking and notes-sharing platform tailored for the Mumbai University student community.

---

## 1. Executive Summary & Architecture Overview

Serious Study transitioned from a legacy Django/MongoDB stack to a serverless **Supabase** backend paired with a **Flutter (Dart)** mobile/web frontend.

```
+-----------------------------------------------------------------------+
|                           FLUTTER FRONTEND                            |
|  +-------------------+   +--------------------+   +----------------+  |
|  | GetX Controllers  |   | UI Layer (Views)   |   | Hive Caching   |  |
|  | (State & Logic)   |---| (M3 + Glassmorphism)|---| (userBox, etc) |  |
|  +-------------------+   +--------------------+   +----------------+  |
+-----------------------------------||-----------------------------------+
                                    || HTTPS / Realtime WSS / JWT
+-----------------------------------\/-----------------------------------+
|                           SUPABASE BACKEND                            |
|  +--------------------+  +--------------------+  +------------------+ |
|  | Supabase Auth      |  | PostgreSQL DB      |  | Supabase Storage | |
|  | (JWT, Argon2/Bcrypt)| | (RLS, RPCs, Triggers)| | (Signed URLs)    | |
|  +--------------------+  +--------------------+  +------------------+ |
+-----------------------------------------------------------------------+
```

---

## 2. Technical Component Mappings

### Core Directories (`notehub/lib/`)
- `lib/controller/`:
  - `auth_controller.dart`: Handles authentication, profile initialization, session state, and Hive sync.
  - `document_controller.dart`: Manages notes/tweets lifecycle, optimistic likes/dislikes, bookmarks, and cross-controller state sync (`_syncWithHome`).
  - `home_controller.dart`: Controls primary feeds, real-time Postgres changes channel listening, pagination (50 items/batch), and official updates feed (limit 20).
  - `profile_controller.dart`: Profile data updates, follow/unfollow logic, and user asset counts.
  - `comment_controller.dart`: Nested comment fetching and thread posting.
  - `upload_controller.dart`: Media uploads, direct PDF file size enforcement (10MB limit), image compression, and external link handling.
- `lib/core/`:
  - `config/color.dart`: Color palette definitions including Premium Deep Blue (`#0D47A1`).
  - `helper/hive_boxes.dart`: Encapsulates Hive local storage (`userBox` for session/profile metadata, `downloadsBox` for offline asset management).
  - `helper/image_helper.dart`: `FlutterImageCompress` utility converting images to 70% quality JPEG format at 1024x1024 max target resolution.
  - `meta/app_meta.dart`: App metadata strings and Supabase URL/Anon Key configurations.
- `lib/service/`:
  - `file_caching.dart`: Caching service leveraging `Dio` and `path_provider` to inspect temporary directory cache before starting new downloads.
- `lib/view/`:
  - UI components categorized into `auth_screen`, `home_screen`, `document_screen`, `upload_screen`, `profile_screen`, `notification_screen`, and shared `widgets` (`DocumentCard`, `PostCard`, `AdminBadge`, `Toasts`).

---

## 3. Performance Analysis

- **Reactive State Management**: GetX observables (`.obs`, `Obx`) decouple domain logic from presentation. State updates trigger localized widget redraws.
- **Local Caching & Offline Speed**: Hive NoSQL key-value store persists user profile metadata (`userBox`), enabling instant app launches without initial blocking network calls. `downloadsBox` tracks local file references.
- **Network & Asset Optimization**:
  - `CachedNetworkImage` prevents duplicate downloads of thumbnails and cover images.
  - `FlutterImageCompress` resizes and compresses user-uploaded images before upload to Supabase Storage.
  - Direct file uploads enforce a strict 10MB limit; external links (e.g., Google Drive, Mega) are supported to conserve network bandwidth.
- **Database Query Efficiency & Atomic Operations**:
  - Atomic counter updates (`likes_count`, `dislikes_count`, `bookmarks_count`) use PostgreSQL Stored Functions (`RPCs`) such as `increment_likes` and `decrement_dislikes`.
  - RPC calls prevent race conditions under high concurrent traffic and remove client-side data calculations.
  - Feed pagination loads items in batches of 50. Official update feeds are constrained to 20 recent records.
- **Perceived Performance**: Shimmer placeholders (`shimmer` package) render immediate visual skeletons during network operations.

---

## 4. Design & UI Paradigm

- **Design System**: Built on Material 3 with a customized **Glassmorphic** visual style.
  - Color Palette: Anchored around **Premium Deep Blue** (`#0D47A1`) to reflect academic excellence for Mumbai University students.
  - Semi-transparent overlays and modern color manipulation using `.withValues(alpha: ...)` ensure precision loss prevention in modern Flutter versions.
  - Custom gradient overlays (`AppGradients.premiumGradient`).
- **Feedback & Micro-interactions**:
  - Lottie vector animations for empty states, loading indicators, and post-upload confirmations.
  - Vector graphics rendered via `flutter_svg`.

---

## 5. Security & Migration Audit

### Authentication & Session Management
- Migrated from custom session-less legacy authentication to **Supabase Auth (JWT)**.
- Passwords are no longer stored or transmitted in plain text, utilizing managed standard hashing algorithms (Argon2/Bcrypt).

### Row Level Security (RLS) & Access Control
- All PostgreSQL tables in `SUPABASE_SCHEMA.sql` enforce Row Level Security:
  - `profiles`: Publicly readable; `INSERT` and `UPDATE` permitted only when `auth.uid() = id`.
  - `documents`: Publicly readable; `INSERT`, `UPDATE`, and `DELETE` restricted to `auth.uid() = user_id`. Admin policies grant administrative update access.
  - `notifications` & `bookmarks`: Restricted exclusively to the recipient/owner user ID.
- **Privilege Escalation Protection**:
  - Profile updates enforce `WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))` to prevent non-admin users from escalating their own privileges via raw update payloads.
  - PostgreSQL trigger `ensure_official_permission` restricts setting `is_official = true` on `documents` to verified admins.
- **RPC Function Security**: Stored functions utilize `SECURITY DEFINER` with explicit `SET search_path = public` to prevent search-path hijacking.

---

## 6. Developer Guide, Maintenance & QA

### System Prerequisites & Stack Versions
- **Flutter SDK**: v3.24+ (Stable Channel)
- **Dart SDK**: ^3.5.4
- **Target OS**: Android (targeting `compileSdk 36`, source & target compatibility Java 17).

### Code Standards & "Zero Warnings" Policy
1. **Color Deprecation**: Use `.withValues(alpha: 0.15)` instead of the deprecated `.withOpacity(...)`.
2. **Switch Controls**: Use `activeThumbColor` instead of the deprecated `activeColor` on Flutter Switch widgets.
3. **Flow Control**: All `if` and `else` statements must use explicit curly braces (`curly_braces_in_flow_control_structures`).
4. **Empty Catches**: Annotate intentional empty catch blocks with `// ignore: empty_catches` on its own line within the catch block.

### Verification & QA Workflow
To run static analysis and verify project health:
```bash
# Navigate to notehub workspace
cd notehub

# Resolve packages
flutter pub get

# Execute static code analysis
flutter analyze

# Run unit and dummy integration test suite
flutter test
```

Visual UI verification can be conducted by launching a web server (`flutter run -d web-server --web-port 8080`) and executing Playwright verification scripts.

---
*Maintained and documented by Jules, Software Engineer.*
