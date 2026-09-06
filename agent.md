# Developer Manual & Architectural Guide — Serious Study (formerly NoteHub)

> **Platform**: Android & Cross-Platform (Flutter Web/Desktop ready)
> **Target Audience**: Core Maintainers, System Architects, & Security Auditors
> **Core Stack**: Flutter 3.24+ | Dart SDK ^3.5.4 | GetX State Management | Hive Local Storage | Supabase (PostgreSQL 15+, Auth JWT, Row Level Security, Realtime, Storage)

---

## 1. Executive Summary & System Architecture

**Serious Study** is a high-performance, community-driven academic platform designed for Mumbai University (MU) students. The application delivers note sharing, peer discovery, academic networking, official university circular distributions, and interactive updates ("tweets").

Originally built on a monolithic legacy stack (Django/MongoDB), the platform was migrated to a serverless **Supabase** backend and modern **Flutter/GetX** frontend. This migration eliminated server maintenance overhead, drastically improved real-time performance, introduced atomic database-level operations, and enforced strict zero-trust security via Row Level Security (RLS).

```
                      +---------------------------------------+
                      |       Flutter Presentation Layer       |
                      | (Material 3 + Glassmorphism + GetX UI) |
                      +-------------------+-------------------+
                                          |
                                          v
                      +---------------------------------------+
                      |          GetX Controller Layer        |
                      |  (AuthController, DocumentController, |
                      |   HomeController, UploadController)   |
                      +---------+-------------------+---------+
                                |                   |
             +------------------+                   +------------------+
             |                                                         |
             v                                                         v
+------------------------+                                +------------------------+
|   Local Cache / Engine |                                |  Supabase Backend Engine|
| (Hive NoSQL + Dio Cache) |                                | (Auth JWT + Realtime)  |
+------------------------+                                +-----------+------------+
                                                                      |
                                                                      v
                                                          +------------------------+
                                                          | PostgreSQL Relational |
                                                          |   Database & RPCs      |
                                                          |   (Row Level Security) |
                                                          +------------------------+
```

---

## 2. Directory Structure & Complete File Mapping

The repository structure follows a strict modular separation of concerns adhering to GetX MVC patterns:

```
.
├── ANALYSIS.md                     # High-level architecture summary
├── CONFLICT_RESOLUTION_GUIDE.md    # Git conflict resolution procedures
├── README.md                       # Project overview & quickstart
├── SUPABASE_GUIDE.md               # Backend setup & deployment guide
├── SUPABASE_SCHEMA.sql             # Idempotent PostgreSQL DDL, RPCs & RLS policies
├── agent.md                        # Primary developer guide & system manual (This document)
└── notehub/                        # Main Flutter Project Root
    ├── pubspec.yaml                # App dependencies (Dart ^3.5.4)
    ├── analysis_options.yaml       # Lint rules enforcing Zero Warnings
    ├── android/                    # Android Native Gradle Project (CompileSDK 36, Java 17)
    ├── assets/                     # Media, Animations (Lottie), Icons, Vectors
    ├── lib/
    │   ├── main.dart               # App entrypoint, Supabase & Hive initialization
    │   ├── layout.dart             # Root scaffold holding Bottom Navigation
    │   ├── controller/             # GetX Controllers (Business Logic)
    │   │   ├── auth_controller.dart
    │   │   ├── bottom_navigation_controller.dart
    │   │   ├── comment_controller.dart
    │   │   ├── connection_controller.dart
    │   │   ├── document_controller.dart
    │   │   ├── download_controller.dart
    │   │   ├── file_controller.dart
    │   │   ├── home_controller.dart
    │   │   ├── notification_controller.dart
    │   │   ├── post_controller.dart
    │   │   ├── profile_controller.dart
    │   │   ├── profile_user_controller.dart
    │   │   ├── remote_config_controller.dart
    │   │   ├── search_controller.dart
    │   │   ├── showcase_controller.dart
    │   │   └── upload_controller.dart
    │   ├── model/                  # Data Models & Adapters
    │   │   ├── document_model.dart
    │   │   ├── mini_user_model.dart
    │   │   ├── post_model.dart
    │   │   ├── user_model.dart
    │   │   └── user_model.g.dart   # Hive TypeAdapter
    │   ├── service/                # Core Utility Services
    │   │   ├── file_caching.dart   # Dio-based local file caching
    │   │   ├── file_download.dart  # Native file download handlers
    │   │   └── notification_service.dart # Local system notifications
    │   ├── core/                   # Design Tokens & Helpers
    │   │   ├── config/
    │   │   │   ├── color.dart      # App Colors & Gradients
    │   │   │   └── typography.dart # Material Typography
    │   │   ├── helper/
    │   │   │   ├── custom_icon.dart
    │   │   │   ├── hive_boxes.dart # Persistent Hive storage utility
    │   │   │   └── image_helper.dart # Asset compression engine
    │   │   └── meta/
    │   │       └── app_meta.dart   # App metadata & Supabase keys
    │   └── view/                   # UI Screens & Reusable Widgets
    │       ├── auth_screen/        # Login/Register UI
    │       ├── bottom_footer/      # Glassmorphism Navigation Bar
    │       ├── connection_screen/  # Peer Connections UI
    │       ├── document_screen/    # Document Viewer & Comment Section
    │       ├── home_screen/        # Main Feed & Shimmer Loaders
    │       ├── notification_screen/ # User Notification Feed
    │       ├── official_screen/    # Official MU Updates Feed
    │       ├── onboarding_screen/  # Welcome Walkthrough
    │       ├── profile_screen/     # User Profile & Showcase Tabs
    │       ├── search_screen/      # Search Page & Filters
    │       ├── settings_screen/    # Settings Drawer & About
    │       ├── splash_screen/      # Branded Startup Splash
    │       ├── upload_screen/      # Document/Link Post Upload Form
    │       └── widgets/            # Generic Components (Cards, Buttons, Badges)
    └── test/
        └── dummy_test.dart         # Unit tests
```

