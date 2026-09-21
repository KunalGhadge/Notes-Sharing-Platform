# Serious Study (NoteHub) - System Manual & Developer Maintenance Guide

> **Primary System Reference**: This document serves as the comprehensive architectural reference, developer manual, and maintenance guide for **Serious Study** (formerly *NoteHub*). It provides an in-depth technical analysis from a developer's perspective covering performance engineering, UI/UX design systems, database security models, full codebase mapping, and QA/maintenance guidelines.

---

## 1. System Overview & Tech Stack

Serious Study is a cross-platform, academic resource-sharing and community platform tailored for Mumbai University students. Built with Flutter and powered by Supabase, the application allows users to upload, search, download, rate, comment on, and share academic notes, as well as interact via social updates ("tweets").

### Core Technology Stack

| Domain | Technology / Library | Version / Detail | Technical Role |
| :--- | :--- | :--- | :--- |
| **Framework** | Flutter | `>=3.24.0` | Cross-platform UI engine |
| **Language** | Dart SDK | `^3.5.4` | Modern Dart compiler & runtime |
| **State Management** | GetX | `^4.6.6` | Reactive state, dependency injection, navigation |
| **Local Storage** | Hive & Hive Flutter | `^2.2.3` / `^1.1.0` | High-performance NoSQL offline key-value storage |
| **Backend & Auth** | Supabase Flutter | `^2.8.1` | Authentication (JWT), PostgreSQL database, Storage, Realtime |
| **HTTP & Caching** | Dio | `^5.7.0` | Chunked file downloading and caching engine |
| **UI Effects** | Glassmorphism, Shimmer | `^3.0.0` / `^3.0.0` | Frosted glass visual effects and skeleton loading |
| **Vector & Motion** | `flutter_svg`, `lottie` | `^2.0.10+1` / `^3.1.3` | Scalable vector icons and interactive animations |
| **Image Compression** | `flutter_image_compress` | `^2.3.0` | Client-side JPEG/PNG cover image optimization |
| **Toast System** | `toastification` | `^3.0.3` | Non-blocking, contextual toast notifications |

---

## 2. Complete Repository Architecture & File Mapping

The repository adopts a modular, GetX-driven MVC (Model-View-Controller) structure under `notehub/lib/`:

