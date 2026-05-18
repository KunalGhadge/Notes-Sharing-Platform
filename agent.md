# Developer Perspective: Serious Study (Mumbai University Community App)

## 1. Architectural Foundation
Serious Study is built on a modern, reactive, and serverless architecture. It leverages the **GetX MVC** pattern to separate business logic from the UI, ensuring a highly maintainable and testable codebase.

### Core Architecture Components:
- **Reactive State Management**: `GetX` is used extensively for real-time UI updates. Controllers (e.g., `DocumentController`, `HomeController`) encapsulate all logic, from data fetching to complex UI state transitions.
- **Dependency Injection**: Services and controllers are lazily initialized via `Get.put()` and `Get.find()`, optimizing memory usage.
- **Local Persistence**: `Hive` provides a high-performance NoSQL caching layer. Critical user data is stored in `userBox` for instantaneous app launches, while `downloadsBox` tracks local file metadata.

---

## 2. Performance Engineering

### Optimized Data Retrieval:
- **Sticky Sort Algorithm**: The `HomeController` implements a custom sorting logic that prioritizes 'official' documents at the top of the feed while maintaining chronological order for community contributions.
- **Atomic Operations (RPCs)**: Critical interactions like likes, dislikes, and bookmarks use PostgreSQL **Remote Procedure Calls (RPCs)**. This ensures data integrity by performing increments/decrements directly on the database server, preventing race conditions.
- **Optimistic UI Updates**: Interactions provide immediate visual feedback. The UI updates locally while the backend synchronizes in the background, with built-in error recovery/rollback logic.

### Media & Storage Optimization:
- **Mandatory Image Compression**: The `UploadController` integrates `ImageHelper` (using `flutter_image_compress`) to optimize cover images before upload, reducing storage costs and load times.
- **10MB Direct Upload Limit**: To maintain system stability and cost-effectiveness, a hard 10MB limit is enforced for direct document uploads.
- **External Hosting Support**: Users can opt to share resources via external links (e.g., Google Drive, Mega), significantly reducing server bandwidth consumption.
- **Intelligent File Caching**: The `FileCaching` service uses `Dio` and `path_provider` to manage a local cache of accessed documents in the system's temporary directory.

---

## 3. Design Language & UI/UX

### Visual Identity:
- **Branding**: The application features a "Premium Deep Blue" (`#0D47A1`) theme, symbolizing academic excellence and integrity.
- **Glassmorphism**: Custom `Glassmorphism` containers and semi-transparent overlays (using modern `.withValues(alpha: ...)` API) create a sophisticated, layered UI.
- **Material 3**: Fully compliant with Material 3 design principles, featuring large headers, rounded corners (30.0 for the floating bottom bar), and standard Material feedback.

### User Experience Enhancements:
- **Standardized Loaders**: `Loader` and `Loader2` components provide consistent visual feedback during asynchronous operations.
- **Shimmer Effects**: Used in feed sections to provide smooth transitions during data fetching.
- **RefresherWidget**: Integrates `LiquidPullToRefresh` for an engaging and consistent refresh experience.

---

## 4. Security Architecture

### Comprehensive Authentication & Authorization:
- **JWT-Based Auth**: Integrated with **Supabase Auth**, utilizing secure JSON Web Tokens for session management.
- **Row Level Security (RLS)**: Granular PostgreSQL policies are enforced at the database level.
    - Owners have full CRUD on their documents and profiles.
    - Public read access is restricted to verified content.
    - Administrative columns (`is_admin`, `is_official`) are protected from unauthorized manipulation.

### Granular Real-time Security:
- **Secure Change Channels**: The `NotificationController` applies precise filters on Supabase PostgreSQL Change channels (e.g., `receiver_id` and `is_global` filters), ensuring users only receive relevant and authorized real-time updates.
- **Security Definer Functions**: Critical backend logic (like atomic counter updates) is encapsulated in `SECURITY DEFINER` functions, allowing users to perform authorized operations without needing direct write access to sensitive tables.

---

## 5. Development & QA Standards

### Code Quality Policies:
- **Zero Warnings Policy**: The codebase is strictly maintained with zero linting warnings. Modern APIs (e.g., `withValues`, `activeThumbColor`) are mandatory.
- **Flow Control Integrity**: All flow control structures must use explicit curly braces to maintain readability and prevent logical errors.
- **Silent Error Handling**: Intentional empty catch blocks must be annotated with `// ignore: empty_catches` to pass static analysis.

### Build Environment (Feb 2026):
- **Framework**: Flutter 3.41.2 (Stable)
- **SDK**: Dart 3.11.0
- **Android**: AGP 8.9.1, Kotlin 2.1.0, Gradle 8.12

---
*Documented by Jules, AI Software Engineer.*
