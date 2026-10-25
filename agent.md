# Developer Technical Guide & System Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-centric technical analysis and maintenance manual for **Serious Study** (formerly NoteHub), a notes-sharing and academic community application for Mumbai University students.

---

## 1. Executive Summary & System Overview
Serious Study is a cross-platform mobile application engineered specifically for the Mumbai University student ecosystem. The platform enables students to publish academic resources (PDF notes, study links, image sets) as well as short updates ("tweets"), follow peers, interact via threaded comments, bookmark documents, and receive real-time updates.

### System Evolution
The codebase underwent a complete architectural migration from a legacy Django/MongoDB backend to a serverless **Supabase** infrastructure backed by **PostgreSQL** and **Flutter (3.24+ / Dart 3.5.4+)**. This transition eliminated custom authentication vulnerabilities, unlocked database-level Row Level Security (RLS), and introduced real-time WebSocket subscriptions.

---

## 2. System Architecture & Component Mapping

Serious Study follows a decoupled, reactive **MVC-like architecture** powered by **GetX** for dependency injection, route management, and state propagation.

```
lib/
├── controller/          # GetX Business Logic Controllers (16 controllers)
├── core/                # System Configurations, Meta, and Helpers
│   ├── config/          # Color palettes and Typography scale
│   ├── helper/          # Hive local storage boxes, image helpers, custom icons
│   └── meta/            # App metadata and Supabase credentials
├── model/               # Data Models & Generated Hive Adapters
├── service/             # Caching, Downloading, and Notification Services
└── view/                # UI Screens & Modular Widgets
```

### 2.1 File-by-File Core Component Mapping

#### App Lifecycle & Frame
- **`lib/main.dart`**: Core entry point. Initializes Supabase SDK with client credentials from `AppMetaData`, configures Hive local storage boxes, and injects global GetX bindings.
- **`lib/layout.dart`**: Main application shell incorporating the floating Glassmorphic bottom navigation footer (`BottomFooter`) and indexed screen switcher.

#### State Controllers (`lib/controller/`)
- **`auth_controller.dart`**: Manages authentication (Email/Password registration and login), profile sync, and local session storage in `HiveBoxes`.
- **`document_controller.dart`**: Controls document lifecycle operations (fetching, liking/disliking, bookmarking, file opening/launching, and deletion). Implements optimistic UI updates with automatic rollback on network failure.
- **`home_controller.dart`**: Manages the main document feed with paginated fetching (50 items per query), official resource updates, sticky timestamp sorting, and real-time Supabase Postgres channel subscriptions.
- **`upload_controller.dart`**: Handles resource publishing for both direct file uploads (10MB limit enforcement) and external link sharing (Google Drive, Mega), including cover image picking and compression.
- **`profile_controller.dart` & `profile_user_controller.dart`**: Fetches user profile metadata, handles follow/unfollow interactions, and updates local `userBox` cache.
- **`comment_controller.dart`**: Controls multi-level nested comment rendering, posting, and deletion logic.
- **`notification_controller.dart`**: Powers real-time user notification feeds and unread badge counters.
- **`search_controller.dart`**: Handles search query execution across document titles, topics, and authors.
- **`connection_controller.dart`**: Manages user followers and following relationships.
- **`download_controller.dart` & `file_controller.dart`**: Tracks local file download states and storage interactions.
- **`remote_config_controller.dart`**: Fetches dynamic remote app configurations without requiring client rebuilds.
- **`showcase_controller.dart`**: Manages user profile grid views (uploaded posts vs. saved/bookmarked posts).
- **`bottom_navigation_controller.dart`**: Reactive state for bottom navigation tab selection.

#### Data Models (`lib/model/`)
- **`document_model.dart`**: Representation of notes and tweets (ID, title, topic, description, URLs, likes/dislikes counters, flags like `isExternal`, `isOfficial`, `postType`).
- **`user_model.dart` & `mini_user_model.dart`**: Encapsulates profile data, academic institute, stats (followers, following, uploaded docs count), and admin privileges (`isAdmin`).
- **`post_model.dart`**: Auxiliary data container for feed posts.

#### Low-Level Services (`lib/service/`)
- **`file_caching.dart`**: Handles Dio-based HTTP file downloading with local temp file check before initiating network requests.
- **`file_download.dart`**: Manages download notifications using `flutter_local_notifications` and saves files to persistent local device storage via `path_provider`.
- **`notification_service.dart`**: Integrates native push/local notifications for device alerts.

#### Native Android Configuration (`android/`)
- **`android/app/build.gradle`**: Configured with `compileSdk 36`, `Java 17` source/target compatibility, `multiDexEnabled true`, and `coreLibraryDesugaring` to support native Android local notification plugins.

---

## 3. Performance Analysis

### 3.1 State Management Optimization
- **GetX Reactive Binding**: Minimizes widget rebuild overhead by using fine-grained `Obx` and `GetX` listeners rather than global full-tree `setState`. UI rebuilds occur exclusively when specific reactive primitives (`RxBool`, `RxList`, `Rxn`) emit changes.

### 3.2 High-Performance Caching (Hive & Memory)
- **Hive NoSQL Storage**:
  - `userBox`: Stores user profile metadata (`UserModel`) locally (`lib/core/helper/hive_boxes.dart`). This enables instant cold-boot app rendering without waiting for network authentication handshake.
  - `downloadsBox`: Caches downloaded document metadata to allow offline access to previously fetched PDF files.

