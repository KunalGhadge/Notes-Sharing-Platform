# Serious Study (formerly NoteHub) - Developer Guide & System Architecture Manual

This manual provides an in-depth, developer-centric analysis of **Serious Study**, a high-performance notes-sharing and academic networking platform built specifically for the Mumbai University student community. The application was migrated from a legacy Django/MongoDB stack to a serverless **Supabase** (PostgreSQL) architecture, paired with a modern **Flutter** frontend.

---

## 1. Executive Summary & System Stack

Serious Study provides students and educators with real-time study resource access, peer-to-peer networking, nested discussions, and administrative announcements.

### Key Technology Stack
- **Framework**: Flutter 3.24+ (Channel stable)
- **Language / SDK**: Dart SDK ^3.5.4
- **State Management & DI**: **GetX** (Reactive state controllers, `Get.put()`, `Get.find()`, `GetX<T>` / `Obx()` builders)
- **Backend-as-a-Service**: **Supabase**
  - **Auth**: Managed JWT Auth with session synchronization
  - **Database**: PostgreSQL with Row Level Security (RLS) and Postgres Realtime
  - **Storage**: Supabase Object Storage (`documents` bucket with RLS policies)
- **Local Persistent Storage**: **Hive** (`userBox` for session/profile metadata, `downloadsBox` for cached file references)
- **Networking & File Caching**: **Supabase Flutter SDK** & **Dio** (custom caching service via `path_provider`)
- **Media Optimization**: **flutter_image_compress** (JPEG 70% quality compression target before bucket upload)

---

## 2. Codebase Architecture & Directory Mapping

The application adheres to a modular MVC-like decoupled architecture where UI views listen to GetX Controllers, which in turn communicate with Supabase backend services and Hive local storage.

```
notehub/lib/
├── controller/            # Reactive GetX business logic controllers
│   ├── auth_controller.dart
│   ├── document_controller.dart
│   ├── home_controller.dart
│   ├── upload_controller.dart
│   ├── profile_controller.dart
│   ├── profile_user_controller.dart
│   ├── comment_controller.dart
│   ├── download_controller.dart
│   ├── notification_controller.dart
│   ├── post_controller.dart
│   ├── remote_config_controller.dart
│   ├── search_controller.dart
│   ├── showcase_controller.dart
│   └── bottom_navigation_controller.dart
├── core/                  # Core configurations, constants, and utilities
│   ├── config/
│   │   ├── color.dart       # Design tokens, gradients, color palette
│   │   └── typography.dart  # Material 3 typography rules
│   ├── helper/
│   │   ├── hive_boxes.dart   # Hive NoSQL persistent storage wrapper
│   │   ├── image_helper.dart # Media compression pipeline
│   │   └── custom_icon.dart  # Vector & avatar helper widgets
│   └── meta/
│       └── app_meta.dart     # Centralized metadata & credentials
├── model/                 # Data contracts & serialization models
│   ├── document_model.dart
│   ├── user_model.dart
│   ├── post_model.dart
│   └── mini_user_model.dart
├── service/               # Infrastructure & native platform services
│   ├── file_caching.dart    # Dio-based local file caching
│   ├── file_download.dart   # Downloads & local notifications
│   └── notification_service.dart
├── view/                  # UI Presentation Layer (Screens & Widgets)
│   ├── auth_screen/
│   ├── home_screen/
│   ├── upload_screen/
│   ├── document_screen/
│   ├── profile_screen/
│   ├── notification_screen/
│   ├── search_screen/
│   ├── official_screen/
│   ├── settings_screen/
│   ├── splash_screen/
│   ├── onboarding_screen/
│   ├── bottom_footer/
│   └── widgets/           # Reusable atomic UI components
└── layout.dart            # Main app shell with custom bottom navigation
```

---

## 3. Performance Analysis

### 3.1 Reactive State & Controller Lifecycle
- **Decoupled Business Logic**: GetX Controllers (`DocumentController`, `HomeController`, `UploadController`) encapsulate backend interactions completely away from UI render widgets.
- **Optimistic UI Updates**: User actions like liking a document or bookmarking a post reflect instantly in the UI state before network RPC completion (`DocumentController.toggleLike()`). If the backend request fails, the controller automatically reverts the local UI state and displays a contextual toast.
- **Cross-Controller Synchronization**: `DocumentController` notifies `HomeController` upon document updates (`_syncWithHome()`) to maintain seamless multi-view consistency.

