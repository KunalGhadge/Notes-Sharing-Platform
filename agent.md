# Developer Guide & Architectural System Manual - Serious Study

Welcome to the definitive developer guide and architectural manual for **Serious Study** (formerly NoteHub). This document provides an exhaustive, developer-perspective technical breakdown of the application, detailing its architecture, performance optimizations, design paradigm, security governance, file-by-file mapping, and maintenance QA procedures following its migration from legacy Django/MongoDB to a serverless **Supabase** (PostgreSQL) architecture.

---

## 1. Executive Summary & Tech Stack Overview

**Serious Study** is a high-performance academic community platform built for Mumbai University students. It facilitates notes sharing, subject discussion, peer-to-peer networking, and real-time announcements.

### Key Architecture & Tech Stack

| Domain | Technology / Library | Purpose & Developer Context |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter 3.24+ (Dart SDK ^3.5.4) | Cross-platform mobile runtime targeting Android (`compileSdk 36`, Java 17). |
| **State Management** | **GetX** (`GetxController`, `Obx`, `GetBuilder`) | Decoupled reactive state management, routing, and dependency injection. |
| **Local Storage** | **Hive** (`HiveBoxes`, `LazyBox`) | High-performance NoSQL persistent store for user session and profile metadata (`userBox`). |
| **Backend & Auth** | **Supabase Flutter SDK** | Serverless PostgreSQL backend, managed JWT authentication, and Postgres Realtime streams. |
| **Networking & Files** | **Dio** & `path_provider` | Custom file caching engine (`FileCachingService`) for optimized document streaming and offline support. |
| **Media Engine** | `flutter_image_compress` | Client-side compression pipeline targeting 70% JPEG quality before network transit. |
| **UI Aesthetics** | Material 3 + Glassmorphism | Custom Glassmorphic containers, vector graphics (`flutter_svg`), Lottie animations, and Premium Deep Blue theme (`#0D47A1`). |

---

## 2. File-by-File & Component Architecture Mapping

The repository structure follows a clean MVC-like modular architectural pattern:

```text
notehub/
├── android/                   # Native Android wrapper (configured with compileSdk 36, Java 17, desugaring)
├── assets/                    # Vector SVGs, Lottie animations, and static imagery
├── lib/
│   ├── controller/            # GetX Reactive Business Logic Controllers
│   │   ├── auth_controller.dart              # User lifecycle, Supabase Auth, session sync with Hive
│   │   ├── document_controller.dart          # Resource feed, optimistic likes/dislikes, RPC triggers
│   │   ├── home_controller.dart              # Feed fetching, search filtering, official posts stream
│   │   ├── profile_controller.dart           # Active user profile state and local sync
│   │   ├── profile_user_controller.dart      # Target user profile & follow/unfollow logic
│   │   ├── comment_controller.dart           # Comments and nested comment reply engine
│   │   ├── notification_controller.dart     # Activity feed and unread status manager
│   │   ├── upload_controller.dart            # Document upload validation, compression, storage upload
│   │   ├── showcase_controller.dart          # Tabbed profile document showcases (uploaded vs saved)
│   │   ├── bottom_navigation_controller.dart # Main shell navigation index state
│   │   └── search_controller.dart            # Document and user search query handling
│   ├── core/                  # Core Constants & Global Utilities
│   │   ├── config/
│   │   │   ├── color.dart                    # Rebranded palette (Primary Deep Blue #0D47A1) & Gradients
│   │   │   └── typography.dart               # Google Fonts (Poppins) typography hierarchy
│   │   ├── helper/
│   │   │   ├── hive_boxes.dart               # Hive NoSQL initialization, `userBox`, and session accessors
│   │   │   ├── image_helper.dart             # JPEG image compression pipeline
│   │   │   └── custom_icon.dart              # Custom SVG icon renderers & user avatars
│   │   └── meta/
│   │       └── app_meta.dart                 # App branding, API URLs, and avatar generators
│   ├── model/                 # Data Transfer Objects & Schemas
│   │   ├── user_model.dart                   # Profile model with admin flag and counter metadata
│   │   └── document_model.dart               # Resource model supporting notes and tweet post types
│   ├── service/               # Specialized External Services
│   │   ├── file_caching.dart                 # Dio file cache download and path resolver
│   │   └── file_download.dart                # Local notification progress & file saver
│   ├── view/                  # UI Presentation Layer
│   │   ├── auth_screen/                      # Login & registration views
│   │   ├── bottom_footer/                    # Glassmorphic bottom navigation bar
│   │   ├── document_screen/                  # Detailed note view, comment section & tiles
│   │   ├── home_screen/                      # Primary feed header, document list, shimmer placeholders
│   │   ├── notification_screen/              # User notification list view
│   │   ├── profile_screen/                   # Profile header, followers counters, showcase tabs
│   │   ├── search_screen/                    # Instant search interface
│   │   ├── settings_screen/                  # Settings and About page
│   │   ├── splash_screen/                    # Lottie animated launch splash
│   │   ├── upload_screen/                    # Multi-part resource upload form & official toggle
│   │   └── widgets/                          # Shared UI widgets (Admin badge, Document card, Toasts, etc.)
│   ├── layout.dart            # Main application layout wrapper
│   └── main.dart              # Application entrypoint & Supabase client initialization
└── SUPABASE_SCHEMA.sql        # Serverless PostgreSQL database schema, RPC functions, and RLS policies
```

