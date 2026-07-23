# Serious Study (formerly NoteHub) — Developer Guide & Maintenance Manual

This document serves as the primary system manual, technical reference, and maintenance guide for the **Serious Study** Android application (rebranded from NoteHub). It is designed to provide future software engineers and AI developers with a deep-dive analysis of the codebase, covering architecture, performance, UI/UX design, database schema, state management, and comprehensive security policies.

---

## 1. Executive Summary & Tech Stack

Serious Study is a premium, decentralized academic social networking and resources sharing application tailored specifically for the Mumbai University student community. The application allows users to discover, upload, upvote, comment on, bookmark, and download high-quality academic notes and resources.

The project represents a complete modernization from a legacy, session-less Django/MongoDB backend to a modern, high-performance serverless **Supabase (PostgreSQL)** database engine.

### Tech Stack Overview
- **Frontend Framework**: Flutter 3.24+ (Channel Stable)
- **Dart SDK**: ^3.5.4 (Ensures compatibility with modern APIs and strict lint rules)
- **State Management & DI**: GetX (Model-View-Controller pattern)
- **Local Database**: Hive NoSQL (High-performance caching for rapid application startup)
- **Database Engine**: PostgreSQL via Supabase Serverless Architecture
- **Real-Time Subscription**: Supabase Realtime Channels (WebSocket-based PostgreSQL changes)
- **Network Client**: Supabase Client SDK & Dio (for large file caching and chunked downloads)
- **Media Compression**: `flutter_image_compress` for cover image optimization

---

## 2. Directory Structure & Architecture Model

The application utilizes a modular MVC-like layout where business logic is strictly decoupled from presentation components.

```
notehub/
├── android/               # Android native configurations (compileSdk 36, Java 17)
├── assets/                # Local static vectors, images, and Lottie animations
├── lib/
│   ├── controller/        # GetX Controllers managing state and API integrations
│   ├── core/
│   │   ├── config/        # Centralized theme (Premium Deep Blue) and typography definitions
│   │   ├── helper/        # Custom helpers (Hive database boxes, image compress, icons)
│   │   └── meta/          # AppMetaData configuration variables (API Keys, Supabase URLs)
│   ├── model/             # Decoupled data parsing models (User, Document, Post, Comments)
│   ├── service/           # Standalone services (File download caches, native notifications)
│   ├── view/              # Modular UI components, screens, and custom widgets
│   ├── layout.dart        # Core Bottom Navigation Wrapper layout structure
│   └── main.dart          # Entry point and global GetX dependency initializer
└── test/                  # Automated integration and widget test cases
```

---

## 3. Deep-Dive Performance Optimization

To deliver a highly fluid mobile experience (60/120 FPS targets), the application incorporates advanced optimization protocols across several domains:

### 3.1 Media Compression Pipeline
Uncompressed mobile screenshots and document cover images represent a major source of storage and bandwidth overhead. The application handles this via `ImageHelper.compressImage` located in `lib/core/helper/image_helper.dart`:
- Captures source image assets via `FilePicker`.
- Compresses images to JPEG format at **70% quality** with a target resolution bounding box of **1024x1024**.
- Writes output to a temporary `.jpg` cache before initiating Supabase Storage uploads.
- This results in up to a **90% file size reduction** while retaining complete readability of the preview cover.

### 3.2 Caching and Local Database (Hive)
Two critical Hive boxes are registered during the application launch in `main.dart`:
1. **`userBox`**: High-performance local persistence of current session profile data mapped using the compiled `user_model.g.dart` adapter. User credentials, institute ("Mumbai University"), profile avatar URL, and interaction statistics are parsed and loaded instantly upon app launch, removing startup latency and enabling offline profile rendering.
2. **`downloadsBox`**: Tracks local paths of downloaded PDF files and document models. This allows the application to check if a resource is already stored locally before performing unnecessary network calls.

