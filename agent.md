# Developer Guide & System Manual - Serious Study

Welcome to the **Serious Study** (formerly NoteHub) developer guide. This document serves as the exhaustive source of truth for the application's architecture, design philosophy, security protocols, and maintenance standards.

## 1. Project Vision
Serious Study is a premium academic networking and resource-sharing platform specifically designed for the Mumbai University community. It bridges the gap between traditional study methods and modern digital collaboration.

## 2. Architectural Analysis (Performance)

### 2.1 State Management & Logic
- **GetX Framework**: The application uses `GetX` for reactive state management, dependency injection, and routing.
- **Controller Pattern**: Business logic is strictly decoupled into controllers (e.g., `DocumentController`, `HomeController`).
- **Optimistic UI**: Interactions like likes, dislikes, and bookmarks are reflected in the UI immediately using optimistic updates before being synchronized with the Supabase backend.

### 2.2 Data Strategy
- **Hybrid Storage**:
    - **Supabase (Remote)**: Primary source of truth using PostgreSQL.
    - **Hive (Local)**: High-performance NoSQL caching for user sessions and profile data (`userBox`) and download metadata (`downloadsBox`).
- **Network Optimization**:
    - **Batching**: The home feed fetches documents in batches of 50 to balance responsiveness and data usage.
    - **Sticky Sort**: The `HomeController` implements a "Sticky Sort" algorithm where 'Official' documents are prioritized at the top of the feed regardless of their creation date.
    - **Atomic Operations**: Critical counters (likes/dislikes) are updated via PostgreSQL RPCs (`increment_likes`, `decrement_dislikes`) to prevent race conditions.

### 2.3 Media & Asset Handling
- **Compression**: `ImageHelper` utilizes `flutter_image_compress` to optimize cover images before upload, maintaining a 70% quality threshold.
- **Caching**: `cached_network_image` is used globally to minimize redundant asset downloads.
- **Upload Constraints**: The `UploadController` enforces a 10MB limit for direct document uploads to ensure platform sustainability.

## 3. Design Philosophy

### 3.1 Visual Identity
- **Theme**: "Premium Deep Blue" (#0D47A1) serves as the primary brand color.
- **Typography**: "Plus Jakarta Sans" is the standardized typeface for all UI components.
- **Material 3**: Full implementation of Material 3 components and design patterns.

### 3.2 Advanced UI Components
- **Glassmorphism**: Applied to the `BottomFooter` and various overlays using semi-transparent white values (alpha: 0.1 - 0.15) and spread shadows.
- **Micro-interactions**: Enhanced via `liquid_pull_to_refresh`, `shimmer` placeholders, and `Lottie` animations for state feedback.
- **Loaders**: Custom `Loader` widget provides a consistent brand experience during asynchronous operations.

## 4. Security Framework

### 4.1 Authentication & Authorization
- **Supabase Auth**: Managed JWT-based authentication ensures secure session handling.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - **Profiles**: Publicly viewable, but only owners can update their own data.
    - **Documents**: Publicly viewable, but only owners (or admins) can modify content.
    - **Storage**: Governed by policies ensuring that only authenticated users can upload to specific paths.

### 4.2 Known Security Considerations
- **Privilege Escalation Risk**: Currently, the `profiles` update policy allows users to update their own rows. Developers must ensure column-level restrictions are implemented via triggers or more granular policies to prevent users from self-assigning the `is_admin` flag.
- **Official Status**: Similar to profiles, the `documents` policy currently allows owners to modify any field of their document, including the `is_official` flag. Administrative verification should ideally be handled via a `SECURITY DEFINER` RPC.

## 5. Maintenance & QA (Zero Warnings Policy)

The project adheres to a strict **"Zero Warnings"** policy. All contributions must pass `flutter analyze` without any errors or info-level hints.

### 5.1 Modernization Standards
- **Color APIs**: Always use `.withValues(alpha: ...)` instead of the deprecated `.withOpacity()`.
- **Switch Widgets**: Use `activeThumbColor` instead of the deprecated `activeColor`.
- **Flow Control**: All `if`, `else`, `for`, and `while` statements **must** be enclosed in curly braces, even for single-line blocks.
- **Silent Catches**: Intentional empty catch blocks must be annotated with `// ignore: empty_catches` inside the block.

### 5.2 Verification Workflow
Before submitting any code, developers must:
1. Run `flutter analyze` and resolve all issues.
2. Run `flutter test` to ensure no regressions in the core models or controllers.
3. Verify UI changes against the Glassmorphism standards defined in `BottomFooter`.

---
*Maintained by Jules, AI Software Engineer.*
