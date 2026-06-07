# Developer Guide & System Manual - Serious Study (formerly NoteHub)

This document serves as the definitive technical reference for the Serious Study platform. It provides a deep-dive analysis of the application's architecture, performance optimizations, design philosophy, and security implementation.

## 1. Architectural Overview
Serious Study follows a modular, reactive architecture using **Flutter** and **GetX**.

### Core Stack
- **Frontend**: Flutter 3.44.1+ (SDK 3.5.4)
- **State Management**: GetX (MVC pattern: Controllers decouple logic from Views)
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Local Cache**: Hive (High-performance NoSQL)
- **Networking**: Supabase SDK (Data/Auth) & Dio (File transfers)

### Directory Structure
- `lib/controller/`: Business logic and reactive state (e.g., `DocumentController`, `UploadController`).
- `lib/view/`: Modular UI components organized by feature (e.g., `home_screen`, `upload_screen`).
- `lib/core/`: Centralized configurations (meta, theme, helpers).
- `lib/service/`: Infrastructure services (notifications, caching, downloads).
- `lib/model/`: Data models with serialization logic.

## 2. Performance Analysis
The application is engineered for responsiveness and efficiency in high-latency environments.

### Data Handling
- **Sticky Sort Algorithm**: Implemented in `HomeController`. Fetches documents in batches (limit 50) and sorts them with `is_official` documents prioritized at the top, followed by chronological order.
- **Optimistic UI Updates**: Interactions like likes, dislikes, and bookmarks are reflected in the UI immediately before backend confirmation, ensuring zero perceived latency.
- **Atomic Operations (RPCs)**: Critical counters (likes/dislikes) are managed via PostgreSQL `SECURITY DEFINER` functions (`increment_likes`, etc.) to prevent race conditions and ensure consistency.

### Media & Storage Optimization
- **Image Compression**: `UploadController` utilizes `ImageHelper` (wrapping `flutter_image_compress`) to optimize cover images before upload.
- **Upload Constraints**: Direct document uploads are strictly capped at **10MB**. For larger files, the app encourages the use of `isExternalLink` (Google Drive/Mega) to preserve bandwidth.
- **Intelligent Caching**:
  - `cached_network_image` for UI assets.
  - `FileCaching` service using `Dio` to check the local filesystem before initiating re-downloads.
  - `Hive` stores the user profile and session metadata for instant startup.

## 3. Design & UX Philosophy
Serious Study employs a "Premium Academic" aesthetic tailored for university students.

### UI Paradigm
- **Material 3**: The foundation for all standard components.
- **Glassmorphism**: Applied to the custom `BottomFooter` and high-level cards to create a layered, modern feel.
- **Premium Deep Blue**: The brand identity is anchored in `#0D47A1` (PrimaryColor.shade500).
- **Typography**: Uses **Plus Jakarta Sans** for a professional and readable academic interface.

### User Feedback
- **Loaders & Shimmers**: Standardized `Shimmer` placeholders in `HomeDocumentSection` and `SearchPage`.
- **Toasts**: Uses the `toastification` package with a consistent `flatColored` style and `topRight` alignment.
- **Lottie Animations**: Integrated for empty states and successful action feedback.

## 4. Security & Data Integrity
The platform utilizes a multi-layered security model centered on the Supabase ecosystem.

### Authentication
- **JWT-based Auth**: Managed by Supabase. Tokens are handled securely by the SDK.
- **Secure Sessions**: Authentication state is synchronized with `Hive` for persistence but validated against Supabase on every protected action.

### Authorization (Row Level Security)
- **Profiles**: Publicly readable; `UPDATE` restricted to `auth.uid() = id`.
- **Documents**: Publicly readable; `INSERT`/`DELETE` restricted to `auth.uid() = user_id`.
- **Notifications & Bookmarks**: Strictly private; accessible only by the owner.
- **Admin Privileges**: `is_admin` (profiles) and `is_official` (documents) flags govern elevated permissions. RLS policies ensure only admins can toggle the `is_official` status on documents.

### API Security
- No direct database access is allowed from the frontend except through RLS-protected queries.
- Complex state mutations are performed via PostgreSQL RPCs, limiting the surface area for malicious data manipulation.

## 5. Maintenance & QA
To maintain the "Zero Warnings" status, the following guidelines must be followed:

### Coding Conventions
- **Modernized APIs**: Use `.withValues(alpha: x)` instead of `.withOpacity(x)`.
- **Switch Widgets**: Use `activeThumbColor` to resolve deprecation warnings from `activeColor`.
- **Flow Control**: All `if`/`else` and loop blocks must use explicit curly braces `{}`.
- **Error Handling**: Use `// ignore: empty_catches` for intentional silent catches.

### Verification Workflow
1. **Static Analysis**: `cd notehub && flutter analyze`.
2. **Testing**: `flutter test` for logic verification.
3. **Frontend Verification**: Use `flutter run -d web-server` and Playwright scripts for visual audits.

---
*Maintained by the Serious Study Engineering Team.*
