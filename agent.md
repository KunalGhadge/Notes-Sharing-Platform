# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It serves as the primary source of truth for architecture, performance optimizations, design standards, and security protocols within the codebase.

## 1. Project Overview
Serious Study is a premium notes-sharing and academic networking platform for the Mumbai University student community. It features a Flutter frontend and a serverless Supabase (PostgreSQL) backend.

## 2. Architecture & State Management
- **Framework**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management**: **GetX** is used for reactive state updates and dependency injection.
    - **Controllers**: (e.g., `DocumentController`, `AuthController`) manage business logic and communicate with the Supabase client.
    - **Views**: Modular UI components that react to controller state changes.
- **Backend**: **Supabase Serverless Architecture**.
    - **PostgreSQL**: Relational database with Row Level Security (RLS).
    - **Supabase Auth**: JWT-based session management and secure authentication.
    - **Supabase Storage**: Object storage for documents and user-generated media.

## 3. Performance Optimizations
- **Media Handling**:
    - **Image Compression**: Centralized in `lib/core/helper/image_helper.dart` using `flutter_image_compress` (Quality: 70, MinWidth/Height: 1024) to optimize uploads and reduce bandwidth.
    - **Caching**: `cached_network_image` is used globally to prevent redundant media downloads.
- **Data Retrieval**:
    - **Batch Fetching**: `HomeController` limits feed updates to 50 items per request to minimize networking overhead.
    - **Sticky Sort**: Official university documents are prioritized in the feed using a custom sort logic (is_official DESC, created_at DESC).
    - **Atomic Operations**: Critical interactions (likes, dislikes) use PostgreSQL **RPCs** (e.g., `increment_likes`) with `SECURITY DEFINER` to ensure data consistency and prevent race conditions.
- **Local Persistence**: **Hive** (NoSQL) is used for high-performance local caching of user profiles (`userBox`) and download metadata, ensuring instant UI responsiveness.
- **Optimistic UI**: The `DocumentController` implements optimistic updates for likes and bookmarks, providing immediate visual feedback before backend synchronization.

## 4. Design & UX Standards
- **Design Language**: **Material 3** with a **Glassmorphism** aesthetic.
    - **Glassmorphism**: Implemented via `GlassmorphicContainer` and `AppGradients.glassGradient` (see `PostCard` and `BottomFooter`).
- **Branding**:
    - **Primary Color**: Premium Deep Blue (`#0D47A1`).
    - **Typography**: 'Plus Jakarta Sans' (via `google_fonts`).
- **Feedback**:
    - **Shimmer Effects**: Used in `HomeDocumentSection` to eliminate "grey space" during data fetching.
    - **Lottie Animations**: Integrated for empty states and success feedback.
- **SVG Handling**: All SVGs must use `colorFilter` (not the deprecated `color` property) via `SvgPicture.asset`.

## 5. Security Protocols
- **Authorization**: **Row Level Security (RLS)** is strictly enforced in `SUPABASE_SCHEMA.sql`.
    - Public readability for profiles and documents.
    - Private write access (owners only) for all user-generated content.
- **Database Integrity**: RPC functions use `SECURITY DEFINER` to allow atomic counter updates (likes/dislikes) without granting users direct write access to sensitive columns.
- **Upload Restrictions**: Direct document uploads are capped at **10MB** to maintain storage efficiency; the app encourages external links (Google Drive/Mega) for larger files.
- **Session Management**: Auth tokens (JWT) are handled by the Supabase SDK, with deep-link support configured in `AndroidManifest.xml` (`io.supabase.flutternotehub`).

## 6. Development & QA Directives
- **Linting Policy**: Code should pass `flutter analyze` with minimal warnings. While the project aims for high code quality, certain deprecations (like `withOpacity` or `activeColor`) are tolerated to maintain compatibility with older Flutter SDKs (3.24+).
- **Coding Conventions**:
    - Use `camelCase` for variables (e.g., `avatarUrl`).
    - Avoid `print()` statements; use `debugPrint()` or specialized logging if necessary.
    - All flow control structures (if, for, while) must use curly braces.
    - Intentional empty catch blocks must include comments (e.g., `/* silent */`).
- **Verification**: Run `flutter analyze && flutter test` in the `notehub/` directory to ensure codebase integrity.

---
*Maintained by Jules, AI Software Engineer.*
