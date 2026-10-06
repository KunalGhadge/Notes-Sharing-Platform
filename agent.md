# Developer Guide & Deep Technical Manual - Serious Study (formerly NoteHub)

This document serves as the primary system manual, developer guide, and architectural reference for the **Serious Study** Android application codebase. It provides a deep-dive analysis from a senior software engineer's perspective, covering performance optimizations, UI/UX design architecture, database governance, security posturing, and developer maintenance procedures.

---

## 1. Executive Summary & Tech Stack Overview

**Serious Study** is a high-performance academic content and social platform designed for the Mumbai University student community. The application was migrated from a legacy Django/MongoDB stack to a modern serverless backend architecture powered by **Supabase** (PostgreSQL) and a **Flutter** client.

### Tech Stack Matrix
- **Client Framework**: Flutter 3.24+ (Dart SDK ^3.5.4)
- **State Management & Routing**: GetX (Reactive architecture, dependency injection)
- **Local Storage / Caching**: Hive (NoSQL local persistent storage for user profile & session caching)
- **Networking & API**: Supabase Flutter SDK (Realtime, PostgREST, Auth), Dio (High-performance file transfers & HTTP caching)
- **Database & Serverless Logic**: PostgreSQL with Row Level Security (RLS), Atomic RPC Functions, Database Triggers, and Realtime Subscriptions
- **Media Optimization**: `cached_network_image`, `flutter_image_compress`

---

## 2. Codebase Architecture & File Mapping

The application follows a decoupled, reactive **MVC-like (Model-View-Controller)** pattern where views consume reactive controllers powered by GetX.

```
notehub/lib/
├── main.dart                          # Application entry point & Supabase/Hive initialization
├── layout.dart                        # Root navigation wrapper with bottom navigation bar
├── controller/                        # GetX controllers managing business logic & state
│   ├── auth_controller.dart           # Supabase Auth, local session sync, user profile setup
│   ├── home_controller.dart           # Document feed, batch fetching, search/filter, official updates
│   ├── document_controller.dart       # Document detail operations, likes/dislikes RPCs, downloads
│   ├── upload_controller.dart         # Multi-part document & thumbnail upload pipeline, image compression
│   ├── profile_controller.dart        # User profile, follower management, user documents
│   ├── comment_controller.dart        # Nested document commentary state & RPC sync
│   ├── notification_controller.dart   # In-app notifications & announcement state
│   ├── search_controller.dart        # Multi-field document & user search
│   └── download_controller.dart      # Local download manager with Hive metadata tracking
├── service/                           # External services & hardware interactions
│   ├── file_caching.dart              # Dio-based cached file downloads & local path provider
│   ├── file_download.dart             # Storage manager & file viewer handler
│   └── notification_service.dart      # Flutter Local Notifications integration
├── model/                             # Strongly typed Data Models
│   ├── user_model.dart                # User profile model with Hive annotations
│   ├── document_model.dart            # Academic document metadata model
│   ├── post_model.dart                # Post & tweet content model
│   └── mini_user_model.dart           # Simplified user entity for list representations
├── core/                              # App-wide constants, configurations, utilities
│   ├── meta/app_meta.dart             # Environment config & Supabase credentials
│   ├── config/color.dart              # Material 3 & Premium Deep Blue color palette
│   ├── config/theme.dart              # Global ThemeData & Glassmorphic styling
│   └── helper/
│       ├── hive_boxes.dart            # Hive box wrappers for session & downloads
│       └── image_helper.dart          # Media asset compression utility
└── view/                              # Modular UI Components & Screens
    ├── auth_screen/                   # Login & registration screens
    ├── home_screen/                   # Document feed & category filtering
    ├── document_screen/               # Details view, viewer, comment sections
    ├── profile_screen/                # User profile & follower/following lists
    ├── upload_screen/                 # Document creation & official toggle forms
    ├── notification_screen/           # Activity feed & announcements
    ├── settings_screen/               # App configuration & about screen
    └── widgets/                       # Reusable custom UI components (cards, badges, buttons)
```

---

## 3. Deep-Dive Developer Analysis

### 3.1 Performance Analysis & Optimizations
- **Reactive State Management (GetX)**:
  - Business logic is strictly decoupled from UI widgets. Controllers use reactive observables (`.obs`) to notify views only when required state updates occur, eliminating unnecessary widget re-renders.
  - Optimistic UI updates are used in `DocumentController` for instant feedback on likes/dislikes/bookmarks before backend RPC network responses complete.
- **High-Performance Local Caching (Hive)**:
  - User session details and active profiles are cached in local NoSQL Hive boxes (`userBox`). Upon app startup, the user state is loaded synchronously from disk, eliminating startup delays.
  - Downloaded document metadata is tracked in `downloadsBox` to allow seamless offline access.
