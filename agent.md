# Developer Guide & System Manual - Serious Study

This document provides a comprehensive technical audit and developer guide for the Serious Study platform (formerly NoteHub). It serves as the source of truth for architecture, performance, design, and security standards.

## 1. System Architecture (GetX MVC)
The application follows a decoupled **MVC (Model-View-Controller)** pattern enforced by the **GetX** ecosystem.

- **Models (`lib/model/`)**: Define data structures and JSON serialization (e.g., `UserModel`, `DocumentModel`).
- **Controllers (`lib/controller/`)**: Manage reactive state and business logic.
    - `AuthController`: Manages Supabase JWT sessions and profile synchronization.
    - `DocumentController`: Handles the lifecycle of academic resources, utilizing optimistic UI updates.
    - `UploadController`: Manages multi-part uploads with file size enforcement (10MB limit).
- **Views (`lib/view/`)**: Modular UI components. Business logic is strictly kept out of build methods, delegating to controllers via `GetView` or `Obx`.
- **Services (`lib/service/`)**: Singleton-like classes for infrastructure (e.g., `NotificationService`, `FileDownload`).

## 2. Performance & Optimization
Serious Study is engineered for high performance in low-bandwidth environments:

- **Local Persistence (Hive)**:
    - `userBox`: Caches user metadata (`id`, `username`, `profileUrl`) for instant launch.
    - `downloadsBox`: Tracks local file state to prevent redundant downloads.
- **Media Pipeline**:
    - **Compression**: `ImageHelper` automatically compresses cover images before upload to Supabase Storage.
    - **Caching**: `CachedNetworkImage` is mandatory for all network-fetched assets to reduce data consumption.
- **Database Strategy**:
    - **PostgreSQL RPCs**: Atomic operations like `increment_likes` are handled server-side to prevent race conditions and minimize client-side logic.
    - **Sticky Sort**: Feeds are sorted by `created_at` descending at the database layer.

## 3. Design System (Premium Deep Blue)
The app implements a **Material 3** design with a custom **Glassmorphism** aesthetic.

- **Branding**: The primary color is **Premium Deep Blue** (`#0D47A1`).
- **Visual Feedback**:
    - **Shimmers**: Standardized `Shimmer` placeholders for all async data loading.
    - **Lottie**: Used for state transitions (e.g., success animations).
- **Glassmorphism**: Applied via semi-transparent overlays (e.g., `.withValues(alpha: 0.15)`) and `BackdropFilter`.

## 4. Security & Compliance
- **Authentication**: Powered by **Supabase Auth (JWT)**. Sessions are managed securely and synchronized with the local `Hive` box.
- **Authorization (RLS)**: **Row Level Security** is enabled on all tables.
    - Users can only modify their own profiles and documents.
    - Notifications and Bookmarks are private to the owner.
- **File Security**: Supabase Storage buckets are governed by policies that restrict upload/delete access to the file owner based on `auth.uid()`.

## 5. Coding Conventions (Zero Warnings Policy)
To maintain the repository's 'Zero Warnings' status (verified via `flutter analyze`), developers must adhere to:

- **Modern APIs**:
    - Always use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
    - Use `activeThumbColor` in `Switch` widgets instead of `activeColor`.
- **Flow Control**:
    - All `if`, `else`, `for`, and `while` blocks **must** use explicit curly braces `{}`.
- **Error Handling**:
    - Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.
- **Formatting**:
    - Run `flutter format .` before every commit.

---
*Maintained by Jules, AI Software Engineer (Feb 2026 Audit).*
