# Developer Guide & System Analysis - Serious Study (formerly NoteHub)

This document provides a comprehensive, developer-centric analysis of **Serious Study**, an academic notes-sharing and community platform tailored for the Mumbai University student ecosystem. The platform underwent a migration from a legacy Django/MongoDB architecture to a serverless **Supabase (PostgreSQL)** backend and modern **Flutter/GetX** frontend.

---

## 1. System Architecture & Tech Stack

```
                     ┌────────────────────────────────────────────────────────┐
                     │              Flutter Mobile App (Android)              │
                     │          (Flutter 3.24+ / Dart SDK ^3.5.4)             │
                     └───────────────────────────┬────────────────────────────┘
                                                 │
                                ┌────────────────┴────────────────┐
                                │       GetX Controller Layer     │
                                └───────┬─────────────────┬───────┘
                                        │                 │
                 ┌──────────────────────┴──────┐   ┌──────┴──────────────────────┐
                 │    Hive Local Storage       │   │    Network Services         │
                 │ (userBox / downloadsBox)    │   │  (Supabase SDK & Dio)       │
                 └─────────────────────────────┘   └──────────────┬──────────────┘
                                                                  │
                                           ┌──────────────────────┴──────────────────────┐
                                           │              Supabase Backend               │
                                           │  ┌───────────────────────────────────────┐  │
                                           │  │  PostgreSQL (RLS, Triggers, RPCs)    │  │
                                           │  ├───────────────────────────────────────┤  │
                                           │  │  Supabase Auth (JWT & Session Sync)   │  │
                                           │  ├───────────────────────────────────────┤  │
                                           │  │  Supabase Storage (Assets & Vectors)  │  │
                                           │  └───────────────────────────────────────┘  │
                                           └─────────────────────────────────────────────┘
```

### Core Architecture Components
- **Framework & Runtime**: Flutter 3.24+ paired with Dart SDK ^3.5.4. Target platform configuration includes Android (`compileSdk 36`, Java 17 toolchain).
- **State Management**: **GetX** (`GetxController`) manages reactive view models, cross-page state synchronization, and dependency injection.
- **Local Persistence**: **Hive** NoSQL storage provides local session caching (`userBox`) and download tracking (`downloadsBox`).
- **Backend & Database**: **Supabase PostgreSQL** handles data relations, authentication, and security via Row Level Security (RLS) policies and `SECURITY DEFINER` Remote Procedure Calls (RPCs).
- **Networking & File Operations**: **Supabase Flutter SDK** manages database subscriptions and auth, while **Dio** handles background file downloading and caching.

---

## 2. Directory & File Mapping

```
notehub/lib/
├── controller/                      # GetX State Controllers
│   ├── auth_controller.dart         # Managed auth lifecycle, session storage & profile hydration
│   ├── document_controller.dart     # Document interactions, like/dislike RPCs, optimistic UI
│   ├── home_controller.dart         # Feed fetching, pagination (limit 50), Realtime channel listeners
│   ├── upload_controller.dart       # Upload validation (10MB threshold), cover compression, storage insertion
│   ├── profile_controller.dart      # User profile, follower counts, document listings
│   ├── download_controller.dart     # File download state management & Dio integration
│   ├── comment_controller.dart      # Document discussion threads & nested comment handling
│   ├── connection_controller.dart   # Follow/unfollow relationships and social graph updates
│   ├── notification_controller.dart # Activity alerts and system announcement feed
│   └── remote_config_controller.dart# Remote feature flags and dynamic configuration
├── core/                            # Configuration & Utility Helpers
│   ├── config/
│   │   ├── color.dart               # Theme colors, gradients, and Material 3 palettes
│   │   └── typography.dart          # Text style definitions & Google Fonts integration
│   ├── helper/
│   │   ├── hive_boxes.dart          # Hive initialization & typed box accessors
│   │   ├── image_helper.dart        # Image compression (1024x1024, 70% quality JPEG)
│   │   └── custom_icon.dart         # Asset vector mappings
│   └── meta/
│       └── app_meta.dart            # Centralized API URLs, keys, and app metadata
├── model/                           # Data Transfer Objects & Serialization
│   ├── user_model.dart              # User profile DTO with Hive adapter serialization
│   ├── document_model.dart          # Document metadata, external link flags, & interaction counts
│   ├── post_model.dart              # Generalized social post model
│   └── mini_user_model.dart         # Lightweight user representation for avatars and feeds
├── service/                         # External Service & Hardware Integrations
│   ├── file_caching.dart            # Local directory file caching via Path Provider & Dio
│   ├── file_download.dart           # File download pipeline
│   └── notification_service.dart    # Local device notifications configuration
└── view/                            # UI Layer (Screens & Modular Widgets)
    ├── auth_screen/                 # Authentication views (Login, Registration, Verification)
    ├── home_screen/                 # Primary activity feed and official update section
    ├── document_screen/             # Detailed document viewer, comments, and action drawer
    ├── upload_screen/               # Multi-format content publisher (Files & External Links)
    ├── profile_screen/              # User showcase, statistics, and bio management
    ├── notification_screen/         # Activity feed view
    ├── search_screen/               # Full-text query screen
    └── widgets/                     # Reusable Material 3 components (PostCard, DocumentCard, Toasts)
```

---

## 3. Performance Analysis

### 3.1 State Management & Reactive UI Execution
- **Decoupled Business Logic**: GetX Controllers isolates business logic from rendering code. Views consume state reactively through `Obx` widgets or `GetBuilder`, minimizing unnecessary widget rebuilds.
- **Cross-Controller State Synchronization**: `DocumentController` encapsulates `_syncWithHome()`, which updates reactive records in `HomeController` upon user interactions (such as liking or bookmarking a document) without triggering full database re-queries.

