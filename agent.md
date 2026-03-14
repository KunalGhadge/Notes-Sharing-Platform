# Developer Guide - Serious Study (formerly NoteHub)

Serious Study is a premium notes-sharing and academic networking platform specifically designed for Mumbai University students. This document provides a technical deep dive into the application's architecture, performance strategies, design system, and security framework.

## 1. Technical Architecture

### Frontend (Flutter)
- **Framework**: Flutter (SDK ^3.5.4).
- **State Management**: **GetX**. Used for reactive state updates, dependency injection, and clean navigation. Controllers (e.g., `DocumentController`, `AuthController`) decouple business logic from the UI.
- **Local Storage**: **Hive**. A high-performance NoSQL database used for persistent local caching.
    - `user` box: Stores the `UserModel` for immediate access to profile data on app launch.
    - `downloads` box: Manages local document metadata.
- **Networking**:
    - **Supabase Flutter SDK**: Primary interface for Auth, Database (PostgreSQL), and Storage.
    - **Dio**: Used for specialized file downloading and caching operations.

### Backend (Supabase)
- **Database**: **PostgreSQL**. Relational storage with complex joins and atomic operations.
- **Authentication**: **Supabase Auth**. JWT-based session management.
- **Storage**: **Supabase Storage**. S3-compatible object storage for documents and media thumbnails.
- **Real-time**: Leverages PostgreSQL logical replication for instant UI updates (e.g., live feed updates in `HomeController`).

---

## 2. Performance Optimizations

### Optimistic UI Patterns
The application implements an optimistic UI pattern for high-frequency user interactions (Likes, Dislikes, Bookmarks).
- In `DocumentController`, the UI state is updated immediately before the network request is initiated.
- If the backend synchronization fails, the UI state is gracefully reverted to the previous state, providing a seamless user experience.

### Media Handling & Compression
- **Centralized Compression**: All image uploads (e.g., document covers) are routed through `ImageHelper.compressImage`.
- **Optimization Parameters**: Uses `flutter_image_compress` with a quality setting of 70 and a minimum resolution of 1024x1024 to minimize bandwidth and storage usage while maintaining visual clarity.
- **Efficient Caching**: `cached_network_image` is utilized throughout the app to prevent redundant downloads of media assets.

### Atomic Operations (PostgreSQL RPCs)
To prevent race conditions and ensure data integrity for counters (likes, dislikes), the app avoids client-side increments. Instead, it uses **PostgreSQL RPC functions** (defined in `SUPABASE_SCHEMA.sql`):
- `increment_likes(doc_id)` / `decrement_likes(doc_id)`
- `increment_dislikes(doc_id)` / `decrement_dislikes(doc_id)`

---

## 3. Design System & UX

### Visual Identity
- **Theme**: Material 3 with a "Premium Deep Blue" primary color (#0D47A1).
- **Aesthetic**: Modern **Glassmorphism**. Implemented using `GlassmorphicContainer` and custom gradients (`AppGradients.glassGradient`) for a layered, high-end feel.
- **Typography**: Uses the **Plus Jakarta Sans** font family via `google_fonts` for a clean, academic look.

### User Experience Enhancements
- **Shimmer Loading**: Sections like `HomeDocumentSection` use Shimmer placeholders to eliminate "grey space" issues during data fetching.
- **Sticky Sort**: The `HomeController` implements a "Sticky Sort" logic where official university documents are prioritized at the top of the feed.
- **Lottie Animations**: Custom animations are used for state feedback (e.g., empty search results or successful uploads).

---

## 4. Security Implementation

### Row Level Security (RLS)
Security is enforced at the database layer. All tables in `SUPABASE_SCHEMA.sql` have strict RLS policies:
- **Profiles**: Publicly viewable, but only the owner can `UPDATE`.
- **Documents**: Publicly viewable, but only the owner can `INSERT` or `DELETE`.
- **Notifications**: Private; only the `receiver_id` can `SELECT`.

### Managed Authentication
- **JWT Protection**: All communication with Supabase is secured using JSON Web Tokens.
- **Secure RPCs**: RPC functions are defined with `SECURITY DEFINER`, allowing users to perform specific atomic updates to protected columns (like `likes_count`) without granting them direct write access to the table.

### Data Validation
- **Upload Limits**: A strict 10MB limit is enforced for direct document uploads to Supabase Storage.
- **External Links**: The app encourages the use of external links (Google Drive/Mega) for larger files to maintain service scalability.

---

## 5. Development Standards

- **Linting**: Adheres to a "Zero Warnings" policy. Deprecated members (e.g., `withOpacity`) are modernized (e.g., `withValues(alpha: x)`).
- **Environment**: CI/CD workflows are configured to run `flutter analyze` and `flutter test` within the `notehub/` subdirectory.
- **Branching**: Follow descriptive naming conventions for branches and atomic commits.

---
*Created and Maintained by the Divine Visionary Team.*
