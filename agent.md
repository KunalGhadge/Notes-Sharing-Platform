# Developer Technical Manual & System Architecture — Serious Study

> **System Manual & Maintenance Guide for Developers and AI Agents**
> **Platform:** Serious Study (formerly NoteHub)
> **Target Community:** Mumbai University Student & Alumni Community
> **Stack:** Flutter (Dart 3.5.4+ / Flutter 3.24+) + Serverless Supabase (PostgreSQL 15+)

---

## Executive Summary

**Serious Study** is a modernized, serverless, high-performance community and academic resource-sharing platform engineered specifically for Mumbai University students. It enables seamless sharing of lecture notes, Previous Year Questions (PYQs), Important Questions (IMPs), academic updates, and peer-to-peer networking.

Originally built on a legacy Django/MongoDB backend, the entire ecosystem was re-architected to a **Flutter + Supabase** serverless model. This transition delivered real-time reactive capabilities, reduced latency via local Hive caching, eliminated custom server infrastructure overhead, and fortified database security via Row Level Security (RLS) policies and PostgreSQL RPCs.

---

## 1. System Architecture & Tech Stack Overview

```
 ┌─────────────────────────────────────────────────────────────────┐
 │                   Flutter Client Application                    │
 │  ┌──────────────────┐ ┌────────────────────┐ ┌───────────────┐  │
 │  │ GetX Controllers │ │ Material 3 & Glass │ │ Hive Caching │  │
 │  └─────────┬────────┘ └────────────────────┘ └───────┬───────┘  │
 └────────────┼─────────────────────────────────────────┼──────────┘
              │ Direct GraphQL/REST & Realtime          │ Offline Sync & Session
              ▼                                         ▼
 ┌─────────────────────────────────────────────────────────────────┐
 │                       Supabase Serverless                       │
 │  ┌──────────────────┐ ┌────────────────────┐ ┌───────────────┐  │
 │  │ Supabase Auth    │ │ PostgreSQL Engine  │ │ Object        │  │
 │  │ (JWT / Hashing)  │ │ (RLS + RPCs + Real)│ │ Storage       │  │
 │  └──────────────────┘ └────────────────────┘ └───────────────┘  │
 └─────────────────────────────────────────────────────────────────┘
```

### Core Tech Stack Components
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management**: **GetX** (`GetxController`, `Obx`, `GetBuilder`, reactive `.obs` primitives) for decoupled reactive state, dependency injection, and context-free routing.
- **Local Storage Engine**: **Hive** for high-performance NoSQL persistent caching of user profiles, authentication sessions, and download metadata.
- **Networking & Transfers**: **Supabase Flutter SDK** for database CRUD and real-time WebSocket events; **Dio** for chunked background file downloads and HTTP transfers.
- **Backend Infrastructure**: Serverless **Supabase** (PostgreSQL) with Row Level Security (RLS), atomic stored procedures (`RPCs`), and database triggers.
- **Media Optimization**: `flutter_image_compress` for client-side JPEG compression, `cached_network_image` for memory and disk caching of remote thumbnails.

---

## 2. Deep-Dive Performance Analysis

### 2.1 Reactive State Engine & GetX Lifecycle
- **Separation of Concerns**: UI widgets (`lib/view/`) are purely presentation layers. All business logic, network API requests, and mutation algorithms reside inside controllers (`lib/controller/`).
- **Optimistic UI Updates**: User actions like liking (`toggleLike`), disliking (`toggleDislike`), and bookmarking (`toggleBookmark`) in `DocumentController` instantly reflect in the UI before network requests resolve. If a network call fails, state is silently and gracefully reverted to preserve data integrity.
- **Global Cross-Controller Synchronization**: The `DocumentController` invokes `_syncWithHome()` on state mutations, signaling `HomeController` to update its reactive feed without triggering full page re-renders.

### 2.2 Hive NoSQL Persistent Caching
- **Instant App Launch**: User session data and profile info are stored in Hive's `userBox` (`lib/core/helper/hive_boxes.dart`). On app launch, the profile tab and header render instantly without waiting for network authentication checks.
- **Offline Download Indexing**: Downloaded file metadata and local disk paths are stored in `downloadsBox`, preventing redundant network requests for previously fetched assets.

