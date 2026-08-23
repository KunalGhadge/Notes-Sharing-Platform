# Comprehensive Developer & Architecture Manual — Serious Study (formerly NoteHub)

---

## Executive Overview
**Serious Study** is a high-performance academic networking and notes-sharing mobile application engineered for the Mumbai University student community. The application provides seamless document access, tweet-style mini-posts, peer connections, and official university announcements.

The codebase represents a fully modernized serverless architecture, migrated from a legacy Django/MongoDB backend to **Supabase (PostgreSQL)**, powered by a **Flutter** (3.24+) and **Dart SDK** (^3.5.4) mobile frontend.

---

## Technical Stack & Systems Architecture

| Architecture Layer | Technology / Package | Key Responsibility |
| :--- | :--- | :--- |
| **Frontend Framework** | Flutter 3.24+ (Dart SDK ^3.5.4) | Cross-platform UI rendering |
| **State Management** | GetX (`get: ^4.6.6`) | Reactive state management, dependency injection & routing |
| **Local NoSQL Caching** | Hive (`hive: ^2.2.3`, `hive_flutter`) | Microsecond user session & offline download metadata persistence |
| **Backend & Database** | Supabase (`supabase_flutter: ^2.12.0`) | PostgreSQL relational engine, JWT Auth, RLS, Storage & Realtime |
| **HTTP & Media Handling** | Dio (`dio: ^5.9.1`), `flutter_image_compress` | Efficient multi-part file downloads, HTTP caching & client compression |
| **Design System** | Material 3 + Glassmorphism | Custom design system using `AppGradients` and `.withValues(alpha: ...)` |

---

## Directory & Component Mapping

```text
notehub/
├── android/                   # Native Android configuration (compileSdk 36, Java 17, desugaring)
├── assets/                    # SVG icons, images, and Lottie animations
├── lib/
│   ├── main.dart              # App bootstrapping, Hive & Supabase initialization
│   ├── layout.dart            # Main scaffold with reactive bottom navigation host
│   ├── controller/            # GetX controllers handling domain logic
│   │   ├── auth_controller.dart              # Authentication lifecycle & session management
│   │   ├── document_controller.dart          # Likes, bookmarks, comments & document view state
│   │   ├── home_controller.dart              # Realtime feed, sticky sort & official updates
│   │   ├── profile_controller.dart           # User profile management & avatar updates
│   │   ├── upload_controller.dart            # Document/Tweet upload pipeline & compression
│   │   ├── search_controller.dart            # Dynamic query searching across posts
│   │   ├── comment_controller.dart           # Tree-based comment & reply management
│   │   ├── connection_controller.dart        # User follow/unfollow relationships
│   │   ├── download_controller.dart        # Local document download & Hive syncing
│   │   ├── notification_controller.dart      # Realtime notification management
│   │   └── remote_config_controller.dart     # Dynamic app configuration from backend
│   ├── core/                  # App constants, metadata, design tokens & helpers
│   │   ├── config/color.dart                 # Color palettes (Deep Blue #0D47A1) & gradients
│   │   ├── config/typography.dart            # Google Fonts Inter & Poppins typography
│   │   ├── helper/hive_boxes.dart            # Hive box accessors (`userBox`, `downloadsBox`)
│   │   ├── helper/image_helper.dart          # Image picker & JPEG compression helper
│   │   └── meta/app_meta.dart                # App version and institutional constants
│   ├── model/                 # Data transfer models & Hive adaptors
│   │   ├── user_model.dart                   # Hive-annotated user model (`@HiveType(typeId: 0)`)
│   │   ├── document_model.dart               # Document & post data structure
│   │   ├── post_model.dart                   # General content post model
│   │   └── mini_user_model.dart              # Lightweight user representation for feeds
│   ├── service/               # Background services & I/O helpers
│   │   ├── file_caching.dart                 # Dio file download & caching pipeline
│   │   ├── file_download.dart                # Native platform file saving helper
│   │   └── notification_service.dart         # Flutter local notifications service
│   └── view/                  # Modular screen hierarchy & UI components
│       ├── auth_screen/                      # Login & Registration views
│       ├── home_screen/                      # Main dynamic feed view
│       ├── document_screen/                  # Document detail, reader & comment section
│       ├── upload_screen/                    # Upload form (file upload, external link, tweet)
│       ├── profile_screen/                   # User profile view & edit modal
│       ├── official_screen/                  # Official university announcements feed
│       ├── search_screen/                    # Multi-parameter post search interface
│       ├── notification_screen/              # User notification center
│       └── widgets/                          # Reusable UI components (PostCard, DocumentCard, Toasts)
├── SUPABASE_SCHEMA.sql        # Database schema, RLS policies, RPC functions & triggers
```

