# Serious Study (formerly NoteHub) - Technical Audit & System Manual
*A comprehensive developer-perspective report covering performance, architecture, design, security, and migration.*

---

## Table of Contents
1. [Executive Architecture & Layout Map](#1-executive-architecture--layout-map)
2. [Deep-Dive Performance & Scalability Audits](#2-deep-dive-performance--scalability-audits)
3. [Design Principles & UX Aesthetics](#3-design-principles--ux-aesthetics)
4. [Robust Security & Database Schema Analysis](#4-robust-security--database-schema-analysis)
5. [Future Recommendations & Scaling Roadmap](#5-future-recommendations--scaling-roadmap)
6. [Developer Prerequisite Guide & QA Procedures](#6-developer-prerequisite-guide--qa-procedures)

---

## 1. Executive Architecture & Layout Map

Serious Study is an advanced notes-sharing, community discussion, and academic networking mobile application built explicitly for the Mumbai University student community. The application utilizes a highly decoupled, state-driven model leveraging **GetX** and a serverless **Supabase** backend.

### Decoupled Core Layer Pattern (MVC-like Flow)
The code is structured cleanly into distinct structural layers:

```
                  ┌───────────────────────┐
                  │      Views (UI)       │
                  └───────────┬───────────┘
                              │ GetBuilder / Obx Observables
                              ▼
                  ┌───────────────────────┐
                  │    GetX Controllers   │
                  └───────────┬───────────┘
                              │ Services, Hive Persistent State, SDK
                              ▼
        ┌───────────────────────────────────────────┐
        │            Backend & Storage              │
        │  [Supabase Auth, Database, Storage, RPC]  │
        └───────────────────────────────────────────┘
```

### Complete File & Component Mapping

#### **1. Controllers (`lib/controller/`)**
- **`AuthController`**: Performs JWT token negotiations via Supabase Auth, handles fallback profile creation for users, manages the local session storage in Hive (`userBox`), and fetches count aggregates (e.g., following, followers, documents) via Postgres calls.
- **`DocumentController`**: Handles reactive life-cycles of study resources, manages atomic interaction RPC calls (`increment_likes`, `decrement_dislikes`, etc.), toggles local reactive state for fast UI rendering (Optimistic UI), triggers notifications upon likes, and cleans up storage paths during document deletions.
- **`HomeController`**: Subscribes to real-time notifications and feed alterations via Postgres Changes streaming (`public:documents`). Implements lazy loading / batch limits (50 documents) and performs the "Sticky Sort" algorithms prioritizing official documents.
- **`UploadController`**: Manages document uploads with cover compressions, restricts uploads using size barriers (10MB maximum), supports external links, and accommodates admin functions (setting `is_official` or `post_type` flags).
- **`CommentController`**: Manages the loading and insertion of nested comment structures and replies.
- **`NotificationController`**: Facilitates the parsing and retrieval of global and personal activity feeds.
- **`ProfileController`**: Synchronizes user details and allows live metadata updates.

#### **2. Services (`lib/service/`)**
- **`FileCaching`**: Uses `Dio` downloading utilities and `path_provider` to locally cache documents before launching them with `open_file`, optimizing network requests.
- **`FileDownload`**: Handles high-performance direct byte writes to download destinations on device storage.
- **`NotificationService`**: Coordinates with `flutter_local_notifications` to provide local device push events.

#### **3. Views & Layouts (`lib/view/`)**
- **`Splash` & `Onboarding`**: Guide the user through initialization states and checking cached Hive profiles.
- **`AuthScreen`**: Uses modern glassmorphism panels to provide visual fields for registrations, login flows, and password resets.
- **`HomeScreen`**: Implements a Glassmorphic AppBar, active tab states, and Shimmer animations during lazy loadings.
- **`DocumentScreen`**: Implements reading utilities, comments panels, and download controls.
- **`UploadScreen`**: Handles files picker UI and features an admin panel toggle with modernized active switches.
- **`ProfileScreen`**: Displays instant cached states of user biography, interests, university ID details, and statistics.

#### **4. Models (`lib/model/`)**
- **`UserModel`**: Features annotated annotations for Hive NoSQL persistence and automatic generation (`user_model.g.dart`).
- **`DocumentModel`**: Parsed object schema for notes, links, and tweets containing properties like `isOfficial`, `isExternal`, and `postType`.

---

## 2. Deep-Dive Performance & Scalability Audits

To operate cleanly on standard mid-range mobile devices, Serious Study incorporates multiple frontend and backend optimizations:

### A. Optimistic UI Updates
To achieve near-instantaneous tactile responsiveness, the `DocumentController` updates model parameters locally (e.g., liking/disliking toggles) prior to sending network request confirmations. If the network call encounters failures, GetX seamlessly reverts the properties and alerts the user:

```dart
// Snippet from lib/controller/document_controller.dart
final wasLiked = doc.isLiked;
final originalLikes = doc.likes;

doc.isLiked = !doc.isLiked;
doc.likes += doc.isLiked ? 1 : -1;
update(); // Instant visual feedback to the client

try {
  if (wasLiked) {
    await supabase.from('interactions').delete().match(...);
    await supabase.rpc('decrement_likes', params: {'doc_id': doc.documentId});
  } else {
    // Add interaction & increment via RPC
  }
} catch (e) {
  // Revert UI if network request fails
  doc.isLiked = wasLiked;
  doc.likes = originalLikes;
  update();
}
```

### B. Intelligent Media & Upload Compression
- **Lossless Thumbnails Optimization**: To prevent massive file uploads for note covers, `UploadController` integrates `ImageHelper.compressImage` (powered by `flutter_image_compress`), reducing quality to 70% and normalizing covers into optimized JPEG binaries prior to transit.
- **10MB Direct Upload Limit**: Limits bandwidth consumption. Documents exceeding this limit are restricted, prompting users to share external URLs (e.g., Google Drive, Mega) to preserve system storage.

### C. Persistent Storage Architecture
- **Hive NoSQL Storage**: The app stores authentication state and current profile metadata in `userBox` (relying on high-speed byte indexes). When the application launches, the splash screen fetches user context directly from `HiveBoxes.userBox` without network queries, rendering the main layout instantly.
- **Downloads Metadata**: Local downloads metadata is cached within `downloadsBox` to enable instant offline access verification.

### D. Streaming Updates & Batch Fetching
- **Real-Time Feed Updates**: Subscribes to changes via Postgres Changes (`public:documents`).
- **Batching & Sorting**: Restricts feed requests to `limit(50)` sorted descending by publication date. The algorithm implements a custom **Sticky Sort** putting official documents on top of the list first, then sorting standard notes and posts chronologically.

---

## 3. Design Principles & UX Aesthetics

Serious Study implements a customized Material 3 implementation designed for academic environments.

```
                  ┌───────────────────────┐
                  │    Primary Colors     │
                  │   Premium Deep Blue   │
                  │       (#0D47A1)       │
                  └───────────┬───────────┘
                              ▼
                  ┌───────────────────────┐
                  │     Accent Tones      │
                  │  Premium Gold (#FFD700)│
                  │  Malibu Blue (#4ABCFC)│
                  └───────────┬───────────┘
                              ▼
                  ┌───────────────────────┐
                  │   UI Visual Effects   │
                  │  Linear Glass Gradients│
                  │   Shimmer Loaders     │
                  └───────────────────────┘
```

### Aesthetic Specifications
- **Brand Theme Color**: Premium Deep Blue (`#0D47A1`) replaces generic styling to project academic integrity.
- **Glassmorphism Overlay Layout**: Semi-transparent, layered panels are used heavily across bottom-nav menus and background sheets using a white color configuration with a highly customized opacity alpha parameter:
  ```dart
  Colors.white.withValues(alpha: 0.15) // Replaces deprecated .withOpacity
  ```
- **Custom Icons & SVG**: Vector graphics and standard Material icons are layered with soft shadows.
- **Micro-interactions & Lottie**: Custom animations are used to convey states (such as blank search states, upload loading circles, and success feedback checks).
- **Responsive Theme Configuration**: Supports material component properties across switch elements using standard, non-deprecated variables (e.g., using `activeThumbColor` in `Switch` components instead of `activeColor` to meet Dart SDK ^3.5.4 criteria).

---

## 4. Robust Security & Database Schema Analysis

Serious Study features a highly structured backend architecture built on Supabase, leveraging strict database protections.

### Comprehensive Schema Matrix

| Database Table | RLS Policies | Operations Allowed | Critical Security Feature |
| :--- | :--- | :--- | :--- |
| **`profiles`** | Enabled | Public READ, Authenticated Owner UPDATE/INSERT | Prevent self role escalation (`is_admin`) |
| **`documents`** | Enabled | Public READ, Authenticated Owner INSERT/UPDATE/DELETE | Trigger validation restricts official label to admins |
| **`comments`** | Enabled | Public READ, Authenticated Owner INSERT/DELETE | Nested comments with cascading deletes |
| **`interactions`** | Enabled | User-restricted READ/WRITE | `UNIQUE(document_id, user_id)` stops count manipulations |
| **`bookmarks`** | Enabled | User-restricted READ/WRITE | `UNIQUE(document_id, user_id)` stops bookmarked duplicates |
| **`notifications`** | Enabled | Receiver SELECT/UPDATE, Sender INSERT | Prevents snooping on other users' updates |

### Critical PostgreSQL Security Implementations

#### 1. Privilege Escalation Mitigation
To prevent malicious users from modifying their own roles or setting unauthorized labels, the database implements two layers of protection:
- **`WITH CHECK` on Profile Update**: The RLS policy for profiles prevents users from setting `is_admin` to true:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
  ```
- **Official Label Constraints**: An update trigger prevents non-admin users from altering `is_official` flags inside the `documents` table, rejecting unauthorized operations.

#### 2. Search-Path Hijacking Mitigation
All stored procedures, triggers, and atomic functions are defined with an explicit `SET search_path = public` configuration. This forces PostgreSQL to look up functions and tables within the correct schema, mitigating search-path hijacking attacks.

#### 3. Database Integrity Functions (RPCs)
To keep interaction counters accurate, direct table edits on aggregate counts (such as `likes_count` or `dislikes_count`) are restricted. Changes to these values must pass through atomic PostgreSQL functions configured with `SECURITY DEFINER`.

```sql
CREATE OR REPLACE FUNCTION public.increment_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents
  SET likes_count = likes_count + 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```

---

## 5. Future Recommendations & Scaling Roadmap

To support future growth, developers should consider the following enhancements:

- **1. Paginated Feed Queries**: Replace `.limit(50)` with cursor-based pagination (using the `id` column or `created_at` timestamp) to optimize bandwidth as the collection of notes scales.
- **2. Edge Functions Integration**: Delegate heavy computation (e.g., thumbnail generation, AI-powered PDF classification) to Supabase Edge Functions.
- **3. Object Cleanup Triggers**: Implement PostgreSQL triggers to automatically remove orphaned document cover images from Supabase Storage buckets when a document is deleted.
- **4. Global CDN Caching**: Configure edge caching rules on public buckets to accelerate document downloads for students across Mumbai.

---

## 6. Developer Prerequisite Guide & QA Procedures

### Environmental Requirements
- **Flutter SDK**: `v3.24+` (stable channel recommended)
- **Dart SDK**: `^3.5.4` (ensures modern APIs like `.withValues()` and non-deprecated Switch properties are supported)
- **Java Platform**: `Java 17`
- **Gradle Configuration**: Targeted compile API SDK level `36` with Multidex support.

### Local Quality Assurance & Linting Execution
Always run these checks in your terminal to ensure code health and zero warnings:

```bash
# Navigate to code directory
cd notehub/

# Perform standard Flutter analysis
flutter analyze

# Execute test suite
flutter test
```

---
*Maintained and curated by AI Engineering Operations. Last revised in June 2026.*
