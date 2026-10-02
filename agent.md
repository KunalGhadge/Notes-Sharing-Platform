# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-perspective technical analysis of the **Serious Study** Android application. It serves as the primary engineering reference manual, detailing performance optimizations, UI/UX design architecture, database and application security, native Android configurations, and QA guidelines following the platform's migration to a serverless **Supabase** backend.

---

## 1. System Overview & Technical Stack

**Serious Study** is an academic networking and resource-sharing platform engineered specifically for the Mumbai University student community. The platform enables students and faculty to share verified study materials, lecture notes, previous year question papers (PYQs), important question sets (IMPs), and official university announcements.

### Architectural Stack Summary
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management & DI**: GetX (Reactive state management, dependency injection, and smart routing).
- **Local Storage / Caching**: Hive NoSQL database (low-latency session & download tracking).
- **Backend Infrastructure**: Supabase (Serverless PostgreSQL, Managed Auth, Object Storage, Realtime).
- **HTTP & File Processing**: Dio & Supabase Client SDK for optimized API and file streaming.

---

## 2. In-Depth Performance Analysis

### 2.1 Reactive State Management (GetX)
The application avoids heavy widget rebuilds by decoupling business logic into reactive GetX controllers. Rebuilds are scoped tightly using `Obx`, `GetX`, and `GetBuilder` widgets.

- **Controller Lifecycle Management**: Controllers are registered lazily or on-demand (`Get.put()`, `Get.lazyPut()`) and tied to screen lifecycles to prevent memory leaks.
- **Reactive vs Static Updates**: Fine-grained reactive primitives (`RxBool`, `RxString`, `RxList`) are used for volatile states like loading indicators and form fields, while `update()` calls are selectively triggered for list updates.

### 2.2 Local Persistent Caching (Hive)
Local persistent storage is implemented via `HiveBoxes` (`lib/core/helper/hive_boxes.dart`) to provide instant UI rendering on launch before network requests resolve:
- **`userBox`**: Caches the authenticated user's `UserModel` (ID, username, display name, profile URL, institute, document count, followers, following, and admin flag).
- **`downloadsBox`**: Tracks downloaded document metadata and local device storage paths.

### 2.3 Media Pipeline & Optimization
- **Image Compression**: `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) automatically compresses images using `flutter_image_compress` to JPEG format at 70% quality with a maximum dimensions ceiling of 1024x1024 before uploading to Supabase Storage.
- **Network Image Caching**: Network images and document thumbnails use `cached_network_image` to avoid redundant network fetching and bandwidth usage.
- **Direct Upload Limit**: `UploadController` enforces a strict 10MB limit on direct document uploads. Users sharing larger files are prompted to provide external repository links (Google Drive, Mega, OneDrive).

### 2.4 File Caching & Streaming (`file_caching.dart`)
- Document downloads are managed by Dio in `lib/service/file_caching.dart`.
- Documents are streamed directly to the device's temporary cache directory using `path_provider`. Existing local files are verified prior to issuing network requests, drastically reducing network round-trips.

### 2.5 Database Scalability & Atomic Counters
- **PostgreSQL RPCs**: User interactions (likes, dislikes, bookmarks) call atomic database RPC functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`). This eliminates client-side race conditions and state desynchronization.
- **Optimistic UI Updates**: `DocumentController` updates UI state optimistically before executing RPC calls, reverting state gracefully if a network error occurs.
- **Pagination & Batching**: `HomeController` fetches posts in batches of 50 items ordered by creation date, preventing excessive memory consumption on large feeds.
- **Realtime Subscriptions**: `HomeController` leverages Supabase Postgres Realtime (`public:documents` channel) to reflect new posts automatically.

---

## 3. Design, UI/UX & Architecture

### 3.1 UI Paradigm & Design System
- **Design Language**: Material 3 combined with Glassmorphism overlays (`glassmorphism` package).
- **Color Palette**:
  - **Primary Theme**: Premium Deep Blue (`#0D47A1`).
  - **Secondary / Accent**: Maliblue (`#4ABCFC`), Tiger Lily (`#E66432`), Premium Gold (`#FFD700`).
  - **Gradients**: `AppGradients.premiumGradient` (`#0D47A1` to `#1976D2`) and semi-transparent glass gradients.
  - **Dart 3.5+ Compatibility**: All opacities utilize `.withValues(alpha: ...)` to satisfy modern Flutter rendering requirements.

### 3.2 File-by-File Component Mapping

