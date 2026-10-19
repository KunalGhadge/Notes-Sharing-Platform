# Serious Study (formerly NoteHub) - Developer Architectural & Technical Manual

Welcome to the technical reference and architectural manual for **Serious Study** (formerly NoteHub), the primary academic networking and notes-sharing ecosystem engineered for the Mumbai University student community.

This document serves as an exhaustive, developer-centric guide detailing system architecture, state management patterns, local persistence, design system tokens, database security parameters (RLS/RPCs), performance engineering, and quality assurance standards.

---

## 1. System Overview & Technical Stack

Serious Study has evolved from a legacy server-rendered Django/MongoDB monolith into a modern, decoupled, serverless mobile architecture.

```
+-----------------------------------------------------------------------------------+
|                                 FLUTTER FRONTEND                                  |
|                                                                                   |
|  +-------------------+  +-----------------------+  +---------------------------+  |
|  |  View / UI Layer  |  |  GetX Reactive State  |  |   Local Storage / Cache   |  |
|  | (Material3/Glass) | <-> | (Controllers / Logic) | <-> | (Hive NoSQL Boxes / Dio) |  |
|  +-------------------+  +-----------------------+  +---------------------------+  |
+---------------------------------------^-------------------------------------------+
                                        |  Supabase Flutter SDK (JWT / RPC / Realtime)
                                        v
+-----------------------------------------------------------------------------------+
|                               SUPABASE BACKEND                                    |
|                                                                                   |
|  +-------------------+  +-----------------------+  +---------------------------+  |
|  |   Supabase Auth   |  | PostgreSQL DB (RLS)   |  |     Supabase Storage      |  |
|  | (JWT Auth Engine) |  | (RPCs / Constraints)  |  | (Public/Private Buckets)  |  |
|  +-------------------+  +-----------------------+  +---------------------------+  |
+-----------------------------------------------------------------------------------+
```

### Core Stack Metrics
- **Frontend Framework**: Flutter 3.24+ (Dart SDK `^3.5.4`)
- **State & Dependency Management**: `GetX` (`^4.6.6`)
- **Local Storage / Session Cache**: `Hive` (`^2.2.3`) & `hive_flutter` (`^1.1.0`)
- **Network Operations & Downloads**: `supabase_flutter` (`^2.8.1`), `dio` (`^5.7.0`), `http` (`^1.2.2`)
- **Media Optimization**: `flutter_image_compress` (`^2.3.0`), `cached_network_image` (`^3.4.1`)
- **UI Frameworks & Visuals**: `glassmorphism` (`^3.0.0`), `shimmer` (`^3.0.0`), `flutter_svg` (`^2.0.10+1`), `lottie` (`^3.1.3`)
- **Backend Services**: Serverless Supabase (PostgreSQL 15+, Supabase Auth, Storage, Realtime)

---

## 2. Codebase Structure & Component Mapping

```
notehub/lib/
├── controller/            # Business Logic & GetX Controllers
│   ├── auth_controller.dart            # Registration, login, profile bootstrap, session management
│   ├── document_controller.dart        # Likes, dislikes, bookmarks, document RPC interactions
│   ├── home_controller.dart            # Document feeds, pagination, Realtime sync
│   ├── upload_controller.dart          # Direct & link submissions, file compression, validation
│   ├── profile_controller.dart         # Profile updates, showcase, user documents
│   ├── comment_controller.dart         # Nested comment threads, replies, and posting
│   ├── download_controller.dart        # Offline storage, Dio download management
│   ├── notification_controller.dart  # Activity feed, user notifications
│   ├── search_controller.dart        # Document and user filtering logic
│   └── connection_controller.dart    # Follow/unfollow networking logic
├── core/                  # Configurations, Helpers, & Tokens
│   ├── config/
│   │   ├── color.dart                  # Color tokens, Premium Deep Blue, Glassmorphic gradients
│   │   └── typography.dart             # Google Fonts integration & style scale
│   ├── helper/
│   │   ├── custom_icon.dart            # Custom SVG icon mapping
│   │   ├── hive_boxes.dart             # Hive box definitions (`userBox`, `downloadsBox`)
│   │   └── image_helper.dart           # JPEG image compression (70% quality, max 1024x1024)
│   └── meta/
│       └── app_meta.dart               # App metadata & Supabase API credentials
├── model/                 # Data Models & Serialization
│   ├── document_model.dart             # Note metadata model
│   ├── user_model.dart                 # User profile model & Hive adapter
│   ├── post_model.dart                 # Social/tweet post model
│   └── mini_user_model.dart            # Light profile snapshot
├── service/               # External Services & Native Integrations
│   ├── file_caching.dart               # Local disk cache lookup & Dio downloader
│   ├── file_download.dart              # Platform download handlers
│   └── notification_service.dart       # Local notification triggers
└── view/                  # UI Presentation Layer
    ├── auth_screen/                    # Login, registration, & onboarding views
    ├── home_screen/                    # Main feed, header, & shimmer loaders
    ├── document_screen/                # Document detail, viewer, and comment threads
    ├── upload_screen/                  # Submission forms & administrative toggles
    ├── profile_screen/                 # User showcase, stats, and profile editing
    ├── notification_screen/            # Real-time user alert list
    ├── settings_screen/                # App settings, about page, and legal notes
    └── widgets/                        # Reusable cards, buttons, badges, and toasts
```

