# Serious Study (formerly NoteHub) - Developer Documentation

Serious Study is a premium academic networking and notes-sharing platform dedicated to the Mumbai University student community. This document serves as the primary technical source of truth for developers working on the project.

---

## 1. Tech Stack Overview

- **Frontend**: Flutter 3.5.4+ (Stable Channel)
- **State Management**: **GetX** (Reactive state, dependency injection, and routing)
- **Local Persistence**: **Hive** (High-performance NoSQL for local caching and session management)
- **Backend-as-a-Service**: **Supabase**
    - **Database**: PostgreSQL with Row Level Security (RLS)
    - **Authentication**: JWT-based Auth (Managed by Supabase Auth)
    - **Storage**: Object storage for academic documents and media
- **Networking**: Supabase Flutter SDK & **Dio** (Specialized file operations and caching)
- **UI & Animations**: Material 3, Glassmorphism, Lottie, Shimmer

---

## 2. Project Architecture

The application follows a modular architecture organized by responsibility:

- **`lib/controller/`**: Contains business logic and reactive state management.
    - `DocumentController`: Handles document interactions (likes, bookmarks, deletes) with Optimistic UI updates.
    - `AuthController`: Manages user sessions, registration flows, and profile synchronization.
    - `HomeController`: Implements real-time feed updates and "Sticky Sort" logic for official resources.
- **`lib/service/`**: Low-level services for file handling and notifications.
    - `file_caching.dart`: Implements Dio-based file downloading and temporary storage.
- **`lib/model/`**: Data models (e.g., `DocumentModel`, `UserModel`) with JSON/Hive adapters.
- **`lib/view/`**: Modular UI components.
    - `widgets/`: Reusable components like `PostCard` (Glassmorphism), `Loader` (Shimmer), and `Toasts`.
- **`lib/core/`**: Centralized configuration, themes, and helper utilities.
    - `meta/app_meta.dart`: Branding and API credentials.
    - `helper/image_helper.dart`: Media optimization using `flutter_image_compress`.

---

## 3. Performance & Optimization Strategies

### 3.1 Perceived Performance
- **Optimistic UI**: Interactions like liking or bookmarking a document update the UI immediately before the network request completes. Reversions are handled automatically on failure.
- **Shimmer Placeholders**: Used in `HomeDocumentSection` and `SearchPage` to prevent "grey space" and provide visual feedback during loading.

### 3.2 Data & Network Optimization
- **Batching**: Home feed fetches are limited to 50 items per request to reduce bandwidth.
- **Media Caching**:
    - `cached_network_image`: Prevents redundant downloads of document thumbnails.
    - `Hive`: Stores user profile metadata (`userBox`) for instant access on app launch.
- **Asset Compression**: `FlutterImageCompress` reduces image sizes to ~70% quality before uploading to Supabase, saving storage and user data.

### 3.3 Backend Efficiency
- **Atomic Operations**: PostgreSQL Functions (RPCs) like `increment_likes` ensure data integrity by performing counter updates server-side, preventing race conditions.
- **Sticky Sort**: The `HomeController` prioritizes official university documents at the top of the feed regardless of the raw creation timestamp.

---

## 4. Security & Data Integrity

### 4.1 Authentication
- Sessions are secured via JWT tokens managed by the Supabase SDK.
- Support for deep linking (`io.supabase.flutternotehub://login-callback`) for secure auth redirects.

### 4.2 Authorization (RLS)
Row Level Security is strictly enforced at the database level:
- **Profiles**: Publicly viewable; `UPDATE` restricted to the account owner.
- **Documents**: `INSERT` and `DELETE` restricted to the owner.
- **Interactions/Bookmarks**: Private to the user who created them.
- **Admin Access**: Special `is_admin` flag in the `profiles` table allows bypass for moderation (governed by specific RLS policies).

---

## 5. Android Build Configuration

- **Namespace**: `com.divinevisionary.notehub`
- **Gradle**: AGP 8.9.1, Gradle 8.10.2
- **SDK Versions**: `compileSdk 36`, `targetSdk 36`, `minSdkVersion 21` (inherited from Flutter)
- **Features**:
    - `multiDexEnabled true`: Required for extensive plugin dependencies.
    - `coreLibraryDesugaringEnabled true`: Enables modern Java 8+ API support via `com.android.tools:desugar_jdk_libs:2.1.4`.

---

## 6. Development Guidelines

- **Linting**: Ensure `flutter analyze` passes before every commit.
- **SVG Handling**: Use `CustomIcon` or `SvgPicture.asset` with `colorFilter` (avoid deprecated `color` property).
- **State Updates**: Always use `update()` or `.obs` variables appropriately within GetX controllers.
- **Naming**: Follow `lowerCamelCase` for variables (e.g., `avatarUrl`) and `PascalCase` for classes.

---
*Maintained by Jules, AI Software Engineer.*