#### App Core & Layout
- **`lib/main.dart`**: Application entry point. Initializes Hive, Supabase client (`AppMetaData.supabaseUrl`, `AppMetaData.supabaseAnonKey`), and launches `GetMaterialApp` targeting `Splash`.
- **`lib/layout.dart`**: Master layout screen managing bottom tab switching and persistent state across screens.

#### Controllers (`lib/controller/`)
- **`auth_controller.dart`**: Handles email/password authentication, registration with Mumbai University metadata, profile fetching (`fetchAndStoreProfile`), session sync, and logout.
- **`comment_controller.dart`**: Manages hierarchical nested comments, comment creation, and deletion.
- **`document_controller.dart`**: Core controller for document feed management, optimistic like/dislike/bookmark toggles, document deletion, and launching external links or local PDFs.
- **`home_controller.dart`**: Fetches home feed documents, official updates, handles tab switching, search filtering, and Postgres Realtime feed listening.
- **`profile_controller.dart`**: Reactive state controller for the logged-in user's profile info.
- **`profile_user.dart` / `profile_user_controller.dart`**: Fetches user profiles by username and handles follow/unfollow actions.
- **`search_controller.dart`**: Dynamic query filtering across document titles, subjects, topics, and authors.
- **`upload_controller.dart`**: Form state management for file picker, image compression, external URL validation, content type toggling ('note' vs 'tweet'), and official post tagging.
- **`notification_controller.dart`**: Fetches activity notifications and handles mark-as-read updates.
- **`bottom_navigation_controller.dart`**: Reactive index tracker for bottom navigation bar.
- **`showcase_controller.dart`**: Manages profile post tabs (user uploads vs saved/bookmarked documents).

#### Core Configurations & Helpers (`lib/core/`)
- **`config/color.dart`**: Centralized palette, grayscale definitions, `AppGradients`, and glassmorphic colors.
- **`config/theme.dart`**: Material 3 `ThemeData` configuration.
- **`config/typography.dart`**: Standardized Google Fonts typography hierarchy (`AppTypography`).
- **`meta/app_meta.dart`**: App branding constants and Supabase API endpoints.
- **`helper/hive_boxes.dart`**: Hive box initialization and static getter methods for session tokens and user data.
- **`helper/image_helper.dart`**: Image compression logic wrapper.
- **`helper/custom_icon.dart`**: SVG asset renderer and avatar generator helper.

#### Data Models (`lib/model/`)
- **`user_model.dart`**: User profile model with Hive annotations for local serialization.
- **`document_model.dart`**: Complete model representing notes, tweets, links, author info, and interaction states.
- **`comment_model.dart`**: Nested comment node structure.
- **`notification_model.dart`**: User activity notification payload model.

#### Services (`lib/service/`)
- **`file_caching.dart`**: Dio-based chunked file download manager.
- **`file_download.dart`**: Local notification trigger during file download completion.
- **`notification_service.dart`**: Local push notifications setup via `flutter_local_notifications`.

#### Views & Screen Components (`lib/view/`)
- **`auth_screen/`**: Login, registration, and form validation views.
- **`bottom_footer/`**: Floating glassmorphic bottom navigation bar with active tab indicators and avatar icon.
- **`document_screen/`**: Detailed view for notes/tweets, displaying full description, PDF preview/open actions, and nested `CommentSection`.
- **`home_screen/`**: Home view featuring `HomeHeader`, tab selector (All Notes vs Official Updates), and document card feed.
- **`notification_screen/`**: Activity notification feed displaying likes, comments, follows, and global announcements.
- **`profile_screen/`**: User profile header, statistics (Docs, Followers, Following), follow button, share action, and `ProfileShowcase` tab view.
- **`search_screen/`**: Real-time search page with query clear and empty-state animation.
- **`settings_screen/`**: About page detailing vision, MU community mission, and developer information.
- **`splash_screen/`**: Animated splash screen with Lottie animation and automatic session redirect.
- **`upload_screen/`**: Multi-section upload form supporting direct PDF upload, cover image selection, external links, tweet posts, and administrative 'Official' content toggle.
- **`widgets/`**: Reusable UI primitives:
  - `admin_badge.dart`: Gold badge indicator for verified admin accounts.
  - `document_card.dart`: Document card supporting preview thumbnail, official badge, popup overflow menu (download/delete), and animated heart likes.
  - `post_card.dart`: Feed card with glassmorphic title overlay and interaction action bar.
  - `loader.dart`, `primary_button.dart`, `secondary_button.dart`, `refresher_widget.dart`, `toasts.dart`, `upload_text_field.dart`.

---

## 4. Security Analysis & Mitigation Audit