---

## 3. Performance Analysis

### 3.1 Reactive State Management (GetX)
- **Decoupled Architecture**: View widgets (`Obx`, `GetBuilder`) reactively observe state changes in business controllers without expensive full-widget tree rebuilds.
- **Optimistic UI Updates**: Interactions such as liking, disliking, or bookmarking documents update the local UI model immediately (`doc.isLiked = !doc.isLiked`) before asynchronous backend calls complete. On API failure, state is seamlessly reverted with feedback toast messages.

### 3.2 Persistent Local Storage (Hive)
- **Instant App Startup**: `HiveBoxes` provides synchronous access to cached session data (`HiveBoxes.userId`, `HiveBoxes.username`).
- **Profile Caching**: Active user profile data is persisted in `userBox`, allowing the "My Profile" tab and Home header to render instantaneously upon launch without network latency.

### 3.3 Network & Media Optimization
- **File Caching Engine (`file_caching.dart`)**: Uses `Dio` to check for cached local copies of files in the application temporary directory prior to triggering network requests.
- **Client-Side Image Compression (`image_helper.dart`)**: Compresses uploaded cover images to JPEG format with a target quality of 70% and max dimensions of 1024x1024, preventing storage inflation and reducing mobile data usage.
- **Lazy Document Batching**: Document queries fetch in chunks of 50 to optimize payload size and response times.

### 3.4 Database Scalability & Atomic Counters
- **PostgreSQL RPCs**: Counters (`likes_count`, `dislikes_count`, `bookmarks_count`) are updated using server-side PostgreSQL atomic increment/decrement functions (`increment_likes`, `decrement_likes`). This eliminates client-side race conditions.
- **Postgres Realtime Subscriptions**: `HomeController` subscribes to `supabase.channel('public:documents')` to stream live updates to active feeds.

---

## 4. Design & UI/UX Analysis

### 4.1 Design Paradigm: Material 3 & Glassmorphism
- **Color Palette**: Modernized to a "Premium Deep Blue" (`#0D47A1`) theme, paired with soft gold (`#FFD700`) accents for administrative branding.
- **Glassmorphism**: Applied across navigation and cover overlays using `GlassmorphicContainer` and backdrop blur effects.
- **Modernized Color Manipulation**: All color opacity calculations utilize the non-deprecated Dart SDK `.withValues(alpha: ...)` API.

### 4.2 Micro-Interactions & Visual Feedback
- **Animated Interactions**: Like icons feature heart-scale spring animations (`ScaleTransition` with `TweenSequence`).
- **Shimmer Loading States**: Asynchronous data loading presents polished `Shimmer` placeholders across document lists and profile headers.
- **Lottie Feedback**: Empty search states and splash screens utilize Lottie vector animations (`notes.json`).

---

## 5. Security Audit & Backend Governance

### 5.1 Authentication Architecture
- **Supabase Auth (JWT)**: Passwords are encrypted server-side using Argon2/Bcrypt. Clients store access JWTs securely via standard SDK handlers.
- **Session Verification**: `AuthController` verifies local session integrity with `fetchAndStoreProfile()` before allowing complete app access.

### 5.2 Row Level Security (RLS) Deep Dive

Security is strictly enforced in PostgreSQL via Supabase Row Level Security (`SUPABASE_SCHEMA.sql`):

```sql
-- Profiles: Public read, owner-only update
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Documents: Public read, owner-only write/delete
CREATE POLICY "Documents are viewable by everyone" ON public.documents FOR SELECT USING (true);
CREATE POLICY "Users can insert their own documents" ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update/delete their own documents" ON public.documents FOR ALL USING (auth.uid() = user_id);

-- Admin Document Updates: Strict Role Enforcement
CREATE POLICY "Admins can update documents" ON public.documents
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
```

### 5.3 RPC Safety & Security Definer Controls
- Atomic RPC functions use `SECURITY DEFINER` to allow authorized counter updates while preventing users from modifying underlying table records directly.
- Functions explicitly specify `SET search_path = public` to protect against search-path hijacking.

---

## 6. Developer Setup & QA Maintenance Guide

### 6.1 Prerequisites
- **Flutter SDK**: `>= 3.24.0`
- **Dart SDK**: `>= 3.5.4`
- **Java**: Java 17 JDK
- **Android Target**: `compileSdk 36`, `minSdkVersion 21`

### 6.2 Codebase Cleanliness & 'Zero Warnings' QA Rule
All code must strictly adhere to modern Dart/Flutter lint rules:
1. **No Deprecated Color APIs**: Always use `.withValues(alpha: ...)` instead of `.withOpacity(...)`.
2. **Switch Controls**: Use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Braces**: Enclose all `if`, `else`, `for`, and `while` statements in curly braces `{}`.
4. **Empty Catches**: Annotate necessary silent catch blocks with `// ignore: empty_catches`.

### 6.3 Maintenance & Verification Commands

To verify static analysis cleanliness:
```bash
cd notehub
flutter analyze
```

To run the automated test suite:
```bash
cd notehub
flutter test
```

---
*Maintained and Verified by Jules, AI Software Engineer.*
