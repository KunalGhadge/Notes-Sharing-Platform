# Developer System Architecture & Technical Manual - Serious Study (formerly NoteHub)

This document serves as the primary technical system manual and maintenance reference for the **Serious Study** Android application. It provides an in-depth developer-perspective audit covering system architecture, performance engineering, visual design patterns, security parameters, database schema controls, file-by-file component mappings, and quality assurance standards.

---

## 1. Executive Summary & Architecture Overview

### 1.1 Project Context & Evolution
Serious Study is an academic resource and networking platform built specifically for the Mumbai University student community. The application enables note-sharing, academic tweets/discussions, user profiles, document verification, and real-time community engagement.

Originally developed on a legacy Django/MongoDB backend stack, the platform has been completely re-architected into a serverless **Supabase** (PostgreSQL) framework combined with a high-performance **Flutter** frontend.

### 1.2 Core System Stack
| Component | Technology | Technical Purpose |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter 3.24+ (Dart SDK ^3.5.4) | Cross-platform UI compilation targeting Android (compileSdk 36, Java 17). |
| **State Management** | GetX (v4.6.6) | Reactive state management (`RxBool`, `RxList`), dependency injection, and micro-routing. |
| **Local Storage** | Hive (v2.2.3) | Lightweight NoSQL key-value engine (`userBox`, `downloadsBox`) for instant offline launch. |
| **Database & Auth** | Supabase (v2.12.0) | Serverless PostgreSQL with Row Level Security (RLS) and JWT-based Auth services. |
| **File I/O & Caching** | Dio (v5.9.1) & Path Provider | Network file streams, chunked document downloads, and path management. |
| **Media Pipeline** | Flutter Image Compress (v2.4.0) | Client-side JPEG/PNG compression (70% quality, max 1024x1024 resolution). |
| **UI Aesthetics** | Material 3 & Glassmorphism | Custom Deep Blue theme (`#0D47A1`), gradient overlays, and semi-transparent visual hierarchy. |

### 1.3 Architectural Flow Diagram
```
                     +---------------------------------------+
                     |             FLUTTER VIEW              |
                     |  (Widgets / Material 3 Glassmorphism) |
                     +-------------------+-------------------+
                                         |
                                         v
                     +-------------------+-------------------+
                     |           GETX CONTROLLER             |
                     | (DocumentController / AuthController) |
                     +---------+-------------------+---------+
                               |                   |
               Optimistic      |                   | Offline Cache /
               State Update    |                   | Local Storage
                               v                   v
                     +---------+---------+ +-------+---------+
                     | SUPABASE CLIENT   | |  HIVE STORAGE   |
                     | (Postgrest / Auth)| | (userBox /      |
                     +---------+---------+ |  downloadsBox)  |
                               |           +-----------------+
                               v
                     +---------+-------------------+
                     |  SUPABASE POSTGRES BACKEND  |
                     | (RLS Policies / RPCs / Auth)|
                     +-----------------------------+
```

---

## 2. Performance Analysis & Engineering

### 2.1 State Management & Perceived Performance
- **Reactive Decoupling**: Business logic is strictly separated from presentation layers via `GetxController` subclasses (`HomeController`, `DocumentController`, `ProfileController`).
- **Optimistic UI Execution**: Micro-interactions like Liking/Disliking documents and Bookmarking trigger instant state mutations on client-side models (`DocumentModel.isLiked`, `DocumentModel.likes`). If the underlying network RPC fails, the controller automatically rolls back the local state and alerts the user via toast notifications.
- **Cross-Controller State Synchronization**: The `DocumentController` implements `_syncWithHome()` to notify `HomeController` whenever document state changes occur, ensuring unified feed rendering without re-fetching network payloads.

### 2.2 Local Storage & Offline Readiness
- **Hive NoSQL Cache**: Upon app launch, `userBox` hydrates current user metadata (`id`, `username`, `displayName`, `institute`, `profile_url`). This eliminates initial loading latency on the profile and home screens.
- **Download Metadata Tracking**: `downloadsBox` maintains local records of saved PDF documents and external resources, enabling instant offline access without query delays.

