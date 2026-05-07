# System Manual & Developer Guide: Serious Study

## 1. Executive Summary
**Serious Study** (formerly NoteHub) is a high-performance, community-driven academic platform designed specifically for the Mumbai University student ecosystem. The application enables seamless sharing of study resources, peer-to-peer networking, and real-time academic updates. Architecturally, it has transitioned from a legacy monolithic stack to a modern, serverless **Supabase** infrastructure, ensuring high scalability and robust security.

---

## 2. Technical Architecture (The Stack)

### Frontend: Flutter (3.41.2+)
- **State Management**: **GetX** (MVC Pattern). Controllers (`DocumentController`, `HomeController`, etc.) decouple business logic from the view layer.
- **Local Persistence**: **Hive**. Used for millisecond-latency access to user profiles (`userBox`) and tracking local downloads (`downloadsBox`).
- **Reactive UI**: Extensive use of `Obx` and `GetBuilder` for real-time interface updates.
- **Networking**: **Supabase Flutter SDK** for database and auth; **Dio** for chunked file downloads and caching.

### Backend: Supabase (Serverless)
- **Database**: **PostgreSQL** with **Row Level Security (RLS)**.
- **Real-time**: PostgreSQL Change streams are utilized to provide live feed updates and instant notifications.
- **Authentication**: JWT-based secure sessions via Supabase Auth.
- **Storage**: S3-compatible bucket storage for documents and compressed thumbnails.

---

## 3. Performance Analysis & Optimizations

### Data Retrieval & Caching
- **Sticky Sort Strategy**: The `HomeController` implements a "Sticky Sort" algorithm that prioritizes official university documents (`is_official`) at the top of the feed before falling back to chronological order.
- **Batch Processing**: Data is fetched in batches of 50 to minimize payload size and improve initial load times.
- **Local Warm Cache**: User metadata (ID, Username, Profile URL) is cached in Hive, allowing the app to bypass network requests for personal profile views.
- **Shimmer UI**: `Shimmer` effect placeholders are used during asynchronous fetches to maintain a high "perceived performance" score.

### Asset Management
- **Image Compression**: `ImageHelper` uses `flutter_image_compress` (70% quality, 1024px min dimensions) to reduce upload sizes by up to 80% before they leave the device.
- **Bandwidth Control**: A strict 10MB limit is enforced for direct document uploads. For larger resources, the app supports **External Link Submission** (Google Drive/Mega), shifting hosting costs away from the platform.
- **Network Optimization**: `CachedNetworkImage` is used globally to prevent redundant downloads of repetitive assets like covers and avatars.

---

## 4. Design & UX Standards

### Visual Language
- **Theme**: **Premium Deep Blue** (#0D47A1) as the primary brand color, conveying academic trust.
- **Aesthetic**: **Glassmorphism**. Semi-transparent overlays and `BackdropFilter` are used for Bottom Navigation and Profile Cards to create depth.
- **Typography**: "Plus Jakarta Sans" via `google_fonts`.
- **Feedback**: `LiquidPullToRefresh` and `Toastification` (top-right alignment) provide consistent interactive feedback.

### Modular Components
- **Standardized Loaders**: `Loader` and `Loader2` wrap `CircularProgressIndicator` to ensure consistent UI during wait states.
- **Empty States**: Lottie animations and SVGs are used to handle empty search results or notifications gracefully.

---

## 5. Security & Data Integrity

### Authorization Model (RLS)
Security is enforced at the database level, not just the client:
- **Profile Protection**: Only the owner (matching `auth.uid()`) can update their profile.
- **Document Ownership**: Only the creator of a document has `DELETE` and `UPDATE` permissions.
- **Granular Privacy**: Notifications and Bookmarks are private to the user; no other user can query them.

### Atomic Operations (RPCs)
To prevent race conditions and ensure integrity, the app uses **PostgreSQL Functions (SECURITY DEFINER)** for interactions:
- `increment_likes`, `decrement_likes`, `increment_dislikes`, `decrement_dislikes`.
- These functions allow users to update protected counters without having direct write access to the `documents` table columns.

---

## 6. Developer Guidelines

### Zero Warnings Policy
The project maintains a strict "Zero Warnings" standard. Every change must be verified:
```bash
cd notehub
flutter analyze
flutter test
```

### Modernization Standards
- **Color Modernization**: Do not use `.withOpacity(x)`. Use `.withValues(alpha: x)` to comply with Flutter 3.41.2+ standards.
- **Switch Widgets**: Use `activeThumbColor` instead of the deprecated `activeColor`.
- **Flow Control**: All `if/else/for` loops **must** use explicit curly braces to pass linting.
- **Error Handling**: Silent catches must be annotated with `// ignore: empty_catches`.

### Storage Pathing
- Covers: `storage/v1/object/public/documents/{user_id}/covers/{timestamp}_{name}.jpg`
- Documents: `storage/v1/object/public/documents/{user_id}/docs/{timestamp}_{name}{ext}`

---
*Maintained by Jules, AI Software Engineer.*
