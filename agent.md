# Developer Guide - Serious Study (Mumbai University Community App)

This document provides a comprehensive technical analysis and development guidelines for the **Serious Study** platform (formerly NoteHub). It is designed to assist engineers in understanding the architecture, performance optimizations, and security protocols of the system.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform tailored for students of Mumbai University. The platform has been migrated from a legacy stack to a modern, serverless architecture using **Flutter** for the frontend and **Supabase** for the backend.

## 2. Technical Stack
- **Frontend**: Flutter (Target SDK: 3.27+ | Minimal SDK: 3.5.4)
- **State Management**: **GetX** (Reactive patterns, Dependency Injection)
- **Backend-as-a-Service**: **Supabase** (PostgreSQL, Auth, Storage, Realtime)
- **Local Persistence**: **Hive** (NoSQL local caching)
- **Asset Management**: `flutter_svg`, `lottie`, `cached_network_image`
- **Networking/File Ops**: `Dio`, `path_provider`, `open_file`

## 3. Performance & Optimization
The application is built with a focus on perceived performance and bandwidth efficiency.

### 3.1 Reactive Architecture & Caching
- **GetX State Management**: Controllers (e.g., `DocumentController`, `HomeController`) manage business logic independently. UI components react only to necessary state changes.
- **Hive Local Storage**:
    - User profile data is cached in `userBox` for instant loading on app launch.
    - Downloaded documents are tracked in `downloadsBox`.
- **Cached Network Image**: Thumbnails and profile pictures are cached locally to minimize redundant network requests.

### 3.2 Media Handling
- **Image Compression**: Centralized in `lib/core/helper/image_helper.dart`. Before upload, cover images are compressed using `flutter_image_compress` (quality 70, 1024px min dimensions) to optimize storage and loading times.
- **Bandwidth Management**: Direct document uploads are capped at **10MB**. Users are encouraged to share external links (Google Drive/Mega) for larger files.

### 3.3 Database Efficiency
- **PostgreSQL RPCs**: High-frequency operations like likes and bookmarks use atomic RPC functions (e.g., `increment_likes`, `decrement_dislikes`) to prevent race conditions and reduce client-side logic.
- **Batching & Limits**: Home feed updates are limited to 50 items, and search results are optimized to fetch relational data (profiles, interactions) in a single join query.
- **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm prioritizing official university documents at the top of the feed.

## 4. Design & UI/UX
The application adheres to **Material 3** principles with a distinct **Glassmorphism** aesthetic.

### 4.1 Visual Language
- **Color Palette**: Centered around **Premium Deep Blue** (`#0D47A1`), symbolizing academic integrity.
- **Typography**: Uses **Plus Jakarta Sans** via `google_fonts` for a modern, readable feel.
- **Glassmorphism**: Implemented using the `glassmorphism` package and custom gradients (`AppGradients.glassGradient`) for a layered, premium look.
- **UX Feedback**: Shimmer placeholders (`shimmer` package) and Lottie animations are used to handle loading states and empty results gracefully.

### 4.2 Asset Integration
- **SVG Rendering**: SVGs are rendered via `SvgPicture.asset` using `colorFilter` instead of the deprecated `color` property.
- **Animations**: `Lottie` is used for interactive state feedback (e.g., success checkmarks).

## 5. Security & Data Integrity
Migration to Supabase has systematically addressed legacy vulnerabilities.

### 5.1 Authentication & Authorization
- **JWT Auth**: Managed by Supabase Auth with secure session handling.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - **Profiles**: Only owners can `UPDATE`.
    - **Documents**: Only owners can `INSERT` or `DELETE`.
    - **Bookmarks/Notifications**: Private to the specific user.
- **Security Definer RPCs**: Database functions for counters are defined with `SECURITY DEFINER`, allowing users to trigger increments without having direct write access to sensitive table columns.

### 5.2 Secure File Storage
- Storage buckets use RLS-like policies to ensure that document paths are only writable by the authenticated owner.

## 6. Development Guidelines & Conventions
The project maintains a **Zero Warnings** linting policy.

### 6.1 Coding Conventions
- **Variable Naming**: Use `lowerCamelCase` (e.g., `avatarUrl`).
- **Modern APIs**:
    - Use `.withValues(alpha: x)` instead of `.withOpacity(x)`.
    - Use `activeThumbColor` instead of `activeColor` for Material 3 components.
- **Error Handling**: Use the `// ignore: empty_catches` annotation and a comment (e.g., `/* silent */`) for intentional empty catch blocks.
- **Prohibited**: Avoid `print()` statements; use `debugPrint()` or specialized logging if necessary.
- **Flow Control**: All flow control structures (`if`, `for`, `while`) **MUST** use curly braces.

### 6.2 Project Structure
- `lib/controller/`: Business logic and state management.
- `lib/model/`: Data structures and Hive adapters.
- `lib/service/`: Low-level utilities (e.g., file caching, API clients).
- `lib/view/`: UI screens and modular widgets.
- `lib/core/`: Global configurations, themes, and metadata.

## 7. Build & Deployment
### 7.1 Android Configuration
- **Prerequisites**: `multiDexEnabled true`, `coreLibraryDesugaringEnabled true`.
- **Dependencies**: `com.android.tools:desugar_jdk_libs:2.1.4` for modern API support.
- **Deep Linking**: Configured for `io.supabase.flutternotehub://login-callback` in `AndroidManifest.xml`.

### 7.2 Verification
Before submission, always run:
```bash
cd notehub
flutter analyze
flutter test
```

---
*Documentation maintained by Jules, AI Software Engineer.*
