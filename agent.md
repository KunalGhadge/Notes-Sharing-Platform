# Developer Guide - Serious Study (Mumbai University Community App)

This document serves as a comprehensive technical guide and system manual for the **Serious Study** (formerly NoteHub) Android application. It provides a deep dive into the architecture, performance optimizations, design patterns, and security protocols from a developer's perspective.

## 1. System Architecture
The application follows a decoupled MVC-inspired architecture powered by **GetX** for state management and **Supabase** for a serverless backend.

### Core Technologies
- **Frontend**: Flutter 3.24+ (SDK ^3.5.4)
- **State Management**: GetX (Reactive, Dependency Injection, Routing)
- **Local Persistence**: Hive (High-performance NoSQL)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Real-time)
- **Networking**: Supabase SDK & Dio

### Project Structure
- `lib/controller/`: Reactive business logic (e.g., `DocumentController`, `AuthController`).
- `lib/view/`: Modular UI components and screen layouts.
- `lib/model/`: Data structures and serialization logic.
- `lib/core/`: Centralized configurations (Meta, Theme, Typography, Helpers).
- `lib/service/`: Infrastructure services (Notifications, File Caching).

---

## 2. Performance Analysis & Optimizations
Serious Study is engineered for high responsiveness and minimal latency.

- **Reactive UI updates**: Utilizing `Obx` and `GetX` builders ensures that only the necessary widgets are rebuilt when the state changes.
- **Local Metadata Caching**: User profiles and session data are stored in `HiveBoxes`. This allows for "instant-on" feel where the UI renders user data without waiting for network calls.
- **Sticky Sort Algorithm**: The `HomeController` implements a custom sort where `is_official` documents are pinned to the top, followed by a chronological sort (`created_at DESC`).
- **Atomic Operations (RPCs)**: Critical counters like `likes_count` and `dislikes_count` are managed via PostgreSQL Functions (RPCs). This prevents race conditions and ensures data integrity across thousands of concurrent users.
- **Media Optimization**:
    - **Compression**: `flutter_image_compress` reduces cover image sizes before upload.
    - **Lazy Loading**: Documents are fetched in batches of 50 in the main feed.
    - **Caching**: `cached_network_image` is used globally to prevent redundant asset downloads.

---

## 3. Design & Aesthetics
The app implements a modern, premium academic aesthetic tailored for Mumbai University.

- **Material 3**: Fully compliant with M3 guidelines, featuring dynamic color schemes and updated component styles.
- **Glassmorphism**: Applied to high-impact areas like the `BottomFooter` and profile cards, using semi-transparent overlays (`Colors.white.withValues(alpha: 0.15)`) and Gaussian blurs.
- **Brand Identity**: Rebranded with **Premium Deep Blue** (`#0D47A1`) as the primary color, complemented by **Premium Gold** for official highlights.
- **Typography**: Uses **Plus Jakarta Sans** as the primary typeface for a clean, professional look.
- **Visual Feedback**: Integrated **Shimmer** effects for loading states and **Lottie** animations for interactive feedback (e.g., success/empty states).

---

## 4. Security & Data Integrity
Security is a core pillar of the migration from legacy systems to Supabase.

- **Authentication**: JWT-based security managed by Supabase Auth. Sessions are persisted securely and validated on every request.
- **Authorization (RLS)**: **Row Level Security** is enforced at the database level.
    - Users can only `UPDATE` their own profiles.
    - Only the document creator (or admins) can `DELETE` content.
    - `is_official` status is protected; only users with `is_admin = true` in their profile can set this flag (enforced via database constraints and Flutter UI logic).
- **Secure File Access**: All documents in Supabase Storage are governed by policies that restrict access to authorized users or public buckets as defined by project requirements.
- **Search-Path Hijacking Protection**: PostgreSQL functions use explicit `SET search_path = public` to mitigate security risks.

---

## 5. Maintenance & QA
To maintain the high quality of the codebase, developers must adhere to the following standards:

- **Zero Warnings Policy**: All code must pass `flutter analyze` with zero warnings. Modern APIs (e.g., `.withValues()` instead of `.withOpacity()`) must be used.
- **Testing**: Run `flutter test` to verify logic integrity in controllers and models.
- **Android Configuration**: Target SDK 36, Java 17, and MultiDex enabled for compatibility with modern Android features.
- **Code Standards**:
    - Use explicit curly braces for all flow control statements.
    - Use `debugPrint` for logging instead of `print`.
    - Document major logic changes in `agent.md`.

---
*Maintained by Jules, Lead AI Software Engineer.*
