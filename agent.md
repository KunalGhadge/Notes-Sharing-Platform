# Developer Technical Manual & System Guide - Serious Study (NoteHub)

This document serves as the primary system reference manual and technical guide for developers working on **Serious Study** (formerly NoteHub), an academic networking and notes-sharing platform built for the Mumbai University student community.

---

## 1. System Overview & Architecture

Serious Study is built on a serverless, decoupled mobile architecture featuring a **Flutter** frontend for Android and a **Supabase (PostgreSQL)** backend.

```
       +-------------------------------------------------------+
       |                  FLUTTER FRONTEND                     |
       |  GetX Controllers | Hive Local Box | Material 3 & UI  |
       +-------------------------------------------------------+
                                  |
            +---------------------+---------------------+
            | (HTTPS / REST)                            | (Postgres Realtime / WSS)
            v                                           v
+-----------------------+                   +-----------------------+
| Supabase Auth (JWT)   |                   | Supabase Realtime Hub |
+-----------------------+                   +-----------------------+
            |                                           |
            v                                           v
+-------------------------------------------------------------------+
|                     SUPABASE POSTGRESQL DATABASE                  |
|  RLS Policies | SECURITY DEFINER RPCs | Triggers | Public Buckets |
+-------------------------------------------------------------------+
```

### Stack Highlights
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management & DI**: GetX (`GetxController`, `GetX<T>`, `Obx`, `Get.put()`)
- **Local Persistent Storage**: Hive NoSQL (`userBox`, `downloadsBox`)
- **Backend Infrastructure**: Supabase (PostgreSQL, Supabase Auth JWT, Supabase Storage)
- **Network & Asset Operations**: Dio, `path_provider`, `flutter_image_compress`, `cached_network_image`
- **Target OS**: Android (targeting SDK 36, Java 17 compatibility)

---

## 2. Core Performance Analysis

### 2.1 State Management & Reactive UI (GetX)
- Business logic is strictly separated from UI widgets using reactive GetX controllers (`GetxController`).
- Fine-grained reactivity is achieved through `.obs` reactive variables (e.g., `isLoading.value`, `userDocs.value`) and lightweight UI rebuilds using `Obx` and `GetBuilder`.
- State updates between dependent controllers are synchronized cleanly; for instance, `DocumentController._syncWithHome()` triggers `HomeController.update()` to refresh global feed state whenever likes, dislikes, or bookmarks change.

### 2.2 Local Caching Architecture (Hive & Dio)
- **User Session & Profile Caching**: `lib/core/helper/hive_boxes.dart` provides instant app startup by persisting user metadata in `userBox`. Profile details are fetched from Hive without requiring an initial network round-trip.
- **Downloaded File Caching**: Files saved locally are tracked in `downloadsBox` to prevent redundant network requests and manage local storage efficiently.
- **Network File Operations**: `lib/service/file_caching.dart` uses `Dio` and `path_provider` to download documents to the device's temporary directory. Prior to triggering a remote download, the service checks if the target file already exists locally.

### 2.3 Asset Compression & Media Pipeline
- **Image Compression**: `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) automatically compresses user-uploaded images using `flutter_image_compress` to JPEG format at 70% quality before pushing to Supabase Storage.
- **Upload Constraints**: Direct document uploads are constrained to 10MB in `UploadController` to preserve storage capacity and minimize network latency.
- **External Resource Offloading**: Supports sharing external links (Google Drive, Mega, OneDrive) alongside direct uploads, offloading file hosting while retaining resource cataloging.

### 2.4 Query Optimization, Batching & Realtime Synchronization
- **Pagination & Batching**: Feed queries in `HomeController` fetch documents in constrained batches (limit 50) to optimize initial payload size. The official updates feed fetches the top 20 recent official posts (`fetchOfficialUpdates`).
- **Atomic Counter RPCs**: Counter increments/decrements (`likes_count`, `dislikes_count`) are executed atomically via PostgreSQL Functions (RPCs) defined in `SUPABASE_SCHEMA.sql` (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`). This eliminates race conditions during high-concurrency interactions.
- **Postgres Realtime Integration**: `HomeController` subscribes to database changes via `supabase.channel('public:documents').onPostgresChanges(...)`, enabling real-time updates across active user sessions when new content is uploaded.
- **Visual Perceived Performance**: Shimmer placeholders (`shimmer` package) and Lottie feedback animations (`assets/animations/notes.json`) are displayed during network requests to eliminate perceived latency.

