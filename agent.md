# Developer Manual & Comprehensive System Guide — Serious Study (formerly NoteHub)

This manual provides an exhaustive, developer-centric analysis of the **Serious Study** repository. It serves as the primary system architectural reference, technical design document, security audit report, and QA maintenance guide for engineering teams working on the codebase.

---

## 1. Executive Summary & Tech Stack

**Serious Study** is a high-performance academic networking and notes-sharing platform designed for the Mumbai University student community. The application was migrated from a legacy Django/MongoDB backend to a modern, serverless **Supabase** infrastructure paired with a **Flutter** mobile client.

### Core Tech Stack
- **Client Framework**: Flutter SDK 3.24+ (Dart SDK ^3.5.4) targeting Android (`compileSdk 36`, Java 17).
- **State Management**: **GetX** (v4.6.6) for reactive data flows, dependency injection (`Get.put`, `Get.find`), and route management.
- **Local Persistence**: **Hive** (v2.2.3) NoSQL key-value database for caching session tokens, profile metadata, and offline download records.
- **Backend Architecture**: **Supabase** (v2.8.1)
  - **Auth**: Managed JWT authentication with automatic session persistence and email confirmation flow.
  - **Database**: PostgreSQL with Row Level Security (RLS) enabled on all tables.
  - **Realtime**: Postgres changes published over WebSockets for document feed and interaction synchronization.
  - **Storage**: Supabase Storage buckets with strict RLS policies governing media uploads.
  - **Stored Procedures**: PostgreSQL Functions (`SECURITY DEFINER` RPCs) for atomic state mutations (e.g., counters, like/dislike interactions).
- **Networking & Media**: `Dio` (v5.7.0) for file transfer operations, `cached_network_image` for image caching, and `flutter_image_compress` for pre-upload payload optimization.

---

## 2. Comprehensive File & Architectural Directory Mapping

Below is the complete file-by-file mapping of the codebase from a developer perspective:

```
.
├── ANALYSIS.md                        # High-level executive overview and tech stack summary
├── CONFLICT_RESOLUTION_GUIDE.md        # Migration and git branch conflict resolution instructions
├── README.md                          # Repository landing page and setup guide
├── SUPABASE_SCHEMA.sql                # Complete PostgreSQL DDL, RLS policies, RPCs, and triggers
├── agent.md                           # Master developer manual and maintenance guide (this file)
└── notehub/                           # Main Flutter project root
    ├── analysis_options.yaml          # Static analysis and linting configuration
    ├── pubspec.yaml                   # Dependency definitions and asset declarations
    ├── test/
    │   └── dummy_test.dart            # Automated test suite entry point
    └── lib/
        ├── main.dart                  # Application entry point & Supabase client initialization
        ├── layout.dart                # Primary navigation wrapper & bottom navigation handler
        ├── core/
        │   ├── config/
        │   │   ├── color.dart         # Color definitions (Premium Deep Blue palette & overlays)
        │   │   └── typography.dart    # Poppins text styles and scale hierarchy
        │   ├── helper/
        │   │   ├── custom_icon.dart   # SVG/Icon rendering helpers
        │   │   ├── hive_boxes.dart    # Hive box initializer and persistent storage keys
        │   │   └── image_helper.dart  # Client-side image compression pipeline (70% JPEG quality)
        │   └── meta/
        │       └── app_meta.dart      # Global app constants and Supabase endpoint configurations
        ├── model/
        │   ├── user_model.dart        # User profile entity
        │   ├── user_model.g.dart      # Hive adapter generated code for UserModel
        │   ├── document_model.dart    # Academic note and tweet data model
        │   ├── post_model.dart        # Feed item wrapper
        │   └── mini_user_model.dart   # Lightweight profile DTO for feed cards
        ├── controller/
        │   ├── auth_controller.dart              # Login, registration, session storage, and profile bootstrapping
        │   ├── home_controller.dart              # Global document feed fetching, realtime listeners, pagination (batch: 50)
        │   ├── document_controller.dart          # Optimistic likes/dislikes/bookmarks, document deletion, and opening
        │   ├── upload_controller.dart            # Multi-part file/link upload pipeline & 10MB limit validation
        │   ├── profile_controller.dart           # Authenticated user profile edits and avatar updates
        │   ├── profile_user_controller.dart      # Peer profile viewing, follower counts, and follow toggle
        │   ├── comment_controller.dart           # Comment listing, nested replies creation, and counts
        │   ├── search_controller.dart            # Full-text and filter-based search logic
        │   ├── notification_controller.dart      # System notifications and activity stream management
        │   ├── connection_controller.dart        # Follower/following network graph logic
        │   ├── showcase_controller.dart          # Featured content and onboarding highlight management
        │   ├── remote_config_controller.dart     # Dynamic app parameters fetched from PostgreSQL `remote_config`
        │   ├── bottom_navigation_controller.dart # Active tab state management
        │   ├── file_controller.dart              # Local storage file status helper
        │   └── download_controller.dart          # Active file download state tracker
        ├── service/
        │   ├── file_caching.dart       # Dio-based cached file fetcher
        │   ├── file_download.dart      # File save to local device storage and open handler
        │   └── notification_service.dart# Local push notification configuration
        └── view/
            ├── auth_screen/            # Login, registration, and credential input screens
            ├── home_screen/            # Main document feed with tab bar, shimmer loaders, and posts
            ├── official_screen/        # Verified university announcements feed
            ├── document_screen/        # Detailed document view, comment section, and interaction bar
            ├── upload_screen/          # Material upload form with 'Official' toggle for admins
            ├── profile_screen/         # Self profile and peer profile view layouts
            ├── search_screen/          # Real-time search page
            ├── notification_screen/    # Activity and alert feed view
            ├── connection_screen/      # Follower / following lists page
            ├── onboarding_screen/      # First-launch onboarding slides
            ├── settings_screen/        # About page and drawer settings
            ├── splash_screen/          # Initial splash screen and session routing
            ├── bottom_footer/          # Glassmorphic bottom navigation tab bar
            └── widgets/                # Reusable UI widgets (DocumentCard, PostCard, PrimaryButton, etc.)
```