---

## 3. Comprehensive Technical Analysis

### 3.1 Performance Engineering
1. **Reactive Micro-Updates with GetX**:
   Controllers act as single sources of truth. Reactive primitives (`RxBool`, `RxList`, `obs`) trigger isolated widget updates without triggering global screen rebuilds.
2. **Local Session Persistence via Hive**:
   User credentials and profile metadata are saved locally in NoSQL Hive boxes (`userBox`). Upon application launch, session verification completes instantaneously without blocking on backend latency.
3. **Optimized Media Pipeline**:
   - Images uploaded as covers are compressed using `ImageHelper.compressImage()` (JPEG quality 70%, 1024x1024 scale), reducing client upload bandwidth.
   - Remote avatars and document thumbnails utilize `CachedNetworkImage` with disk caching to eliminate redundant network fetches.
4. **Lazy Batch Fetching & Sticky Feeds**:
   - The feed in `HomeController` requests documents in paginated batches (limit 50) to optimize response size.
   - Realtime channels listening on `public:documents` handle post additions dynamically without requiring full feed pulls.
5. **Atomic Counter Synchronization via Backend RPCs**:
   User interactions (likes, dislikes, bookmarks) bypass slow client-calculated count updates. Instead, client actions invoke PostgreSQL Remote Procedure Calls (`increment_likes`, `decrement_dislikes`), executing counter updates atomically within the database engine.

### 3.2 Design System & Visual Architecture
1. **Material 3 & Glassmorphism Fusion**:
   - Primary Accent: **Premium Deep Blue** (`#0D47A1`).
   - Glassmorphic Overlays: Translucent backgrounds created using layered `LinearGradient` components with low opacity white values (`.withValues(alpha: 0.15)`).
2. **Standardized Color & Typography Scale**:
   - `PrimaryColor.shade500`: `#0D47A1` (Primary Brand Identity).
   - Dynamic typography configured through `GoogleFonts` in `lib/core/config/typography.dart`.
3. **Visual Feedback & Motion**:
   - Skeleton shimmer loaders (`shimmer` package) maintain visual flow during asynchronous HTTP calls.
   - Vector graphics (`flutter_svg`) and `Lottie` animations display empty and success states cleanly.

### 3.3 Security & RLS Policy Architecture
The migration from Django to Supabase replaced custom API endpoints with database-level constraints and Row Level Security (RLS).

1. **JWT Managed Authentication**:
   All user requests pass JWT tokens generated during authentication (`auth.users`). Passwords are stored securely via Supabase Auth using Argon2/Bcrypt hashing.
2. **Database Row Level Security (RLS)**:
   - `profiles`: Viewable by everyone (`SELECT true`). Updates restricted to profile owners (`auth.uid() = id`).
   - `documents`: Viewable by everyone (`SELECT true`). Insertion/deletion restricted to document owners (`auth.uid() = user_id`). Admin role permissions required for official mark assignment.
   - `interactions` & `bookmarks`: Viewable and modifiable exclusively by the session owner.
3. **Defensive RPC Execution**:
   Counter operations execute under `SECURITY DEFINER` with explicit `SET search_path = public` flags to prevent search-path hijacking attacks.
4. **Privilege Escalation Protection**:
   Updating `is_admin` or setting `is_official` flags on documents requires admin status verified via PostgreSQL triggers and RLS policies.

---

## 4. Backend Database Schema (`SUPABASE_SCHEMA.sql`)

### Key Tables & Constraints
- `profiles`: Stores student attributes (`username`, `display_name`, `institute`, `is_admin`, counts).
- `documents`: Holds note entries (`name`, `topic`, `document_url`, `is_external`, `is_official`, `post_type`). Supports both direct PDF/file uploads and external link references.
- `comments`: Supports nested thread discussions via `parent_id` foreign key references.
- `interactions`: Implements composite unique key `(document_id, user_id)` enforcing single active interaction per user.
- `bookmarks`: Tracks user saved items using `(document_id, user_id)` uniqueness.
- `notifications`: Stores personal and global platform activity alerts.

---

## 5. Maintenance, Testing & QA Protocol

### Prerequisites
- **Flutter SDK**: `^3.24.0`
- **Dart SDK**: `^3.5.4`

### Code Quality & "Zero Warnings" QA Guidelines
1. **Modern Color Opacity API**:
   Do NOT use deprecated `Color.withOpacity(double)`. Always use `Color.withValues(alpha: double)`.
2. **Switch Widget Controls**:
   Do NOT use deprecated `activeColor` on `Switch` widgets. Always use `activeThumbColor`.
3. **Flow Control Braces**:
   Always wrap single-line `if`/`else` control statements in explicit curly braces `{}`.
4. **Silent Catch Annotations**:
   When empty catch blocks are intentionally required, place `// ignore: empty_catches` on its own line inside the catch block.

### Verification Commands
To maintain CI cleanliness and zero-warning compliance, always run the following inside `notehub/`:

```bash
# Run Static Analysis
cd notehub
flutter analyze

# Run Test Suite
flutter test
```

---
*Maintained and documented for Serious Study development team.*