### 2.3 Media & Bandwidth Optimization Pipeline
- **Image Compression Pipeline**: Uploaded assets (cover photos and document images) pass through `ImageHelper.compressImage` before network transmission. Photos are re-encoded to JPEG at 70% quality and resized to max dimensions of 1024x1024, preventing storage inflation.
- **Network Image Caching**: UI views utilize `CachedNetworkImage` to cache remote avatar and cover thumbnails on disk, avoiding duplicate download overhead.
- **File Download Handling**: `FileCachingService` leverages `Dio` to download files into temporary app directories, verifying local existence before initiating network downloads.
- **Bandwidth Restrictions**: Upload operations enforce a 10MB direct file size boundary in `UploadController` and support external resource links (Google Drive/Mega) for larger media.

### 2.4 Database Scalability & RPC Counter Operations
- **Atomic Counter RPCs**: To prevent concurrency conflicts and race conditions, document interaction counters (`likes_count`, `dislikes_count`, `followers`, `following`) are modified using dedicated PostgreSQL functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`).
- **Paginated Feed Operations**: `HomeController` fetches feeds in paginated batches (limit 50 per fetch) ordered by sticky parameters (`is_official DESC, created_at DESC`).

---

## 3. Design System & UI/UX Architecture

### 3.1 Visual Theme Paradigm
- **Material 3 Foundation**: Modernized structure leveraging Material 3 color palettes and dynamic typography.
- **Brand Palette**: Styled with "Premium Deep Blue" (`#0D47A1`) as the primary brand identity, representing Mumbai University's academic standard.
- **Glassmorphic Styling**: Custom translucent layers built with `Colors.white.withValues(alpha: ...)` or `Colors.black.withValues(alpha: ...)`, combined with backdrop blurs in top/bottom navbars.

### 3.2 Visual Components & Feedback
- **Shimmer Placeholders**: `Shimmer` skeletons render during data fetching in feed cards (`HomeDocumentSection`) to prevent sudden layout shifts.
- **Lottie Micro-Animations**: Used for state transitions, empty search results, and upload progress feedback.
- **Custom Toast Infrastructure**: Non-blocking toast messages (`Toasts.showTostSuccess`, `Toasts.showTostError`, `Toasts.showTostWarning`) provide contextual alerts.

---

## 4. Security Audit & Row Level Security (RLS) Matrix

### 4.1 Authentication & Password Standards
- **JWT Session Tokens**: Authentication is managed by Supabase Auth using industry-standard JSON Web Tokens (JWT). Client applications store sessions securely using Supabase SDK token refresh flows.
- **Password Protection**: Plaintext credentials are never handled by application backend code; Supabase Auth executes Argon2/Bcrypt password hashing natively.

### 4.2 Database Table & Row Level Security (RLS) Matrix

| Table | SELECT Policy | INSERT Policy | UPDATE Policy | DELETE Policy | Security Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`profiles`** | Public (`true`) | Owner (`auth.uid() = id`) | Owner (`auth.uid() = id`) | System Admin Only | Prevents unauthorized profile modifications. Admin role escalation restricted by `WITH CHECK` clauses. |
| **`documents`** | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner OR Admin (`auth.uid() = user_id` OR `is_admin = true`) | Owner OR Admin | Content verification setting (`is_official`) guarded via `check_official_permission` function. |
| **`comments`** | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | Foreign key cascading handles thread cleanup on document deletion. |
| **`interactions`** | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | Unique composite key `(document_id, user_id)` prevents duplicate voting. |
| **`bookmarks`** | Private Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | None | Owner (`auth.uid() = user_id`) | User bookmark lists remain completely private to each user. |
| **`notifications`**| Receiver Only (`auth.uid() = receiver_id`) | Authenticated System Trigger | Owner (`auth.uid() = receiver_id`) | Owner (`auth.uid() = receiver_id`) | Prevents cross-user notification viewing. |
| **`followers`** | Public (`true`) | Owner (`auth.uid() = follower_id`) | None | Owner (`auth.uid() = follower_id`) | Enforces unique `(follower_id, following_id)` constraints. |