---

## 3. Deep-Dive Performance Analysis

### 3.1 State Management & Execution Lifecycle
- **Reactive GetX Framework**: Business logic is separated into reactive controllers (`GetxController`). UI widgets consume properties via `Obx` or `GetBuilder`.
- **Cross-Controller State Synchronization**: When an interaction occurs in `DocumentController` (e.g., liking a note), `_syncWithHome()` triggers an update on `HomeController` to reflect counter updates across feeds seamlessly without requiring manual re-fetches.

### 3.2 Offline Storage & Caching Layer
- **Hive NoSQL Storage Engine**:
  - `userBox`: Stores the authenticated user's `UserModel` instance locally. On application launch, profile details render instantly while Supabase verifies session validity in the background.
  - `downloadsBox`: Maintains an index of locally downloaded PDF files and assets to prevent redundant network requests.
- **HTTP & Asset Caching**:
  - `CachedNetworkImage`: Utilized across avatars and document thumbnails with disk cache management, suppressing flicker and bandwidth overuse.
  - `FileCachingService`: Employs `Dio` to check existing local file paths in temporary app directories before downloading remote files.

### 3.3 Media Compression Pipeline
- **Upload Optimization**: In `lib/core/helper/image_helper.dart`, image files selected for avatars or document cover thumbnails are passed through `FlutterImageCompress.compressAndGetFile`.
- **Compression Parameters**:
  - Target format: JPEG.
  - Quality setting: 70%.
  - Output target resolution capped at 1024x1024.
- **Upload Boundaries**: `UploadController` enforces a strict 10MB threshold on direct document uploads, advising users to provide external cloud links (e.g., Google Drive) for larger files.

### 3.4 Database Query & Pagination Performance
- **Batch Pagination**: `HomeController` fetches document feeds in batches of 50 records sorted descending by `created_at` (`.order('created_at', ascending: false)`), keeping payloads lightweight.
- **Atomic Database RPCs**: Client applications do not issue read-modify-write transactions for counters. Instead, PostgreSQL functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`) execute atomic counter mutations directly inside PostgreSQL, eliminating race conditions.

---

## 4. UI/UX & Design System Architecture

### 4.1 Aesthetic Paradigm
- **Material 3 Foundation**: Modern material components with updated rounded corners, elevated surfaces, and adaptive layouts.
- **Glassmorphism Layering**: Subdued semi-transparent background overlays with subtle borders (e.g., `.withValues(alpha: 0.15)`), applied across bottom navigation bars and modal overlays.
- **Brand Palette ("Premium Deep Blue")**:
  - Primary Swatch: Deep Blue (`#0D47A1`).
  - Accent Gradients: Defined in `AppGradients.premiumGradient`.
  - Contrast System: High-contrast white typography on dark primary containers for clarity.

