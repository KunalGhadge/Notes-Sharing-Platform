# Developer Technical Guide & System Manual - Serious Study (formerly NoteHub)

This document provides a comprehensive technical reference and developer-centric system manual for **Serious Study**. It details the application architecture, performance optimizations, design standards, database security policies, and maintenance procedures following the full migration from a legacy Django/MongoDB stack to a serverless **Supabase** and **Flutter** infrastructure.

---

## 1. Executive Summary & Tech Stack Overview

**Serious Study** is a cross-platform mobile and web application tailored for academic content sharing, notes distribution, and community engagement within higher education institutes (specifically targeting Mumbai University).

### Tech Stack
- **Frontend Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management**: GetX (^4.6.6) for reactive dependency injection and route management.
- **Local Persistent Storage**: Hive (^2.2.3) & Hive Flutter (^1.1.0) for high-performance NoSQL local caching.
- **Backend & Database**: Supabase (PostgreSQL 15+) with Row Level Security (RLS) and Supabase Auth.
- **Realtime Services**: PostgreSQL Realtime (pub/sub engine via Supabase Realtime).
- **Network & Caching**: Dio (^5.7.0) with custom file caching service and Path Provider (^2.1.4).
- **UI Framework & Styling**: Material 3, Glassmorphism (^3.0.0), Google Fonts (^8.0.2), Lottie animations (^3.1.3), Flutter SVG (^2.0.10+1).

---

## 2. System Architecture & File Structure Mapping

The frontend project is housed in the `notehub/` directory, adhering to a clean, modular MVC-like pattern decoupled via GetX controllers.

```
notehub/lib/
├── controller/                   # Reactive Business Logic (GetX Controllers)
│   ├── auth_controller.dart      # Session management, login, registration, Hive user sync
│   ├── document_controller.dart  # Document fetching, liking, bookmarking, RPC triggers
│   ├── home_controller.dart      # Realtime document feed, sorting, category filtering
│   ├── profile_controller.dart   # Current user profile management, posts, statistics
│   ├── profile_user_controller.dart # Third-party user profile viewing & follow logic
│   ├── comment_controller.dart  # Threaded comments and reply handling
│   ├── upload_controller.dart   # File/link upload validation and storage push
│   ├── download_controller.dart # PDF/Asset download manager via Dio & Hive
│   ├── notification_controller.dart # Realtime user notifications
│   ├── search_controller.dart   # Debounced document and user query engine
│   └── connection_controller.dart # Followers and network graph management
│
├── core/                         # Global Configurations & Utilities
│   ├── config/
│   │   ├── color.dart            # Primary color palette (Deep Blue #0D47A1), gradients
│   │   └── typography.dart       # Google Fonts text styles (Poppins/Inter)
│   ├── helper/
│   │   ├── hive_boxes.dart       # Hive box initialization & persistent state getters/setters
│   │   ├── image_helper.dart     # Asset compression using flutter_image_compress
│   │   └── custom_icon.dart      # Custom SVG/Icon definitions
│   └── meta/
│       └── app_meta.dart         # Global metadata, Supabase URL & public anon key
│
├── model/                        # Data Models & Adapters
│   ├── user_model.dart           # User profile object with HiveType annotations
│   ├── document_model.dart       # Academic document model (notes, tweets, official posts)
│   ├── mini_user_model.dart      # Lightweight user payload for feeds and comments
│   └── post_model.dart          # Unified feed item model
│
├── service/                      # Infrastructure & Core Services
│   ├── file_caching.dart         # Local file cache strategy checking temp storage before network download
│   ├── file_download.dart        # Background file streaming and notification handlers
│   └── notification_service.dart # Local system notifications via flutter_local_notifications
│
└── view/                         # Modern Material 3 & Glassmorphic UI Screens & Widgets
    ├── auth_screen/              # Login & Register views with form validation
    ├── home_screen/              # Dynamic document feed, search header, category filter
    ├── document_screen/          # Document viewer, comment thread drawer, description
    ├── profile_screen/           # User showcase, uploaded notes, followers list
    ├── upload_screen/            # File upload form, external link poster, official toggle
    ├── notification_screen/      # User activity notifications feed
    ├── official_screen/          # Verified institutional updates and notices
    └── widgets/                  # Reusable UI widgets (DocumentCard, PostCard, AdminBadge, etc.)
```

---

## 3. Performance Analysis & Engineering Strategy

### High-Throughput State Management
- **GetX Reactive Engine**: UI widgets use `Obx()` or `GetBuilder()` to listen to specific reactive variables (`RxBool`, `RxList`, `RxString`), preventing unnecessary full-screen re-renders during state mutations.
- **Optimistic UI Updates**: Interactions like liking a document or bookmarking update the local state immediately (`document.likesCount++`, `isLiked.value = true`), providing instant feedback while asynchronously calling Supabase RPCs in the background.

### Local Persistent Storage (Hive NoSQL)
- **Zero-Latency App Startup**: User credentials and profile metadata are cached locally in `HiveBoxes.userBox`. Upon launch, `HiveBoxes.getUser()` immediately hydrates the user model, bypassing network latency for login verification.
- **Offline Download Indexing**: `HiveBoxes.downloadsBox` tracks downloaded PDF metadata, allowing users to view cached documents offline without querying the server.

### Image & Document Asset Pipeline
- **Media Compression**: `ImageHelper.compressImage()` uses `flutter_image_compress` to re-encode high-resolution uploads to JPEG ( quality 70%, target size 1024x1024) before uploading to Supabase Storage, dramatically reducing bandwidth usage.
- **Smart Image Caching**: Network images leverage `cached_network_image` with low-memory disk cache limits to avoid memory bloat during infinite scrolling.

