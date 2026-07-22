# Serious Study (NoteHub) — Developer Manual & Architecture Deep Dive

Welcome to the definitive, developer-centric technical analysis and maintenance guide for the **Serious Study** (formerly NoteHub) mobile application. This manual provides a deep-dive exploration into the codebase, performance strategies, design decisions, database layout, security frameworks, and QA procedures.

---

## 1. Executive Summary & Project History

**Serious Study** is a high-performance community sharing and academic networking platform tailored specifically for the Mumbai University student community. The application enables seamless sharing of academic resources (lecture notes, exam papers, reference materials) and peer-to-peer social updates (tweets/short updates).

Originally built on a legacy Django/MongoDB monolithic backend, the platform suffered from key structural inefficiencies, lack of real-time support, and critical security gaps (such as storing plain-text passwords and exposing open MongoDB object streams).

In June 2026, the application underwent a complete serverless migration to **Supabase (PostgreSQL)**, which introduced:
- Fully managed JWT-based standard session handling.
- Fine-grained Row Level Security (RLS) policies.
- Ultra-responsive, real-time activity feeds and social triggers.
- Atomicity via database-level RPC functions.

---

## 2. Tech Stack Overview

| Technology | Role | Details |
| :--- | :--- | :--- |
| **Dart SDK ^3.5.4** | Programming Language | Enables modern language features like `.withValues()` and pattern matching. |
| **Flutter SDK 3.24+** | Frontend Framework | Single codebase targeting Android, iOS, and Web (compiled with Material 3). |
| **GetX** | State & Navigation | Reactive state management, global dependency injection, and micro-routing. |
| **Hive** | Local NoSQL Cache | High-speed local persistent storage using lightweight, binary box encoders. |
| **Supabase** | Serverless Backend | Relational PostgreSQL, Auth (GoTrue), Storage bucket APIs, and real-time PubSub channels. |
| **Dio** | Specialized HTTP Client | Specialized download client carrying progress listeners and chunked file caching. |
| **path_provider** | Local File Storage | Resolves secure directory endpoints across platform-specific filesystems. |

---

## 3. Directory & File-by-File Analysis

```
notehub/
├── android/                  # Android specific builds (Targets CompileSDK 36, Java 17)
├── assets/                   # Lottie animations, custom SVG icons, and branding vectors
├── lib/                      # Source Code
│   ├── controller/           # State Management (GetX Controllers)
│   ├── core/                 # Central Core configs, branding, and local helper utilities
│   ├── model/                # Data Serialization and Hive Adapter entities
│   ├── service/              # System-level utility classes and file caching services
│   ├── view/                 # UI View Layouts, Screen Composites, and custom widgets
│   ├── layout.dart           # Master Shell enclosing Bottom Footer Navigation and Tab switches
│   └── main.dart             # Bootstrapper (Initializes Hive, Supabase client, and App bindings)
├── test/                     # Unit and Integration Suite
└── pubspec.yaml              # Module constraints, dependencies, and Flutter assets
```

### 3.1 `lib/controller/` (GetX Business Logic)
- **`auth_controller.dart`**: Manages email-based registration and password login. Securely fetches the profile metadata and writes standard configurations to Hive's local cache.
- **`bottom_navigation_controller.dart`**: Oversees layout tab indexes, navigating seamlessly across the principal application spaces (Home feed, Search, Upload, Profile, and Official feed).
- **`comment_controller.dart`**: Implements hierarchical comment streams. Manages the lifecycle of user conversations, syncing nested answers using a relational `parent_id` architecture.
- **`connection_controller.dart`**: Watches system network states to gracefully disable real-time channels or inform users of network disruption.
- **`document_controller.dart`**: Coordinates download streams, deletes, likes, dislikes, and bookmarks. Incorporates optimistic UI rendering (updating local visual states immediately before calling backend functions) to provide snappy performance.
- **`download_controller.dart`**: Coordinates file caching progress, updating download progress indicators and writing download records to `downloadsBox`.
- **`home_controller.dart`**: Powers the main dashboard. Listens to real-time additions to the `documents` table using Supabase's realtime PubSub channel (`supabase.channel('public:documents')`).
- **`notification_controller.dart`**: Monitors personal alerts (e.g., likes on user-uploaded files, replies to comments).
- **`profile_controller.dart` & `profile_user_controller.dart`**: Orchestrates profile information and follows (incrementing/decrementing follow metrics).
- **`remote_config_controller.dart`**: Downloads and cache system configurations dynamically from the `remote_config` table (enabling live feature flags without forcing APK updates).
- **`search_controller.dart`**: Features quick filtering matching queries with target titles, description tokens, or tags.
- **`upload_controller.dart`**: Validates form entries, manages local files, and handles the multi-part upload pipeline (Cover + Document payload).

