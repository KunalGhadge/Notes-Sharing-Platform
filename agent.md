# Developer Guide & Maintenance Manual - Serious Study (formerly NoteHub)

This manual provides an exhaustive, developer-perspective technical analysis of **Serious Study** (formerly NoteHub). It acts as the ultimate developer handbook for maintaining, scaling, and auditing the application codebase, covering performance optimizations, design patterns, security frameworks, and a file-by-file directory breakdown.

---

## 1. Architectural System Overview

Serious Study is a premium, high-performance notes-sharing and academic networking application designed for the **Mumbai University** student community. The application's core architecture leverages a decentralized, serverless pattern powered by **Supabase (PostgreSQL)**, completely replacing its legacy Django and MongoDB database roots.

The frontend is built on **Flutter (Dart SDK ^3.5.4, Flutter SDK 3.24+)** with **GetX** as the state management framework. It implements a decoupled Model-View-Controller (MVC) pattern where user interaction immediately triggers reactive updates across the UI layer.

### Core Architecture Diagram

```mermaid
graph TD
    subgraph Frontend (Flutter & GetX)
        View[UI Layer / Views]
        Controller[GetX Controllers]
        Hive[Hive Cache / Local NoSQL]
    end

    subgraph Backend (Supabase Serverless)
        Auth[Supabase Auth / JWT]
        DB[(PostgreSQL Database)]
        Storage[[Supabase Storage / Buckets]]
        RPC[SQL RPC Functions / Triggers]
    end

    View -->|User Actions / Triggers| Controller
    Controller -->|Reactive Streams| View
    Controller -->|Read/Write Session & Offline Metadata| Hive
    Controller -->|Secure JWT Authentication| Auth
    Controller -->|Query / Stream Real-time Updates| DB
    Controller -->|Atomic Counter Updates| RPC
    Controller -->|Media & PDF Uploads / Downloads| Storage
    DB -->|Postgres Realtime Channel| Controller
```

---

## 2. Directory & File-by-File Component Mapping

The codebase is structured logically to separate business logic from the visual rendering pipeline. Below is a comprehensive file-by-file analysis of the `notehub/lib/` folder hierarchy.

### 2.1 Configuration, Meta, & Helpers (`lib/core/`)

The `core` directory holds global, immutable, or utility classes shared across the codebase.

