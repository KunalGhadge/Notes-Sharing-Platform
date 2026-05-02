# Developer Guide & System Manual - NoteHub

This document provides an exhaustive technical analysis and developer guide for NoteHub, a premium academic platform for the Mumbai University community.

## 1. Core Architecture
NoteHub follows a **GetX-based MVC (Model-View-Controller)** pattern for reactive state management, dependency injection, and clean separation of concerns.

### Key Directories:
- `lib/controller/`: Reactive business logic (e.g., `AuthController`, `DocumentController`).
- `lib/view/`: Modular UI screens and reusable widgets.
- `lib/core/`: Application constants, themes, and helper utilities.
- `lib/service/`: Infrastructure services like file caching and notifications.
- `lib/model/`: Data structures representing the domain entities.

---

## 2. Performance Optimizations
- **Static Access Caching**: `HiveBoxes` (`lib/core/helper/hive_boxes.dart`) provides high-speed static access to the `userBox` (storing `UserModel`) and `downloadsBox`.
- **Intelligent File Caching**: `FileCaching` (`lib/service/file_caching.dart`) utilizes `Dio` to download assets to the system's temporary directory, verifying local existence before re-downloading to minimize latency and bandwidth.
- **Media Optimization**: `UploadController` enforces a 10MB file limit for direct uploads and uses `ImageHelper` for mandatory JPEG compression (quality 70) to optimize storage.
- **Efficient Data Retrieval**: `HomeController` implements a batch fetch limit (50 items) and utilizes "Sticky Sort" logic to prioritize official university resources.
- **Interaction Atomicity**: Like/Dislike operations utilize PostgreSQL RPC functions (`increment_likes`, etc.) to ensure counter integrity and prevent race conditions.

---

## 3. Design System
- **Theme**: Premium Deep Blue (#0D47A1) as the primary brand color, using 'Plus Jakarta Sans' typography.
- **UI Principles**: Adheres to **Material 3** with extensive use of **Glassmorphism** (via the `glassmorphism` package) for a modern, high-end feel.
- **Animations**: Standardized `Lottie` animations for empty states and feedback.
- **Loaders**: Uniform `Loader` and `Loader2` components wrap `CircularProgressIndicator` to maintain visual consistency during asynchronous operations.

---

## 4. Security Framework
The application implements a robust serverless security model using **Supabase**:

- **Authentication**: JWT-based session management handled via Supabase Auth.
- **Row Level Security (RLS)**: Strictly enforced at the database level (`SUPABASE_SCHEMA.sql`):
  - `profiles`: Public read, owner-only update.
  - `documents`: Public read, owner-only insert/delete.
  - `notifications`: Private to the `receiver_id`.
- **Security Definer RPCs**: Database functions used for interactions are marked as `SECURITY DEFINER`, allowing controlled updates to protected columns (like `likes_count`) without granting direct write access to users.
- **Real-time Security**: `NotificationController` applies granular filters (`receiver_id` or `is_global`) on PostgreSQL Change channels to ensure users only receive relevant updates.

---

## 5. Codebase Standards & Guidelines
- **Zero Warnings Policy**: All code must pass `flutter analyze` without warnings.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Flow Control**: All `if`, `for`, and `while` statements must use explicit curly braces.
- **Error Handling**: Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.
- **Switches**: Use `activeThumbColor` for `Switch` widgets as required by Flutter 3.41.2+.
- **Build Verification**: Integrity is verified using `cd notehub && flutter analyze && flutter test`.

---
*Maintained by Jules, Lead AI Software Engineer.*
