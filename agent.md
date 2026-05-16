# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project, documenting its architecture, performance optimizations, security protocols, and development standards.

## 1. Architectural Overview
Serious Study follows a clean **MVC (Model-View-Controller)** pattern implemented via the **GetX** ecosystem.

### Key Components:
- **Controllers (`lib/controller/`)**: Manage reactive state and business logic.
    - `DocumentController`: Handles document lifecycles, optimistic interactions (likes/dislikes), and file opening logic.
    - `HomeController`: Manages the real-time feed, utilizing Supabase PostgreSQL Change channels for live updates.
    - `UploadController`: Coordinates multi-part uploads (Cover Image + Document) with size enforcement and compression.
    - `NotificationController`: Manages user-specific and global announcements with local tray notifications.
- **Services (`lib/service/`)**: Dedicated logic for specialized tasks.
    - `FileDownload`: Chunk-based downloading with Android notification progress bars.
    - `FileCaching`: Temporary storage management to prevent redundant network calls.
- **Core (`lib/core/`)**: Centralized configuration and helpers.
    - `AppMetaData`: Global constants (Supabase credentials, app naming).
    - `HiveBoxes`: Static access to local persistent storage.

---

## 2. Performance Engineering

### High-Performance Data Handling
- **Local Persistence (Hive)**: The app uses **Hive** for ultra-fast NoSQL local storage.
    - `userBox`: Caches user profile metadata to ensure the "My Profile" tab and personalized headers load instantly without waiting for backend sync.
    - `downloadsBox`: Tracks local file paths for offline access and status checking.
- **Optimistic UI Updates**: Interactions like `toggleLike` and `toggleBookmark` update the UI immediately before confirming with the Supabase backend, providing a lag-free experience.

### Media & Network Optimization
- **Asset Compression**: `flutter_image_compress` is integrated into the upload pipeline. Cover images are compressed to 70% quality to reduce storage costs and improve feed loading speeds.
- **Network Caching**: `cached_network_image` is used globally to minimize data consumption and eliminate flickering during list scrolling.
- **Sticky Sort Algorithm**: The `HomeController` implements a "Sticky Sort" that prioritizes `is_official` documents at the top of the feed, followed by reverse chronological order.

### Storage Scalability
- **10MB Direct Upload Limit**: To manage cloud costs and ensure fast downloads, direct file uploads are capped at 10MB.
- **External Hosting Support**: The platform supports external links (Google Drive, Mega), allowing the community to share large resources without straining the app's storage buckets.

---

## 3. Security Framework

### Identity & Access Management
- **JWT Authentication**: Secured by **Supabase Auth**. Tokens are managed by the SDK and refreshed automatically.
- **Row Level Security (RLS)**: Strictly enforced at the database level.
    - **Profiles**: Only owners can modify their data.
    - **Documents**: Write/Delete access is restricted to the original uploader.
    - **Notifications**: Private to the intended recipient.

### Database Integrity
- **Atomic Operations (RPCs)**: Critical counters (likes, dislikes, views) are never updated directly by the client. Instead, the app calls PostgreSQL Functions (`SECURITY DEFINER`) to ensure atomic increments and prevent "like-botting" via direct API calls.
- **Admin Controls**: Administrative features (e.g., `is_official` toggles and global announcements) are protected by server-side checks against the `is_admin` flag in the `profiles` table.

---

## 4. Design & UI Standards
- **Material 3**: Fully utilizes the modern Material Design system.
- **Glassmorphism**: Applied to the `BottomFooter` and high-level UI cards using semi-transparent overlays and blur effects for a premium aesthetic.
- **Premium Branding**: Standardized on **Premium Deep Blue (#0D47A1)**.
- **Visual Feedback**:
    - **Shimmer**: Used in `HomeDocumentSection` to provide smooth visual continuity during fetches.
    - **Toastification**: Premium top-right aligned alerts for success/error feedback.

---

## 5. Development & QA Protocol

### Known Maintenance Issues
- **`auth_controller.dart` Integrity**: This file is prone to recurring syntax corruption (e.g., the `qaWSQA` prefix). Always verify its integrity during merge reviews.

### Verification Standards
The project adheres to a **Zero Warnings** policy. Before every commit, developers must run the following checks from the `notehub/` directory:
```bash
flutter analyze
flutter test
```

### Environment Requirements
- **Flutter SDK**: 3.41.2 (Channel Stable)
- **Dart SDK**: 3.11.0
- **Java**: 17
- **Target API**: 36

---
*Maintained by Jules, AI Software Engineer.*