### 4.3 RPC Security Definer & Privilege Escalation Defenses
- **RPC Function Security**: Database stored procedures run under `SECURITY DEFINER` with explicit `SET search_path = public` directives to neutralize search-path hijacking.
- **Admin Escalation Prevention**: `SUPABASE_SCHEMA.sql` incorporates strict checks so users cannot set `is_admin = true` during self-profile update queries. `is_official` document updates require verified `is_admin` status.

---

## 5. File-by-File Codebase Map

### 5.1 Root & Configuration Files
- `README.md`: High-level user overview and repository setup instructions.
- `ANALYSIS.md`: Architectural overview and serverless migration summary.
- `SUPABASE_SCHEMA.sql`: Production DDL defining PostgreSQL tables, indexes, RLS policies, triggers, and RPC counter procedures.
- `agent.md`: Comprehensive system architecture and maintenance manual (this document).

### 5.2 Application Core (`notehub/lib/core/`)
- `lib/main.dart`: Entry point. Initializes Supabase SDK, Hive boxes, and GetX route controllers.
- `lib/layout.dart`: Main shell containing bottom navigation and page switching logic.
- `lib/core/config/color.dart`: Defines color tokens including `PrimaryColor` shades, background gradients (`AppGradients`), and transparent values using `.withValues(alpha: ...)`.
- `lib/core/config/typography.dart`: `AppTypography` text styles scaling across standard display screens.
- `lib/core/meta/app_meta.dart`: Configuration holding branding constants and Supabase API credentials.
- `lib/core/helper/hive_boxes.dart`: Hive persistence helper managing `userBox` and `downloadsBox`.
- `lib/core/helper/image_helper.dart`: Media compression helper utility.
- `lib/core/helper/custom_icon.dart`: SVG icon asset mapping helper.

### 5.3 State Management & Controllers (`notehub/lib/controller/`)
- `auth_controller.dart`: Manages login/registration, session sync, profile retrieval, and Hive user caching.
- `document_controller.dart`: Core document management handling feed fetch, optimistic likes/dislikes/bookmarks, document deletion, and file execution.
- `home_controller.dart`: Controls home feed pagination, official updates, tab filtering, and Postgres Realtime subscription logic.
- `upload_controller.dart`: Document and post upload flow manager (PDF/image selection, cover compression, external URL validation, 10MB limits).
- `profile_controller.dart`: Current user profile state manager handling stats, uploaded resources, saved bookmarks, and profile details updates.
- `profile_user_controller.dart`: Handles secondary public user profile viewing and follower relations.
- `comment_controller.dart`: Nested comment fetching, posting, and reply thread management.
- `notification_controller.dart`: System notification list fetching and mark-as-read updates.
- `search_controller.dart`: Multi-parameter search filter logic across document titles, subjects, and authors.
- `file_controller.dart`: Storage download task state tracking.
- `download_controller.dart`: Downloaded document management and local filesystem listing.
- `connection_controller.dart`: Follower/following network query controller.
- `bottom_navigation_controller.dart`: Bottom navigation bar state tracking.
- `post_controller.dart`: Alternate feed/tweet post management.
- `remote_config_controller.dart`: Dynamic remote parameter sync controller.
- `showcase_controller.dart`: Feature onboarding showcase controller.

### 5.4 Data Models (`notehub/lib/model/`)
- `user_model.dart` & `user_model.g.dart`: Primary user domain model with Hive type adapter serialization (`@HiveType`).
- `document_model.dart`: Document and tweet entity model with interaction flags (`isLiked`, `isDisliked`, `isBookmarked`, `isOfficial`, `postType`).
- `post_model.dart`: Specialized post/tweet model representation.
- `mini_user_model.dart`: Lightweight profile summary model for list items and avatars.

