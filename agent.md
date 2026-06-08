# Developer Guide & System Manual - Serious Study

Serious Study is a premium academic networking and notes-sharing platform optimized for the Mumbai University community. This manual provides a deep-dive analysis of the system architecture, performance optimizations, and security protocols from a developer's perspective.

## 1. System Architecture
The application follows a reactive **MVC (Model-View-Controller)** pattern powered by the **GetX** ecosystem.

- **Frontend**: Flutter 3.5.4+ utilizing Material 3 and Glassmorphism design principles.
- **Backend**: Supabase (Serverless PostgreSQL).
- **State Management**: Reactive GetX controllers manage the business logic and UI state independently.
- **Persistence**: Hybrid approach using **Hive** for ultra-fast local NoSQL caching and **PostgreSQL** for relational global data.

## 2. Performance Analysis
The system is engineered for high responsiveness and minimal latency:

### 2.1 Optimized Data Fetching
- **Sticky Sort Algorithm**: The `HomeController` implements a "Sticky Sort" that prioritizes `is_official` documents at the top of the feed, followed by chronological ordering. This ensures high-quality academic content is always visible.
- **Batch Processing**: Feeds are fetched in batches (limit 50) to balance initial load time and network overhead.
- **Real-time Sync**: `Postgres Changes` via Supabase Realtime ensure that likes, comments, and new uploads are reflected instantly across all clients without manual refreshes.

### 2.2 Asset & Caching Strategy
- **Image Compression**: Mandatory compression using `flutter_image_compress` in the `UploadController` reduces asset size before transit, significantly lowering storage costs and improving load speeds.
- **Aggressive Caching**:
  - `cached_network_image` handles thumbnail caching.
  - `FileCaching` service uses `Dio` to download and store documents in the system's temporary directory, avoiding redundant downloads.
  - `HiveBoxes` store critical user metadata (`UserModel`) for instant profile loading.

### 2.3 Perceived Performance
- **Shimmer UI**: Standardized shimmer loaders are used across the app to provide immediate visual feedback during asynchronous operations.
- **Optimistic UI**: The `DocumentController` implements optimistic updates for likes and bookmarks, ensuring the UI responds instantly while the background sync with Supabase takes place.

## 3. Design Principles
Serious Study adheres to a "Premium Academic" aesthetic:

- **Typography**: Primary typeface is **Plus Jakarta Sans**, configured for hierarchical clarity in `AppTypography`.
- **Theming**: A dedicated "Premium Deep Blue" (`#0D47A1`) primary theme with support for glassmorphism overlays (`withValues(alpha: ...)`).
- **Componentization**: Modular UI widgets (e.g., `DocumentCard`, `PostCard`, `Toasts`) ensure a consistent experience and high code reusability.

## 4. Security Implementation
The platform has been hardened against common vulnerabilities through a multi-layered security approach:

### 4.1 Authentication & Authorization
- **JWT-based Auth**: Supabase Auth manages secure JSON Web Tokens.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
  - **Profiles**: `UPDATE` restricted to `auth.uid() = id`.
  - **Documents**: `INSERT` and `DELETE` restricted to the owner (`user_id`).
  - **Official Content**: Controlled via the `is_official` flag, which is restricted to administrative updates.

### 4.2 Data Integrity
- **PostgreSQL RPCs**: Atomic operations like `increment_likes` and `decrement_dislikes` are handled via `SECURITY DEFINER` functions to prevent race conditions and direct table manipulation by clients.
- **Column-level Restrictions**: Critical flags like `is_admin` are protected by RLS to prevent privilege escalation via direct API calls.

## 5. Maintenance & QA
- **Zero Warnings Policy**: The codebase is maintained with zero linting warnings (`flutter analyze`).
- **Standardized Toasts**: Error and success feedback are managed via the `toastification` package with custom styling.
- **Remote Config**: The `RemoteConfigController` allows for global maintenance toggles and announcements without requiring a new APK release.

---
*Maintained by Jules, AI Software Engineer.*
*Last System Audit: May 2026*
