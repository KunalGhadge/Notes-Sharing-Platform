# Serious Study (NoteHub) - Technical Source of Truth

Serious Study is a premium notes-sharing and academic networking platform specifically tailored for Mumbai University students. This document serves as the primary technical guide and system overview for developers and agents working on the codebase.

## 1. System Architecture
The application follows a serverless architecture with a Flutter frontend and a Supabase backend.

- **Frontend**: Flutter 3.24+ (Dart ^3.5.4) using GetX for state management.
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions).
- **Local Storage**: Hive (NoSQL) for high-performance local caching of user sessions and persistent metadata.

## 2. Technical Standards & Conventions

### 2.1 Coding Conventions & Lints
- **Flutter 3.24+**: Replace deprecated `.withOpacity(x)` with `.withValues(alpha: x)`.
- **Switch Widgets**: Use `activeThumbColor` instead of deprecated `activeColor`.
- **Flow Control**: All `if`, `for`, `while` statements must use curly braces `{}`.
- **Error Handling**: Intentional empty catch blocks should include a comment like `/* silent */` or `/* ignored */`.
- **Naming**: Use `lowerCamelCase` for variables and `UpperCamelCase` for classes/enums.

### 2.2 State Management (GetX)
- Use reactive state variables (`.obs`) in controllers.
- Controllers should handle all business logic, keeping views focused on UI.
- Use `Get.put()` for global controllers and GetX tags for concurrent states where necessary.

### 2.2 Local Caching (Hive)
- **User Metadata**: Stored in `userBox` (`lib/core/helper/hive_boxes.dart`).
- **Download Status**: Managed via `downloads` box to track local file availability.
- **Initialization**: Hive is initialized in `main.dart` with necessary adapters (e.g., `UserModelAdapter`).

### 2.3 Networking & Data Sync
- **Supabase SDK**: Primary interface for database and authentication.
- **Optimistic UI**: Implement immediate UI updates for user interactions (likes, bookmarks) before backend confirmation. See `DocumentController` for reference.
- **Batching**: Fetch documents in batches (e.g., limit 50) to optimize bandwidth.
- **Real-time**: Use Supabase Realtime channels for live feed updates (implemented in `HomeController`).

### 2.4 Media Handling
- **Image Compression**: Use `flutter_image_compress` (quality 70, minWidth/Height 1024) in `ImageHelper` for all uploads.
- **Image Caching**: Use `cached_network_image` for all network-based assets.
- **File Handling**: Direct uploads are limited to **10MB**. External links (Google Drive, Mega) are encouraged for larger resources.

## 3. Database & Security

### 3.1 PostgreSQL Schema
- **RLS (Row Level Security)**: Strictly enforced on all tables. Public access is limited to `SELECT` on non-sensitive data; `INSERT/UPDATE/DELETE` require ownership.
- **Atomic Operations**: Use PostgreSQL RPCs (e.g., `increment_likes`, `decrement_likes`) to handle counter updates safely.
- **Triggers**: Automated profile creation and metadata synchronization are handled via database triggers.

### 3.2 Authentication
- **Supabase Auth**: JWT-based authentication with email/password.
- **Deep Linking**: Android supports `io.supabase.flutternotehub://login-callback` for OAuth/Email confirmation flows.
- **Registration**: Handles email confirmation status; immediate profile upserts are skipped if confirmation is pending.

## 4. UI/UX Design Patterns

- **Theme**: Material 3 with a "Premium Deep Blue" (`#0D47A1`) primary color.
- **Visual Style**: Glassmorphism (using `glassmorphism` package and `AppGradients.glassGradient`).
- **Animations**: Lottie for feedback (success/empty states).
- **Typography**: 'Plus Jakarta Sans'.
- **Loading**: Use Shimmer placeholders to prevent blank screen "pop-in".

## 5. Performance Optimizations

- **Sticky Sort**: Official university documents are prioritized at the top of feeds via `HomeController`.
- **Count Optimization**: Use `CountOption.exact` for native record counting.
- **Relational Joins**: Use single Supabase queries with relational selectors (`* , profiles(...), interactions(...)`) to minimize network round-trips.

## 6. Android Configuration

- **SDK Versions**: `compileSdk 36`, `targetSdk 36`.
- **Build Features**: `multiDexEnabled true`, `coreLibraryDesugaringEnabled true`.
- **Desugar Library**: `com.android.tools:desugar_jdk_libs:2.1.4`.
- **Gradle**: Uses AGP 8.9.1+ and Gradle 8.10.2.

## 7. Quality Assurance

- **Static Analysis**: Run `flutter analyze` and ensure zero warnings.
- **Testing**: Run `flutter test` in the `notehub/` directory.
- **Pre-commit**: Always verify changes against `analysis_options.yaml` and run basic smoke tests.

---
*Last Updated: February 2025*
