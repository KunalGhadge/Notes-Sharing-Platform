# Developer Guide - Serious Study (formerly NoteHub)

This document serves as the comprehensive technical manual and developer guide for **Serious Study**, a high-performance community platform for Mumbai University students. It documents the architecture, performance strategies, design principles, and security measures implemented in the application.

## 1. Architecture & Tech Stack
Serious Study follows a modern, serverless architecture using Flutter and Supabase.

- **Frontend**: Flutter 3.41.2 (Channel Stable)
- **State Management**: **GetX** (Reactive patterns, Dependency Injection)
- **Backend**: **Supabase** (PostgreSQL, Auth, Storage, Real-time)
- **Local Persistence**: **Hive** (NoSQL caching)
- **Networking**: **Dio** (Specialized file handling) & Supabase SDK

### Directory Structure
- `lib/controller/`: Business logic and state management (e.g., `DocumentController`, `AuthController`).
- `lib/view/`: Modular UI components and screens.
- `lib/core/`: Centralized configurations (theme, constants, helpers).
- `lib/model/`: Data structures (e.g., `DocumentModel`, `UserModel`).
- `lib/service/`: Utility services like file caching and notifications.

---

## 2. Performance Analysis
The application is optimized for responsiveness and low latency, particularly for mobile users on Mumbai University campuses.

### 2.1 Reactive State & Optimistic UI
- **GetX Integration**: Controllers manage state reactively. `Obx` and `GetBuilder` are used for granular UI updates.
- **Optimistic Updates**: Implemented in `DocumentController` for likes, dislikes, and bookmarks. The UI updates immediately before the Supabase backend confirms the transaction, providing zero-latency feedback.
  - *Example*: In `toggleLike`, `doc.isLiked` is toggled and `update()` is called before the `RPC` call.

### 2.2 Data Caching & Persistence
- **Hive Boxes**:
  - `userBox`: Stores the authenticated user's profile metadata for instant loading on app launch.
  - `downloadsBox`: Tracks locally saved documents.
- **Thumbnail Caching**: `CachedNetworkImage` is used globally to prevent redundant media downloads.
- **File Caching**: `FileCaching` service uses `Dio` and `path_provider` to store documents in the system's temporary directory, checking for existence before re-downloading.

### 2.3 Network Optimization
- **Batch Fetching**: `HomeController` limits initial feed fetches to 50 documents to balance responsiveness.
- **Sticky Sort**: A custom sorting algorithm prioritizes 'official' documents at the top of the feed regardless of their creation date.
- **Image Compression**: `flutter_image_compress` is integrated into the `UploadController` pipeline, reducing cover image sizes to optimize storage and bandwidth.
- **External Links**: To stay within a 10MB direct upload limit, the app encourages the use of external links (Google Drive, Mega) via the `isExternalLink` toggle.

---

## 3. Design & UI/UX
The design language is "Premium Academic," focusing on clarity and a modern aesthetic.

### 3.1 Design Language
- **Theme**: Premium Deep Blue (`#0D47A1`) as the primary brand color.
- **Material 3**: Fully utilized for modern component behavior and standard layouts.
- **Typography**: **Plus Jakarta Sans** is the primary typeface, configured with varying weights in `AppTypography` for visual hierarchy.

### 3.2 Premium UI Effects
- **Glassmorphism**:
  - Implemented using the `glassmorphism` package.
  - Used in `PostCard` for title overlays and `BottomFooter` (legacy) to create a layered, modern look.
  - Custom `AppGradients.glassGradient` handles the translucent effect.
- **Shimmer Effects**: `shimmer` package provides placeholders during data fetching to maintain layout stability.
- **Animations**: `lottie` animations are used for empty states, success feedback, and loading sequences.

---

## 4. Security Analysis
Security is a core pillar of the migration from the legacy stack.

### 4.1 Authentication & Authorization
- **JWT (JSON Web Tokens)**: All requests are authenticated via Supabase Auth.
- **Row Level Security (RLS)**: Strictly enforced in PostgreSQL.
  - Users can only `UPDATE` their own profiles (`auth.uid() = id`).
  - Users can only `DELETE` their own documents (`auth.uid() = user_id`).
  - `Public` read access is granted for documents and profiles to facilitate community sharing.

### 4.2 Data Integrity
- **Atomic Operations (RPCs)**: Counter increments (likes/dislikes) are handled via `SECURITY DEFINER` PostgreSQL functions (`increment_likes`, `decrement_dislikes`). This prevents race conditions and ensures clients cannot arbitrarily set counter values.
- **Storage Policies**: Files in Supabase Storage are protected by bucket-level policies, ensuring only authenticated users can upload and owners can delete.

---

## 5. Maintenance & QA
To maintain the "Zero Warnings" status and project health:

- **Linting**: Always run `flutter analyze` before committing. The project follows `package:flutter_lints/flutter.yaml`.
- **Testing**: Run `flutter test` to verify logic in `test/` directory.
- **Dependencies**: Ensure Flutter SDK is `^3.41.2` and Dart `^3.11.0`.
- **Pre-Commit**: Always call `pre_commit_instructions` and follow its steps.

---
*Maintained by: Jules (AI Software Engineer)*
*Last Updated: June 2026*
