# Developer Guide - Serious Study (formerly NoteHub)

This document provides an exhaustive technical analysis of the Serious Study project from a developer's perspective. It documents the architecture, performance optimizations, security measures, and coding standards following the migration to a serverless **Supabase** architecture.

## 1. Architectural Overview
Serious Study is built using the **GetX MVC** (Model-View-Controller) pattern, ensuring a clean separation of concerns and reactive state management.

- **`lib/controller/`**: Contains reactive business logic. Controllers manage data fetching, user interactions (likes, bookmarks), and authentication.
- **`lib/view/`**: Modular UI components. Views are typically stateless or stateful widgets that observe GetX controllers.
- **`lib/core/`**: Centralized configurations including themes (`config/`), helper utilities (`helper/`), and app metadata (`meta/`).
- **`lib/model/`**: Plain Old Dart Objects (PODOs) for data mapping (e.g., `DocumentModel`, `UserModel`).
- **`lib/service/`**: Low-level infrastructure services for local notifications, file downloading, and caching.

## 2. Performance Analysis
The application is optimized for low latency and efficient resource usage, critical for a community-driven mobile platform.

### 2.1. Local Persistent Storage (Hive)
- **High-Performance NoSQL**: `Hive` is used instead of SQLite for faster read/write operations.
- **`userBox`**: Caches the `UserModel` (ID, username, profile URL) to allow the "My Profile" tab and header to load instantly without hitting the network.
- **`downloadsBox`**: Tracks locally downloaded documents for offline access management.

### 2.2. Perceived Performance & Optimistic UI
- **Optimistic Updates**: In `DocumentController`, interactions like `toggleLike` and `toggleBookmark` update the UI immediately before the Supabase RPC call completes. If the backend fails, the state is reverted, ensuring zero lag for the user.
- **Shimmer Placeholders**: Used in `HomeDocumentSection` and search results to prevent "blank screen" anxiety during data fetching.
- **Sticky Sort**: The `HomeController` implements a custom sorting algorithm that prioritizes official university documents (`is_official`) at the top of the feed while maintaining chronological order for peer-to-peer notes.

### 2.3. Data & Media Optimization
- **Batch Fetching**: Feed queries are limited to 50 items per request to reduce initial payload and memory pressure.
- **Image Compression**: `lib/core/helper/image_helper.dart` utilizes `flutter_image_compress` to reduce cover image sizes to 70% quality (min 1024px) before uploading to Supabase Storage.
- **Thumbnail Caching**: `CachedNetworkImage` is used globally to persist thumbnails in a temporary directory, reducing data consumption.

## 3. Security Architecture
Post-migration, security is enforced at the database level, removing the need for a traditional middleware server.

### 3.1. Authentication & Session Management
- **Supabase Auth (JWT)**: Secure, industry-standard authentication. Sessions are handled by the SDK, and sensitive credentials never touch the frontend's local storage in plain text.
- **Deep Linking**: Configured in `AndroidManifest.xml` via the `io.supabase.flutternotehub` scheme for secure login callbacks.

### 3.2. Authorization (Row Level Security)
The `SUPABASE_SCHEMA.sql` defines strict RLS policies:
- **Public Read Access**: Profiles and Documents are viewable by everyone.
- **Restricted Write Access**: Users can only `INSERT`, `UPDATE`, or `DELETE` rows where `auth.uid() = user_id`.
- **Administrative Controls**: An `is_admin` boolean in the `profiles` table enables specific UI/UX features (e.g., broadcasting global announcements).

### 3.3. Data Integrity via PostgreSQL RPCs
- **Atomic Operations**: Counters for likes and dislikes are modified via `SECURITY DEFINER` functions (`increment_likes`, `decrement_dislikes`). This prevents users from directly writing to the `likes_count` column, ensuring auditability and preventing manipulation.
- **Interaction Exclusivity**: The `DocumentController` logic ensures a user cannot like and dislike the same document simultaneously by recursively toggling the opposite interaction before syncing.

## 4. Design & UI/UX
The app adheres to **Material 3** principles with a specialized academic aesthetic.

- **Theming**: Centered around "Premium Deep Blue" (`#0D47A1`).
- **Glassmorphism**: Implemented via the `glassmorphism` package and custom `AppGradients.glassGradient` to create depth in the UI (e.g., `PostCard` overlays).
- **Typography**: Uses 'Plus Jakarta Sans' (via `google_fonts`) for high readability in dense academic text.
- **Feedback Systems**: Standardized loaders (`lib/view/widgets/loader.dart`) and styled toasts (`lib/view/widgets/toasts.dart`) provide consistent feedback.

## 5. Developer Guidelines & Coding Standards
All contributors MUST follow these rules to pass CI/CD:

- **Zero Warnings Policy**: Code must pass `flutter analyze` with zero warnings. Informational issues must be addressed.
- **Modern API Usage**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Linting**:
    - Ensure all flow control (if/else/for) uses curly braces.
    - Avoid `print()` statements; use `debugPrint()` or specialized logging.
    - Annotate intentional empty catch blocks with `// ignore: empty_catches`.
- **State Management**:
    - Avoid putting business logic in `onInit` if it depends on other controllers; use `WidgetsBinding.instance.addPostFrameCallback` or GetX dependency injection (`Get.find`).
    - Use GetX tags for instances that may co-exist (e.g., `ShowcaseController`).

## 6. Project Maintenance
- **Analysis**: Run `flutter analyze` from the `notehub/` directory.
- **Testing**: Run `flutter test` to execute the unit and widget test suite.
- **Build**: Android builds require `multiDexEnabled` and Java 17 compatibility as per `android/app/build.gradle`.

---
*Maintained by Jules, AI Software Engineer.*
