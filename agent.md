# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It documents the current state of the application after its migration from a legacy Django/MongoDB stack to a serverless **Supabase** architecture.

## 1. Performance Analysis
Serious Study is engineered for high performance on Mumbai University's varying network conditions.

- **Reactive State Management**: Utilizing `GetX` for efficient state updates and dependency injection. Controllers (e.g., `DocumentController`, `HomeController`) manage business logic independently from the UI, ensuring smooth interactions.
- **Local Persistent Storage**: `Hive` (NoSQL) is used for high-performance local caching. User profile metadata and downloaded document metadata are stored locally to ensure immediate UI responsiveness upon app launch.
- **Batching & Lazy Loading**: The `HomeController` implements a 50-document fetch limit per request to balance initial load times with content availability.
- **Media Optimization**:
    - **Caching**: `cached_network_image` is used throughout the app (e.g., in `HomeHeader`) to minimize network usage.
    - **Compression**: `flutter_image_compress` is integrated into the upload pipeline to optimize asset sizes (targeting 70% quality) before they reach Supabase Storage.
    - **Upload Constraints**: Direct document uploads are capped at 10MB to maintain infrastructure sustainability.
- **Database Scalability**:
    - **Atomic Operations**: Critical interactions like `increment_likes` and `decrement_dislikes` are handled via PostgreSQL Functions (`RPCs`) with `SECURITY DEFINER` privileges. This ensures data consistency and prevents race conditions.
- **Optimistic UI Updates**: Interactions like likes, dislikes, and bookmarks are reflected immediately in the UI before being synchronized with the Supabase backend, providing a lag-free user experience.

## 2. Design & Architecture
The application implements **Material 3** with a **Glassmorphism** aesthetic, focused on academic professionalism.

- **UI Paradigm**:
    - **Rebranded Theme**: Utilizes a "Premium Deep Blue" (`#0D47A1`) primary color.
    - **Glassmorphism**: Semi-transparent overlays (`.withValues(alpha: ...)`) and custom gradients (`AppGradients.premiumGradient`) create a modern, layered look.
    - **Visual Feedback**: Shimmer placeholders and `Lottie` animations are used for state feedback (e.g., loading, empty search results, success).
- **Project Structure (MVC-inspired)**:
    - `lib/controller/`: Business logic and reactive state.
    - `lib/view/`: Modular UI components and screen layouts.
    - `lib/core/`: Centralized configurations (`AppMetaData`), themes, and helper utilities.
    - `lib/service/`: Low-level services for file caching and local notifications.
- **Sticky Sort Algorithm**: The `HomeController` implements a custom sort that prioritizes "Official" documents at the top of the feed regardless of their upload date, ensuring verified content is always visible.

## 3. Security Analysis & Vulnerability Audit
The migration to Supabase has systematically addressed legacy vulnerabilities, but some architectural risks remain.

- **Authentication**: Migrated from a custom session-less system to **Supabase Auth (JWT)**. Sessions are securely managed by the Supabase SDK with proper token refresh cycles.
- **Password Security**: Managed by Supabase using industry-standard hashing (Argon2/Bcrypt).
- **Authorization (RLS)**: **Row Level Security** is enforced on all tables.
    - **Documents**: Policies ensure that users can only modify their own content.
    - **Notifications/Bookmarks**: Strictly private to the owning user.
- **Identified Security Risks (High Priority)**:
    - **Privilege Escalation**: Current RLS policies on the `profiles` table (`auth.uid() = id`) allow any authenticated user to update *any* field in their own row. Since the `is_admin` column is part of the `profiles` table, a malicious user could potentially grant themselves administrative privileges via a direct API call (e.g., using `supabase.from('profiles').update({'is_admin': true})`).
    - **Official Content Manipulation**: While the UI hides the "Official" toggle from non-admins, the backend RLS policy for the `documents` table allows users to `UPDATE` their own documents without column-level restrictions. This means a user could potentially set their own document as `is_official: true` via the API.
- **API Integrity**: By using `RPCs` for counter updates, the underlying table data is protected from direct unauthorized manipulation for these specific fields.

## 4. Development & Maintenance
- **Prerequisites**: Flutter SDK ^3.41.2 (mandatory for `.withValues()` and Switch `activeThumbColor` support).
- **Zero Warnings Policy**: All code must pass `flutter analyze` with zero warnings. Modernized APIs must be used (e.g., avoid `.withOpacity` and `activeColor`).
- **Silent Error Handling**: Use `// ignore: empty_catches` for intentional silent catches in controllers to maintain linting compliance.
- **QA Workflow**:
    - Run `flutter analyze` for static validation.
    - Run `flutter test` for logic verification.

---
*Analyzed and Documented by Jules, AI Software Engineer (May 2026).*
