# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study repository from a software engineer's perspective. It serves as the primary manual for onboarding, maintenance, and quality assurance.

## 1. Project Overview & Architecture
Serious Study is a premium academic networking and resource-sharing platform for Mumbai University.

- **Frontend**: Flutter (3.24+ / SDK 3.5.4) using GetX MVC pattern.
- **Backend**: Supabase (PostgreSQL + Auth + Storage).
- **Communication**: Supabase SDK for real-time data and Dio for specialized file caching.
- **Design System**: Material 3 with a custom Glassmorphism aesthetic and a "Premium Deep Blue" (#0D47A1) branding.

---

## 2. Technical Deep Dive

### 2.1 State Management (GetX)
The application utilizes `GetX` for reactive state management, dependency injection, and routing.
- **Controllers**: Business logic is decoupled from UI. Key controllers include:
  - `DocumentController`: Handles the lifecycle of academic resources (fetching, interacting, downloading).
  - `HomeController`: Manages the global feed with real-time sync via `PostgresChanges`.
  - `UploadController`: Manages complex multi-part uploads with size enforcement (10MB limit).

### 2.2 Performance Strategies
- **Optimistic UI**: Interactions like liking, disliking, and bookmarking (in `DocumentController`) update the local state immediately before synchronizing with the backend, providing zero-latency feedback.
- **Local Persistence (Hive)**: User profile data and download metadata are cached in `Hive` boxes (`lib/core/helper/hive_boxes.dart`) for instant app startup.
- **Media Optimization**:
  - `cached_network_image`: Used globally to reduce redundant network requests.
  - `flutter_image_compress`: Mandatory compression for cover images before upload.
- **Data Batching**: The `HomeController` fetches updates in batches of 50 to balance responsiveness and data usage.

### 2.3 Design & UX
- **Typography**: Uses "Plus Jakarta Sans" for all headings and UI elements.
- **Sticky Sort**: The home feed prioritizes "Official" content at the top of the feed using a custom sorting algorithm in `HomeController.fetchUpdates()`.
- **Glassmorphism**: Achieved using the `glassmorphism` package, applied to components like `BottomFooter` and `PostCard` overlays for a premium feel.

---

## 3. Security Model

### 3.1 Authentication
- **JWT (JSON Web Tokens)**: Managed by Supabase Auth.
- **Session Management**: Handled via `Supabase.instance.client.auth`, with automatic token refresh.

### 3.2 Authorization (Row Level Security)
All database tables are protected by RLS policies defined in `SUPABASE_SCHEMA.sql`:
- **Profiles**: `UPDATE` restricted to `auth.uid() = id`.
- **Documents**: `INSERT/DELETE` restricted to the owner.
- **Admin Privileges**: Certain actions (like marking content as "Official") are restricted to users with `is_admin = true` via database triggers (`ensure_official_permission`).

### 3.3 Data Integrity (RPCs)
- **Atomic Counters**: Counter updates (likes, dislikes) are handled via PostgreSQL functions (`RPCs`) with `SECURITY DEFINER`. This prevents clients from directly manipulating count values and ensures atomic increments/decrements.

---

## 4. Backend Schema (PostgreSQL)
The relational schema is optimized for social interactions:
- **`profiles`**: Extended user data with MU-specific attributes.
- **`documents`**: Central table for all shared content (Notes & Short Updates).
- **`interactions`**: Unique (user_id, document_id) pairs to enforce single-interaction logic.
- **`notifications`**: Real-time activity feed with support for global announcements.

---

## 5. Maintenance & QA

### 5.1 Project Prerequisites
- **Dart SDK**: ^3.5.4
- **Flutter**: Stable channel (3.24+)

### 5.2 Zero Warning Policy
The project maintains a strict "Zero Warnings" status.
- **Linting**: Run `flutter analyze` from the `notehub/` directory before any commit.
- **Modern APIs**: Use `.withValues(alpha: ...)` instead of the deprecated `.withOpacity()`. Use `activeThumbColor` for `Switch` widgets.
- **Flow Control**: All flow control structures (if, else, for) must use explicit curly braces.

### 5.3 Verification Scripts
Developers can use Playwright-based verification scripts (like `verify_app.py`) to visually inspect UI changes against a `flutter run -d web-server` instance.

---
*Maintained by Jules, Divine Visionary AI.*