### 3.3 Fine-grained Network File Cache
The utility `lib/service/file_caching.dart` optimizes PDF and notes rendering:
- Implements `Dio` to stream and write large documents into the system's sandbox temporary directory.
- Prior to starting any download task, it evaluates if a file with the matched suffix/hash exists using `ifFileExists`.
- If the file is present, the download is aborted, and the cached local filesystem path is supplied directly to the file viewer, conserving student bandwidth.

### 3.4 Database Query Performance (Batching & Sticky Sort)
- **Pagination and Payload Limits**: Feed resources inside the `HomeController` are queried in batches of exactly **50 items** per call using PostgreSQL limits (`limit(50)`) to maintain fast payload parsing.
- **Sticky Sort Strategy**: Feeds are arranged dynamically on the client side using a sticky-sort algorithm where admin-curated/verified "Official" items are hoisted to the top of the feed (`is_official DESC`), followed by descending chronological sort order (`created_at DESC`).

---

## 4. State Management & Real-Time Sync

The presentation layers remain reactive and synchronized with backend events through GetX state tracking.

### 4.1 State Management Lifecycle
GetX controllers inherit from `GetxController` to hook directly into the widget lifecycles:
- **`onInit()`**: Used to initialize controllers, instantiate streams, and pull starting payloads.
- **`onClose()`**: Destroys active subscriptions, clears temporary memory pools, and prevents resource leaks.

### 4.2 Optimistic UI Updates
To elevate perceived performance during user engagement, the `DocumentController` employs optimistic state updates for interactions like likes, dislikes, and bookmarks:
1. When a student triggers a "Like" button, the UI immediately increments the count and switches active icons.
2. An asynchronous RPC update is fired to the backend in the background.
3. If the backend fails (e.g., poor connectivity, postgrest exception), the transaction catches the error, rolls back the client-side UI counter, and prompts the user with a Toast notification.

### 4.3 WebSocket Real-time Postgres Change Channel
Rather than polling endpoints, the app leverages real-time push capabilities. The `HomeController` initiates a connection to the PostgreSQL database subscription channels:
- `supabase.channel('public:documents').onPostgresChanges(...)`
- It listens for any changes (INSERT, UPDATE, DELETE) inside the `documents` table and triggers immediate update calls on the current device list seamlessly.

---

## 5. Security & Supabase Schema Architecture

The migration to Supabase introduces enterprise-grade security controls directly at the database layer.

### 5.1 Database Models
The relational design mapped inside `SUPABASE_SCHEMA.sql` ensures clean data organization:
- **`profiles`**: Tied strictly to Supabase Auth UUIDs (`auth.users`), mapping student profiles.
- **`documents`**: The central content container. Supports direct PDF uploads or external link mapping (`is_external`), as well as multi-format content sharing (notes or Tweets).
- **`interactions` / `bookmarks`**: Unique join tables enforcing singular unique records per user/document pair (`UNIQUE(document_id, user_id)`), preventing interaction gaming.
- **`notifications`**: Powers in-app notifications and announcements.
- **`followers`**: Resolves follower/following relationships.

### 5.2 Row Level Security (RLS) Policies
Row Level Security is globally enabled for all relational tables, ensuring no client can alter data outside their authorized scope.

| Table | Policy Name | Permitted Actions | Security Check / Logic |
| :--- | :--- | :--- | :--- |
| **`profiles`** | Public read, owner write | `SELECT` for all; `UPDATE` for owner | `auth.uid() = id` (Ensures profile changes belong only to the creator) |
| **`documents`**| Public read, owner write | `SELECT` for all; `INSERT/UPDATE/DELETE` for owner | `auth.uid() = user_id` |
| **`comments`** | Public read, owner write | `SELECT` for all; `INSERT` for owner | `auth.uid() = user_id` |
| **`notifications`** | Private access | `SELECT` for recipient only | `auth.uid() = receiver_id` |

### 5.3 Privilege Escalation Countermeasures
Several safeguards exist to protect system administrative roles and prevent malicious privilege escalation:
- **Profile Self-Promotion Block**: A strict `WITH CHECK` constraint is configured on the `profiles` table update policy. A user updating their profile information is locked to their existing administrative state:
  `WITH CHECK (auth.uid() = id AND is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()))`
  This ensures any attempt to pass `is_admin = true` inside a profile payload is dropped by the query processor.
