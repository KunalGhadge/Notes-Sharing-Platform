# Developer Guide - Serious Study (Mumbai University Community App)

This document provides a comprehensive technical analysis of the Serious Study application from a developer's perspective, documenting its architecture, performance, design, and security.

## 1. Performance Analysis
- **Reactive State Management**: The application utilizes `GetX` for high-performance reactive state updates. Controllers manage business logic independently of the UI, ensuring efficient rebuilds only when necessary.
- **Local Persistent Caching**:
    - **Hive**: Used as a high-speed NoSQL local database for caching primary user profile data (`userBox`) and download metadata (`downloadsBox`). This ensures near-instant UI responsiveness upon app launch by bypassing initial network calls.
- **Media Optimization Pipeline**:
    - **Image Compression**: Integrated via `flutter_image_compress` in `lib/core/helper/image_helper.dart`. All cover images are compressed to 70% quality with a `minWidth`/`minHeight` of 1024px before upload.
    - **Bandwidth Management**: A strict 10MB limit is enforced for direct document uploads in `UploadController`. For larger files, the app encourages the use of external hosting links (Google Drive, Mega) to reduce server load and user data usage.
    - **Thumbnail Caching**: `cached_network_image` is used throughout the UI to prevent redundant downloads of asset thumbnails.
- **Data Fetching Strategy**:
    - **Lazy Loading**: `HomeController` fetches updates in batches of 50.
    - **Sticky Sort**: Implemented in `HomeController` to prioritize official university resources (`is_official`) at the top of the feed, followed by chronological sorting.
- **Optimistic UI Updates**: Interactions like liking, disliking, and bookmarking (in `DocumentController`) provide immediate UI feedback before confirming the transaction with the Supabase backend.

## 2. Design & UX
- **UI Paradigm**: The app adheres to **Material 3** principles, featuring modern typography and layered components.
- **Glassmorphism Aesthetic**: Implemented using the `glassmorphism` package, particularly in the navigation bar and post cards, creating a premium, academic feel.
- **Visual Feedback**:
    - **Shimmer Effects**: Used in feed sections during data fetching to reduce perceived latency.
    - **Lottie Animations**: Custom animations are used for state feedback, such as empty search results or successful contributions.
- **Typography & Color**:
    - **Primary Theme**: "Premium Deep Blue" (#0D47A1) as defined in `lib/core/config/color.dart`.
    - **Typography**: Uses the 'Plus Jakarta Sans' typeface via `google_fonts`.

## 3. Security Architecture
- **Authentication**: Powered by **Supabase Auth (JWT)**. Sessions are managed securely by the SDK, moving away from legacy session-less models.
- **Authorization (Row Level Security)**: Strict **RLS** is enforced on the PostgreSQL database. Policies in `SUPABASE_SCHEMA.sql` ensure:
    - Users can only modify their own profiles and documents.
    - Notifications and bookmarks are private to the recipient/owner.
    - Public read access is granted for community content (profiles, documents, interactions).
- **Atomic Operations (RPC)**: Atomic interactions (e.g., `increment_likes`, `decrement_dislikes`) are handled via `SECURITY DEFINER` PostgreSQL functions. This prevents race conditions and allows for counter updates without giving users direct write access to protected columns.
- **Storage Security**: Supabase Storage buckets are governed by policies that restrict file uploads and deletions to the owner of the specific asset path (`$userId/`).

## 4. System Architecture
- **Structure**: Follows a decoupled MVC-like pattern using GetX:
    - `lib/controller/`: Business logic and state management.
    - `lib/model/`: Data structures and Hive adapters.
    - `lib/view/`: Modular, reusable UI components and screens.
    - `lib/service/`: Core utilities for networking, notifications, and file management.
- **Backend Architecture**: Serverless implementation using Supabase (PostgreSQL, Auth, Storage, and Real-time).
- **Real-time Synchronization**: Uses Supabase PostgreSQL Change channels to sync document updates and notifications across clients in real-time.

---
*Maintained by the Serious Study Engineering Team.*
