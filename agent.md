# Developer Technical Guide & Maintenance Manual - Serious Study

## Executive Summary
**Serious Study** (formerly *NoteHub*) is a high-performance notes-sharing and academic networking application specifically tailored for the Mumbai University student community. The application has been modernized from a legacy Django/MongoDB backend to a serverless **Supabase** (PostgreSQL) architecture, paired with a Flutter client using **GetX** reactive state management and **Hive** local storage.

This document serves as the primary technical specification and operational manual for developers maintaining or extending the codebase.

---

## 1. System Architecture & Component Mapping

The application follows an **MVC (Model-View-Controller)** pattern tailored for Flutter via GetX state management.

```
lib/
├── controller/         # Business logic and reactive GetX controllers
├── model/              # Data models and Hive type adapters
├── service/            # Singleton service implementations (caching, notifications)
├── view/               # Modular UI screens and sub-widgets
│   ├── auth_screen/    # Login and registration flows
│   ├── document_screen/# Document detail view, comments, and interactions
│   ├── home_screen/    # Main feed and categorized document discovery
│   ├── profile_screen/ # User profile, follower lists, uploaded posts
│   ├── upload_screen/  # Document and external link upload form
│   └── widgets/        # Reusable Material 3 / Glassmorphic UI components
└── core/               # App configuration, theme tokens, typography, and metadata
```

### Key Controller Responsibilities
- **`DocumentController`** (`lib/controller/document_controller.dart`): Handles interaction events (likes, dislikes, bookmarks), optimistic UI updates, document deletion (Database & Storage cleanup), and file opening/launching.
- **`HomeController`** (`lib/controller/home_controller.dart`): Manages document feed fetching with real-time Postgres changes (`supabase_realtime`), sticky feed sorting, and official update feeds (top 20 limit).
- **`AuthController`** (`lib/controller/auth_controller.dart`): Manages Supabase Auth JWT login and registration, form verification, and local session caching via `HiveBoxes`.
- **`UploadController`** (`lib/controller/upload_controller.dart`): Controls direct document uploads (PDFs, images up to 10MB) and external URL links, compressing media prior to Supabase Storage upload.
- **`ProfileController`** (`lib/controller/profile_controller.dart`): Manages user profile data, follower/following counts, and post rendering showcase.

---

## 2. Performance Engineering Analysis

### 2.1 Reactive State Management & UI Isolation
- **GetX Architecture**: Business logic is separated into GetX controllers using reactive primitives (`.obs`). UI components listen specifically to state changes, eliminating redundant full-tree re-renders.
- **Optimistic UI Updates**: Operations such as `toggleLike`, `toggleDislike`, and `toggleBookmark` in `DocumentController` update the UI immediately before making network RPC/SQL calls to Supabase. If the backend call fails, the state gracefully rolls back and notifies the user via Toast alerts.

### 2.2 Database Performance & Atomic Operations
- **PostgreSQL RPCs**: To prevent race conditions during concurrent user interactions, atomic count operations use PostgreSQL stored functions defined in `SUPABASE_SCHEMA.sql`:
  - `increment_likes`, `decrement_likes`
  - `increment_dislikes`, `decrement_dislikes`
  - `increment_bookmarks`, `decrement_bookmarks`
- **Feed Pagination & Caching**: Feed queries limit batch sizes (e.g., initial 50 records for home feed, 20 records for official updates) to optimize response payload sizes and network latency.

### 2.3 Local Storage & Asset Optimization
- **Hive NoSQL Local Storage**: User profile metadata is persisted locally in `userBox` (`lib/core/helper/hive_boxes.dart`). On app launch, local profile data is loaded instantly, avoiding blocking startup network requests.
- **Download & File Caching**: The file caching engine (`lib/service/file_caching.dart`) checks local storage prior to executing Dio network downloads for documents.
- **Image Compression**: Direct image uploads are processed via `ImageHelper.compressImage` (`lib/core/helper/image_helper.dart`) using `flutter_image_compress` to convert images to JPEG format at 70% quality and max 1024x1024 resolution before pushing to Supabase Storage.

