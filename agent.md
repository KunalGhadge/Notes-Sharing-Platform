# Serious Study (formerly NoteHub) - Developer Technical Guide & Maintenance Manual

This document serves as the primary system manual, developer guide, and architectural reference for the **Serious Study** platform (Mumbai University notes-sharing and academic networking ecosystem).

---

## 1. Executive Summary & Architecture Blueprint

Serious Study is built on a modern, serverless architecture featuring a **Flutter** client (targeting Android, iOS, and Web) integrated with **Supabase** (PostgreSQL) as the backend-as-a-service. The legacy Django/MongoDB backend was fully decommissioned in favor of this serverless model.

```
                  +-------------------------------------------------+
                  |                 Flutter Client                  |
                  |               (Dart SDK ^3.5.4)                 |
                  +-----------------------+-------------------------+
                                          |
                +-------------------------+-------------------------+
                |                                                   |
     +----------v----------+                             +----------v----------+
     |   GetX Controllers  |                             |   Hive Persistent   |
     | (State & Logic Ops) |                             | Local Storage Cache |
     +----------+----------+                             +---------------------+
                |
     +----------v----------+
     | Supabase Client SDK |
     +----------+----------+
                |
     +----------v---------------------------------------------------+
     |                      Supabase Backend                        |
     |  +-----------------------+     +--------------------------+  |
     |  |   PostgreSQL + RLS    |     | Supabase Auth (JWT)      |  |
     |  +-----------------------+     +--------------------------+  |
     |  |   Supabase Storage    |     | Postgres Realtime Engine |  |
     |  +-----------------------+     +--------------------------+  |
     +--------------------------------------------------------------+
```

### Key Technical Pillars
- **Frontend Paradigm**: Decoupled MVC-like reactive state management powered by **GetX** (`GetxController`, `Rx`, `Obx`).
- **Local Persistence & Offline First**: Key-value NoSQL caching via **Hive** (`userBox`, `downloadsBox`) ensuring instant UI startup.
- **Serverless Core**: **Supabase** managing authentication (JWT), real-time database changes, RPC functions, and storage bucket policies.
- **Design System**: **Material 3** with a **Glassmorphism** visual language and "Premium Deep Blue" theme palette (`#0D47A1`).

---

## 2. Directory & File Structure Mapping

The codebase is structured under `notehub/lib/` according to clear separation of concerns:

```
notehub/lib/
├── controller/                 # Business logic and GetX reactive state management
│   ├── auth_controller.dart           # Supabase Auth, session sync, profile creation
│   ├── bottom_navigation_controller.dart # Bottom bar active index management
│   ├── comment_controller.dart        # Nested threaded comments & replies
│   ├── connection_controller.dart     # Network connectivity listener
│   ├── document_controller.dart       # Likes, bookmarks, RPC calls, optimistic updates
│   ├── download_controller.dart       # Local file downloads & metadata tracking
│   ├── file_controller.dart           # File picker & asset selection stream
│   ├── home_controller.dart           # Main document feed, real-time channels, batching
│   ├── notification_controller.dart   # System & user notification feeds
│   ├── post_controller.dart           # Micro-blogging ('tweets') post management
│   ├── profile_controller.dart        # Current user profile & documents feed
│   ├── profile_user_controller.dart   # External user profiles & follow/unfollow actions
│   ├── remote_config_controller.dart  # Dynamic feature flags from remote_config table
│   ├── search_controller.dart         # Multi-field document search & category filters
│   ├── showcase_controller.dart       # First-run onboard showcase guidance
│   └── upload_controller.dart         # File/link/post uploads & image compression
├── core/                       # Core configurations, constants, and helpers
│   ├── config/
│   │   └── color.dart                 # Primary palette, gradients, translucent overlays
│   ├── helper/
│   │   ├── hive_boxes.dart            # Hive box definitions & access methods
│   │   └── image_helper.dart          # Image compression pipeline (flutter_image_compress)
│   └── meta/
│       └── meta.dart                  # App constants, version numbers, university defaults
├── model/                      # Data models and JSON serializers
│   ├── comment_model.dart             # Comment schema & child reply hierarchy
│   ├── document_model.dart            # Academic document & post metadata
│   ├── notification_model.dart        # Notification payload schema
│   └── user_model.dart                # Profile & user stats model
├── service/                    # Infrastructure services
│   ├── file_caching.dart              # Dio-based local file download & caching
│   ├── file_download.dart             # Persistent storage file download manager
│   └── notification_service.dart      # flutter_local_notifications system tray engine
├── view/                       # Modular UI views and screens
│   ├── auth_screen/                   # Login & registration views
│   ├── bottom_footer/                 # Custom glassmorphic bottom navigation bar
│   ├── document_screen/               # Document detail screen, PDF viewer, comment section
│   ├── home_screen/                   # Main feed, header, official announcements, document list
│   ├── notification_screen/           # User notification center
│   ├── profile_screen/                # Current user profile, external profile, stats
│   ├── search_screen/                 # Real-time search UI & category filter chips
│   ├── settings_screen/               # App settings, about page, theme options
│   ├── splash_screen/                 # Initial loading & auth state verification
│   ├── upload_screen/                 # Multi-type creation form (note/link/tweet)
│   └── widgets/                       # Shared reusable UI widgets (DocumentCard, PostCard, AdminBadge, Toasts)
├── layout.dart                 # Root shell hosting BottomFooter and current active tab view
└── main.dart                   # Application entry point initializing Hive, Supabase, and GetX
```