---

## 1. Detailed Performance Analysis

### A. Reactive State Management & Cross-Controller Sync
- **GetX Reactive Engine**: Utilizes reactive primitives (`RxBool`, `RxList`, `.obs`) to avoid costly widget tree rebuilds. UI elements consume state using `Obx(() => ...)` or `GetBuilder`.
- **Cross-Controller State Synchronization**: When user interactions occur (e.g., liking a document in `DocumentController`), state changes are instantly reflected in `HomeController` via explicit sync methods (`_syncWithHome()`), preventing stale feed state without forcing complete re-fetches.

### B. High-Performance Local NoSQL Caching
- **Hive Key-Value Store**: Bypasses heavy SQLite overhead by maintaining lightweight binary key-value stores.
  - `userBox`: Caches active session parameters (`id`, `displayName`, `institute`, `followers`, `documents`). Provides zero-latency application launch without waiting for network authentication checks.
  - `downloadsBox`: Caches local metadata for offline-accessible PDF documents.
- Access is encapsulated clean-code style in `HiveBoxes` (`lib/core/helper/hive_boxes.dart`).

### C. Bandwidth & Media Optimization
- **On-Device Image Compression**: Before uploading cover images or profile avatars to Supabase Storage, `ImageHelper.compressImage` executes client-side compression:
  - Formats image to JPEG with 70% quality.
  - Constrains target dimensions to `1024x1024` pixels.
  - Prevents high-resolution camera uploads from exhausting network bandwidth.
- **Dio HTTP & File Caching Pipeline**: `FileCachingService` validates local file existence in temporary directories prior to triggering network transfer requests, reducing redundant bandwidth utilization.
- **Image Network Caching**: Network images render through `cached_network_image`, retaining image blobs locally with memory/disk fallback.

### D. Database Query & Concurrency Optimization
- **Atomic Operations via PostgreSQL RPCs**: Counter increments/decrements (`likes_count`, `dislikes_count`, `bookmarks_count`) do not execute read-then-write loops in Dart code. Instead, atomic PostgreSQL functions defined in `SUPABASE_SCHEMA.sql` handle mutations on the server:
  ```sql
  CREATE OR REPLACE FUNCTION increment_likes(doc_id BIGINT)
  RETURNS VOID AS $$
  BEGIN
    UPDATE public.documents SET likes_count = likes_count + 1 WHERE id = doc_id;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;
  ```
  This eliminates race conditions under high concurrent user load.
- **Feed Batching & Sticky Sort**: `HomeController` caps initial dynamic post feeds at 50 items (`.limit(50)`), ordering items by sticky priority (`is_official DESC, created_at DESC`). Official feeds are restricted to 20 items (`.limit(20)`).

---

## 2. Design System & UI/UX Paradigm

### A. Material 3 & Glassmorphism Aesthetics
The UI combines Material 3 principles with modern translucent Glassmorphism overlay patterns.
- **Color Palette (`AppColor`)**:
  - Primary Theme: **Premium Deep Blue** (`#0D47A1`).
  - Dark Neutral: `Color(0xFF1E1E1E)`.
  - Light Neutral: `Color(0xFFF5F5F7)`.
- **Modern Opacity Specifications**: Following modern Flutter SDK guidelines, color transmittances use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`:
  ```dart
  // Translucent overlay container background
  color: Colors.white.withValues(alpha: 0.15);
  ```
- **Gradients (`AppGradients`)**:
  - `premiumGradient`: Deep Blue (`#0D47A1`) to Navy (`#0A2472`).
  - `glassGradient`: White alpha blending layer for semi-transparent cards.

