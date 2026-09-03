# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-centric analysis and technical reference for the **Serious Study** platform. It details the architecture, performance optimizations, design patterns, security controls, database schema, component mappings, and quality assurance procedures following its full migration to a serverless **Supabase** backend.

---

## 1. Executive Summary & Tech Stack Architecture

**Serious Study** is a high-performance notes-sharing and academic networking application designed for the Mumbai University student community. The project follows a decoupled, reactive MVC-like pattern built on Flutter and Supabase.

### Technology Stack Overview
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management & DI**: **GetX** (Reactive state management using `Rx` variables, dependency injection via `Get.put()` / `Get.find()`, and decoupled routing)
- **Local Persistence & Caching**: **Hive** (NoSQL local key-value store for session persistence and offline metadata)
- **Networking & Media**:
  - **Supabase Flutter SDK**: Data queries, authentication, and Realtime Postgres changes subscriptions.
  - **Dio**: Specialized file streaming, caching, and download management.
  - **flutter_image_compress**: Image compression pipeline before cloud upload.
  - **cached_network_image**: Efficient image caching and placeholder rendering.
- **Backend (Serverless)**:
  - **Database**: PostgreSQL with Row-Level Security (RLS) enabled on all tables.
  - **Auth**: Supabase Auth with JWT token management and password hashing (Argon2/Bcrypt).
  - **Storage**: Supabase Storage buckets for PDFs and cover assets.
  - **Database Logic**: Atomic Stored Procedures (`RPCs`) and triggers for counter operations and permission checks.

---

## 2. Developer's Analysis: Performance, Design & Security

### 2.1 Performance Analysis & Optimizations
- **Reactive State Management**: GetX controllers encapsulate business logic and update only relevant UI subtrees via `Obx` and `GetBuilder`, minimizing Flutter widget rebuild costs.
- **Instant UI Hydration via Hive**: Cold-start latency is minimized by persisting user profile metadata in local Hive boxes (`userBox`). Upon launch, profile views hydrate instantly from Hive before network sync completes.
- **Media Pipeline & Bandwidth Efficiency**:
  - Image assets are compressed using `ImageHelper.compressImage()` (`flutter_image_compress`) to JPEG format with 70% quality and max dimensions of 1024x1024 before uploading to Supabase Storage.
  - Upload limit is strictly enforced at 10MB per file. External links (Google Drive, Mega) are supported to save bandwidth.
  - Avatars and cover thumbnails are cached via `cached_network_image` to avoid redundant network requests.
- **Atomic Database Counter RPCs**: Critical user interactions (likes, dislikes, bookmarks) call server-side PostgreSQL functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`, `increment_bookmarks`, `decrement_bookmarks`) defined with `SECURITY DEFINER`. This eliminates client-side race conditions and prevents counter inconsistency.
- **Optimistic UI Updates**: `DocumentController` updates UI state optimistically when a user likes or bookmarks a post, providing instant feedback while asynchronously persisting changes to Supabase.
- **Feed Batching & Sticky Sorting**: `HomeController` fetches posts in batches of 50 items and applies a sticky sorting algorithm that prioritizes official announcements and administrative updates at the top of the feed.

### 2.2 Design & UX Systems
- **Design Paradigm**: **Material 3** combined with modern **Glassmorphism** aesthetic overlays (`AppGradients.glassGradient`, `Colors.white.withValues(alpha: 0.15)`).
- **Brand Identity & Color Palette**:
  - **Primary Accent**: Premium Deep Blue (`#0D47A1` primary, `#1976D2` secondary), symbolizing academic excellence and reliability for Mumbai University students.
  - **Administrative Accents**: Gold badges and highlights (`#FFD700` / `#B8860B`) designated exclusively for verified official posts and admin profiles.