### 3.2 Local Caching & Data Persistence
- **Hive NoSQL Storage**: Session data (`userBox`) is persisted locally in `lib/core/helper/hive_boxes.dart`, eliminating unnecessary profile requests on application startup.
- **Metadata for Downloads**: `downloadsBox` maintains local metadata for downloaded PDF resources to avoid redundant network transfers.

### 3.3 Network & Media Optimization
- **File Size Management**: `UploadController` enforces a 10MB limit on direct file uploads, prompting users to provide external resource links (Google Drive, Mega) for larger files.
- **Image Compression Pipeline**: Images are compressed via `ImageHelper.compressImage()` using `flutter_image_compress` (70% quality JPEG target) before uploading to Supabase Storage, dramatically reducing bandwidth usage.
- **Lazy Fetching & Sticky Feed Sorting**: `HomeController.fetchUpdates()` fetches documents in batches (limit 50) and executes a sticky sort placing official posts (`is_official == true`) at the top of the feed while maintaining chronological order for community posts.

### 3.4 PostgreSQL Remote Procedure Calls (RPCs)
Counter operations (`likes_count`, `dislikes_count`) are offloaded to PostgreSQL RPC functions (`increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`) to guarantee atomic updates and prevent client-side race conditions under concurrent usage.

---

## 4. Design & Architecture (Material 3 & Visual Language)

- **Primary Rebrand Theme**: "Premium Deep Blue" (`#0D47A1`), representing academic integrity and clarity for Mumbai University students.
- **Glassmorphism Aesthetic**:
  - Translucent navigation overlays and floating elements using custom gradients (`AppGradients.glassGradient`).
  - Strict utilization of standard modern Flutter color manipulation (`.withValues(alpha: x)`) to comply with Flutter 3.24+ / Dart 3.5.4+ standards.
- **Visual Feedback & Micro-Interactions**:
  - **Shimmer Effects**: Implemented in loading feeds (`HomeDocumentSection`, `ProfileUser`) for continuous visual feedback.
  - **Lottie Animations**: Embedded for empty state displays and initial splash screen transitions (`notes.json`).
  - **Admin & Official Branding**: Custom gold badges (`AdminBadge`) and official resource tags for verified administrative content.

---

## 5. Security Analysis & Database Security Audit

### 5.1 Authentication & Token Handling
- Migrated from legacy custom session checks to managed **Supabase Auth (JWT)**.
- Passwords are encrypted and managed securely by Supabase Auth using Argon2/Bcrypt hashing.

### 5.2 Row Level Security (RLS) Policies
Row Level Security is enabled across all relational tables in `SUPABASE_SCHEMA.sql`:

```sql
-- Profiles: Public read, owner update only
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Documents: Public read, owner/admin write
CREATE POLICY "Documents are viewable by everyone" ON public.documents FOR SELECT USING (true);
CREATE POLICY "Users can insert their own documents" ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update/delete their own documents" ON public.documents FOR ALL USING (auth.uid() = user_id);

-- Privilege Escalation Safeguard: Admin updates
CREATE POLICY "Admins can update documents" ON public.documents
  USING (auth.uid() IN (SELECT id FROM public.profiles WHERE is_admin = true));
```

### 5.3 Database Integrity & Security Definers
- **Atomic Functions (`SECURITY DEFINER`)**: RPC functions run with security definer privileges to update post counters without exposing raw table `UPDATE` permissions to unauthenticated clients.
- **Postgres Realtime Subscriptions**: Channels (`public:documents`) enable instantaneous feed updates without polling.

---

## 6. Developer Maintenance & QA Manual

### Prerequisites & Setup
- **Flutter SDK**: `3.24+`
- **Dart SDK**: `^3.5.4`

### Code Quality & Static Analysis Policy ("Zero Warnings")
All code modified in `notehub/` must strictly maintain zero static analysis warnings under Flutter lint rules:
1. **No Deprecated Members**:
   - Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
   - Use `activeThumbColor` instead of deprecated `activeColor` on `Switch` controls.
2. **Flow Control Braces**: Always enclose `if` statements in explicit block syntax (`curly_braces_in_flow_control_structures`).
3. **Empty Catches**: Annotate intentional empty catch blocks with `// ignore: empty_catches` on its own line within the catch body.

### Verification Commands
Execute the following from the `notehub/` root directory:
```bash
# Static Analysis Check
flutter analyze

# Unit & Widget Test Suite
flutter test
```

---
*Analyzed, Modernized, and Documented by Jules, AI Software Engineer.*