---

## 3. Design & Aesthetic Architecture

### 3.1 Visual Paradigm: Material 3 & Glassmorphism
- **Theme Foundation**: Built on Material 3 (`useMaterial3: true`), with a primary palette anchored in **Premium Deep Blue** (`#0D47A1`).
- **Glassmorphism**: Visual depth is achieved using semi-transparent overlay colors (e.g., `.withValues(alpha: 0.15)` for Flutter Dart 3.5.4+ compatibility) coupled with gradient fills (`AppGradients.premiumGradient`).
- **Typography**: Defined in `lib/core/config/typography.dart` using scalable text styles optimized for high legibility across Android density buckets.

### 3.2 Modular Component Library
- **`DocumentCard`** (`lib/view/widgets/document_card.dart`): Main post card component rendering document metadata, tags, official badges, and interaction buttons.
- **`AdminBadge`** (`lib/view/widgets/admin_badge.dart`): Visual pill highlighting verified admin or official university content.
- **`RefresherWidget`** (`lib/view/widgets/refresher_widget.dart`): Pull-to-refresh wrapper for asynchronous feed updates.

---

## 4. Security Architecture & Database Security Audit

### 4.1 Authentication & Session Management
- **Token-Based Auth**: Handled via Supabase Auth using JSON Web Tokens (JWT). Sessions are securely persisted by the client SDK.
- **Password Security**: Managed by Supabase Auth with standard cryptographic hashing (Bcrypt/Argon2). Passwords are never stored or transmitted in plain text.

### 4.2 Database Security & Row Level Security (RLS)
Every table in `SUPABASE_SCHEMA.sql` enforces Row Level Security (RLS):

| Table | RLS SELECT | RLS INSERT | RLS UPDATE / DELETE |
| :--- | :--- | :--- | :--- |
| `profiles` | Public (`true`) | Owner (`auth.uid() = id`) | Owner (`auth.uid() = id`) |
| `documents` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `comments` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `interactions` | Public (`true`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `bookmarks` | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) | Owner (`auth.uid() = user_id`) |
| `notifications` | Receiver (`auth.uid() = receiver_id`) | System / User | Receiver (`auth.uid() = receiver_id`) |

### 4.3 Defense Against Privilege Escalation
- **Profile Privilege Escalation Prevention**: The `UPDATE` policy on `public.profiles` includes a strict `WITH CHECK` clause:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
  ```
  This prevents non-admin users from escalating their own privileges by sending `is_admin: true` in an update payload.
- **Official Status Verification**: Setting `is_official = true` on `documents` requires administrator privileges, enforced via backend database checks and RLS policy controls.
- **Search Path Isolation**: Stored functions defined with `SECURITY DEFINER` explicitly declare `SET search_path = public` to prevent search-path hijacking attacks.

---

## 5. Developer QA & Maintenance Guidelines

### Prerequisites & Target Environment
- **Flutter SDK**: `>=3.24.0`
- **Dart SDK**: `^3.5.4`
- **Android Target**: `compileSdk 36`, source & target Java compatibility set to `Java 17`.

### Zero Warnings Policy & Linting Standard
All code added to `lib/` must adhere to strict zero-warning compliance under `flutter analyze`:
- Use `.withValues(alpha: value)` instead of deprecated `.withOpacity(value)`.
- Use `activeThumbColor` for `Switch` widgets instead of deprecated `activeColor`.
- Ensure all flow control blocks have explicit curly braces (`curly_braces_in_flow_control_structures`).
- For intentional silent error handling, place `// ignore: empty_catches` on its own line within the catch block.

### Running Tests
Execute the test suite using Flutter's test runner:
```bash
cd notehub
flutter test
```

---
*Maintained and documented for Serious Study development team.*