- **Visual Feedback & Motion**:
  - **Shimmer Effects**: Smooth loading placeholders (`shimmer`) on document feeds and profile headers during data fetch.
  - **Lottie Animations**: Vector animations (`assets/animations/notes.json`) used for splash screens and empty state feedback.
  - **Toast Notifications**: Reusable toast alerts (`Toasts.showTostSuccess`, `showTostError`, `showTostWarning`) for user action feedback.

### 2.3 Security Analysis & System Hardening
- **JWT-Based Authentication**: Custom legacy session tokens were replaced with Supabase Auth (JWT). Authentication headers are automatically managed by the Supabase client SDK.
- **Row-Level Security (RLS)**: Strictly enforced across all PostgreSQL tables (`profiles`, `documents`, `comments`, `interactions`, `bookmarks`, `notifications`, `followers`).
  - `FOR SELECT`: Publicly readable where applicable.
  - `FOR INSERT / UPDATE / DELETE`: Strictly restricted to record owners (`auth.uid() = user_id`).
- **Privilege Escalation Protection**:
  - The `profiles` table update policy contains a explicit `WITH CHECK` constraint:
    `WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))`
    This prevents normal users from altering their `is_admin` flag via direct API requests.
  - The database trigger `ensure_official_permission` restricts setting `is_official = true` on `documents` to authorized admin profiles only.
- **RPC Function Security**:
  - Functions are declared with `SECURITY DEFINER` to safely modify system counters without requiring elevated client table permissions.
  - Functions include an explicit `SET search_path = public` directive to prevent search path hijacking attacks.

---

## 3. Directory & Component Mapping

```
notehub/
├── android/                   # Android native config (compileSdk 36, Java 17, MultiDex)
├── assets/                    # Vector icons (SVG) and Lottie animations
├── lib/
│   ├── main.dart              # App entry point, Supabase initialization, GetX global bindings
│   ├── layout.dart            # Main navigation shell with BottomFooter integration
│   ├── controller/            # GetX Controllers (Business Logic)
│   │   ├── auth_controller.dart          # Auth lifecycle, login/register, Hive profile storage
│   │   ├── bottom_navigation_controller.dart # Main bottom bar page index
│   │   ├── comment_controller.dart       # Post comments, nested replies, deletion
│   │   ├── connection_controller.dart    # User connections and followers searching
│   │   ├── document_controller.dart      # Document lifecycle, likes/dislikes/bookmarks, deletion
│   │   ├── download_controller.dart      # Local download state tracking
│   │   ├── file_controller.dart          # Local file picker interactions
│   │   ├── home_controller.dart          # Main feed, Realtime Postgres changes subscription
│   │   ├── notification_controller.dart  # Activity notifications list and mark-as-read
│   │   ├── post_controller.dart          # Generic post view helper
│   │   ├── profile_controller.dart       # Current user profile reactive state
│   │   ├── profile_user_controller.dart  # Other users' profile view state & follow actions
│   │   ├── remote_config_controller.dart # Dynamic config key-value pairs from database
│   │   ├── search_controller.dart        # Search filter across documents and subjects
│   │   ├── showcase_controller.dart      # Profile user posts and saved bookmarks showcase
│   │   └── upload_controller.dart        # File upload form validation, compression & posting
│   ├── core/                  # Core Utilities & App Configuration
│   │   ├── config/
│   │   │   ├── color.dart                # Color tokens, Deep Blue #0D47A1, AppGradients
│   │   │   └── typography.dart           # AppTypography text style definitions
│   │   ├── helper/
│   │   │   ├── custom_icon.dart          # Custom SVG icon and avatar builders
│   │   │   ├── hive_boxes.dart           # Hive database initialization (userBox, downloadsBox)
│   │   │   └── image_helper.dart         # Compression utility via flutter_image_compress
│   │   └── meta/
│   │       └── app_meta.dart             # App metadata, Supabase credentials, branding strings
│   ├── model/                 # Data Models & Hive Adapters
│   │   ├── document_model.dart           # DocumentModel with interaction reactive state
│   │   ├── mini_user_model.dart          # Lightweight user model
│   │   ├── post_model.dart               # Generic post container model
│   │   ├── user_model.dart               # UserModel class with HiveType annotation
│   │   └── user_model.g.dart             # Generated Hive TypeAdapter for UserModel
│   ├── service/               # Background Services & Utilities
│   │   ├── file_caching.dart             # Local temp caching via Dio & path_provider
│   │   ├── file_download.dart            # File download manager with notification progress
│   │   └── notification_service.dart     # Local push notification configuration
│   └── view/                  # Presentation Layer (UI Widgets & Screens)
│       ├── auth_screen/                  # Login and registration screens & fields
│       ├── bottom_footer/                # Glassmorphic bottom navigation bar widget
│       ├── connection_screen/            # Followers & following user list view
│       ├── document_screen/              # Document detailed view, description, comments section
│       ├── home_screen/                  # Feed view, header, document section
│       ├── notification_screen/          # User activity feed view
│       ├── official_screen/              # Verified official notices & announcements view
│       ├── onboarding_screen/            # Initial app onboarding view
│       ├── profile_screen/               # Current and target user profile screens & showcases
│       ├── search_screen/                # Global search screen
│       ├── settings_screen/              # App info, About Serious Study, drawer navigation
│       ├── splash_screen/                # Animated Lottie splash screen
│       ├── upload_screen/                # Document and update posting screen & admin controls
│       └── widgets/                      # Shared UI widgets (DocumentCard, PostCard, AdminBadge, etc.)
└── SUPABASE_SCHEMA.sql        # Database tables, RLS policies, RPC functions, and triggers
```