### 5.5 System Services (`notehub/lib/service/`)
- `service/file_caching.dart`: Disk caching service using Dio for efficient file downloads.
- `service/file_download.dart`: Native device download manager handling path providers and storage writing.
- `service/notification_service.dart`: Native local push notifications integration (`flutter_local_notifications`).

### 5.6 Presentation Layer & UI Views (`notehub/lib/view/`)
- `view/home_screen/`: `home.dart`, `widget/home_header.dart`, `widget/home_document_section.dart`.
- `view/upload_screen/`: `upload_screen.dart`, `widget/upload_form.dart`, `widget/upload_button.dart`.
- `view/document_screen/`: `document.dart`, `widget/comment_section.dart`, `widget/comment_tile.dart`, `widget/doc_description.dart`, `widget/icon_viewer.dart`, `widget/follow_button.dart`.
- `view/profile_screen/`: `profile.dart`, `profile_user.dart`, `widget/profile_header.dart`, `widget/profile_showcase.dart`, `widget/post_renderer.dart`, `widget/follower_widget.dart`, `widget/edit_profile_dialog.dart`.
- `view/auth_screen/`: `login.dart`, `widget/login_form.dart`, `widget/login_header.dart`, `widget/login_fields.dart`.
- `view/notification_screen/`: `notifications.dart`.
- `view/search_screen/`: `search.dart`.
- `view/official_screen/`: `official_screen.dart`.
- `view/connection_screen/`: `connection.dart`, `widget/connection_avatar.dart`, `widget/more_options.dart`.
- `view/settings_screen/`: `about.dart`, `settings_drawer.dart`.
- `view/splash_screen/`: `splash.dart`.
- `view/onboarding_screen/`: `onboarding.dart`.
- `view/bottom_footer/`: `bottom_footer.dart`.
- `view/widgets/`: Shared modular UI widgets (`document_card.dart`, `post_card.dart`, `admin_badge.dart`, `loader.dart`, `primary_button.dart`, `secondary_button.dart`, `normal_button.dart`, `option_button.dart`, `refresher_widget.dart`, `toasts.dart`, `upload_text_field.dart`).

### 5.7 Native Platform & Build Configurations
- `notehub/android/app/build.gradle`: Android gradle setup (`compileSdk 36`, `targetSdk 34`, `minSdk 21`, `Java 17` source/target compatibility, `multiDexEnabled true`, `coreLibraryDesugaring`).
- `notehub/pubspec.yaml`: Project metadata, SDK constraint (`^3.5.4`), and dependency definitions.

---

## 6. Development, Testing & Quality Assurance

### 6.1 Requirements & Prerequisites
- **Flutter SDK**: 3.24+
- **Dart SDK**: ^3.5.4
- **Java Development Kit**: JDK 17 (required for Android builds)

### 6.2 Standard Testing & Static Analysis Procedures
- **Static Analysis (Zero Warnings Standard)**:
  Run the static analyzer from the `notehub` directory to verify code compliance:
  ```bash
  cd notehub && flutter analyze
  ```
  *Requirement: Zero warnings/errors must be reported before committing.*

- **Automated Test Execution**:
  Run unit and widget tests:
  ```bash
  cd notehub && flutter test
  ```

- **Application Build Execution**:
  Compile an Android release APK:
  ```bash
  cd notehub && flutter build apk --release
  ```

### 6.3 Zero Warnings Modernization Rules
1. **Color Transparency**: Always use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
2. **Switch Controls**: Always use `activeThumbColor` instead of deprecated `activeColor` on `Switch` widgets.
3. **Flow Control Braces**: Always enclose `if`/`else` statements in explicit curly braces (`{}`).
4. **Catch Annotations**: When using silent catches, place `// ignore: empty_catches` on its own line inside the block to avoid syntax issues.

---
*Analyzed, Modernized, and Documented by Jules, AI Software Engineer.*