---

## 3. Deep-Dive Performance Analysis

### 3.1 State Management & Reactive UI Execution
- **GetX Architecture**: The app avoids broad UI rebuilds by wrapping dynamic UI regions in fine-grained `Obx()` listeners or `GetBuilder` widgets.
- **Synchronized State**: `DocumentController` manages user interaction triggers (likes, dislikes, bookmarks) and invokes `_syncWithHome()` to update feeds across memory instantly without full API refetches.

### 3.2 Local Persistence & Cold-Start Optimization
- **Hive NoSQL Storage**: User profiles and authentication sessions are cached locally using `Hive` inside `userBox` (`lib/core/helper/hive_boxes.dart`). On cold starts, user details load synchronously from disk before network requests complete, removing loading flicker.
- **Downloaded File Metadata**: File download states and local file paths are stored in `downloadsBox` to grant offline access to cached documents.

### 3.3 Network, Bandwidth & Media Optimization
- **Dio File Caching**: The file caching engine (`lib/service/file_caching.dart`) checks local temporary storage (`getTemporaryDirectory()`) before initiating Dio downloads. If the cached file exists, network execution is skipped.
- **Client-Side Image Compression**: Cover images selected for upload pass through `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`), compressing images to JPEG format at 70% quality (target resolution max 1024x1024), reducing payload size by up to 80%.
- **Batching & Lazy Fetching**: `HomeController` limits document requests to batches of 50 items (`.limit(50)`), sorting items with sticky priority (Official notices pinned first).

### 3.4 Database RPC Atomic Operations
To prevent race conditions during high-concurrency interactions (e.g., thousands of students liking a document simultaneously), counter modifications bypass client increments and execute directly via atomic PostgreSQL RPC functions:
- `increment_likes` / `decrement_likes`
- `increment_dislikes` / `decrement_dislikes`
- `increment_bookmarks` / `decrement_bookmarks`

---

## 4. Design & UI/UX System Analysis

### 4.1 Aesthetic & Visual Identity
- **Material 3 Foundation**: Modern component design with standardized border radii (12–16dp), surface elevation, and color roles.
- **Premium Deep Blue Palette**: Modernized color tokens in `lib/core/config/color.dart`:
  - Primary Theme Color: `#0D47A1` (Deep Blue)
  - Secondary Accent: `#1976D2`
  - Background Gradient: `AppGradients.premiumGradient`
- **Glassmorphism**: Visual depth achieved via semi-transparent layers utilizing `Colors.white.withValues(alpha: 0.15)` combined with backdrop blurs (`BackdropFilter`) in bottom navigation footers (`BottomFooter`) and profile hero cards.

### 4.2 Interactive Feedback & Perception
- **Shimmer Placeholders**: Structural skeleton loaders (`HomeDocumentSection`) prevent visual layout shifts during data hydration.
- **Micro-Animations**: Vector graphics (`flutter_svg`) and custom `Lottie` animations provide delightful feedback during empty search results, upload processing, and error states.

---

## 5. Comprehensive Security & Migration Audit

### 5.1 Threat Matrix & Mitigation Overview

| Security Attribute | Legacy Stack (Django / MongoDB) | Modern Serverless Architecture (Supabase) | Security Impact |
| :--- | :--- | :--- | :--- |
| **Authentication** | Session/Cookie-based custom tokens | Supabase Auth Managed **JWT (JSON Web Tokens)** | Standardized token signatures, automated expiry & token refresh |
| **Password Hashing** | Plain text / Legacy hashes | Industry Standard **Argon2 / Bcrypt** Hashing | Immune to offline rainbow table / brute-force attacks |
| **Data Access Layer** | Exposed API endpoints without strict scoping | PostgreSQL **Row Level Security (RLS)** | Scopes database row access strictly to authentic owners |
| **Role Escalation** | Variable client-side flags | Server-Side Trigger Enforcement & `WITH CHECK` RLS | Prevents unauthorized admin privilege acquisition |
| **Data Mutability** | Direct client-side counter updates | Encapsulated RPCs with `SECURITY DEFINER` | Guarantees atomic counter math, blocking payload spoofing |