- **Network & Media Efficiency**:
  - **Image Compression**: `ImageHelper.compressImage` automatically compresses cover images (Target JPEG format, 70% quality, max 1024x1024 resolution) before uploading to Supabase Storage, reducing network overhead and storage costs.
  - **Batch Fetching & Pagination**: `HomeController` fetches document feeds in controlled batches (limit 50 per page) with sticky sort criteria to ensure low memory consumption.
  - **Network Caching**: Image thumbnails utilize `cached_network_image` to avoid redundant downloads across app screens.

### 3.2 Design Architecture & Visual Aesthetics
- **Material 3 Paradigm**: Built on Flutter's Material 3 design system, incorporating modern typography and dynamic elevation.
- **Rebranded Color Palette**:
  - **Primary Accent**: Premium Deep Blue (`#0D47A1`), representing academic trust and precision for Mumbai University students.
  - **Background & Card Surfaces**: Modern dark and light contrast surfaces paired with subtle gradients (`AppGradients.premiumGradient`).
- **Glassmorphism Aesthetic**:
  - Backdrop filters and semi-transparent color overlays (e.g., `.withValues(alpha: 0.15)`) are utilized on bottom navigation overlays, header bars, and profile summary cards.
- **User Feedback & Micro-Interactions**:
  - Shimmer placeholder widgets (`HomeDocumentSection`, `SearchPage`) provide visual structure during network requests.
  - Lottie vector animations communicate empty states, loading indicators, and submission successes.

### 3.3 Security Architecture & Database Governance
The backend transition from legacy MongoDB/Django to serverless Supabase PostgreSQL implemented robust enterprise security principles:

- **JWT Authentication & Passwords**:
  - Client authentication utilizes Supabase Auth using short-lived JSON Web Tokens (JWT). Passwords are hashed server-side using Argon2/Bcrypt and are never exposed in transit or at rest.
- **Row Level Security (RLS)**:
  - Every database table in `SUPABASE_SCHEMA.sql` enforces strict RLS policies:
    - `profiles`: Publicly readable; `UPDATE` policy strictly requires `auth.uid() = id`.
    - `documents`: Publicly readable; `INSERT`, `UPDATE`, and `DELETE` policies enforce ownership (`auth.uid() = user_id`).
    - `interactions` & `bookmarks`: Restricted to the owning user ID.
    - Privilege escalation prevention: The `is_admin` column updates are protected by database policy and restricted triggers (`ensure_official_permission`).
- **Atomic Operations & RPCs**:
  - Counter mutations (`likes_count`, `dislikes_count`) execute via PostgreSQL functions configured with `SECURITY DEFINER` and explicit `SET search_path = public` directives to mitigate search-path hijacking.

---

## 4. Database Schema Reference (`SUPABASE_SCHEMA.sql`)

```sql
-- 1. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  profile_url TEXT,
  institute TEXT,
  academic_interests TEXT[],
  bio TEXT,
  is_admin BOOLEAN DEFAULT false,
  followers INT DEFAULT 0,
  following INT DEFAULT 0,
  documents INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Documents Table
CREATE TABLE IF NOT EXISTS public.documents (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  topic TEXT,
  description TEXT,
  document_url TEXT,
  document_name TEXT,
  cover_url TEXT,
  icon_name TEXT,
  likes_count INT DEFAULT 0,
  dislikes_count INT DEFAULT 0,
  is_external BOOLEAN DEFAULT false,
  is_official BOOLEAN DEFAULT false,
  post_type TEXT DEFAULT 'note' CHECK (post_type IN ('note', 'tweet')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Comments Table
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id BIGINT REFERENCES public.documents(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES public.comments(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

---

## 5. Developer QA & Maintenance Guide

### Project Prerequisites
- **Flutter SDK**: `^3.24.0`
- **Dart SDK**: `^3.5.4`

### Code Quality & Static Analysis Standards
The codebase adheres to a strict **Zero Warnings** policy. When making updates:
1. Always use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`.
2. Always use `activeThumbColor` for Flutter `Switch` widgets.
3. Enforce curly braces in flow control statements (`curly_braces_in_flow_control_structures`).
4. Avoid silent empty catch blocks; always annotate intentional empty catches with `// ignore: empty_catches` on its own line.

### Verification Commands
From the `notehub/` root directory, execute:
```bash
# Fetch dependencies
flutter pub get

# Run static code analysis
flutter analyze

# Run unit and integration tests
flutter test
```

---
*Maintained and Documented by Jules, AI Software Engineer.*