### 3.3 Network & Asset Compression Pipeline
- **Image Compression**: `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) uses `flutter_image_compress` to compress uploaded cover images to JPEG format at 70% quality target prior to cloud submission, conserving storage bandwidth and upload time.
- **Network Image Caching**: `CachedNetworkImage` is used across all feed items (`PostCard`, `HomeHeader`) to prevent redundant image downloads and reduce mobile data consumption.

### 3.4 Backend Scalability & Atomic Counters
- **PostgreSQL Database RPCs**: Race conditions during concurrent user interactions (e.g., simultaneous liking/disliking) are prevented by delegating counter increments and decrements to PostgreSQL Remote Procedure Calls (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`) defined in `SUPABASE_SCHEMA.sql`.
- **Paginated Batching**: `HomeController` fetches posts in batches of 50 using sticky timestamp ordering (`order('created_at', ascending: false)`), keeping initial data payloads small even as document volume scales.
- **Postgres Realtime Integration**: Uses `supabase.channel('public:documents').onPostgresChanges(...)` to stream real-time updates directly over WebSockets, avoiding aggressive client-side polling loops.

---

## 4. Visual Design & System UI/UX

### 4.1 UI Paradigm & Design Tokens
- **Design System**: Built upon **Material 3** principles combined with **Glassmorphism** visual overlays.
- **Color Palette (`lib/core/config/color.dart`)**:
  - Primary Brand Accent: **Premium Deep Blue** (`#0D47A1` / `PrimaryColor.shade500`).
  - Dark Grayscale / Surface: `GrayscaleBlackColors.almostBlack` (`#111111`).
  - Premium Admin Badging: Gold Linear Gradient (`#FFD700` to `#FFA500`).
  - Danger / Error Accent: `DangerColors.shade500` (`#FF3728`).
- **Typography Scale (`lib/core/config/typography.dart`)**: Standardized font scale utilizing `google_fonts` (Plus Jakarta Sans / Inter style) for clean academic readability across headers, body, and subtexts.

### 4.2 Micro-Interactions & Loading States
- **Glassmorphism Components**: Custom `GlassmorphicContainer` wrappers used in `PostCard` overlay titles and `BottomFooter` floating menus using `AppGradients.glassGradient`.
- **Shimmer Placeholders**: `shimmer` package implemented in `HomeDocumentSection` and `ProfileUser` to render smooth loading skeletons during async data fetch operations.
- **Lottie Vector Animations**: Lottie animations (`assets/animations/notes.json`) provide clean feedback during splash boot sequences and empty state displays.

---

## 5. Security & Row Level Security (RLS) Audit

### 5.1 Authentication & Password Security
- **Supabase Auth (JWT)**: Replaced legacy plain-text session authentication with standard JSON Web Tokens (JWT). Passwords are never exposed or transmitted in plain text and are salted and hashed by Supabase using **Bcrypt/Argon2**.

### 5.2 Row Level Security (RLS) Policy Breakdown

Every PostgreSQL table in `SUPABASE_SCHEMA.sql` enforces strict RLS policies:

```sql
-- Profiles Table Security
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
  );
```

- **Preventing Self-Privilege Escalation**: The `profiles` `UPDATE` policy includes a `WITH CHECK` clause ensuring users cannot alter their own `is_admin` column value during profile updates.
- **Document Access Control**: `documents` table allows public `SELECT` access, but restricts `INSERT`, `UPDATE`, and `DELETE` operations strictly to the owner (`auth.uid() = user_id`) or verified admins (`is_admin = true`).
- **Official Content Verification Protection**: A PostgreSQL trigger `check_official_permission` verifies that setting `is_official = true` on a document is restricted to users holding `is_admin = true` status in `public.profiles`.

### 5.3 Function Security & Search Path Hijacking Mitigation
- Stored PostgreSQL RPC functions use explicit `SECURITY DEFINER` modifiers along with `SET search_path = public` to prevent search-path hijacking vulnerabilities during function execution.

---

## 6. QA Guidelines & Zero Warnings Maintenance

### 6.1 Prerequisites
- **Flutter SDK**: ^3.24.0 (Stable channel)
- **Dart SDK**: ^3.5.4

### 6.2 Codebase Quality & Analysis Rules
To maintain the "Zero Warnings" standard enforced across CI/CD:
1. **Color Opacity Modernization**: Never use deprecated `.withOpacity(double)`. Always use modern Dart 3.5.4+ `.withValues(alpha: double)` (e.g., `Colors.black.withValues(alpha: 0.1)`).
2. **Switch Controls**: Switch widgets must use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Compliance**: Always enclose `if` / `else` statements in explicit curly braces (`curly_braces_in_flow_control_structures`).
4. **Empty Catch Blocks**: Empty `catch` blocks must include the explicit line annotation `// ignore: empty_catches` on its own line inside the block to avoid syntax corruption.
5. **Auth Controller Syntax Integrity**: Regularly check `lib/controller/auth_controller.dart` to verify that no invalid string prefixes exist prior to import statements.

### 6.3 QA Commands
Run the following commands before submitting any pull request:

```bash
# Execute static analysis check
cd notehub && flutter analyze

# Execute full test suite
cd notehub && flutter test
```

---
*Analyzed, Modernized, and Documented by Jules, AI Software Engineer.*
