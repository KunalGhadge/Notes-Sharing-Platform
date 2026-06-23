# Technical Manual & Agent Guide - Serious Study

This document serves as the primary system manual for the Serious Study repository, providing a deep-dive technical analysis from a developer's perspective.

## 1. Project Architecture & Stack
Serious Study is a premium academic networking platform for Mumbai University, utilizing a serverless architecture.

- **Frontend**: Flutter 3.5.4 (Dart 3.5.0+)
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **State Management**: GetX (Reactive pattern)
- **Local Persistence**: Hive (NoSQL)
- **Primary Brand Color**: Premium Deep Blue (`#0D47A1`)

## 2. Performance Analysis
- **Reactive State Management**: `GetX` is used to decouple business logic from UI. Controllers (e.g., `DocumentController`, `HomeController`) manage state reactively using `.obs` and `Obx`.
- **Local Caching**:
    - `Hive` manages high-performance local storage.
    - `userBox` stores `UserModel` data (id, username, profileUrl) for instant profile loading.
    - `downloadsBox` tracks locally cached documents.
- **Optimistic UI Updates**: Interactions such as likes, dislikes, and bookmarks in `DocumentController` use optimistic updates to provide immediate user feedback before backend synchronization.
- **Atomic Operations**: Counter updates (`likes_count`, `dislikes_count`) are handled via Supabase RPCs (`increment_likes`, `decrement_likes`, etc.) to ensure consistency and prevent race conditions.
- **Feed Optimization**: `HomeController` fetches updates in batches (limit 50) and implements a "Sticky Sort" algorithm that prioritizes official documents while maintaining chronological order.

## 3. Design & UX Aesthetic
- **UI Paradigm**: Material 3 with a **Glassmorphism** overlay aesthetic.
- **Glassmorphism**: Implemented using the `glassmorphism` package and custom gradients (`AppGradients.glassGradient`) for components like `BottomFooter` and `PostCard`.
- **Typography**: "Plus Jakarta Sans" is the primary typeface, providing a modern academic feel.
- **Visual Feedback**:
    - `shimmer` placeholders for loading states.
    - `lottie` animations for empty states and success feedback.
    - `liquid_pull_to_refresh` for an organic feel during feed updates.

## 4. Security & Data Integrity
- **Authentication**: Managed via Supabase Auth (JWT). User sessions are verified before sensitive operations (e.g., `UploadController.uploadDocument`).
- **Authorization (RLS)**: Row Level Security is strictly enforced in `SUPABASE_SCHEMA.sql`:
    - **Profiles**: Authenticated users can only update their own records.
    - **Documents**: Owners have full CRUD permissions; others have read-only access.
    - **Official Content**: The `ensure_official_permission` trigger restricts the `is_official` flag to users with `is_admin = true`.
- **Security Definer**: PostgreSQL functions use `SECURITY DEFINER` with explicit `search_path = public` to prevent search-path hijacking while allowing controlled atomic updates.

## 5. Maintenance & QA
- **Zero Warnings Policy**: The codebase strictly adheres to a zero-warning linting standard.
    - Modernized APIs: Use `.withValues(alpha: x)` instead of deprecated `.withOpacity(x)`.
    - Switches: Use `activeThumbColor` instead of `activeColor`.
    - Flow Control: Explicit curly braces are required for all `if/else` and loop structures.
- **Verification Commands**:
    - Analysis: `cd notehub && flutter analyze`
    - Testing: `cd notehub && flutter test`
- **File Limits**: Direct document uploads are enforced at a 10MB limit; larger files are recommended to be shared via external links.

---
*Last Technical Audit: June 2026*
*Documented by Jules, AI Software Engineer.*
