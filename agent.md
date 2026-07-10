# Agent Guide - Serious Study (Mumbai University Community App)

This document serves as the primary technical manual and maintenance guide for the Serious Study repository. It provides a developer-centric analysis of the application's architecture, performance, design, and security.

## 1. Project Overview
Serious Study is a modernized academic networking platform for students. It facilitates notes sharing, peer-to-peer interactions, and official university updates via a serverless architecture.

- **Frontend**: Flutter (Mobile/Web)
- **Backend**: Supabase (Postgres, Auth, Storage)
- **State Management**: GetX
- **Local Database**: Hive

## 2. Technical Analysis

### 2.1 Performance & Optimization
- **Reactive State Management**: Uses `GetX` for granular UI updates. Controllers manage state independently, reducing unnecessary widget rebuilds.
- **Optimistic UI Updates**: Interactions like Likes, Dislikes, and Bookmarks are applied immediately to the local state in `DocumentController` before syncing with the backend.
- **High-Performance Caching**:
    - `Hive` stores the active user's profile and basic metadata, allowing for near-instantaneous startup.
    - `CachedNetworkImage` prevents redundant downloads of document thumbnails.
- **Data Fetching Strategy**:
    - **Batching**: `HomeController` limits feed fetches to 50 documents per request.
    - **Sticky Sort**: Official documents are prioritized at the top of the feed using a custom sorting algorithm that prioritizes the `is_official` flag over chronological order.
- **Media Optimization**:
    - Enforced 10MB limit for direct document uploads in `UploadController`.
    - Mandatory cover image compression via `ImageHelper` (utilizing `flutter_image_compress`).
    - Support for external links (Google Drive, Mega) to offload heavy file storage.

### 2.2 Design & UX
- **Design System**: Material 3 with a customized **Premium Deep Blue** (#0D47A1) theme.
- **Aesthetics**:
    - **Glassmorphism**: Extensively used in components like the `BottomFooter` and profile cards for a modern, layered look.
    - **Typography**: "Plus Jakarta Sans" is the primary typeface, configured in `lib/core/config/typography.dart`.
- **Visual Feedback**:
    - `shimmer` effect during data loading.
    - `liquid_pull_to_refresh` for intuitive feed updates.
    - `lottie` animations for empty states and success confirmations.

### 2.3 Security & Data Integrity
- **Authentication**: Managed via Supabase Auth (JWT). Session tokens are securely handled by the SDK.
- **Database Authorization (RLS)**:
    - **Profiles**: Restricted `UPDATE` access where `auth.uid() = id`.
    - **Documents**: Only the owner can `INSERT` or `DELETE`.
    - **Privilege Escalation Protection**: A database trigger `ensure_official_permission` prevents non-admin users from setting the `is_official` flag on documents.
- **Atomic Operations**: All interaction counters (likes, dislikes, bookmarks) are updated via PostgreSQL Functions (`RPCs`) using `SECURITY DEFINER` and explicit `search_path` settings to mitigate search-path hijacking.
- **Storage Security**: Supabase Storage buckets use RLS policies to ensure that only authorized users can upload to specific paths (e.g., `$userId/docs/`).

## 3. Repository Structure
- `notehub/lib/controller/`: Business logic and state management.
- `notehub/lib/view/`: UI components and screen layouts.
- `notehub/lib/model/`: Data structures and Hive adapters.
- `notehub/lib/service/`: Low-level services (caching, downloads, notifications).
- `notehub/lib/core/`: App-wide configurations, constants, and helper utilities.
- `SUPABASE_SCHEMA.sql`: Comprehensive database definition including tables, RLS policies, and RPC functions.

## 4. Development Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` with no issues.
- **Modern APIs**:
    - Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
    - Use `activeThumbColor` for `Switch` widgets instead of the deprecated `activeColor`.
- **Flow Control**: Always use explicit curly braces for `if`, `for`, and `while` loops, even for single statements.
- **Error Handling**: Use `// ignore: empty_catches` for intentional silent catches, but ensure the catch block is properly formatted on multiple lines to avoid syntax corruption.

## 5. Maintenance & QA
- **Static Analysis**: `cd notehub && flutter analyze`
- **Unit Testing**: `cd notehub && flutter test`
- **Frontend Verification**: Start the local web server (`flutter run -d web-server --web-port 8080`) and use Playwright for visual regression testing.
- **Prerequisites**: Dart SDK ^3.5.4 and Flutter 3.24+.

---
*Analyzed and Documented by Jules (Divine Visionary Agent)*