---

## 3. Design System & UX Architecture

### 3.1 Design Aesthetic: Material 3 & Glassmorphism
The visual interface follows **Material 3** principles enhanced with **Glassmorphism** overlays:
- **Primary Palette**: Rebranded with "Premium Deep Blue" (`#0D47A1` / `PrimaryColor.shade500`) symbolizing academic integrity and professionalism for the Mumbai University community.
- **Accent Tokens**: Premium Gold (`#FFD700`) and Dark Gold (`#B8860B`) represent official/verified administrative status.
- **Glassmorphic Overlays**: `AppGradients.glassGradient` and `GlassmorphicContainer` create semi-transparent, frosted-glass visual layers over media content.

### 3.2 Typography System
Defined in `lib/core/config/typography.dart` using `google_fonts`:
- `heading1` - `heading6`: Bold display typography for headers and titles.
- `subHead1` - `subHead3`: Medium-weight secondary headings.
- `body1` - `body4`: Regular body text spanning descriptions, metadata, and timestamps.

### 3.3 Component Taxonomy (`lib/view/widgets/`)
- `PostCard`: Media-focused feed card with glassmorphic overlay, author avatar, and interaction buttons.
- `DocumentCard`: Compact card for listing notes and resources with popup action menus (Download, Delete).
- `PrimaryButton` & `SecondaryButton`: Standardized action buttons styled with app theme colors.
- `AdminBadge`: Gold gradient badge (`#FFD700` -> `#FFA500`) rendered for administrator profiles and verified content.
- `RefresherWidget`: Wrapper around `liquid_pull_to_refresh` for pull-to-refresh interactions.
- `Toasts`: Configured using `toastification` for user alerts (success, error, warning).
- `Loader`: Centered circular activity indicator.

---

## 4. Deep Security & Data Integrity Audit

### 4.1 Authentication Architecture
- Managed entirely via **Supabase Auth** utilizing industry-standard JSON Web Tokens (JWT).
- Plain-text passwords are never handled or stored on custom app servers; passwords are hashed using Argon2/Bcrypt via Supabase Auth services.
- Sessions are maintained securely by the Supabase client SDK and synced locally to Hive for offline identification.

### 4.2 Row Level Security (RLS) Database Audit
Every table in `SUPABASE_SCHEMA.sql` has Row Level Security strictly enabled:

| Table | SELECT Policy | INSERT Policy | UPDATE / DELETE Policy |
| :--- | :--- | :--- | :--- |
| `profiles` | Public (All users) | Own row (`auth.uid() = id`) | Own row (`auth.uid() = id`) |
| `documents` | Public (All users) | Own row (`auth.uid() = user_id`) | Own row or Admin (`auth.uid() = user_id` OR admin query) |
| `comments` | Public (All users) | Own row (`auth.uid() = user_id`) | Own row or Admin |
| `interactions` | Public (All users) | Own row (`auth.uid() = user_id`) | Own row (`auth.uid() = user_id`) |
| `bookmarks` | Private to owner | Own row (`auth.uid() = user_id`) | Own row (`auth.uid() = user_id`) |
| `notifications` | Receiver only | Service / Trigger | Receiver only |
| `followers` | Public (All users) | Own row (`auth.uid() = follower_id`)| Own row (`auth.uid() = follower_id`) |

### 4.3 Privilege Escalation Mitigations
- **Profile Admin Status Protection**: The `profiles` table update policy incorporates strict `WITH CHECK` conditions ensuring non-admin users cannot mutate their own `is_admin` boolean flag.
- **Official Content Verification Trigger**: The database includes the `ensure_official_permission` trigger on `public.documents`. If `is_official` is set to `true` during insert or update, the trigger verifies that `auth.uid()` belongs to an administrator in `public.profiles`. If not, an exception is raised.
- **Search Path Hardening**: All PostgreSQL RPC functions defined with `SECURITY DEFINER` explicitly specify `SET search_path = public` to prevent search-path hijacking attacks.