```
notehub/
├── android/                   # Android native config (Java 17, compileSdk 36, Multidex)
├── assets/                    # Static assets (animations, icons, vectors, images)
├── lib/
│   ├── controller/            # GetX Business Logic Controllers
│   │   ├── auth_controller.dart               # Auth flows (login, signup, session sync)
│   │   ├── bottom_navigation_controller.dart  # Footer tab navigation index state
│   │   ├── comment_controller.dart            # Document comment threads & replies
│   │   ├── connection_controller.dart         # User connections & follows
│   │   ├── document_controller.dart           # Document details, likes/dislikes/bookmarks
│   │   ├── download_controller.dart           # Offline file management via Hive
│   │   ├── file_controller.dart               # Local file picker logic
│   │   ├── home_controller.dart               # Feed fetching, realtime listener, sticky sort
│   │   ├── notification_controller.dart       # User notification feeds
│   │   ├── post_controller.dart               # Short post ("tweet") management
│   │   ├── profile_controller.dart            # Current user profile & metadata updates
│   │   ├── profile_user_controller.dart       # Secondary user profile inspector
│   │   ├── remote_config_controller.dart      # Dynamic app config via Supabase
│   │   ├── search_controller.dart             # Debounced resource search engine
│   │   ├── showcase_controller.dart           # Feature onboarding tooltips
│   │   └── upload_controller.dart             # Asset upload, compression, 10MB limit enforcement
│   ├── core/                  # Global constants, themes, and utility helpers
│   │   ├── config/
│   │   │   ├── color.dart                     # Color tokens, gradients, surface overlays
│   │   │   └── typography.dart                # GoogleFonts typography rules
│   │   ├── helper/
│   │   │   ├── custom_icon.dart               # Custom SVG/vector mapping
│   │   │   ├── hive_boxes.dart                # Hive box wrappers & getter methods
│   │   │   └── image_helper.dart              # Client-side image compressor (70% JPEG quality)
│   │   └── meta/
│   │       └── app_meta.dart                  # App metadata, versioning, Supabase keys
│   ├── model/                 # Data transfer objects and Hive adapters
│   │   ├── document_model.dart                # Resource/Note object schema
│   │   ├── mini_user_model.dart               # Compact user reference schema
│   │   ├── post_model.dart                    # Community post model
│   │   ├── user_model.dart                    # Hive-annotated user profile model
│   │   └── user_model.g.dart                  # Generated Hive adapter
│   ├── service/               # External services & background task handlers
│   │   ├── file_caching.dart                  # File caching and path resolver
│   │   ├── file_download.dart                 # Chunked download & storage saving
│   │   └── notification_service.dart          # Local Android notification initialization
│   ├── view/                  # UI Presentation Layer
│   │   ├── auth_screen/                       # Login and Registration views
│   │   ├── bottom_footer/                     # Glassmorphic persistent footer
│   │   ├── connection_screen/                 # Follower/Following listing
│   │   ├── document_screen/                   # Document detail viewer & comment section
│   │   ├── home_screen/                       # Main feed with sticky sort & skeleton loaders
│   │   ├── notification_screen/               # Notification history list
│   │   ├── official_screen/                   # Verified administrator updates feed
│   │   ├── onboarding_screen/                 # App introduction carousel
│   │   ├── profile_screen/                    # Personal profile, stats & edit modals
│   │   ├── search_screen/                     # Interactive search & filters
│   │   ├── settings_screen/                   # About & Settings drawer
│   │   ├── splash_screen/                     # Initialization splash screen
│   │   ├── upload_screen/                     # Resource upload form & admin toggles
│   │   └── widgets/                           # Reusable UI components (buttons, cards, toasts)
│   └── layout.dart            # Main navigation shell wrapped with GetX
├── test/
│   └── dummy_test.dart        # Core smoke test suite
├── SUPABASE_SCHEMA.sql        # Database schema, RLS policies, RPCs & triggers
├── pubspec.yaml               # Dependency tree and Dart SDK constraints
└── agent.md                   # Primary system manual & maintenance guide
```

---

## 3. Deep-Dive Developer Analysis

### A. Performance Engineering Analysis

1. **Reactive State Management with GetX**:
   - `GetX` reactive state (`RxBool`, `RxList`, `obs`) isolates widget rebuilds strictly to modified observers without triggering whole-tree re-renders.
   - Controllers (`HomeController`, `DocumentController`) maintain state independently from UI components, separating view rendering from network/database side effects.

2. **High-Performance Offline Caching (Hive NoSQL)**:
   - User profile metadata and session context are persisted in Hive binary storage (`userBox` in `HiveBoxes`).
   - Downloads metadata is maintained in `downloadsBox`, enabling instant offline resource verification without database Round-Trip Time (RTT).

3. **Media Optimization & Bandwidth Reduction**:
   - **Client-Side Compression**: `ImageHelper.compressImage` utilizes `flutter_image_compress` to compress user uploaded cover images to JPEG at 70% quality and 1024x1024 max dimensions before network transmission.
   - **Image Network Caching**: `cached_network_image` caches external avatars and covers locally, preventing redundant HTTP requests on scrolling.
   - **File Caching via Dio**: `file_caching.dart` checks local temporary storage before initializing network downloads, reducing bandwidth overhead.

4. **Database-Level Performance & Atomic Counters**:
   - Interaction increments (likes, dislikes, bookmarks) are offloaded to PostgreSQL Functions (`RPCs`): `increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`. This eliminates client-side race conditions and transactional bottlenecks.
   - Sticky sorting algorithm in `HomeController` (`is_official DESC, created_at DESC`) executes in memory on paginated batches (limit 50) to optimize rendering speed.

5. **Perceived Latency Management**:
   - **Optimistic UI Updates**: `DocumentController` updates local interaction counters (`likes`, `isLiked`) instantly before dispatching Supabase RPC transactions. If a transaction fails, state changes are automatically reverted with an error toast.
   - **Shimmer Skeletons**: `HomeDocumentSection` utilizes `shimmer` loaders during asynchronous state transitions to prevent layout shifts.

---

### B. UI/UX & Design System Architecture

