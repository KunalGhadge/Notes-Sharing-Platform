# Developer Guide - Serious Study (formerly NoteHub)

Serious Study is a high-performance community platform for Mumbai University students to share notes, interact, and network. This guide provides an exhaustive technical breakdown for developers.

## 1. Technical Stack
- **Frontend**: Flutter 3.41.2 / Dart 3.11.0 (Stable Feb 2026).
- **State Management**: **GetX** (MVC Pattern).
- **Backend**: **Supabase** (Serverless PostgreSQL, Auth, Storage).
- **Local Persistence**: **Hive** (High-performance NoSQL).
- **Real-time**: Supabase PostgreSQL Change Channels.

## 2. Architecture & Design Patterns
The project follows a modular **MVC** structure using GetX for reactive dependency injection and state updates.

### Core Directory Structure:
- `lib/controller/`: Logic for Auth, Documents, Profile, and Notifications.
- `lib/view/`: Modular UI screens and reusable widgets.
- `lib/core/`: Centralized themes, metadata, and helper utilities.
- `lib/service/`: Infrastructure services like File Download, Caching, and Notifications.

### UI Paradigm:
- **Material 3**: Modern component set and theming.
- **Glassmorphism**: Applied to key components like the `BottomFooter` and Profile cards for a premium feel.
- **Premium Deep Blue Theme**: Centralized in `AppMetaData` and `PrimaryColor`.

## 3. Performance Analysis
- **Reactive Updates**: Use of `Obx` and `update()` ensures granular UI rebuilds.
- **Data Caching**:
    - **Hive**: User profiles and metadata are cached in `userBox` for instant app launches.
    - **CachedNetworkImage**: Drastically reduces network bandwidth by caching document covers.
- **Media Optimization**:
    - **Image Compression**: `ImageHelper` uses `flutter_image_compress` (70% quality) for all document covers.
    - **10MB Upload Limit**: Enforced in `UploadController` to maintain backend cost-efficiency.
- **Sticky Sort Algorithm**: HomeController prioritizes `is_official` content followed by `created_at` to highlight verified resources.

## 4. Security & Data Integrity
The application leverages Supabase's built-in security features to protect user data.

- **Authentication**: JWT-based sessions managed via Supabase Auth.
- **Row Level Security (RLS)**:
    - Users can only `UPDATE` their own profiles.
    - `INSERT` and `DELETE` on documents are restricted to the asset owner.
    - Notifications are private to the receiver.
- **PostgreSQL RPCs**:
    - Atomic counters (likes, dislikes) are updated via `SECURITY DEFINER` functions (`increment_likes`, `decrement_likes`) to prevent direct table manipulation and race conditions.
- **Admin Controls**: Granular `is_admin` flags in profiles allow broadcasting global announcements and verifying documents.

## 5. Developer Guidelines & Zero Warnings Policy
The project enforces a strict **'Zero Warnings'** policy verified via `flutter analyze`.

### Coding Conventions:
- **API Modernization**: Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
- **Flow Control**: Always use explicit curly braces `{}` in if/for/while structures.
- **Error Handling**: Use `// ignore: empty_catches` for intentional empty catch blocks.
- **Consistency**: Use lowerCamelCase for variables (e.g., `avatarUrl`) and PascalCase for Classes.

### Verification Workflow:
Before submitting any changes, developers MUST run:
```bash
cd notehub && flutter analyze && flutter test
```

---
*Maintained by Jules, AI Software Engineer.*