### Backend Scalability & RPC Operations
- **Atomic Operations via RPCs**: Counter operations (`likes_count`, `dislikes_count`, `followers`) are handled on the PostgreSQL database server using Stored Functions (`RPCs`). This prevents race conditions and lock contention compared to standard client-side read-modify-write patterns.
- **Feed Batching**: `HomeController` fetches documents in batches (default limit: 50) sorted by creation timestamp, ensuring fast response times even as the dataset grows.

---

## 4. Design Architecture & Visual Standards

### Visual Language & Aesthetic
- **Material 3 Foundation**: Built using Material Design 3 guidelines with expressive shape corner radii and soft surface elevations.
- **Glassmorphism Styling**: Features translucent cards, blur filters (`BackdropFilter`), and multi-layered semi-transparent white/blue borders (`Colors.white.withValues(alpha: 0.15)`).
- **Brand Color Palette**:
  - **Primary Accent**: Premium Deep Blue (`#0D47A1`).
  - **Secondary Accent**: Royal Blue (`#1976D2`).
  - **Highlight / Admin**: Premium Gold (`#FFD700`) for verified institutional badges.
  - **Gradients**: `AppGradients.premiumGradient` transitions smoothly between Deep Blue and Royal Blue across headers and primary action buttons.

### Modern Flutter API Compliance
- All color opacity calls utilize `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
- `Switch` widgets explicitly define `activeThumbColor` to satisfy Dart ^3.5.4 zero-warning requirements.

---

## 5. Security Analysis, RLS Audit & Vulnerability Remediation

### Authentication & Session Security
- **Supabase Auth (JWT)**: Standard JSON Web Tokens (JWT) are used for authentication. Tokens are stored securely by the Supabase SDK client.
- **Password Protection**: Passwords are saved and hashed server-side by Supabase Auth using Argon2/Bcrypt; plain-text passwords never pass through or store in application storage.

### Row Level Security (RLS) Policy Verification
Every PostgreSQL table defined in `SUPABASE_SCHEMA.sql` enforces strict RLS policies:

| Table | SELECT Policy | INSERT Policy | UPDATE / DELETE Policy |
| :--- | :--- | :--- | :--- |
| `profiles` | Public read (`USING (true)`) | Self only (`auth.uid() = id`) | Self only (`auth.uid() = id`) |
| `documents` | Public read (`USING (true)`) | Authenticated owner (`auth.uid() = user_id`) | Owner or Admin (`auth.uid() = user_id OR is_admin`) |
| `comments` | Public read (`USING (true)`) | Authenticated user (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `notifications` | Receiver read (`auth.uid() = receiver_id`) | Authenticated sender | System/Receiver |
| `bookmarks` | Owner read (`auth.uid() = user_id`) | Authenticated owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `interactions` | Owner read (`auth.uid() = user_id`) | Authenticated owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |

### Vulnerability Remediation (Privilege Escalation Prevention)
- **Profile Escalation Fix**: Previously, a user could send an `UPDATE` payload modifying `is_admin = true` on their profile. To prevent this, the `profiles` table update policy is bounded with a `WITH CHECK` clause ensuring `is_admin` cannot be changed by non-administrative users.
- **Official Status Enforcement**: Setting `is_official = true` on documents during upload is enforced at both the application level (`UploadController`) and via database policies restricting official posting privileges to users flagged as `is_admin = true`.
- **Search Path Hijacking Protection**: Stored PostgreSQL RPC functions explicitly set `SET search_path = public` to protect against search path injection vulnerabilities.

---

## 6. Database Schema Specifications (`SUPABASE_SCHEMA.sql`)

### Database Diagram Overview
```
+------------------+         +--------------------+         +-------------------+
|     profiles     |         |     documents      |         |     comments      |
+------------------+         +--------------------+         +-------------------+
| id (UUID, PK)    |<-------1| id (BIGINT, PK)    |<-------1| id (UUID, PK)     |
| username (TEXT)  |         | user_id (UUID, FK) |         | document_id (FK)  |
| display_name     |         | name (TEXT)        |         | user_id (UUID, FK)|
| institute (TEXT) |         | topic (TEXT)       |         | parent_id (UUID)  |
| is_admin (BOOL)  |         | document_url (TEXT)|         | content (TEXT)    |
| followers (INT)  |         | likes_count (INT)  |         +-------------------+
| following (INT)  |         | is_official (BOOL) |
+------------------+         | post_type (TEXT)   |
                             +--------------------+
```

### Stored PostgreSQL Functions (RPCs)
- `increment_likes(doc_id)` / `decrement_likes(doc_id)`: Atomically updates `likes_count` on `documents`.
- `increment_dislikes(doc_id)` / `decrement_dislikes(doc_id)`: Atomically updates `dislikes_count` on `documents`.
- `increment_bookmarks(doc_id)` / `decrement_bookmarks(doc_id)`: Manages user bookmark counters.

---

## 7. Development, Quality Assurance & Maintenance Guidelines

### Prerequisites
- Flutter SDK: `3.24.0` or higher.
- Dart SDK: `^3.5.4`.
- CocoaPods (for iOS build targets) / Java 17 (for Android build targets).

### Standard Maintenance Workflow
1. **Analyze Code**:
   Always run static analysis from the `notehub/` directory before pushing changes:
   ```bash
   cd notehub
   flutter analyze
   ```
   *Requirement*: Zero errors or warning regressions allowed.

2. **Run Unit Tests**:
   Execute the test suite to verify controller logic and dummy fallbacks:
   ```bash
   cd notehub
   flutter test
   ```

3. **Database Schema Migrations**:
   Any modification to backend tables or RLS policies must be declared idempotently using `IF NOT EXISTS` in `SUPABASE_SCHEMA.sql`.

---
*Maintained and documented by Jules, AI Software Engineer.*