1. **Material 3 Paradigm & Color Architecture**:
   - Primary Seed Color: **Premium Deep Blue** (`#0D47A1`).
   - Color Palette Configured in `lib/core/config/color.dart`:
     - `AppColors.primaryColor`: `0xFF0D47A1`
     - `AppColors.primaryLight`: `0xFF1976D2`
     - `AppColors.darkBackground`: `0xFF121212`
     - `AppColors.surfaceDark`: `0xFF1E1E1E`
     - `AppGradients.premiumGradient`: Linear gradient from `#0D47A1` to `#1976D2`.

2. **Glassmorphic Aesthetic**:
   - Frosted glass containers are built using `glassmorphism` and custom transparent overlays (`Colors.white.withValues(alpha: 0.15)`).
   - Applied across `BottomFooter`, `HomeHeader`, and modal dialogs to provide depth and visual distinction.

3. **Modernized Visual API Standards**:
   - Full migration from deprecated `.withOpacity()` to `.withValues(alpha: ...)` across all custom widgets and colors.
   - Switches (`UploadForm`) utilize `activeThumbColor: const Color(0xFFB8860B)` to maintain full Dart SDK `3.5.4+` compliance.

---

### C. Security Analysis & Threat Model Audit

1. **Authentication & Session Management**:
   - Session management uses **Supabase Auth (JWT)**. OAuth and email/password tokens are cryptographically signed by Supabase.
   - Passwords are never stored or transmitted in plain text, leveraging Supabase's managed key infrastructure.

2. **Database Row Level Security (RLS)**:
   - Row Level Security is explicitly enabled on all database tables in `SUPABASE_SCHEMA.sql`:
     - `profiles`: Public read, `INSERT`/`UPDATE` restricted strictly to `auth.uid() = id`.
     - `documents`: Public read, `INSERT`/`DELETE` restricted strictly to `auth.uid() = user_id`.
     - `comments`: Public read, `INSERT` restricted strictly to `auth.uid() = user_id`.
     - `notifications`: Private read restricted strictly to `auth.uid() = receiver_id`.
     - `bookmarks` & `interactions`: Private to the owning user ID (`auth.uid() = user_id`).

3. **Privilege Escalation Prevention**:
   - **Profile Admin Field**: `is_admin` escalation is prevented by restricting updates to non-privileged fields.
   - **Official Flag Validation**: Setting `is_official = true` on documents is guarded at the database level by the `check_official_permission` function, which validates whether `auth.uid()` has `is_admin = true` in `profiles`.

4. **RPC Function Security**:
   - Counter functions (`increment_likes`, etc.) are declared with `SECURITY DEFINER` and explicit `SET search_path = public` directives to prevent search-path hijacking.

5. **Storage Access & Upload Safeguards**:
   - Storage buckets enforce a strict **10MB direct upload limit** in `UploadController`. Files exceeding 10MB prompt users to provide external cloud links (Google Drive / Mega).
   - Public URLs are generated through Supabase Storage bucket policy controls.

---

## 4. Quality Assurance & Maintenance Procedures

### A. "Zero Warnings" Static Analysis Policy
All code modifications must strictly adhere to a **Zero Warnings / Zero Lints** standard.

To verify code health:
```bash
cd notehub
flutter analyze
```

#### Code Standards Checklist:
- **No Deprecations**: Avoid `.withOpacity()` (use `.withValues(alpha: ...)`), avoid `Switch.activeColor` (use `activeThumbColor`).
- **Explicit Flow Control**: All `if`, `else`, `for`, `while` statements must use explicit curly braces (`{}`).
- **Empty Catches**: Silent catch blocks must include `// ignore: empty_catches` on its own line inside the block body.
- **Indentation**: Standard 2-space indentation for Dart code; 4-space for block bodies where required.

---

### B. Unit & Smoke Testing
Run the project test suite to verify controller logic and smoke tests:
```bash
cd notehub
flutter test
```

---

### C. Pre-Commit Verification Workflow
Before committing and submitting code:
1. Run `flutter analyze` inside `notehub/` to confirm zero lints/warnings.
2. Run `flutter test` inside `notehub/` to confirm all tests pass.
3. Verify that `notehub/lib/controller/auth_controller.dart` is clean and free of syntax corruption (e.g., stray prefixes).
4. Verify all modified files adhere to project coding guidelines.

---

*Documented and Maintained by Jules, AI Software Engineer.*