---

## 3. Deep-Dive Performance Analysis

### 3.1 State Management & UI Binding Efficiency
- **Reactive UI Rendering**: GetX reactive primitives (`.obs`, `Obx`) are strategically scoped to minimal subtree widgets (e.g., individual action buttons on `DocumentCard` or counter badges on `HomeHeader`) rather than rebuilding whole screen widgets.
- **Optimistic State Updates**: `DocumentController` updates local interaction states (likes count, bookmark status) instantly on user tap before dispatching network calls to Supabase. If the remote operation fails, state is silently rolled back, providing zero input latency.
- **Synchronized View States**: `DocumentController._syncWithHome()` propagates document changes directly to `HomeController` lists in memory, ensuring cross-screen consistency without initiating duplicate network refetches.

### 3.2 Persistent Caching Strategy
- **Hive NoSQL Key-Value Engine**: User profile metadata is stored in `userBox` (`lib/core/helper/hive_boxes.dart`), allowing the app to launch into an authenticated state immediately without waiting for network authentication checks.
- **Download Metadata**: File download records and local storage paths are cached in `downloadsBox` to enable instant offline access verification.

### 3.3 File Caching & Network Optimization
- **Dio Caching Pipeline**: `FileCaching` (`lib/service/file_caching.dart`) checks `path_provider` temporary directories before requesting downloads. If a document already exists locally, the network step is skipped.
- **Asset Compression Engine**: `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) compresses uploaded thumbnails to JPEG format at 70% quality with a maximum target dimension of 1024x1024. This reduces bandwidth consumption by up to 80% during file uploads.
- **Batching & Cap Limits**: `HomeController` limits feed fetches to 50 items with sticky sorting (`created_at` descending) and caps official update fetches to the 20 most recent announcements (`fetchOfficialUpdates`), preventing memory bloating during feed scrolling.

### 3.4 Database Query Optimization
- **Atomic PostgreSQL RPCs**: Interaction operations (likes, dislikes, bookmarks) execute via server-side PostgreSQL functions (`increment_likes`, `decrement_likes`, etc.). This eliminates race conditions, prevents payload overhead, and executes as single atomic transactions on the database cluster.

```
User Action -> GetX Optimistic UI -> PostgreSQL RPC -> Single Atomic UPDATE -> Postgres Realtime Broadcast
```

---

## 4. Design & UI/UX Architecture

### 4.1 Visual Identity & Color Palette
- **Material 3 Paradigm**: Uses clean Material 3 design elements, flexible card layouts, and refined typography (`google_fonts`).
- **Premium Deep Blue Theme**:
  - Primary Accent: `#0D47A1` (Deep Blue)
  - Surface Overlays: Translucent whites (`Colors.white.withValues(alpha: 0.15)`) for Glassmorphism depth effects.
  - Dark/Light Theme Support: Dynamic color mapping defined in `lib/core/config/color.dart`.