*   `core/config/color.dart`: Defines the application's color theme palette, transitioning the legacy branding to the unified **Premium Deep Blue** theme (`#0D47A1`). Utilizes modern Flutter `.withValues(alpha: ...)` for translucent layers and glassmorphic overlays instead of deprecated `.withOpacity()`.
*   `core/config/typography.dart`: Houses text style definitions (`AppTypography`), configuring the typography scale with uniform fonts (e.g., Google Fonts' `Outfit` or `Plus Jakarta Sans`) to maintain clean text hierarchies.
*   `core/meta/app_meta.dart`: Houses critical application credentials, global static strings, and remote endpoints. Contains the Supabase Project URL, anonymous public keys, and the application name.
*   `core/helper/hive_boxes.dart`: Configures the Hive NoSQL storage adapter wrappers. Exposes boxes such as `userBox` for session details and `downloadsBox` for managing offline files and metadata.
*   `core/helper/custom_icon.dart`: Defines custom vectorized assets and iconography mappings to reduce asset sizes.
*   `core/helper/image_helper.dart`: Highly optimized utility for client-side asset processing. Integrates `flutter_image_compress` to compress uploaded cover pictures to a high-efficiency JPEG format (70% quality, 1024x1024 resolution limits) before sending them to Supabase Storage.

### 2.2 Data Models (`lib/model/`)

Provides structured, typed Dart representations of database entities.

*   `model/user_model.dart`: Represents a registered user. Configured as a Hive Type (`@HiveType(typeId: 0)`) to enable direct, binary-level serialization into local storage.
*   `model/user_model.g.dart`: Generated TypeAdapter file created by `build_runner` for high-performance Hive reads and writes.
*   `model/mini_user_model.dart`: A lightweight user model containing minimal metadata (avatar, name, ID) to represent followers or authors without excessive database joins.
*   `model/document_model.dart`: Represents a shared note, document, or "tweet". Maps relational PostgreSQL columns (including `is_official`, `post_type`, and `is_external`) to typed Dart attributes.
*   `model/post_model.dart`: Represents simple text-based status updates or academic tweets within the community feed.

### 2.3 Reactive Controllers (`lib/controller/`)

The brains of the application. GetX Controllers contain state management and talk to the network/storage services.

*   `controller/auth_controller.dart`: Interfaces with Supabase Auth. Manages login, registration, email confirmation redirection, profile initialization in PostgreSQL, and Hive session caching.
*   `controller/bottom_navigation_controller.dart`: Coordinates bottom navbar index switches and layout transitions.
*   `controller/home_controller.dart`: Orchestrates the home feed. Integrates real-time PostgreSQL subscriptions via `supabase.channel` to update the document feed optimistically or reactively when other users upload notes.
*   `controller/document_controller.dart`: Handles notes metadata actions (liking, bookmarking, and viewing comments). Interacts with atomic SQL RPCs (`handle_interaction`) to ensure thread-safe operations on the backend. Updates home controller feeds reactively via `_syncWithHome()`.
*   `controller/upload_controller.dart`: Validates input metadata, checks size limits (maximum 10MB), compresses cover thumbnails, uploads files to the `documents` Supabase Storage bucket, and records metadata in the SQL tables.
*   `controller/download_controller.dart`: Manages file progress state and saves PDF assets.
*   `controller/profile_controller.dart` & `profile_user_controller.dart`: Manages the local user's profile edits and other users' public profile details.
*   `controller/comment_controller.dart`: Tracks real-time comment streams and sub-replies (nested lists) under documents.
*   `controller/connection_controller.dart`: Processes peer-to-peer follower/following relations.
*   `controller/notification_controller.dart`: Manages real-time notifications for interactions (likes, replies, updates) via Supabase Realtime subscription.
*   `controller/remote_config_controller.dart`: Dynamically fetches features and branding parameters from the `remote_config` PostgreSQL table.
*   `controller/search_controller.dart`: Executes server-side and client-side searching and filtering of notes.

### 2.4 Infrastructure Services (`lib/service/`)

Implements low-level cross-cutting concerns.

*   `service/file_caching.dart`: Direct file-download proxy. Utilizes `Dio` to fetch document files, checks local path directories (`path_provider`), and caches files within temporary directories to eliminate duplicate downloads.
*   `service/file_download.dart`: Initiates and monitors system-level downloads.
*   `service/notification_service.dart`: Wraps the `flutter_local_notifications` library, handling incoming background messages and rendering push notifications.

### 2.5 User Interface Screens & Widgets (`lib/view/`)

Modular, decoupled widgets that render the application UI.

*   `view/splash_screen/splash.dart`: Initiates the startup pipeline, checks Hive local storage for existing auth tokens, and routes users to the onboarding screen or home layout.
*   `view/auth_screen/`: Group of widgets (login, registration, text fields) configured with custom inputs and validators.
*   `view/bottom_footer/`: Decoupled glassmorphic navigation bar.
*   `view/home_screen/`: Displays home headers and document feeds with sticky sorting and pull-to-refresh indicators.
*   `view/document_screen/`: Detailed screen rendering note pages, download buttons, nested comments, and engagement counters.
*   `view/upload_screen/`: Comprehensive administrative forms, official toggles, and multi-file selection screens.
*   `view/profile_screen/`: Clean academic profiles showing contribution counts, follower indicators, and glassmorphic header accents.
*   `view/widgets/`: Highly reusable UI elements:
    *   `document_card.dart`: Glassmorphic layout for displaying note previews.
    *   `post_card.dart`: Lightweight card for tweets or updates.
    *   `loader.dart`: Premium loading spinner with Glassmorphism backing.
    *   `toasts.dart`: Wrapped `toastification` handlers for beautiful toast alerts.
    *   `admin_badge.dart`: Visual badge indicating official/verified/admin statuses.

---

## 3. Dynamic Application Flows

### 3.1 Notes Upload Pipeline

This diagram shows how files are processed, compressed, and secured from the client's file system up to Supabase Storage and database indexes.

```
[ User Selects Document & Cover ]
               │
               ▼
[ Size Check: Document <= 10MB? ] ────(No)───► [ Toasts Alert: "File too large!" ]
               │ (Yes)
               ▼
[ Image Compress: Cover Photo ] ──────────────► [ Compress to JPEG, Quality: 70% ]
               │
               ▼
[ Auth Token Verification (JWT) ]
               │
               ▼
[ Upload Core Assets via Supabase Storage ]
   ├── Document PDF ──► `documents` bucket (Folder: {auth.uid}/)
   └── Compressed Cover ──► `documents` bucket (Folder: {auth.uid}/)
               │
               ▼
[ Insert Metadata Row in DB ] ───────────────► [ profiles/documents table ]
               │
               ▼
[ Success State Response ] ──────────────────► [ Optimistic Feed Reload ]
```

### 3.2 Real-time Feed & RPC Interaction Loop

How interactions (Likes, Bookmarks, and Comments) avoid race conditions and synchronize with the Home screen immediately.

```
[ View: User clicks "Like" ]
             │
             ▼
[ Controller: Optimistic UI Update ] ──► (Increment counter in local view state)
             │
             ▼
[ Network: Supabase RPC invocation ] ──► `handle_interaction` (DB level)
             │
             ├──► (Database handles atomic update inside a transaction block)
             └──► (Locks database row, prevents concurrency conflicts)
             │
             ▼
[ Server: PostgreSQL trigger pushes to Realtime Channel ]
             │
             ▼
[ Frontend: HomeController receives event ]
             │
             ▼
[ Layout State Synchronization ] ──► `_syncWithHome()` propagates updates instantly
```

---

## 4. In-Depth Performance Audit

### 4.1 Caching Strategies
The application implements a multi-tier caching mechanism to reduce cold-start latency and minimize expensive backend calls:
1.  **Session Persistent State**: Handled using **Hive NoSQL local storage** (`HiveBoxes.userBox`). On start, the app reads the cached profile from Hive, allowing instant rendering of personal data.
2.  **Asset Caching**: Images are rendered using `CachedNetworkImage` which caches web thumbnails locally. This avoids consuming student bandwidth and reduces server ingress/egress.
3.  **File Download Registry**: Local files are audited prior to starting downloads. `file_caching.dart` checks local files via `downloadsBox` and only initiates connection requests if files have changed or are missing.

### 4.2 Stream & Network Optimizations
- **Data Pagination/Batching**: The `HomeController` queries the backend with strict pagination limits (typically 50 elements at a time). This keeps payloads lightweight.
- **Optimistic Rendering**: Counters (likes, dislikes) update visually on the client before the network request returns. If the backend fails, the state gracefully rolls back, keeping the UX feeling instantaneous.
- **Connection Diagnostics**: Network state is actively monitored via `ConnectionController` to handle offline states without freezing the UI.

---

## 5. UI/UX & Rebranding Audit

The visual redesign establishes an academic-centric aesthetic tailored for Mumbai University.

```
  ┌──────────────────────────────────────────────────────────┐
  │  ★ Serious Study - Premium Blue Theme Color System ★     │
  ├──────────────────────────────────────────────────────────┤
  │                                                          │
  │  Primary Background:  Premium Deep Blue  (#0D47A1)       │
  │  Secondary Accents:  Rich Charcoal & Slate Gray         │
  │  Visual Aesthetics:  Glassmorphic Blur Layers            │
  │  Text Contrast:      High Contrast Grayscale Whites      │
  │                                                          │
  └──────────────────────────────────────────────────────────┘
```

- **Material 3 Integration**: Uses modern components like floating app bars and segmented switch buttons.
- **Glassmorphic Accents**: Translucent backdrops combined with thin white borders and soft drop shadows create a sense of depth in the layout.
- **Shimmer Visual Placeholders**: Skeletons replace raw loaders in list feeds.
- **Lottie and SVG Integrations**: Highly compact animation files provide feedback for empty results, network errors, or uploads.

---

## 6. Database Schema & Security Audit

The backend migration to Supabase introduces a comprehensive security architecture utilizing strict PostgreSQL access controls.

### 6.1 Row Level Security (RLS) Configuration

All tables have RLS enabled, eliminating the legacy risk of global database write/delete vulnerabilities.

| Database Table | RLS Status | Read Access Policy | Write Access Policy | Delete Access Policy |
| :--- | :--- | :--- | :--- | :--- |
| `profiles` | **Enabled** | Public (Anonymous Allowed) | Authenticated (Self-ID matching) | Denied |
| `documents` | **Enabled** | Public (Anonymous Allowed) | Authenticated (Owner UUID matching) | Authenticated (Owner UUID matching) |
| `comments` | **Enabled** | Public (Anonymous Allowed) | Authenticated (Owner UUID matching) | Authenticated (Owner UUID matching) |
| `interactions`| **Enabled** | Public | Authenticated (Self UUID matching) | Authenticated (Self UUID matching) |
| `bookmarks` | **Enabled** | Private (Receiver UUID match) | Authenticated (Self UUID matching) | Authenticated (Self UUID matching) |
| `notifications`| **Enabled** | Private (Receiver UUID match) | System Generated / Triggered | Denied |
| `followers` | **Enabled** | Public | Authenticated (Follower UUID match) | Authenticated (Follower UUID match) |

### 6.2 Privilege Escalation Prevention
1.  **Securing Administrative Roles**:
    The `profiles` table update policy verifies that a user cannot self-promote to `is_admin = true` by incorporating a validating `WITH CHECK` clause:
    ```sql
    CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
    ```
    This ensures that even if a malicious payload tries to set `is_admin` to `true`, the update fails because the new value must match the user's existing database status.

2.  **Verifying Official Content**:
    The system prevents unauthorized users from marking documents as "Official" using a database trigger (`ensure_official_permission`). If a user attempts to set `is_official = true`, the trigger function verifies their administrative status from their user profile, raising an exception if they are not authorized.
    ```sql
    CREATE OR REPLACE FUNCTION public.check_official_permission()
    RETURNS TRIGGER AS $$
    BEGIN
      IF NEW.is_official = true AND NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE id = NEW.user_id AND is_admin = true
      ) THEN
        RAISE EXCEPTION 'Only administrators can mark content as Official.';
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
    ```

3.  **Search Path Hijacking Mitigation**:
    All critical functions are compiled using the explicit `SET search_path = public` directive. This prevents attackers from executing search-path hijacking attacks.

---

## 7. Maintenance, QA, & Troubleshooting Guide

To maintain code health and keep the codebase aligned with the **Zero Warnings Policy**, follow these guidelines:

### 7.1 Static Code Analysis & Code Quality
- Ensure all loops, condition evaluations, and flow structures are enclosed in curly braces to satisfy the `curly_braces_in_flow_control_structures` rule.
- Do not use deprecated `.withOpacity()` for translucent colors. Use the modernized `.withValues(alpha: ...)` API.
- Switch widgets must use `activeThumbColor` to avoid warnings associated with the deprecated `activeColor` parameter:
  ```dart
  Switch(
    value: isOfficial,
    onChanged: (val) => controller.toggleOfficial(val),
    activeThumbColor: const Color(0xFFB8860B),
  )
  ```
- If empty catch blocks are necessary, place `// ignore: empty_catches` on its own line inside the block to avoid parsing errors:
  ```dart
  try {
    // operation
  } catch (e) {
    // ignore: empty_catches
  }
  ```

### 7.2 Running Tests & QA Checks
- Install development dependencies and resolve paths:
  ```bash
  cd notehub
  flutter pub get
  ```
- Run static analysis to verify there are no compilation errors:
  ```bash
  flutter analyze
  ```
- Run the Flutter unit and widget tests:
  ```bash
  flutter test
  ```

### 7.3 Troubleshooting Common Integration Issues
- **Registration Issues / No Profile Created**: Verify that the database setup in `SUPABASE_SCHEMA.sql` was fully applied. Check if the `profiles` table triggers are active.
- **Upload Failures**: Confirm that the Supabase Storage bucket named `documents` has been created and set to **Public**. Verify that the RLS upload policies are correctly defined as shown in `SUPABASE_GUIDE.md`.

---
*Analyzed, documented, and verified by Jules, AI Software Engineer.*
