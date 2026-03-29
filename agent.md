# Developer Guide - Serious Study (formerly NoteHub)

This document provides a comprehensive technical analysis of the Serious Study project from a developer's perspective. It serves as the primary reference for understanding the application's architecture, performance optimizations, design patterns, and security measures.

---

## 1. Project Overview
**Serious Study** is a premium academic networking and notes-sharing platform tailored for the Mumbai University student community. It facilitates seamless collaboration, real-time updates, and high-performance resource management using a Flutter frontend and a serverless Supabase backend.

---

## 2. Core Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.24+ (SDK ^3.5.4).
- **State Management**: **GetX**.
  - Controllers (e.g., `DocumentController`, `AuthController`) manage reactive states and business logic.
  - Dependency Injection via `Get.put()` in `main.dart` and view-level initializations.
- **Routing**: GetX routing for smooth, declarative transitions.
- **Local Persistence**: **Hive**.
  - `userBox`: Stores `UserModel` (id, username, profileUrl) for instant session restoration.
  - `downloadsBox`: Tracks local file downloads.

### Backend (Supabase)
- **Database**: **PostgreSQL** with relational schema and Row Level Security (RLS).
- **Authentication**: **Supabase Auth** (JWT-based). Supports deep-linked login callbacks.
- **Storage**: **Supabase Storage** for document assets and cover thumbnails.
- **Real-time**: PostgreSQL Change channels for live feed updates (`HomeController`) and notifications (`NotificationController`).

---

## 3. Performance Optimizations

### 3.1 Data Management
- **Atomic Operations (RPCs)**: Critical counters (likes, dislikes) are updated via database functions (e.g., `increment_likes`) to ensure data integrity and prevent race conditions.
- **Batch Fetching**: The `HomeController` limits primary feed results to 50 items to minimize initial payload and latency.
- **Optimistic UI**: Interactions like liking, disliking, and bookmarking provide immediate UI feedback before backend synchronization, with automatic rollbacks on failure.
- **Sticky Sort**: The `HomeController` implements a custom sorting algorithm prioritizing official documents (`is_official`) followed by chronological order.

### 3.2 Media & Assets
- **Image Compression**: `ImageHelper` (using `flutter_image_compress`) compresses cover images (Quality 70, 1024x1024 min) before upload to reduce storage costs and bandwidth.
- **Network Caching**: `CachedNetworkImage` is used extensively to prevent redundant downloads of thumbnails and profile pictures.
- **File Caching**: `FileCaching` (using `Dio`) manages temporary storage of downloaded documents to avoid re-downloading existing files.

---

## 4. Design & UX

### 4.1 Aesthetic Paradigm
- **Material 3**: The app utilizes modern Material 3 components and principles.
- **Glassmorphism**: Implemented via the `glassmorphism` package and custom `AppGradients.glassGradient` for a premium, layered aesthetic.
- **Typography**: Powered by `google_fonts` (Plus Jakarta Sans) for academic clarity.
- **Branding**: Centralized "Premium Deep Blue" theme (`#0D47A1`).

### 4.2 User Feedback
- **Standardized Loading**: `Loader` and `Loader2` components provide consistent visual feedback during async operations.
- **Shimmer Effects**: Used in document sections to prevent 'blank screen' issues during data fetching.
- **Lottie Animations**: Integrated for state transitions (e.g., empty states, success confirmations).
- **Toasts**: Standardized top-right notifications using `toastification` with flat colored styling.

---

## 5. Security Implementation

### 5.1 Authorization & Access Control
- **Row Level Security (RLS)**: Strictly enforced on all PostgreSQL tables.
  - `profiles`: Publicly viewable, but only owners can update.
  - `documents`: Publicly viewable, but only owners can insert or delete.
  - `notifications`: Restricted to the `receiver_id` or marked as `is_global`.
- **JWT Authentication**: Secure session management handled entirely by the Supabase SDK.
- **Security Definer RPCs**: Database functions run with owner privileges, allowing users to increment counters without having direct write access to sensitive columns.

### 5.2 File Security
- **Storage Policies**: Access to the 'documents' bucket is governed by RLS-like policies, ensuring users only manipulate their own uploads.
- **Size Limits**: `UploadController` enforces a 10MB limit for direct document uploads to ensure platform stability and cost-efficiency.

---

## 6. Coding Conventions & Quality

### 6.1 Standards
- **Zero Warnings Policy**: All code must pass `flutter analyze` with no errors, warnings, or info-level lints.
- **Modern APIs**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`.
- **Flow Control**: Braces are mandatory for all if/else/for/while blocks.
- **Error Handling**: Empty catch blocks must be annotated with `// ignore: empty_catches`.

### 6.2 Key Utilities
- **`AppMetaData`**: Centralized configuration for Supabase URLs, keys, and app naming.
- **`Toasts`**: Centralized toast management for consistent messaging.
- **`HiveBoxes`**: Static access layer for local persistent storage.

---

## 7. Development & QA
- **CI/CD**: Automated checks run `flutter analyze` and `flutter test`.
- **Testing**: A baseline test suite exists in `test/`. All new features should include corresponding tests.
- **Android Target**: API 36 (compileSdk) with MultiDex and Core Library Desugaring enabled.

---
*Analyzed and Documented by Jules, Divine Visionary Software Engineer.*