### 2.3 Media & Asset Optimization Pipeline
- **Client-Side Compression**: `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) automatically compresses image assets to 70% quality JPEG format targeted at 1024x1024 resolution before uploading to Supabase Storage, saving bandwidth and storage space.
- **Cached Image Rendering**: `CachedNetworkImage` with memory disk LRU cache is utilized across `PostCard` and `HomeHeader` to reduce network fetches.
- **File Transfer Engine**: `FileCaching` service (`lib/service/file_caching.dart`) checks local temporary storage before initializing Dio transfers.

### 2.4 Stored Procedures & Database Scalability
- **Atomic Stored Procedures (RPCs)**: Counter increments/decrements (likes, dislikes, bookmarks) are executed via PostgreSQL RPC functions defined in `SUPABASE_SCHEMA.sql` (`increment_likes`, `decrement_likes`, etc.). This eliminates race conditions and ensures concurrent atomic updates.
- **Batching & Pagination**: Feeds fetch documents in chunks (batch limit of 50). `HomeController.fetchOfficialUpdates()` limits official announcements to the 20 most recent records to minimize payload size.
- **Perceived Visual Performance**: Animated shimmer placeholders (`shimmer`) and custom Lottie vector animations (`lottie`) provide immediate tactile feedback during asynchronous data fetching.

---

## 3. Design Paradigm & UI/UX Architecture

### 3.1 Design Language
- **Material 3 Paradigm**: Built on Material Design 3 guidelines with rounded borders (12px–24px radii), clean typography scale (`AppTypography`), and subtle elevation shadows.
- **Glassmorphism Styling**: Multi-layered visual depth created using `glassmorphism` container overlays (`Colors.white.withValues(alpha: 0.15)`) and linear gradients (`AppGradients.glassGradient`).
- **Rebranded Color Palette**: Features a custom "Premium Deep Blue" (`#0D47A1`) primary palette representing Mumbai University's academic prestige, combined with golden accents (`#FFD700`) for verified admin content.

### 3.2 Modular Code Base Layout
```
lib/
├── controller/         # GetX Controllers (Business Logic & State)
├── core/               # App Configurations, Meta & Helpers
│   ├── config/         # Color palettes & AppTypography definitions
│   ├── helper/         # Hive boxes, Image compression, Custom icons
│   └── meta/           # AppMetaData configuration strings & credentials
├── model/              # Reactive Data Models (UserModel, DocumentModel, etc.)
├── service/            # Services for Notifications, Caching, & Downloads
└── view/               # Modular UI Views & Screen Widgets
    ├── auth_screen/    # Login and Registration Screens
    ├── bottom_footer/  # Floating Glassmorphic Bottom Navigation Bar
    ├── document_screen/# Document Reader & Comment Section
    ├── home_screen/    # Main Feed & Academic Updates
    ├── notification_s/ # Real-time Activity Feed
    ├── official_screen/# Verified Admin Official Updates Feed
    ├── profile_screen/ # User & Public Profiles
    ├── search_screen/  # Search Engine & Filters
    ├── upload_screen/  # Multi-part Asset & Link Upload Form
    └── widgets/        # Reusable UI Widgets (DocumentCard, PostCard, AdminBadge)
```

---

## 4. Security Audit & Protection Mechanisms

### 4.1 Authentication & Password Security
- **JWT Authentication**: Authentication is handled via Supabase Auth issuing secure JSON Web Tokens (JWT). Client-side session management is governed by the official Supabase SDK.
- **Cryptographic Hashing**: User credentials are saved using industry-standard hashing algorithms (Argon2 / Bcrypt) managed inside Supabase Auth schemas.

### 4.2 Row Level Security (RLS) & Authorization
Every database table in `SUPABASE_SCHEMA.sql` enforces Row Level Security:

| Table | Policy Type | Enforcement Rule |
| :--- | :--- | :--- |
| `profiles` | `SELECT` | Publicly readable (`true`). |
| `profiles` | `INSERT` | Owner only (`auth.uid() = id`). |
| `profiles` | `UPDATE` | Owner only (`auth.uid() = id`), with check constraints preventing self-promotion to `is_admin`. |
| `documents` | `SELECT` | Publicly readable (`true`). |
| `documents` | `INSERT` | Authenticated owner only (`auth.uid() = user_id`). |
| `documents` | `ALL` | Authenticated owner or Admin profile (`auth.uid() = user_id OR is_admin = true`). |
| `comments` | `SELECT` / `INSERT` | Public read, authenticated owner write (`auth.uid() = user_id`). |
| `interactions`| `ALL` | User can only manage their own reactions (`auth.uid() = user_id`). |
| `bookmarks` | `ALL` | Private to the specific user (`auth.uid() = user_id`). |
| `notifications`| `SELECT` | Private to receiver (`auth.uid() = receiver_id`). |