### 5.2 Row Level Security (RLS) Policy Audit

Every PostgreSQL table in `SUPABASE_SCHEMA.sql` enforces mandatory Row Level Security (`ENABLE ROW LEVEL SECURITY`):

1. **Profiles Table (`public.profiles`)**:
   - `SELECT`: Public access granted for all authenticated users (`USING (true)`).
   - `INSERT`: Restricts creation to the authenticated owner (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Owner restricted (`USING (auth.uid() = id)`). Privilege escalation on `is_admin` is mitigated via backend policy checks:
     ```sql
     CREATE POLICY "Users can update own profile" ON public.profiles
       FOR UPDATE USING (auth.uid() = id)
       WITH CHECK (
         is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
       );
     ```

2. **Documents Table (`public.documents`)**:
   - `SELECT`: Public read access.
   - `INSERT`: Author constrained (`WITH CHECK (auth.uid() = user_id)`).
   - `UPDATE/DELETE`: Author constrained (`USING (auth.uid() = user_id)`).
   - **Official Flag Security**: Prevented via the `ensure_official_permission` trigger, restricting setting `is_official = true` strictly to profile owners with `is_admin = true`.

3. **Notifications & Bookmarks**:
   - Scoped strictly to the target receiver or owner (`auth.uid() = receiver_id` / `auth.uid() = user_id`).

### 5.3 Function Security & Search Path Isolation
To protect PostgreSQL RPC functions against search-path hijacking vulnerabilities, security definer functions specify explicit search paths:
```sql
CREATE OR REPLACE FUNCTION check_official_permission()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_official = true THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    ) THEN
      RAISE EXCEPTION 'Only administrators can mark documents as official.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 6. Database Schema & Data Models

### 6.1 Entity-Relationship Overview

```
 +------------------------+              +------------------------+
 |    auth.users (System) |              |    public.profiles     |
 +------------------------+              +------------------------+
 | id (UUID, PK)          | <----------  | id (UUID, PK, FK)      |
 | email                  |              | username (TEXT)        |
 +------------------------+              | display_name (TEXT)    |
                                         | institute (TEXT)       |
                                         | is_admin (BOOLEAN)     |
                                         +-----------+------------+
                                                     |
                                                     | 1:N
                                                     v
 +------------------------+              +------------------------+
 |   public.comments      |              |    public.documents    |
 +------------------------+              +------------------------+
 | id (UUID, PK)          |              | id (BIGINT, PK)        |
 | document_id (FK)       | -----------> | user_id (UUID, FK)     |
 | user_id (FK)           |              | name (TEXT)            |
 | content (TEXT)         |              | document_url (TEXT)    |
 | parent_id (UUID, FK)   |              | post_type ('note'/'tweet')
 +------------------------+              | is_official (BOOLEAN)  |
                                         | likes_count (INT)      |
                                         +------------------------+
```

### 6.2 Table Constraints
- `post_type`: Check constraint restricting values to `'note'` or `'tweet'`.
- `document_url` & `document_name`: Nullable to allow native text updates ("tweets") alongside full document uploads.

---

## 7. Developer QA & Maintenance Manual

### 7.1 Development Prerequisites
- **Flutter SDK**: `^3.24.0`
- **Dart SDK**: `^3.5.4`
- **Java Runtime**: JDK 17 (Required for Android Gradle compilation)

### 7.2 Zero Warnings Code Quality Guidelines
The codebase maintains a strict **Zero Warnings** rule under `flutter analyze`. When writing or refactoring code:
1. **Color Opacity Modernization**: Never use `.withOpacity(x)`. Always use the updated Dart SDK API `.withValues(alpha: x)`.
2. **Switch Controls**: Avoid deprecated `activeColor` in `Switch` widgets; use `activeThumbColor`.
3. **Flow Control**: Enforce explicit curly braces for all `if`/`else` control structures (`curly_braces_in_flow_control_structures`).
4. **Silent Exception Annotations**: Place `// ignore: empty_catches` on its own line inside catch blocks to ensure parser integrity.

### 7.3 Testing & Quality Verification Commands
Always run these commands inside `notehub/` before submitting pull requests:

```bash
# 1. Dependency Check
flutter pub get

# 2. Static Analysis Audit (Must return 0 issues)
flutter analyze

# 3. Unit Test Suite Execution
flutter test
```

---
*Maintained and documented by Jules, Software Engineer.*