---

## 4. Database Schema & RPC Operations (`SUPABASE_SCHEMA.sql`)

### Key Tables
1. **`profiles`**: Stores user account metadata extending Supabase Auth (`id`, `username`, `display_name`, `profile_url`, `institute`, `is_admin`, `followers`, `following`, `documents`).
2. **`documents`**: Metadata for uploaded notes and updates (`id`, `user_id`, `name`, `topic`, `description`, `document_url`, `cover_url`, `likes_count`, `dislikes_count`, `is_external`, `is_official`, `post_type`).
3. **`comments`**: Community discussion posts (`id`, `document_id`, `user_id`, `parent_id`, `content`).
4. **`interactions`**: Tracks user likes and dislikes (`document_id`, `user_id`, `type`).
5. **`bookmarks`**: User saved document relationships (`document_id`, `user_id`).
6. **`notifications`**: Activity feed alerts (`receiver_id`, `sender_id`, `document_id`, `type`, `content`, `is_read`, `is_global`).
7. **`followers`**: Follower/following relationships (`follower_id`, `following_id`).
8. **`remote_config`**: Dynamic app configurations stored as key-value JSONB pairs.

### RPC Functions Sample
```sql
CREATE OR REPLACE FUNCTION public.increment_likes(doc_id BIGINT)
RETURNS VOID AS $$
BEGIN
  UPDATE public.documents
  SET likes_count = likes_count + 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 5. QA, Development & Maintenance Guidelines

### Prerequisites
- Flutter SDK: `^3.24.0`
- Dart SDK: `^3.5.4`

### "Zero Warnings" Policy & Code Quality Standards
- All code changes must strictly adhere to the codebase linting rules in `analysis_options.yaml`.
- **Modern Color API**: Always use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)` method.
- **Switch Control**: Use `activeThumbColor` instead of the deprecated `activeColor` property on `Switch` widgets.
- **Flow Control Braces**: All `if` statements must be enclosed in explicit curly braces (`curly_braces_in_flow_control_structures`).
- **Empty Catches**: Silent catch blocks must contain the `// ignore: empty_catches` directive placed on its own line within the catch block.

### Running Quality Checks
From the `notehub/` directory:
```bash
# Verify static analysis compliance (must return "No issues found!")
flutter analyze

# Execute test suite
flutter test
```

---
*Analyzed and Documented by Jules, AI Software Engineer.*
