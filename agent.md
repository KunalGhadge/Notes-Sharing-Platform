# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document provides a deep, developer-perspective technical breakdown of the Serious Study application architecture, performance mechanisms, design system, database schema, security model, and QA procedures.

---

## 1. Executive Summary & Tech Stack Overview

Serious Study is an academic resource-sharing and networking platform tailored for the Mumbai University community. Built using Flutter and Supabase (PostgreSQL serverless engine), it delivers a native Android experience with real-time syncing, local caching, and robust security.

### Core Technology Stack:
- **Frontend Framework**: Flutter (Dart SDK ^3.5.4 / Flutter 3.24+)
- **State Management & Routing**: `GetX` (`GetxController`, `GetBuilder`, `GetX<T>`)
- **Backend & Database**: Supabase (PostgreSQL, Supabase Auth, Supabase Storage, Postgres Realtime)
- **Local Persistent Storage**: `Hive` (Key-value / NoSQL caching)
- **Media Caching & Compression**: `cached_network_image`, `dio`, `flutter_image_compress`
- **UI Aesthetics**: Material 3 with custom Glassmorphism overlays and Premium Deep Blue branding (`#0D47A1`)

---

## 2. Architecture & File Structure

The project follows a modified MVC paradigm using GetX for lightweight dependency injection and state management.

```
notehub/lib/
├── controller/            # GetX Controllers (Business & Data Logic)
│   ├── auth_controller.dart
│   ├── document_controller.dart
│   ├── home_controller.dart
│   ├── profile_controller.dart
│   ├── upload_controller.dart
│   ├── notification_controller.dart
│   ├── search_controller.dart
│   └── connection_controller.dart
├── core/                  # Core Configurations & Utilities
│   ├── config/
│   │   ├── color.dart     # PrimaryColor (#0D47A1), AppGradients, Grayscale
│   │   └── typography.dart# AppTypography styles
│   ├── helper/
│   │   ├── hive_boxes.dart# Hive box keys (userBox, downloadsBox)
│   │   ├── custom_icon.dart
│   │   └── image_helper.dart # Image compression utility (70% JPEG quality)
│   └── meta/
│       └── app_meta.dart  # Metadata, avatar URLs, default assets
├── model/                 # Data Models
│   ├── document_model.dart
│   ├── user_model.dart
│   └── post_model.dart
├── service/               # External Services
│   ├── file_caching.dart  # File caching using Dio & path_provider
│   ├── file_download.dart
│   └── notification_service.dart # Local notifications integration
└── view/                  # Modular Presentation Components & Views
    ├── auth_screen/
    ├── home_screen/
    │   ├── home.dart
    │   └── widget/
    │       ├── home_header.dart
    │       └── home_document_section.dart
    ├── document_screen/
    ├── upload_screen/
    ├── profile_screen/
    ├── notification_screen/
    └── widgets/           # Shared UI Components (PostCard, DocumentCard, PrimaryButton, etc.)
```

---

## 3. Performance Analysis & Optimization Strategies

### A. Reactive State Management & UI Synchronization
- **GetX Architecture**: Business logic is separated from UI views. `HomeController` manages real-time updates while `DocumentController` handles granular actions (likes, dislikes, bookmarks, downloads).
- **Optimistic UI Updates**: Interactions such as `toggleLike()` and `toggleDislike()` in `DocumentController` modify the local observable state immediately before dispatching asynchronous database RPC requests. If a network failure occurs, the state is safely reverted and a toast notification alerts the user.
- **Cross-Controller Synchronization**: Calling `update()` in `DocumentController` invokes `_syncWithHome()`, triggering reactive updates across registered views (`HomeController`) without requiring full page refetches.

### B. High-Performance Caching & Storage
- **Hive NoSQL Local Caching**: `HiveBoxes` provides zero-latency access to persistent session data (`userBox`) and downloaded document metadata (`downloadsBox`).
- **Network Image Caching**: `cached_network_image` is used throughout components like `PostCard` and `HomeHeader` to reduce network bandwidth and speed up scroll rendering.
- **Efficient Document Caching**: `file_caching.dart` uses `Dio` and `path_provider` to download resources into local temporary directories, verifying existing local file paths before initiating new HTTP downloads.

### C. Database & Query Optimization
- **Batching & Limits**: `HomeController` limits primary feed fetches to 50 recent documents (`limit(50)`) and official updates to 20 documents (`limit(20)`).
- **Sticky Sorting Algorithm**: Feeds prioritize official MU verified posts (`is_official == true`) while maintaining chronological sorting (`created_at DESC`).
- **Media Asset Optimization**: `ImageHelper.compressImage` resizes and compresses user avatar and cover uploads down to a 1024x1024 bound at 70% JPEG quality prior to cloud storage upload.