### 4.2 Typography & Asset Strategy
- **Typography Scale**: Built on `GoogleFonts.poppins()` via `AppTypography` with defined text styles for Display, Title, Body, and Label.
- **Vector Icons & Micro-Animations**:
  - `flutter_svg` for crisp, vector-based custom icons (`assets/icons/` and `assets/vectors/`).
  - `Lottie` animations (`assets/animations/`) for engaging feedback on empty states, search results, and upload loading indicators.
- **Perceived Latency Management**: Shimmer skeleton screen overlays (`Shimmer.fromColors`) render in `HomeDocumentSection` while network data is retrieved.

---

## 5. Security Analysis & Migration Audit

### 5.1 Legacy vs. Serverless Security Matrix

| Security Domain | Legacy Architecture (Django / MongoDB) | Modernized Architecture (Supabase / PostgreSQL) |
| :--- | :--- | :--- |
| **Authentication** | Custom session tokens stored in plaintext | **Supabase Auth (JWT)** with secure token refresh & auto-persistence |
| **Password Hashing** | Weak custom hashing / plain text risk | **Bcrypt / Argon2** managed internally by PostgreSQL `auth` schema |
| **Data Authorization** | Monolithic API endpoints with manual checks | **Row Level Security (RLS)** policies enforced at the PostgreSQL database level |
| **Database Integrity** | Vulnerable to client-side race conditions | **Atomic PostgreSQL RPCs** executing thread-safe counter operations |
| **Privilege Escalation** | Flawed client role assertions | **`WITH CHECK` RLS clauses** + PostgreSQL database triggers |
| **Storage Protection** | Exposed public link directories | **Storage Bucket Policies** restricting write/delete access to file owners/admins |

### 5.2 Row Level Security (RLS) Rules Summary
Every table defined in `SUPABASE_SCHEMA.sql` enforces RLS:
1. **`profiles`**:
   - `SELECT`: Publicly readable (`USING (true)`).
   - `INSERT`: Restricted to own UID (`WITH CHECK (auth.uid() = id)`).
   - `UPDATE`: Restricted to account owner (`USING (auth.uid() = id)`). A `WITH CHECK` clause prevents self-assignment of `is_admin = true`.
2. **`documents`**:
   - `SELECT`: Viewable by everyone.
   - `INSERT`: Verified against document owner (`auth.uid() = user_id`).
   - `UPDATE / DELETE`: Restricted to document owner (`auth.uid() = user_id`) or verified admins (`is_admin = true`).
3. **`interactions` & `bookmarks`**:
   - `ALL`: Strictly restricted to owner (`auth.uid() = user_id`).
4. **`notifications`**:
   - `SELECT`: Restricted to intended recipient (`auth.uid() = receiver_id`).

### 5.3 Stored Procedure Hygiene & Search Path Protection
To prevent search-path hijacking vulnerabilities, all custom database RPCs and trigger functions (e.g., `check_official_permission`) explicitly mandate the search path:
```sql
CREATE OR REPLACE FUNCTION public.check_official_permission()
RETURNS TRIGGER AS $$
BEGIN
  -- Permission verification logic
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 6. Development, Maintenance & QA Guide

### 6.1 Prerequisites & Environment Setup
- **Flutter SDK**: `>=3.24.0`
- **Dart SDK**: `>=3.5.4`
- **Android Target**: SDK 36, JDK 17. MultiDex enabled in `android/app/build.gradle`.

### 6.2 Essential Commands

To run static analysis and verify zero linting issues:
```bash
cd notehub
flutter analyze
```

To run unit and integration tests:
```bash
cd notehub
flutter test
```

To regenerate Hive adapters or build runner files:
```bash
cd notehub
flutter pub run build_runner build --delete-conflicting-outputs
```

To run a live web preview server for testing UI rendering:
```bash
cd notehub
flutter run -d web-server --web-port 8080
```

### 6.3 Zero Warnings & Code Quality Directives
1. **Color Modernization**: Avoid deprecated `.withOpacity(val)`. Use `.withValues(alpha: val)` for precise alpha rendering in modern Flutter SDK versions.
2. **Control Controls**: Switch widgets must specify `activeThumbColor` (not deprecated `activeColor`).
3. **Flow Control Braces**: Always enclose conditional blocks in explicit curly braces (`if (...) { ... }`).
4. **Empty Catches**: Annotate intentional empty catch blocks with `// ignore: empty_catches` placed on its own line within the block.

---
*Maintained by Jules, AI Software Engineer.*
