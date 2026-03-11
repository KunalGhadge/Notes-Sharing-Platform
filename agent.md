# Developer Guide - Serious Study (Deep Dive Analysis)

This document provides a comprehensive technical analysis of the Serious Study platform (formerly NoteHub) from a developer's perspective. It details the architecture, performance optimizations, design paradigms, and security measures implemented in the Flutter + Supabase stack.

## 1. Project Overview
Serious Study is a premium academic networking and notes-sharing platform for Mumbai University students. It migrated from a legacy Django/MongoDB stack to a serverless **Supabase** architecture to achieve real-time capabilities, superior scalability, and enterprise-grade security.

## 2. Technical Architecture
The application follows a modular architecture powered by **GetX** for state management and dependency injection.

- **Frontend**: Flutter 3.24+ (SDK ^3.5.4)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Edge Functions)
- **Local Storage**: Hive (High-performance NoSQL)
- **Networking**: Supabase SDK for real-time and CRUD; Dio for specialized file caching/downloads.

### Directory Structure:
- `lib/controller/`: Reactive business logic (e.g., `DocumentController`, `AuthController`).
- `lib/view/`: Modular UI components and screens (Material 3 + Glassmorphism).
- `lib/service/`: Infrastructure layers (e.g., `FileCaching`, `NotificationService`).
- `lib/core/`: Global configurations, theme definitions, and helpers.
- `lib/model/`: Strongly typed data structures for serializing Supabase responses.

## 3. Performance & Optimization

### Reactive State & Optimistic UI
- **GetX Integration**: Controllers manage state independently of the UI. Reactive variables (`.obs`) ensure minimal rebuilds.
- **Optimistic UI**: Interactions like liking, disliking, and bookmarking (in `DocumentController`) update the local UI immediately before synchronizing with the backend. Revert logic is implemented in `catch` blocks to handle network failures gracefully.

### Data Management & Caching
- **High-Speed Caching**: `Hive` is used to store user sessions and profile metadata (`userBox`), ensuring the "My Profile" tab loads instantly without network overhead.
- **Batch Fetching**: The `HomeController` fetches updates in batches of 50 to optimize payload size.
- **Sticky Sort**: Official university documents are prioritized in the feed through a custom sorting algorithm in `HomeController` (`is_official DESC, created_at DESC`).

### Media Optimization
- **Image Compression**: `flutter_image_compress` is integrated into the `UploadController`. Covers are compressed to 70% quality and 1024px dimensions before reaching Supabase Storage to save bandwidth.
- **Asset Caching**: `cached_network_image` is used throughout the app to prevent redundant downloads of document thumbnails and avatars.

### Atomic Database Operations
- **PostgreSQL RPCs**: To prevent race conditions in counters (likes/dislikes), the app uses `supabase.rpc()` to call database-side functions (`increment_likes`, `decrement_dislikes`). These are defined with `SECURITY DEFINER` for atomic, secure updates.

## 4. Design & UI/UX

### Aesthetics
- **Material 3**: The app adheres to the latest Material Design guidelines, utilizing the `ColorScheme.fromSeed` API.
- **Glassmorphism**: Implemented using the `glassmorphism` package. Components like `PostCard` and the bottom navigation bar use semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`) and custom gradients (`AppGradients.glassGradient`).
- **Typography**: Uses 'Plus Jakarta Sans' via `google_fonts` for a modern, academic feel.

### User Experience
- **Shimmer Effects**: `shimmer` placeholders are used during initial data loads (e.g., `HomeDocumentSection`) to prevent blank screens and "grey space" issues.
- **Lottie Animations**: Interactive feedback for success/empty states (e.g., in search results).
- **Custom SVG Rendering**: `flutter_svg` with `colorFilter` is used for high-quality, theme-responsive icons.

## 5. Security Implementation

### Authentication
- **JWT-based Auth**: Managed by Supabase Auth. Sessions are persisted and refreshed securely by the SDK.
- **Deep Linking**: Configured in `AndroidManifest.xml` with the `io.supabase.flutternotehub` scheme to handle secure login callbacks.

### Authorization (RLS)
- **Row Level Security**: Every table in `SUPABASE_SCHEMA.sql` has strict RLS policies.
    - **Profiles**: Publicly readable; writable only by the owner.
    - **Documents**: Publicly readable; owner-only delete/update.
    - **Notifications**: Private to the `receiver_id`.
- **Admin Roles**: The `is_admin` flag in the `profiles` table allows for "Official" document labeling and global announcement broadcasts.

### Storage Security
- **Signed URLs**: Documents are stored in protected buckets. Policies ensure that while thumbnails might be public, direct document access can be restricted to authenticated users.
- **Upload Limits**: A strict 10MB limit is enforced in `UploadController` for direct uploads to maintain free-tier integrity, encouraging external links for larger files.

## 6. Coding Conventions & Standards

Developers must adhere to the project's 'Zero Warnings' policy:
- **Linting**: All code must pass `flutter analyze` without informational issues.
- **Modern APIs**:
    - Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
    - Use `colorFilter` for `SvgPicture` instead of the `color` property.
- **Safety**:
    - All flow control structures must use curly braces `{}`.
    - Use `CountOption.exact` for Supabase record counting.
    - Intentional empty catch blocks must be annotated with `// ignore: empty_catches` and a comment.
- **Testing**: Run `flutter test` before any PR to ensure core models and controllers remain stable.

---
*Maintained by Jules, AI Software Engineer.*