### 3.2 Local Persistence & Caching Hierarchy
- **Zero-Latency App Boot**: App session state is stored locally in Hive (`userBox`). When the application initializes, user metadata (`id`, `displayName`, `institute`) is restored synchronously, eliminating splash screen authentication latency.
- **Download Storage Indexing**: Metadata for saved PDF/document files is indexed in `downloadsBox` (`lib/core/helper/hive_boxes.dart`), providing instant access to downloaded assets offline.

### 3.3 Network Payload & Asset Optimization
- **Client-Side Image Compression**: `ImageHelper.compressImage()` downsamples uploaded images to a 1024x1024 target bounding box with 70% JPEG quality before network transit. This reduces document cover image file sizes by 60-80%.
- **Lazy Asset Fetching**: `cached_network_image` caches user profile avatars and document covers on disk, reducing network bandwidth usage on repeat feed views.
- **Paginated Document Feeds**: `HomeController` requests document feeds in controlled batches (50 records per page), preventing memory spikes when rendering long lists.

### 3.4 Database Atomic RPCs & Throughput
- **Race Condition Prevention**: Document counters (`likes_count`, `dislikes_count`) are modified in PostgreSQL using atomic Remote Procedure Calls (`increment_likes`, `decrement_likes`, etc.). Client applications do not compute arithmetic locally, avoiding write conflicts across concurrent user actions.

---

## 4. Design & UI/UX Paradigm

### 4.1 Aesthetic Design System
- **Theme Palette**: The app features a **Premium Deep Blue** palette (`#0D47A1`), giving it an academic identity suitable for Mumbai University.
- **Glassmorphism Layering**: Overlays employ subtle white alpha masks (`.withValues(alpha: 0.15)`) coupled with gradient fills (`AppGradients.premiumGradient`) to create visual depth across navigation bars and card elements.
- **Material 3 Foundation**: Form fields, bottom sheets, and dialogs follow Material 3 design specifications with rounded corners (12dp–16dp radius) and elevation shadows.

### 4.2 Visual Feedback & Perceived Latency
- **Shimmer Placeholders**: Asynchronous feed operations display `Shimmer` skeletons in `HomeDocumentSection` to signal loading state and minimize perceived loading times.
- **Lottie Feedback Assets**: State feedback (e.g., empty search queries or upload progress) uses `Lottie` animations to provide visual context during user flows.

---

## 5. Security Analysis & Vulnerability Audit

### 5.1 Authentication & Session Management
- **Supabase Auth Infrastructure**: Replaced legacy sessionless architecture with JWT-based Supabase Auth. OAuth tokens are refreshed automatically by the client SDK.
- **Secure Password Hashing**: Passwords are processed and stored by Supabase Auth using Argon2/Bcrypt password hashing algorithms.

### 5.2 Row Level Security (RLS) Matrix

Every database table in `SUPABASE_SCHEMA.sql` enforces strict Row Level Security (RLS):

| Table | Policy Name | Permitted Operations | Access Control Rule |
| :--- | :--- | :--- | :--- |
| **`profiles`** | Public profiles viewable | `SELECT` | `true` (Publicly readable) |
| **`profiles`** | Users insert own profile | `INSERT` | `auth.uid() = id` |
| **`profiles`** | Users update own profile | `UPDATE` | `auth.uid() = id` AND `is_admin` cannot be self-elevated |
| **`documents`** | Documents viewable | `SELECT` | `true` (Publicly readable) |
| **`documents`** | Users insert own documents | `INSERT` | `auth.uid() = user_id` |
| **`documents`** | Users update/delete own | `UPDATE`, `DELETE` | `auth.uid() = user_id` |
| **`comments`** | Comments viewable | `SELECT` | `true` (Publicly readable) |
| **`comments`** | Users insert own comments | `INSERT` | `auth.uid() = user_id` |
| **`notifications`**| Users view own notifications | `SELECT` | `auth.uid() = receiver_id` |
| **`interactions`** | Users view/manage own | `ALL` | `auth.uid() = user_id` |
| **`bookmarks`** | Users view/manage own | `ALL` | `auth.uid() = user_id` |

### 5.3 Function Security & Privilege Isolation
- **Privilege Escalation Protection**: The `profiles` update policy prevents users from altering their `is_admin` status. Furthermore, modifying the `is_official` flag in `documents` is validated by a database trigger (`ensure_official_permission`) that checks the requesting user's admin status.
- **Search Path Isolation**: All PostgreSQL RPC functions specify an explicit `SET search_path = public` configuration, protecting database execution against search-path hijacking attacks.

---

## 6. QA, Development & Maintenance Manual

### 6.1 Prerequisites
- **Flutter SDK**: `^3.24.0` (Stable channel)
- **Dart SDK**: `^3.5.4`
- **Android Target**: SDK Version 36, Java 17 toolchain

### 6.2 Code Quality & Verification Commands

To maintain codebase health and adhere to the "Zero Warnings" standard:

1. **Format Verification**:
   ```bash
   cd notehub
   dart format --set-exit-if-changed lib/ test/
   ```

2. **Static Analysis Compliance**:
   ```bash
   cd notehub
   flutter analyze
   ```
   *Requirement: Ensure 0 errors and 0 warnings are returned.*

3. **Automated Test Execution**:
   ```bash
   cd notehub
   flutter test
   ```

### 6.3 Modernization Conventions
- **Alpha Color Definition**: Use `.withValues(alpha: 0.15)` instead of the deprecated `.withOpacity(0.15)` method.
- **Switch Controls**: Use `activeThumbColor` instead of the deprecated `activeColor` parameter.
- **Flow Control Syntax**: Enforce curly braces for control structures to maintain code legibility and analysis compliance.

---
*Maintained by Jules, Software Engineer.*