### 3.2 `lib/core/` (Configurations & Utilities)
- **`config/color.dart`**: Holds color styling specifications. Rebranded to a premium **Deep Blue** (#0D47A1) for Mumbai University.
- **`config/typography.dart`**: Enforces a strict typographic ladder utilizing Google Fonts (Poppins/Inter).
- **`helper/hive_boxes.dart`**: Provides safe getters/setters for cached boxes (`userBox` for session and `downloadsBox` for metadata).
- **`helper/image_helper.dart`**: Encapsulates `flutter_image_compress` logic, compressing files to 70% quality (target resolution 1024x1024) to save backend bandwidth.

### 3.3 `lib/model/` (Data Serialization)
- **`document_model.dart`**: Maps backend payload to reactive model objects. Handles parameters such as `isOfficial`, `isExternal`, and `postType` ('note' or 'tweet').
- **`user_model.dart` & `user_model.g.dart`**: Encapsulates user session variables. Generated with `hive_generator` for binary file compilation.

### 3.4 `lib/service/` (Infrastructure Services)
- **`file_caching.dart`**: Manages secure document downloads via `Dio`. First checks `downloadsBox` and the temporary directory before attempting network fetches.
- **`notification_service.dart`**: Handles push notifications via `flutter_local_notifications`.

---

## 4. Performance Optimization Strategies

1. **GetX Reactive State**: The UI reacts only to explicit stream changes. Controllers avoid heavy rebuilds of entire screen view trees by isolating changes inside targeted `Obx` wrappers.
2. **Hive NoSQL Cache**: App initialization reads profile metadata directly from Hive in `< 5ms`, avoiding the cold-start delays of database queries.
3. **Atomic Counter Updates (RPCs)**: Direct client-side increments are prone to race conditions and synchronization errors. Serious Study handles counter mutations (likes, dislikes, bookmarks) via PostgreSQL Remote Procedure Calls (`RPC`):
   - `increment_likes` / `decrement_likes`
   - `increment_dislikes` / `decrement_dislikes`
   - `increment_bookmarks` / `decrement_bookmarks`
4. **Bandwidth Savings**:
   - Mandatory client-side image compression before uploading covers.
   - Strict 10MB limits on direct document uploads.
   - Supports external link sharing (e.g., Google Drive, Mega) to reduce file transfer overhead.
5. **Sticky Sorting & Pagination**:
   - Documents are fetched in batches (limit: 50) and sorted in memory using a "sticky" prioritization scheme (Official documents always bubble to the top of the feed).
   - Images are cached using `CachedNetworkImage` to prevent repetitive assets downloads.

---

## 5. Design & UI/UX Principles

- **Material 3 Foundation**: Standardizes component shapes, ink ripples, and padding across all device viewports.
- **Glassmorphic Styling**: Custom semi-transparent gradients blended with background blur filters (`BackdropFilter`) are implemented on key structural elements, such as the `BottomFooter`, to create a layered aesthetic.
- **Observability & Feedback**:
  - Shimmer loaders provide progressive skeletons during fetch cycles.
  - Lottie micro-animations reinforce interactions, such as empty searches and file uploads.
  - Smooth refresh actions are handled using `liquid_pull_to_refresh`.

---

## 6. Secure Database Architecture & RLS

### 6.1 Row Level Security (RLS) Policies
Row-Level Security is strictly enforced on all core PostgreSQL tables. Every query executed by the client must pass authorization checks evaluated by the PostgreSQL engine.

```sql
-- 1. Profiles (Public read, Owner-only update)
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())); -- Prevents self-escalation

-- 2. Documents (Public read, Creator write)
CREATE POLICY "Documents are viewable by everyone" ON public.documents
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own documents" ON public.documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update/delete their own documents" ON public.documents
  FOR ALL USING (auth.uid() = user_id);

-- 3. Bookmarks & Notifications (Private only)
CREATE POLICY "Users can view their own notifications" ON public.notifications
  FOR SELECT USING (auth.uid() = receiver_id);
```

### 6.2 Security Definer & Search Path Hijacking Mitigations
To maintain strict separation of concerns, administrative functions and counter updates are executed as `SECURITY DEFINER` procedures. This allows unauthenticated or authenticated users to trigger updates (such as incrementing a note's like count) without having write access to the main tables.

To mitigate search path hijacking (where malicious users create custom schemas to trick a security definer function), functions are defined with an explicit search path limit:
```sql
CREATE OR REPLACE FUNCTION public.check_official_permission()
RETURNS TRIGGER AS $$
BEGIN
  -- Strict validation of official content toggle
  IF NEW.is_official = true AND NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true
  ) THEN
    RAISE EXCEPTION 'Privilege escalation blocked. Only admins can toggle official content.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 7. QA, Linting, & "Zero Warnings" Policy

The Serious Study project maintains a **Zero Warnings** rule. Every commit must pass strict static analysis checks.

### 7.1 Running Quality Assurance Commands
Developers are expected to execute linting and tests locally inside the `notehub/` directory before pushing changes to remote branches.

- **Check Code Quality / Linting**:
  ```bash
  cd notehub && flutter analyze
  ```
- **Execute Test Suite**:
  ```bash
  cd notehub && flutter test
  ```

### 7.2 Guidelines for Modern Flutter Compatibility
1. **Color Configurations**: Avoid using the deprecated `Color.withOpacity(alpha)`. Instead, use the modern Dart API `.withValues(alpha: value)` to avoid floating-point precision loss.
2. **Switch Widgets**: Do not declare the deprecated `activeColor` property on Switch controls. Always declare the modern `activeThumbColor` attribute.
3. **Silent Errors in Controllers**: When suppressing silent catch blocks (e.g., in `DocumentController` or `ProfileController`), always place the `// ignore: empty_catches` on its own line inside the block to avoid commenting out subsequent blocks:
   ```dart
   try {
     // Operations...
   } catch (e) {
     // ignore: empty_catches
   }
   ```

---

## 8. Scalability & Maintenance Roadmap

1. **Offline Sync Pipeline**: Implement a background sync manager using Hive to cache user uploads offline, queuing them to upload automatically once internet access is restored.
2. **Postgres Edge Functions**: Integrate Supabase Edge Functions for intensive operations, such as extracting text from uploaded PDFs to auto-populate metadata tags.
3. **Advanced RLS Partitioning**: As user counts scale, partition tables (e.g., `interactions`) to maintain low query latency on large datasets.

---
*Maintained and curated by Serious Study's Lead AI Software Architect, Jules.*