### 4.4 Input Sanitization & Storage Access
- **Storage Policies**: Public storage buckets (`documents`, `covers`, `avatars`) are governed by policies requiring authenticated session ownership for write/delete actions.
- **External URL Validation**: External link resources are validated using `Uri.parse()` and launched safely via `url_launcher` in external application scope (`LaunchMode.externalApplication`).

---

## 5. Exhaustive File-by-File Codebase Mapping

```
lib/
├── main.dart                       # App initialization, Supabase connection, GetX bindings, root MaterialApp
├── layout.dart                     # Main Scaffold with BottomFooter and IndexedStack screen navigation
│
├── controller/                     # GetX Controllers (Business Logic & State)
│   ├── auth_controller.dart        # Supabase Auth operations (Login, Register, Profile fetch & Hive sync)
│   ├── bottom_navigation_controller.dart # Active tab index management
│   ├── comment_controller.dart     # Fetching, posting, and deleting document comments/replies
│   ├── connection_controller.dart  # Managing follow/unfollow relations and connections listing
│   ├── document_controller.dart    # Liking, disliking, bookmarking, deleting documents, opening links
│   ├── download_controller.dart    # Managing downloaded file lists
│   ├── file_controller.dart        # Utility controller for local file access
│   ├── home_controller.dart        # Feed document fetching, real-time channel listeners, search & filter
│   ├── notification_controller.dart # Fetching and marking notifications as read
│   ├── post_controller.dart        # Post lifecycle management
│   ├── profile_controller.dart     # Current user profile data and state management
│   ├── profile_user_controller.dart# External user profile viewing and follow status
│   ├── remote_config_controller.dart# Dynamic app configuration from Supabase remote_config table
│   ├── search_controller.dart      # Filtering notes by name, subject topic, or department
│   ├── showcase_controller.dart    # User profile showcase tabs (uploaded docs vs. bookmarked docs)
│   └── upload_controller.dart      # Multi-part resource upload, compression, and administrative flags
│
├── model/                          # Data Models
│   ├── document_model.dart         # Core model representing notes, tweets, links, and interaction metadata
│   ├── mini_user_model.dart        # Lightweight user reference model
│   ├── post_model.dart             # Social post data model
│   ├── user_model.dart             # Hive-annotated user profile model
│   └── user_model.g.dart           # Auto-generated Hive type adapter for UserModel
│
├── service/                        # Infrastructure Services
│   ├── file_caching.dart           # Local temporary storage caching using Dio and path_provider
│   ├── file_download.dart          # Local file download manager with Android notifications integration
│   └── notification_service.dart   # Local notification channel setup and notification triggers
│
├── core/                           # System Configurations & Helpers
│   ├── config/
│   │   ├── color.dart              # Color design tokens (Primary Deep Blue, Grayscale, AppGradients)
│   │   └── typography.dart         # Typography definitions using GoogleFonts
│   ├── helper/
│   │   ├── custom_icon.dart        # SVG and custom asset rendering utilities
│   │   ├── hive_boxes.dart         # Access layer for 'userBox' and 'downloadsBox' Hive storage
│   │   └── image_helper.dart       # Image compression helper using flutter_image_compress
│   └── meta/
│       └── app_meta.dart           # Centralized metadata (appName, Supabase credentials, avatar URL base)
│
└── view/                           # Modular UI Screens & Widgets
    ├── auth_screen/
    │   ├── login.dart              # Main authentication screen wrapper
    │   └── widget/
    │       ├── login_fields.dart   # Email, password, and name text form fields
    │       ├── login_form.dart     # Form layout and action buttons (Login / Register toggle)
    │       └── login_header.dart   # Branding logo and welcome text header
    ├── bottom_footer/
    │   └── bottom_footer.dart      # Floating bottom navigation bar with active tab indicators
    ├── connection_screen/
    │   ├── connection.dart         # Followers and Following list screen
    │   └── widget/
    │       ├── connection_avatar.dart # User tile avatar widget
    │       └── more_options.dart   # Connection action sheet
    ├── document_screen/
    │   ├── document.dart           # Detailed document view page
    │   └── widget/
    │       ├── comment_section.dart# Comment feed with reply capability
    │       ├── comment_tile.dart   # Individual comment card with nested reply indenting & admin badges
    │       ├── doc_description.dart# Resource title, description, and metadata card
    │       ├── follow_button.dart  # Reactive follow/unfollow toggle button
    │       └── icon_viewer.dart    # Cover thumbnail / icon viewer modal
    ├── home_screen/
    │   ├── home.dart               # Primary dashboard feed screen
    │   └── widget/
    │       ├── home_document_section.dart # Document list container with shimmer loading state
    │       └── home_header.dart    # Dashboard header displaying greeting, MU location, and search icon
    ├── notification_screen/
    │   └── notifications.dart      # Real-time activity notifications list
    ├── official_screen/
    │   └── official_screen.dart    # Filtered feed showcasing verified administrative / official updates
    ├── onboarding_screen/
    │   └── onboarding.dart         # App feature introduction screen
    ├── profile_screen/
    │   ├── profile.dart            # Current user's profile view
    │   ├── profile_user.dart       # External user profile view
    │   └── widget/
    │       ├── edit_profile_dialog.dart # Modal dialog for updating bio, institute, and name
    │       ├── follower_widget.dart# Follower/Following numerical stats counter
    │       ├── post_renderer.dart  # Grid/List renderer for profile posts
    │       ├── profile_header.dart # User profile header card with avatar border
    │       └── profile_showcase.dart# Tabbed view switching between 'Uploaded Docs' and 'Saved'
    ├── search_screen/
    │   └── search.dart             # Real-time search page filtering by topic and title
    ├── settings_screen/
    │   ├── about.dart              # Serious Study community vision and developer attribution page
    │   └── settings_drawer.dart    # App settings, theme toggle, and logout drawer
    ├── splash_screen/
    │   └── splash.dart             # Animated splash screen with Lottie animation and auth redirect
    ├── upload_screen/
    │   ├── upload_screen.dart      # Resource creation screen wrapper
    │   └── widget/
    │       ├── upload_button.dart  # File picker trigger button
    │       └── upload_form.dart    # Input form for notes/tweets, file attachment, and official toggle
    └── widgets/                    # Reusable Global Components
        ├── admin_badge.dart        # Gold administrative verification badge
        ├── document_card.dart      # Feed document card with action menus
        ├── loader.dart             # Standard circular progress indicator
        ├── normal_button.dart      # Generic button widget
        ├── option_button.dart      # Choice button control
        ├── post_card.dart          # Rich card widget with glassmorphism preview
        ├── primary_button.dart     # App primary blue action button
        ├── refresher_widget.dart   # Liquid pull-to-refresh wrapper
        ├── secondary_button.dart   # Secondary outline button widget
        ├── toasts.dart             # Toastification alert helper
        └── upload_text_field.dart  # Styled input field for resource submission forms
```

