# Developer Guide & Project Analysis: Serious Study (NoteHub)

This document serves as an exhaustive guide and technical analysis of the **Serious Study** application (formerly NoteHub), a premium notes-sharing and academic networking platform for the Mumbai University community.

---

## 1. Architecture Overview
Serious Study follows a reactive, decoupled architecture centered around the **GetX** ecosystem and **Supabase** serverless backend.

### Frontend: Flutter (MVC-ish with GetX)
- **State Management**: **GetX** (`GetxController`) is used to manage business logic and UI state independently.
- **Dependency Injection**: Services and controllers are lazily initialized or put into global memory via `Get.put()` or `Get.lazyPut()`.
- **Routing**: Managed by GetX for named and unnamed routes.

### Backend: Supabase (PostgreSQL + Auth + Storage)
- **Database**: PostgreSQL with complex relational schemas, utilizing **RPCs** for high-performance operations.
- **Real-time**: Leverages Supabase PostgreSQL changes for live updates in `HomeController` and `NotificationController`.
- **Auth**: JWT-based authentication managed by Supabase Auth.
- **Storage**: Object storage for document PDFs and compressed cover images.

---

## 2. Performance Analysis

### Reactive State & UI
- **Optimistic UI**: Implemented in `DocumentController` for likes, dislikes, and bookmarks. The UI updates immediately before the backend sync, with rollback logic in case of network failure.
- **Shimmer Placeholders**: Used across the app (`HomeDocumentSection`, `SearchPage`) to maintain high perceived performance during data fetching.

### Data Management
- **Local Persistence (Hive)**: High-performance NoSQL storage used in `HiveBoxes`. User profile data is cached in `userBox` for instant app initialization.
- **Batch Loading**: The `HomeController` limits initial feed fetches to 50 items to minimize payload size and latency.
- **Sticky Sort**: A custom sorting algorithm prioritizes "Official" university documents at the top of the feed while maintaining chronological order for peer-to-peer content.

### Media Optimization
- **Image Compression**: Centrally managed in `ImageHelper` using `flutter_image_compress` (70% quality, 1024px min dimensions) to reduce bandwidth and storage costs.
- **External Hosting Support**: The `UploadController` allows users to submit links (Google Drive, Mega) for files exceeding 10MB, optimizing server costs while maintaining resource accessibility.

---

## 3. Design & UI/UX Standards

### Aesthetic Framework
- **Theme**: "Premium Deep Blue" (`#0D47A1`) primary palette with a focus on academic professionalism.
- **Glassmorphism**: Implemented via the `glassmorphism` package, featuring blurred, semi-transparent containers for the Bottom Navigation bar and Post cards.
- **Typography**: Uses 'Plus Jakarta Sans' as the primary typeface for a modern, clean look.

### Standardized Components
- **Buttons**: Specialized classes (`PrimaryButton`, `SecondaryButton`, `OptionButton`) ensure UI consistency.
- **Feedback**: **Toastification** is the standard for system alerts (Success, Error, Warning), configured with `flatColored` style and `topRight` alignment.
- **Animations**: **Lottie** integrations for empty states, loading sequences, and successful actions.

---

## 4. Security & Data Integrity

### Authentication & Authorization
- **JWT Management**: Supabase handles secure token generation and session persistence.
- **Row Level Security (RLS)**: Strictly enforced at the database level. Users can only modify their own profiles and documents. Public readability is controlled via specific SELECT policies.

### Database Logic
- **Atomic Operations (RPCs)**: Critical interactions (like increments/decrements of counters) are handled via PostgreSQL functions defined with `SECURITY DEFINER`. This prevents client-side manipulation and race conditions.
- **Admin Controls**: Administrative features (like marking documents as official) are protected by database checks on the `is_admin` boolean within the `profiles` table.

---

## 5. Development Guidelines

### Tech Stack Constraints
- **Flutter SDK**: `^3.5.4`
- **Dart SDK**: `^3.11.0`
- **Android**: `compileSdk 36`, `Java 17`, `multiDexEnabled true`.

### Coding Conventions
- **Zero Warnings Policy**: All code must pass `flutter analyze` with no warnings.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Flow Control**: All `if`, `for`, and `else` blocks **must** use curly braces.
- **Error Handling**: Intentional empty catch blocks must be annotated with `// ignore: empty_catches`.

### Verification Steps
Before submission, every developer must:
1. Run `flutter analyze` in the `notehub/` directory.
2. Run `flutter test` to ensure unit test compliance.
3. Verify that `pubspec.lock` remains consistent.

---
*Maintained by Jules, AI Software Engineer.*