### B. Component Library & Typography
- **Typography (`AppTypography`)**: Built on Google Fonts (`Inter` for high-density tabular/body text, `Poppins` for title headers).
- **Core Widgets**:
  - `PostCard` & `DocumentCard`: Glassmorphic card containers displaying interaction counters, official badges, and author info.
  - `UploadForm`: Form interface featuring an admin-only "Official Post" switch using `activeThumbColor: const Color(0xFFB8860B)`.
  - `AdminBadge`: Distinctive golden badge for verified administrative posts.
  - `Toasts`: Custom feedback toasts (`Toasts.showTostSuccess`, `Toasts.showTostWarning`, `Toasts.showTostError`).

---

## 3. Security & Backend Governance Audit

### A. Supabase Authentication (JWT Lifecycle)
- Replaced legacy unencrypted session management with Supabase Auth **JSON Web Tokens (JWT)**.
- Client token storage and renewal are securely delegated to the Supabase Flutter SDK.
- Passwords are encrypted on backend servers using industry-standard password hashing algorithms (Bcrypt/Argon2).

### B. Row Level Security (RLS) Governance
Row Level Security is explicitly activated across all tables (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).

```sql
-- 1. Profiles Table Protection
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (
    is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())
  );

-- 2. Documents Table Governance
CREATE POLICY "Documents are viewable by everyone" ON public.documents FOR SELECT USING (true);
CREATE POLICY "Users can insert their own documents" ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update/delete their own documents" ON public.documents FOR ALL USING (auth.uid() = user_id);
```

### C. Security Definer Privilege Escalation Defense
To prevent unauthorized users from marking uploaded documents as `is_official = true` by sending forged API requests, database triggers validate user roles server-side:

```sql
CREATE OR REPLACE FUNCTION check_official_permission()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_official = true AND (OLD.is_official IS NULL OR OLD.is_official = false) THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    ) THEN
      RAISE EXCEPTION 'Only administrative users can publish official documents.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
```
*(Note: `SET search_path = public` is explicitly declared to defend against PostgreSQL search-path hijacking attacks).*

---

## 4. Android Native Configuration

- **Target & Compile SDK Specs**: Configured in `android/app/build.gradle` for standard modern Android deployments (`compileSdk 36`).
- **Java Compatibility**: Source and target options are aligned to `Java 17`.
- **Core Library Desugaring & MultiDex**:
  ```groovy
  android {
      compileSdk 36
      defaultConfig {
          multiDexEnabled true
      }
      compileOptions {
          coreLibraryDesugaringEnabled true
          sourceCompatibility JavaVersion.VERSION_17
          targetCompatibility JavaVersion.VERSION_17
      }
  }
  dependencies {
      coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
  }
  ```
  This guarantees full platform compatibility for Java 8+ API calls used by `flutter_local_notifications`.
- **Deep Linking Protocol**: Configured scheme `io.supabase.flutternotehub://login-callback` for OAuth email confirmation redirects.

---

## 5. Developer Quality Assurance & Maintenance

### Project Prerequisites
- **Flutter SDK**: `3.24+`
- **Dart SDK**: `^3.5.4`

### Code Quality Standards ("Zero Warnings Policy")
To ensure compliance with continuous integration pipelines, all code must adhere to strict Dart static analysis rules:
1. **Color Alpha Calls**: Use `.withValues(alpha: ...)` instead of `.withOpacity(...)`.
2. **Switch Controls**: Use `activeThumbColor` instead of deprecated `activeColor`.
3. **Flow Control Braces**: Enforce explicit curly braces around all `if` statements:
   ```dart
   // Required
   if (condition) {
     doSomething();
   }
   ```
4. **Empty Catch Annotations**: Place `// ignore: empty_catches` on its own line inside empty catch blocks to avoid syntax corruption:
   ```dart
   try {
     await action();
   } catch (e) {
     // ignore: empty_catches
   }
   ```

### Verification & Testing Commands
Execute the following verification commands before submitting pull requests:

```bash
# 1. Navigate to flutter project root
cd notehub

# 2. Run static analyzer (must yield 0 issues)
flutter analyze

# 3. Run unit & regression test suite
flutter test
```

---
*Maintained by AI Software Engineer Jules for Serious Study engineering team.*