---

## 4. UI/UX Design System & Material 3 Integration

### A. Color Palette & Visual Identity
- **Primary Color**: `#0D47A1` (Premium Deep Blue - `PrimaryColor.shade500`).
- **Gradient Accents**: `AppGradients.premiumGradient` transitions smoothly from `#0D47A1` to `#1976D2`.
- **Glassmorphism**: Built using `glassmorphism` and custom `AppGradients.glassGradient`, applying soft backdrop blur effects (e.g. over post card media overlays in `PostCard`).

### B. Key UI Components
- **HomeHeader** (`notehub/lib/view/home_screen/widget/home_header.dart`): Features user greeting, avatar rendering with network fallback, notification icon badge, and Mumbai University location indicator with premium blue gradient card style.
- **PostCard** (`notehub/lib/view/widgets/post_card.dart`): Renders community uploads, featuring cached cover images, glassmorphic floating text overlays, like/dislike/bookmark interactive counters, and user profile routing.
- **HomeDocumentSection**: Displays categorized document feeds with shimmer placeholders for non-blocking asynchronous visual loading.

---

## 5. Security Architecture & Row Level Security (RLS)

The backend migration to Supabase serverless PostgreSQL eliminated legacy vulnerabilities by delegating authentication and table access controls strictly to PostgreSQL RLS policies and JWT validation.

### A. Row Level Security (RLS) Policy Matrix

| Table | Policy | Action | Enforcement Condition |
|---|---|---|---|
| `profiles` | Public read | `SELECT` | `true` |
| `profiles` | Owner insert | `INSERT` | `auth.uid() = id` |
| `profiles` | Owner update | `UPDATE` | `auth.uid() = id` WITH CHECK `is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid())` |
| `documents` | Public read | `SELECT` | `true` |
| `documents` | Owner insert | `INSERT` | `auth.uid() = user_id` |
| `documents` | Owner update/delete | `ALL` | `auth.uid() = user_id` |
| `documents` | Admin update | `UPDATE` | `auth.uid() IN (SELECT id FROM profiles WHERE is_admin = true)` |
| `interactions` | Private user access | `ALL` | `auth.uid() = user_id` |
| `bookmarks` | Private user access | `ALL` | `auth.uid() = user_id` |
| `notifications` | Receiver read | `SELECT` | `auth.uid() = receiver_id` |

### B. Security Definer RPCs & Atomic Counters
Direct modification of numeric counter columns (`likes_count`, `dislikes_count`) by standard client users is prevented. Operations are executed through `SECURITY DEFINER` PostgreSQL functions defined in `SUPABASE_SCHEMA.sql`:

- `increment_likes(doc_id)` / `decrement_likes(doc_id)`
- `increment_dislikes(doc_id)` / `decrement_dislikes(doc_id)`
- `increment_bookmarks(doc_id)` / `decrement_bookmarks(doc_id)`

### C. Official Verification Trigger & Privilege Escalation Prevention
To prevent unauthorized users from marking documents as "Official", the trigger function `check_official_permission` operates with `SET search_path = public`:

```sql
CREATE OR REPLACE FUNCTION public.check_official_permission()
RETURNS TRIGGER
SET search_path = public
AS $$
BEGIN
  IF NEW.is_official = true THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    ) THEN
      RAISE EXCEPTION 'Only administrators can mark content as official.';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 6. Developer Guidelines & QA Procedures

### Prerequisites
- Flutter SDK 3.24+ (Dart SDK ^3.5.4)
- Android SDK (targeting `compileSdk 36`, `Java 17`)

### Zero Warnings Policy & Linting Standard
To maintain repository quality and ensure continuous integration (CI) compliance:
1. **Flow Control Braces**: Always use explicit curly braces `{}` for `if`, `else`, and loop bodies (`curly_braces_in_flow_control_structures`).
2. **Color Manipulation API**: Use modern `.withValues(alpha: ...)` for color opacities in modern Flutter SDKs, or `.withOpacity(...)` where compatibility requires.
3. **Switch Controls**: Ensure `Switch` widgets use `activeThumbColor` instead of deprecated properties.
4. **Empty Catches**: Annotate intentional empty catch blocks with `// ignore: empty_catches` on its own line inside the block.

### Verification Commands
Run the following commands inside `notehub/` before submitting code changes:

```bash
# 1. Check static analysis compliance
flutter analyze

# 2. Execute test suite
flutter test
```

---
*Maintained and documented by Jules, AI Software Engineer.*
