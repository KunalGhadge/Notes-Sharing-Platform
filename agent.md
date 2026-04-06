# Developer Guide - Serious Study (formerly NoteHub)

This document serves as the exhaustive technical guide for the **Serious Study** project. It provides an in-depth analysis of the application's performance, design, architecture, and security from a developer's perspective.

## 1. Project Overview
Serious Study is a premium, academic-focused community platform designed specifically for students at Mumbai University. The application enables users to share notes, interact with peers, and stay updated with official academic resources. The project has undergone a significant migration from a legacy Django/MongoDB stack to a modern, serverless **Supabase** architecture.

---

## 2. Performance Analysis
The application is optimized for responsiveness and efficiency, even in environments with varying network conditions.

### Reactive State Management
- **Framework**: Built with **GetX**, which ensures efficient state updates and dependency injection.
- **Controllers**: Logic is encapsulated in specialized controllers (e.g., `DocumentController`, `AuthController`, `HomeController`) to separate business rules from UI components.

### Data Persistence & Caching
- **Local Storage**: **Hive** is utilized for high-performance NoSQL local storage.
    - `userBox`: Stores the current user's profile metadata (`UserModel`) to enable instant profile loading.
    - `downloadsBox`: Tracks local downloads and caching states.
- **Image Caching**: The `cached_network_image` package is used throughout the app to reduce bandwidth and provide a smoother scrolling experience by caching thumbnails and profile pictures.

### Media Optimization
- **Mandatory Compression**: All cover images are compressed using `flutter_image_compress` in `lib/core/helper/image_helper.dart` before upload. This minimizes storage costs and speeds up feed loading.
- **Upload Limits**: Direct document uploads are capped at **10MB**. For larger files, the app encourages the use of external links (e.g., Google Drive), which are natively handled by `UploadController`.

### Database Efficiency
- **PostgreSQL RPCs**: Critical operations like `increment_likes` and `decrement_dislikes` are executed via database-level functions. This ensures **atomic operations**, preventing race conditions and maintaining data integrity.
- **Batch Processing**: The `HomeController` fetches updates in batches of 50 to minimize initial payload size.
- **Sticky Sort**: The feed implements a "Sticky Sort" logic, prioritizing official university documents at the top of the feed regardless of their upload date.

---

## 3. Design & UI/UX
The design follows **Material 3** principles, emphasizing a premium, academic aesthetic.

### Aesthetic & Themes
- **Primary Color**: **Premium Deep Blue** (`#0D47A1`), chosen to represent academic integrity and professionalism.
- **Glassmorphism**: Extensively used via the `glassmorphism` package, particularly in the `PostCard` and navigation elements, creating a modern, layered look.
- **Typography**: Uses 'Plus Jakarta Sans' (via `google_fonts`) for clean and readable text across all academic content.

### User Experience
- **Optimistic UI**: The `DocumentController` uses optimistic updates for interactions like likes and bookmarks. The UI reflects the change immediately, syncing with the backend in the background.
- **Visual Feedback**:
    - **Shimmer Placeholders**: Used in `HomeDocumentSection` and `SearchPage` to prevent "grey space" and provide a smooth loading experience.
    - **Lottie Animations**: Integrated for success states and empty search results.
    - **Standardized Loaders**: `Loader` and `Loader2` components provide consistent loading indicators.
- **Toast Notifications**: Standardized via the `toastification` package in `lib/view/widgets/toasts.dart`, ensuring clear communication of system status.

---

## 4. Architecture & Security
The migration to **Supabase** has drastically improved the security posture and scalability of the platform.

### Backend Architecture (Serverless)
- **Database**: PostgreSQL with **Row Level Security (RLS)**.
- **Authentication**: JWT-based authentication managed by Supabase Auth.
- **Real-time Engine**: Uses PostgreSQL CDC (Change Data Capture) via `RealtimeChannel` to sync notifications and document updates instantly across clients.

### Security Implementation
- **Data Protection**: RLS policies in `SUPABASE_SCHEMA.sql` ensure:
    - Users can only update their own profiles.
    - Only document owners (or admins) can delete or modify notes.
    - Notifications are private to the receiver.
- **Secure Operations**: Counters (likes/dislikes) are modified using `SECURITY DEFINER` RPC functions, allowing users to increment counts without having direct write access to sensitive database columns.
- **Storage Security**: Document and thumbnail storage in Supabase is governed by policies that restrict access based on user session and ownership.

### Android Specifics
- **Target API**: Compiled with **SDK 36** (Android 15+) to ensure future compatibility.
- **Notifications**: Configured with `flutter_local_notifications` using the `@mipmap/ic_launcher` icon and a high-priority channel (`notes_channel`).
- **Authentication**: Deep links are configured in `AndroidManifest.xml` using the `io.supabase.flutternotehub` scheme.

---

## 5. Development Standards & QA
The project maintains a high bar for code quality and consistency.

### Coding Conventions
- **Zero Warnings Policy**: All code must pass `flutter analyze` without warnings.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Flow Control**: All `if/else` and `for` loops must use curly braces `{}`.
- **Error Handling**: Intentional empty catch blocks must be marked with `// ignore: empty_catches`.
- **Clean Code**: Use `lowerCamelCase` for variables (e.g., `avatarUrl`) and avoid `print()` statements in production code.

### Build & Test
- **Prerequisites**: Flutter SDK `^3.5.4`.
- **Analysis**: Always run `flutter analyze` before committing.
- **Testing**: Ensure all unit tests in the `test/` directory pass.

---
*Documented by Jules, AI Software Engineer.*
