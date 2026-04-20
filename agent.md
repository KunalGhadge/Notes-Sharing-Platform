# Developer Guide - Serious Study (NoteHub)

This document serves as the comprehensive "Developer Guide" and "System Manual" for the Serious Study application. It is intended for developers and AI agents to understand the system architecture, design patterns, and security protocols.

## 1. Core Architecture
The application follows a **Decoupled MVC (Model-View-Controller)** architecture using the **GetX** ecosystem.

- **State Management**: `GetX` is used for reactive state updates and dependency injection.
- **Backend**: **Supabase** (PostgreSQL) provides serverless infrastructure including Auth, Database, Storage, and Real-time subscriptions.
- **Persistence**: **Hive** (NoSQL) handles high-speed local caching for user sessions and profile metadata.
- **Networking**: `Supabase SDK` for database/auth and `Dio` for specialized file downloads.

### Directory Structure
- `lib/controller/`: Reactive business logic (GetX controllers).
- `lib/core/`: Configuration, themes, and helpers.
- `lib/model/`: Data models and adapters (Hive generated).
- `lib/service/`: Utility services (Downloads, Notifications, Caching).
- `lib/view/`: UI screens and modular widgets.

## 2. Technical Performance
- **Reactive Feed**: `HomeController` utilizes `Supabase Realtime` (`public:documents` channel) to refresh the feed instantly upon new uploads.
- **Sticky Sort**: The feed priorities official university documents (`is_official: true`) while maintaining chronological order for peer-to-peer notes.
- **Optimistic UI**: Interactions (likes/bookmarks) provide immediate visual feedback before synchronizing with the backend.
- **Media Optimization**:
    - `ImageHelper`: Compresses cover images using `flutter_image_compress` (Quality 70, 1024px constraints).
    - `UploadController`: Enforces a **10MB limit** for direct document uploads; suggests external links (Google Drive/Mega) for larger files.
    - `CachedNetworkImage`: Standardized for all remote assets to reduce redundant bandwidth usage.

## 3. UI/UX & Design Standards
- **Design System**: Material 3 with **Glassmorphism** overlays.
- **Color Palette**:
    - Primary: `Premium Deep Blue (#0D47A1)`.
    - Accent: `Premium Gold (#FFD700)` (used for official labels and admin controls).
- **Typography**: `Plus Jakarta Sans` via Google Fonts.
- **Standardized Components**:
    - **Loaders**: `Loader` and `Loader2` (customizable size/padding) for async states.
    - **Toasts**: `Toastification` with `flatColored` style, aligned `topRight`.
    - **Shimmers**: Used during data fetching to maintain layout stability.

## 4. Security Framework
The application implements a multi-layered security model:

- **Authentication**: JWT-based session management via Supabase Auth.
- **Authorization (RLS)**: PostgreSQL **Row Level Security** policies in `SUPABASE_SCHEMA.sql` ensure:
    - Users can only edit/delete their own documents.
    - Profiles are public for reading but protected for writing.
    - Notifications and Bookmarks are strictly private to the owner.
- **Atomic Operations (RPC)**: Critical counter updates (likes/dislikes) use `SECURITY DEFINER` functions to prevent client-side data manipulation and race conditions.
- **Storage Security**: Document and cover image buckets use granular policies restricted by `auth.uid()`.

## 5. Development Workflow
### Coding Conventions
- **Zero Warnings**: All contributions must pass `flutter analyze` without warnings.
- **Modern APIs**: Use `.withValues(alpha: x)` instead of `.withOpacity(x)` for modern Flutter compatibility.
- **Flow Control**: All `if/else` and loop structures **must** use curly braces.
- **Error Handling**: Silent catches must be annotated with `// ignore: empty_catches`.

### Local Testing & QA
1. **Analyze**: `cd notehub && flutter analyze`.
2. **Test**: `cd notehub && flutter test`.
3. **Build**: Ensure `multiDexEnabled` is active in `build.gradle` for notification support.

---
*Documented by Jules, AI Software Engineer.*