### 4.3 Privilege Escalation Safeguards
- **Official Content Restriction**: Setting `is_official = true` on the `documents` table is protected by PostgreSQL triggers (`ensure_official_permission`) and RLS rules checking the creator's `is_admin` status in `profiles`.
- **Search-Path Hijacking Prevention**: All database trigger functions and RPCs are declared with `SECURITY DEFINER` and an explicit `SET search_path = public` attribute to neutralize search-path hijacking vectors.

---

## 5. File-by-File Technical Directory Mapping

### 5.1 Controllers (`lib/controller/`)
- `auth_controller.dart`: Authentication lifecycle (Login, SignUp, Profile fetch, Hive storage, Logout).
- `document_controller.dart`: Handles notes fetching, optimistic likes/dislikes, bookmarks, document deletion, and notification trigger dispatches.
- `home_controller.dart`: Real-time home feed management, category filtering, and official updates pagination.
- `upload_controller.dart`: Handles multi-part file uploads, file size checks (10MB limit), image compression, and external link posts.
- `comment_controller.dart`: Nested multi-level comment thread fetching, posting, and deletion.
- `profile_controller.dart`: Current user profile state and Hive synchronization.
- `profile_user_controller.dart`: Public user profile inspection, follow/unfollow functionality.
- `notification_controller.dart`: Real-time notification polling and batch mark-as-read updates.
- `search_controller.dart`: Multi-parameter search across notes, topics, and users.
- `connection_controller.dart`: Follower/following network graph querying.
- `download_controller.dart`: Disk file management and downloadsBox syncing.
- `remote_config_controller.dart`: Dynamic app configurations fetched from Supabase `remote_config` table.
- `showcase_controller.dart`: User profile showcase tab logic (User posts vs. Bookmarked posts).
- `bottom_navigation_controller.dart`: Index state tracking for the primary bottom navigation bar.

### 5.2 Core Infrastructure (`lib/core/`)
- `meta/app_meta.dart`: System metadata, branding strings, and Supabase credentials.
- `config/color.dart`: Color palettes, `AppGradients`, and design tokens.
- `config/typography.dart`: Global font families and `AppTypography` text styles.
- `helper/hive_boxes.dart`: Hive box initializations (`userBox`, `downloadsBox`) and getter accessors.
- `helper/image_helper.dart`: Image compression utility (`compressImage`).
- `helper/custom_icon.dart`: SVG vector icon renderer with support for circular avatar fallbacks (`CustomAvatar`).

### 5.3 Data Models (`lib/model/`)
- `user_model.dart` & `user_model.g.dart`: UserModel class annotated with `@HiveType` for Hive adapter generation.
- `document_model.dart`: Reactive model for document entries, reactions, and post types.
- `mini_user_model.dart`: Lightweight user profile snippet for feed headers.
- `post_model.dart`: Data structure for short update posts ("tweets").

### 5.4 Application Services (`lib/service/`)
- `file_caching.dart`: Local disk cache validator for downloaded files.
- `file_download.dart`: System notification progress bar and file downloading pipeline.
- `notification_service.dart`: Local push notification initialization using `flutter_local_notifications`.

### 5.5 Database Schema (`SUPABASE_SCHEMA.sql`)
- Comprehensive SQL migration file defining all 7 core relational tables, indexes, RLS policies, PostgreSQL counter RPCs, and Realtime publication bindings.

---

## 6. Android Configuration & Native Build Setup

### Android Build Specifications (`notehub/android/app/build.gradle`)
- **Compile SDK Target**: `compileSdk 36`
- **Minimum SDK Target**: `minSdkVersion 21`
- **Target SDK**: `targetSdkVersion 34`
- **Java Toolchain**: `Java 17` source and target compatibility.
- **Multidex & Desugaring**: `multiDexEnabled true` and `coreLibraryDesugaring` enabled to support modern Java APIs required by `flutter_local_notifications`.

---

## 7. QA, Maintenance & Code Quality Standards

### 7.1 "Zero Warnings" Policy
All codebase contributions must strictly maintain **Zero Warnings** under `flutter analyze`.

1. **Color Modernization**: Avoid deprecated `.withOpacity()`. Use modern Flutter API: `.withValues(alpha: 0.1)`.
2. **Switch Widgets**: Use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Syntax**: Enforce curly braces for all conditional flow control structures (`curly_braces_in_flow_control_structures`).
4. **Empty Catch Blocks**: Line annotations `// ignore: empty_catches` must be placed on their own line inside the catch block to avoid syntax corruption.

### 7.2 Developer Verification Steps
Before committing changes, execute the full QA test pipeline:

```bash
# 1. Run static code analysis
cd notehub && flutter analyze

# 2. Run unit and integration test suite
flutter test
```

---
*Manual compiled and verified for Serious Study core codebase.*