### 4.2 UI Component Hierarchy
- **`DocumentCard` & `PostCard`**: Specialized card widgets engineered for high scroll performance. Modernized using `.withValues(alpha: ...)` to guarantee compatibility with Dart SDK 3.5.4+.
- **`AdminBadge`**: Displays an official verification badge for platform admins and verified university notices.
- **Micro-Interactions**: Features `Lottie` animations for empty feed states and customized `Toastification` toasts for user feedback.

---

## 5. Security Analysis & Vulnerability Audit

### 5.1 Authentication & Token Lifecycle
- **JWT Authorization**: Authenticated sessions are managed through **Supabase Auth**. Cryptographic JWTs are embedded in HTTP authorization headers for every Supabase database request.
- **Argon2/Bcrypt Password Security**: Raw credentials are never processed or stored by client application logic; password hashing and session generation are handled entirely by Supabase Auth backend infrastructure.

### 5.2 Row Level Security (RLS) Policy Matrix

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `profiles` | Public (`true`) | Authenticated (`auth.uid() = id`) | Owner Only (`auth.uid() = id`) | Restricted |
| `documents` | Public (`true`) | Authenticated (`auth.uid() = user_id`) | Owner/Admin (`auth.uid() = user_id` OR `is_admin`) | Owner/Admin |
| `comments` | Public (`true`) | Authenticated (`auth.uid() = user_id`) | Owner Only (`auth.uid() = user_id`) | Owner Only |
| `interactions` | Public (`true`) | Authenticated (`auth.uid() = user_id`) | Owner Only | Owner Only |
| `bookmarks` | Private (`auth.uid() = user_id`) | Authenticated (`auth.uid() = user_id`) | Owner Only | Owner Only |
| `notifications` | Receiver (`auth.uid() = receiver_id`) | Authenticated (`auth.uid() = sender_id`) | Receiver Only | Receiver Only |

### 5.3 Privilege Escalation Protections
1. **Profile Role Protection**: To prevent unauthorized users from escalating their own privileges via `UPDATE profiles SET is_admin = true`, the database update policy enforces a `WITH CHECK` validation:
   ```sql
   CREATE POLICY "Users can update own profile" ON public.profiles
     FOR UPDATE USING (auth.uid() = id)
     WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
   ```
2. **Official Verification Protection**: Setting `is_official = true` on academic documents is restricted via the `ensure_official_permission` trigger, which validates that `auth.uid()` belongs to an administrator prior to commit.
3. **RPC Search Path Isolation**: All PostgreSQL RPC functions specify `SECURITY DEFINER SET search_path = public` to prevent search path hijacking attacks.

---

## 6. Development, Testing & Maintenance Manual

### 6.1 Prerequisites & Environment Setup
- **Flutter SDK**: `>=3.24.0`
- **Dart SDK**: `^3.5.4`
- **Android Configuration**:
  - `compileSdk`: `36`
  - Java Version: `Java 17`
  - Enabled Features: `multiDexEnabled true`, `coreLibraryDesugaring` for system notification support.

### 6.2 "Zero Warnings" Code Quality Enforcement
To maintain repository standards:
1. **Flow Control**: All `if`/`else` control structures must utilize explicit curly braces.
2. **Deprecation Compliance**:
   - Use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)` calls.
   - Use `activeThumbColor` instead of deprecated `activeColor` in `Switch` widgets.
3. **Empty Catches**: Any intentional silent catch block must include `// ignore: empty_catches` on its own dedicated line inside the catch block.

### 6.3 QA & Static Analysis Execution
Run the following commands in `notehub/` before submitting pull requests:
```bash
# Execute static analysis
flutter analyze

# Run complete test suite
flutter test
```

### 6.4 Database Migrations
All schema updates must be performed idempotently via `SUPABASE_SCHEMA.sql`. Use `ADD COLUMN IF NOT EXISTS` and `CREATE TABLE IF NOT EXISTS` statements to allow seamless database migration across development and production environments.

---
*Maintained and verified by Jules, AI Software Engineer.*
