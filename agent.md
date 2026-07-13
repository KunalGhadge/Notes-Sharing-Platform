# Developer Guide & Maintenance Manual - Serious Study

This document serves as the primary technical manual for the **Serious Study** (formerly NoteHub) Android application. It provides a developer-perspective audit of the system's performance, design, and security architecture.

## 1. Performance & Architecture
Serious Study is built on a high-performance, serverless architecture that prioritizes responsiveness and data integrity.

### 1.1 State Management (GetX)
- **Reactive Flow**: The application utilizes `GetX` for reactive state management. Controllers (found in `lib/controller/`) are decoupled from the UI, allowing for efficient dependency injection and memory management.
- **Optimistic UI**: Interactions like liking, disliking, or bookmarking documents (implemented in `DocumentController`) use optimistic updates. This ensures the UI reflects user actions instantly while the backend syncs asynchronously.

### 1.2 Data Persistence & Caching
- **Hive (Local NoSQL)**: Used for high-speed local caching of user profiles and download metadata. This eliminates "cold start" latency for personal dashboard views.
- **Media Caching**: `CachedNetworkImage` is used globally to minimize redundant network requests for thumbnails and profile pictures.
- **File Management**: The `FileCaching` service (`lib/service/file_caching.dart`) manages document downloads using `Dio`, checking for local existence before initiating network transfers.

### 1.3 Backend Optimization
- **Batching**: The `HomeController` fetches documents in batches (limit 50) to optimize bandwidth and rendering performance.
- **PostgreSQL RPCs**: Critical atomic operations (e.g., `increment_likes`, `decrement_dislikes`) are handled via Database RPCs. This prevents race conditions and ensures counter integrity across thousands of concurrent users.
- **Sticky Sort**: The feed implements a custom sort algorithm that prioritizes 'Official' content while maintaining chronological order for peer-uploaded notes.

## 2. Design & User Experience
The application follows a modern **Material 3** aesthetic with a premium academic focus.

### 2.1 Aesthetic Identity
- **Brand Color**: "Premium Deep Blue" (`#0D47A1`) is the primary theme color, selected to represent Mumbai University's academic integrity.
- **Glassmorphism**: Applied to navigation bars and profile cards to create a layered, modern feel using semi-transparent overlays (`.withValues(alpha: ...)`).
- **Typography**: "Plus Jakarta Sans" is used as the primary typeface for its readability and modern geometric look.

### 2.2 UI Components
- **Shimmer Effects**: Integrated into data-heavy screens to provide visual feedback during asynchronous loading.
- **Lottie Animations**: Custom animations are used for empty states and success feedback (e.g., successful uploads).

## 3. Security Analysis
Security is baked into the database layer via **Supabase** and **PostgreSQL**.

### 3.1 Authentication & Authorization
- **JWT (JSON Web Tokens)**: Secure, stateless authentication managed by Supabase Auth.
- **Row Level Security (RLS)**: Strictly enforced on every table.
    - **Profiles**: `UPDATE` restricted to `auth.uid() = id`.
    - **Documents**: Owners have `ALL` permissions; others have `SELECT` only.
    - **Interaction Integrity**: Interactions are restricted to the current user, preventing unauthorized manipulation of other users' data.

### 3.2 Database Triggers & RPCs
- **Official Status**: Setting a document as `is_official` is restricted via backend logic to ensure only admins can verify content.
- **Security Definer**: RPC functions use `SECURITY DEFINER` with an explicit `search_path = public` to prevent search-path hijacking while allowing controlled updates to protected tables like `documents`.

## 4. Maintenance & QA
- **Environment**: Requires Flutter SDK ^3.24+ and Dart SDK ^3.5.4.
- **Code Quality**: Adheres to a "Zero Warnings" policy. Always verify changes with `cd notehub && flutter analyze`.
- **Modernization**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()` and `activeThumbColor` for Switch widgets.

---
*Maintained by the Serious Study Developer Community.*