### 4.1 Authentication & Session Management
- Managed via **Supabase Auth (JWT)**.
- Passwords are never stored in plain text or handled by custom servers; hashing is managed via standard Argon2/Bcrypt implementations within Supabase.
- Email verification flows redirect through deep links (`io.supabase.flutternotehub://login-callback`).

### 4.2 Row Level Security (RLS) Database Audit
Row Level Security is strictly enforced on all PostgreSQL tables in `SUPABASE_SCHEMA.sql`:

| Table | Policy Type | Enforcement / Expression |
| :--- | :--- | :--- |
| **`profiles`** | SELECT | `USING (true)` (Publicly viewable) |
| **`profiles`** | INSERT | `WITH CHECK (auth.uid() = id)` |
| **`profiles`** | UPDATE | `USING (auth.uid() = id)` **`WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))`** |
| **`documents`** | SELECT | `USING (true)` |
| **`documents`** | INSERT | `WITH CHECK (auth.uid() = user_id)` |
| **`documents`** | UPDATE/DELETE | `USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true))` |
| **`comments`** | SELECT | `USING (true)` |
| **`comments`** | INSERT | `WITH CHECK (auth.uid() = user_id)` |
| **`comments`** | DELETE | `USING (auth.uid() = user_id OR auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true))` |
| **`interactions`**| ALL | Private to `auth.uid() = user_id` |
| **`bookmarks`** | ALL | Private to `auth.uid() = user_id` |
| **`notifications`**| SELECT | `USING (auth.uid() = receiver_id)` |

### 4.3 Defense Against Privilege Escalation
1. **Admin Role Escalation Mitigation**: Users cannot modify their own `is_admin` column in the `profiles` table. The RLS update policy enforces `WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))`.
2. **Official Document Flag Protection**: To mark a document as official (`is_official = true`), database triggers and permissions (`check_official_permission`) verify that `auth.uid()` has `is_admin = true` in `profiles`.
3. **RPC Security Definer**: PostgreSQL RPC functions run under `SECURITY DEFINER` with explicit `SET search_path = public` to prevent search path hijacking attacks.

---

## 5. Android Native Configuration & Specs

### 5.1 Gradle & Build Parameters (`notehub/android/app/build.gradle`)
- **Compile SDK Version**: `compileSdk 36` (Android 15 ready).
- **Target SDK Version**: `targetSdk 34` (Android 14).
- **Min SDK Version**: `minSdk 21` (Android 5.0 Lollipop+).
- **Java Compatibility**: Java 17 source and target compatibility.
- **Desugaring**: `coreLibraryDesugaring` enabled using `com.android.tools:desugar_jdk_libs:2.0.4` to support modern Java time APIs required by `flutter_local_notifications`.
- **MultiDex**: `multiDexEnabled true`.

### 5.2 Deep Linking & Intent Filters (`AndroidManifest.xml`)
- Configured with custom scheme `io.supabase.flutternotehub` for OAuth and email verification callbacks:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="io.supabase.flutternotehub" android:host="login-callback" />
</intent-filter>
```

### 5.3 Permissions
- `android.permission.INTERNET`: Required for Supabase network communication.
- `android.permission.READ_EXTERNAL_STORAGE` & `WRITE_EXTERNAL_STORAGE`: Configured for PDF file caching and download actions.
- `android.permission.POST_NOTIFICATIONS`: Required on Android 13+ (API 33+) for local notifications.

---

## 6. Developer Maintenance & QA Guidelines

### 6.1 Prerequisites
- **Flutter SDK**: `3.24+`
- **Dart SDK**: `^3.5.4`
- **Android Studio / JDK**: JDK 17

### 6.2 "Zero Warnings" Code Quality Standard
The repository strictly enforces a **Zero Warnings** policy under `flutter analyze`.

When adding or updating code, follow these modernized Flutter rules:
1. **Color Opacity**: Never use `.withOpacity(x)`. Always use `.withValues(alpha: x)` (e.g., `Colors.black.withValues(alpha: 0.1)`).
2. **Switch Controls**: Use `activeThumbColor` instead of deprecated `activeColor`.
3. **Control Flow Braces**: Always enclose `if`/`else` body statements in curly braces (`{ ... }`).
4. **Empty Catches**: Annotate intentionally silent `catch` blocks with `// ignore: empty_catches` on its own line inside the block.

### 6.3 QA Verification Commands
Execute the following commands inside `notehub/` prior to committing any changes:

```bash
# 1. Run static analysis (must report "No issues found!")
flutter analyze

# 2. Run unit and widget tests
flutter test
```

---
*Maintained and documented by Jules, Software Engineer.*
