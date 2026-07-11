# Developer Guide - Serious Study (Mumbai University Community App)

This document serves as the master technical manual and maintenance guide for the Serious Study Android application. It provides a developer-centric analysis of the system architecture, performance optimizations, design standards, and security protocols.

## 1. Project Architecture & Tech Stack

Serious Study is a modernized community platform for Mumbai University students, built using a serverless architecture.

- **Frontend**: Flutter 3.24+ (Dart SDK ^3.5.4).
- **State Management**: **GetX** (MVC Pattern). Controllers handle business logic and expose reactive state to the UI.
- **Local Persistence**: **Hive** NoSQL database for rapid session recovery and local caching of user metadata.
- **Backend**: **Supabase** (PostgreSQL, Auth, Storage, Realtime).
- **Networking**: Supabase Flutter SDK for DB/Auth; **Dio** for specialized file caching and downloads.

## 2. Performance Analysis

### 2.1 State & Data Management
- **Optimistic UI**: Interactions such as likes, dislikes, and bookmarks (implemented in `DocumentController`) update the local UI state immediately before synchronizing with the backend, ensuring a lag-free experience.
- **Reactive Synchronization**: `HomeController` utilizes `_syncWithHome()` to ensure that updates made in document detail views are immediately reflected in the main feed.
- **Batch Loading**: The feed implements a fetching limit of 50 documents per request to balance initial load time with content depth.
- **Sticky Sort**: The `HomeController` implements a custom sorting algorithm that prioritizes "Official" documents at the top of the feed, followed by chronological ordering.

### 2.2 Atomic Backend Operations
- **RPC Counter Management**: To prevent race conditions and ensure data integrity, all document interaction counters (likes, dislikes, bookmarks) are managed via PostgreSQL Functions (`RPCs`).
    - *Example*: `supabase.rpc('increment_likes', params: {'doc_id': id})`.
- **Media Optimization**:
    - **Image Compression**: `flutter_image_compress` is used in the `UploadController` to optimize cover images before upload.
    - **Asset Caching**: `CachedNetworkImage` is used globally to minimize redundant network requests for thumbnails and profile pictures.

## 3. Design & UI/UX Standards

### 3.1 Visual Identity
- **Theme**: Premium Deep Blue (`#0D47A1`), symbolizing Mumbai University's academic integrity.
- **Aesthetic**: **Glassmorphism** + **Material 3**. Implementation uses semi-transparent overlays with `.withValues(alpha: ...)` to create depth and modern layering.
- **Typography**: **Plus Jakarta Sans** is the primary typeface for all headings and body text, managed via `AppTypography`.

### 3.2 Interaction Design
- **Shimmer Feedback**: Used in `HomeDocumentSection` to provide visual continuity during asynchronous data fetching.
- **Real-time Updates**: Real-time listeners on the `documents` table ensure the community feed updates automatically without manual refreshes.

## 4. Security Audit & Protocols

### 4.1 Authentication & Authorization
- **Identity**: Managed via Supabase Auth (JWT). Sessions are persistent and securely handled by the SDK.
- **Row Level Security (RLS)**: Strictly enforced at the database layer.
    - **Profiles**: `UPDATE` is restricted to the owner (`auth.uid() = id`).
    - **Documents**: `INSERT`/`DELETE` restricted to the creator; `UPDATE` of official status restricted to Admins.
    - **Private Data**: Notifications and Bookmarks are strictly private to the authenticated receiver/owner.

### 4.2 Data Integrity
- **Privilege Escalation Prevention**: The `is_admin` flag in the `profiles` table is protected by RLS; users cannot elevate their own permissions.
- **Security Definer**: RPCs use `SECURITY DEFINER` to allow controlled table updates (like incrementing counters) while keeping the underlying tables protected from direct manipulation.

## 5. Maintenance & QA

### 5.1 Environment Prerequisites
- **Flutter SDK**: 3.24.x or higher.
- **Dart SDK**: ^3.5.4 (Required for modern color APIs like `.withValues()`).
- **Android**: Target SDK 36, Java 17 compatibility.

### 5.2 Code Quality Standards
- **Zero Warnings Policy**: The project must pass `flutter analyze` with no issues.
- **Modern API Compliance**:
    - Use `.withValues(alpha: x)` instead of the deprecated `.withOpacity(x)`.
    - Use `activeThumbColor` for Switch widgets.
- **Flow Control**: All flow control structures (if, else, for, while) must use explicit curly braces `{}`.

---
*Maintained by the Divine Visionary Engineering Team.*