- **Content Authenticity Trigger**: Setting `is_official = true` inside the `documents` table is restricted to validated administrators. Database triggers (`ensure_official_permission`) intercept write operations to verify that the creator profile's `is_admin` is true prior to saving:
  ```sql
  CREATE OR REPLACE FUNCTION check_official_permission() RETURNS TRIGGER AS $$
  BEGIN
    IF NEW.is_official = true AND NOT EXISTS (
      SELECT 1 FROM public.profiles WHERE id = NEW.user_id AND is_admin = true
    ) THEN
      RAISE EXCEPTION 'Privilege escalation prevented: Only administrators can label content as official.';
    END IF;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SET search_path = public;
  ```
- **Search-Path Hijacking Mitigation**: In compliance with PostgreSQL best practices, all triggers and custom RPC functions are explicitly compiled with `SET search_path = public` to mitigate search-path hijacking attacks.

### 5.4 Secure Counter Increments via Isolated RPCs
To avoid race conditions and database manipulation vulnerabilities, user-facing client controllers cannot directly modify likes, dislikes, or bookmark counts in the `documents` table.
- Direct edits to documents table numbers are forbidden by RLS.
- Updates are processed via specialized PostgreSQL Functions (`RPC`) declared with `SECURITY DEFINER` (e.g., `increment_likes`, `decrement_likes`). These functions validate user presence, process changes atomically, and manage counters securely inside database space.

---

## 6. UI/UX & Responsive Design Patterns

The layout balances structural efficiency with premium styling to match its academic branding:

- **Premium Deep Blue Theme**: Rooted in `#0D47A1` primary seed colors, symbolizing the identity of Mumbai University.
- **Glassmorphism Overlay Pattern**: Semi-transparent, blur-backed containers (utilizing `BackdropFilter` and `.withValues(alpha: ...)` color definitions) offer layered layouts for profiles, headers, and footer bottom navigation widgets.
- **Liquid Refreshes & Visual Indicators**: The feed implements `liquid_pull_to_refresh` to animate asynchronous feed fetches, paired with custom Shimmer loader widgets to represent un-rendered rows.
- **Lottie Animators**: Integrates interactive vectors representing state behaviors, such as empty-state notification feeds or upload success checkpoints.

---

## 7. QA, Maintenance, and Zero Warnings Compliance

Strict adherence to code guidelines ensures frictionless continuous integration (CI) and reliable builds:

### 7.1 Modernization Requirements
The project strictly enforces Flutter modern coding conventions. The following patterns are mandatory for zero-warning static analysis runs:
- **Opacity Declarations**: Deprecated `.withOpacity(x)` invocations must be modernized to `.withValues(alpha: x)` to prevent runtime precision losses.
- **Switch Widgets**: Deprecated `activeColor` switches inside form inputs must utilize `activeThumbColor` properties to align with Flutter's Material 3 styling engine.
- **Silent Exceptions**: Whenever silent exception parsing is needed inside controllers (e.g., `try-catch` structures without explicit log targets), the `// ignore: empty_catches` directive must be placed on its own line inside the block to preserve indentation.
- **Flow Control Braces**: All conditional branches (`if-else`) and Obx builders must encapsulate executable blocks within explicit curly braces `{}` to satisfy code analysis protocols.

### 7.2 Testing and Verification Steps
Maintain absolute build compliance by executing validation tasks before commits:
1. **Analyze Static Integrity**:
   Run static lint checks inside the primary sub-directory:
   ```bash
   cd notehub
   flutter analyze
   ```
   Ensure the output reports **"No issues found!"**
2. **Execute Automated Tests**:
   Ensure all critical integration cases run and resolve successfully:
   ```bash
   flutter test
   ```

---
*Analyzed, Refined, and Documented by Jules, Principal Software Engineer.*
*Verified Zero Warnings Compliant — June 2026*