---

## 6. Developer Maintenance, Build Setup & QA Guidelines

### 6.1 Prerequisites & System Environment
- **Flutter SDK**: `^3.24.0` (Stable channel)
- **Dart SDK**: `^3.5.4`
- **Java Development Kit**: JDK 17

### 6.2 Android Build Configuration (`android/app/build.gradle`)
- **Namespace**: `com.divinevisionary.notehub`
- **Compile SDK**: `36`
- **Target SDK**: `36`
- **Java / Kotlin Target Compatibility**: `JavaVersion.VERSION_17` / JVM target `17`
- **Core Library Desugaring**: Enabled (`com.android.tools:desugar_jdk_libs:2.1.4`) to support modern Java APIs required by `flutter_local_notifications`.
- **MultiDex**: Enabled (`multiDexEnabled true`).

### 6.3 Zero-Warning Code Quality Policy
All code modifications must maintain a strict **Zero Warnings** standard under `flutter analyze`:
1. **Switch Widgets**: Use `activeThumbColor` instead of the deprecated `activeColor` property.
2. **Color Manipulation**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)` method.
3. **Flow Control**: Enclose all `if`, `else`, and loop control structures in explicit curly braces (`{ ... }`).
4. **Error Handling**: Silent catch blocks must include explicit comments (`// ignore: empty_catches`) placed cleanly within the catch block.

### 6.4 QA & Testing Procedures
To verify codebase integrity before committing changes:
```bash
# Navigate to the Flutter project root
cd notehub

# Execute static analysis check (Must return "No issues found!")
flutter analyze

# Execute automated test suite
flutter test
```

---
*Analyzed, Modernized, and Documented by Jules, AI Software Engineer.*
