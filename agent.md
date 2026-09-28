# Developer Technical Guide & Maintenance Manual - Serious Study (formerly NoteHub)

This manual provides a detailed technical analysis of the **Serious Study** Android application from a developer's perspective. It covers system architecture, performance engineering, design paradigms, security auditing, and maintenance procedures.

---

## 1. Executive Summary & Architecture Overview

**Serious Study** is a cross-platform mobile application tailored for student collaboration, academic content sharing, and resource management within the Mumbai University community. The platform underwent a architectural modernization, transitioning from a legacy Django/MongoDB stack to a high-performance serverless Flutter + Supabase architecture.

### Core Tech Stack
- **Framework**: Flutter 3.24+ / Dart SDK ^3.5.4 (Targeting Android SDK 36, Java 17).
- **State Management**: GetX (^4.6.6) implementing an MVC pattern.
- **Backend & Database**: Supabase (PostgreSQL with Row Level Security, Auth, Storage, Realtime).
- **Local Persistence**: Hive (^2.2.3) NoSQL embedded database for local user sessions and download tracking.
- **Network & File Transfer**: Dio (^5.7.0) with path_provider for managed file caching and downloads.

---

## 2. Performance Engineering & Scalability

### State Management & Perceived Performance
- **GetX Controller Separation**: Business logic is completely decoupled from UI widgets. Controllers (`DocumentController`, `AuthController`, `HomeController`, `NotificationController`) handle asynchronous network calls and expose reactive states (`.obs`).
- **Optimistic UI Updates**: Operations such as liking, disliking, and bookmarking documents trigger immediate local state modifications in `DocumentController` prior to server confirmation. If a network RPC call fails, the UI reverts optimistically to its previous state with error feedback via `Toastification`.
- **Shimmer Loading States**: Asynchronous data loading views (e.g., document feeds) use `shimmer` loaders to maintain active visual feedback and reduce visual layout shift.

### Local Caching & Data Persistence
- **Hive Session Caching**: User session data is serialized via Hive adapters (`UserModelAdapter`) and saved to `userBox` upon login (`HiveBoxes.setUser()`). App boot times are optimized by instantly loading cached user credentials on startup.
- **Smart File Caching**: The `saveAndOpenFile()` utility in `lib/service/file_caching.dart` checks local device storage (`getTemporaryDirectory()`) before initiating Dio network downloads, preventing duplicate bandwidth usage and allowing offline document access.
- **Image Compression**: Uploaded images pass through `flutter_image_compress` in the upload pipeline before reaching Supabase Storage, minimizing storage footprint and network overhead.

### Database Query Optimization & RPC Functions
- **Atomic Operations**: Counter operations (likes, dislikes, bookmarks) use PostgreSQL RPC functions (`increment_likes`, `decrement_likes`, etc.) to execute atomic updates at the database layer. This eliminates race conditions during concurrent user interactions.
- **Postgres Realtime**: Supabase realtime channels (`supabase_realtime`) are enabled selectively on tables (`documents`, `notifications`, `interactions`, `comments`) to push updates instantly without client polling.

---

## 3. UI/UX Design & Aesthetic Paradigm

### Design Principles
- **Material 3 Paradigm**: Built on Flutter's Material 3 design system, re-branded with a **Premium Deep Blue** palette (`#0D47A1` primary seed color).
- **Glassmorphism**: UI surfaces (navigation elements, floating action cards, dialogs) utilize glassmorphic overlays with semi-transparent backdrops (`Colors.white.withValues(alpha: 0.15)` or `AppGradients.premiumGradient`) and subtle blurs.
- **Modern Color API Compliance**: Codebase strictly utilizes `.withValues(alpha: ...)` for color opacities, adhering to Dart 3.5.4+ standards and eliminating legacy `.withOpacity()` deprecation warnings.

### Typography & Asset Pipeline
- **Google Fonts & SVG Rendering**: Uses `google_fonts` for clean typography and `flutter_svg` for vector icons across bottom navigation, headers, and document action bars.
- **Interactive Micro-Animations**: Lottie animations (`assets/animations/notes.json`) provide friendly empty-state feedback during search and document queries.

---

## 4. Security Audit & Backend Protection

### Authentication & Token Management
- **Supabase Auth (JWT)**: User authentication relies on Supabase Auth. OAuth/Magic links and email/password registrations generate cryptographically signed JWTs managed automatically by the Supabase Flutter SDK.
- **Password Security**: Eliminates plain-text or custom password management; credentials are standardly hashed by Supabase using Argon2/Bcrypt.
- **Auth Redirects**: Configured deep-link callback URI (`io.supabase.flutternotehub://login-callback`) handles email confirmation flows securely.

### Database Security & Row Level Security (RLS)
Every table in `SUPABASE_SCHEMA.sql` enforces strict Row Level Security policies:
- **`profiles`**: Public read access (`SELECTUSING (true)`), write restricted strictly to table owners (`INSERT/UPDATE WITH CHECK (auth.uid() = id)`).
- **`documents`**: Public read access, insert and deletion restricted to the document creator (`auth.uid() = user_id`).
- **`notifications` & `bookmarks`**: Strictly private; queries are restricted to `auth.uid() = receiver_id` or `auth.uid() = user_id`.
- **Privilege Escalation Defense**: PostgreSQL RPC stored procedures use `SECURITY DEFINER` with explicit `SET search_path = public` directives to prevent search-path hijacking. Admin actions require explicit profile role verification (`is_admin = true`).

### Android Build Configuration
- **Target SDK**: Configured for `compileSdk 36` and `targetSdk 36` in `android/app/build.gradle`.
- **Java 17 & Desugaring**: Uses Java 17 language level compatibility and `coreLibraryDesugaring` (`com.android.tools:desugar_jdk_libs:2.1.4`) to support `flutter_local_notifications` on older Android runtime environments.

---

## 5. Repository File Organization & Module Mapping

```
notehub/
├── android/                   # Native Android config (SDK 36, Gradle plugins, Desugaring)
├── assets/                    # Vector icons, image assets, Lottie JSON animations
├── lib/
│   ├── main.dart              # App bootstrap (Supabase, Hive, Local Notifications, GetX App)
│   ├── layout.dart            # Main navigation container & tab switcher
│   ├── controller/            # GetX Reactive Business Logic
│   │   ├── auth_controller.dart          # Auth workflows, session sync, profile creation
│   │   ├── document_controller.dart      # Feed loading, optimistic likes/dislikes/bookmarks
│   │   ├── home_controller.dart          # Main feed, realtime subscriptions, search filtering
│   │   ├── upload_controller.dart        # Document & Tweet creation, storage upload
│   │   ├── profile_controller.dart       # User profile management, stats synchronization
│   │   ├── notification_controller.dart # Notification fetching & marking read
│   │   └── connection_controller.dart   # Followers/following network relations
│   ├── core/                  # Configurations, Theme, Hive Helper
│   │   ├── config/            # Color palettes, typography definitions
│   │   ├── helper/            # HiveBoxes helper, custom SVG icon loaders, image compressor
│   │   └── meta/              # AppMetaData constants (Supabase URLs, Keys)
│   ├── model/                 # Data Models & Hive Adapters (UserModel, DocumentModel, etc.)
│   ├── service/               # External Services (File Caching, Local Notifications, Downloads)
│   └── view/                  # UI Screens & Component Widgets
│       ├── auth_screen/       # Login / Registration screens
│       ├── home_screen/       # Feed & document display widgets
│       ├── document_screen/   # Single document detail view & comment section
│       ├── profile_screen/    # User profile & document management
│       ├── upload_screen/     # Document & link submission forms
│       ├── official_screen/   # Admin official announcements
│       └── widgets/           # Reusable UI elements (Buttons, Cards, Toasts, Loaders)
├── test/                      # Unit & integration tests
├── pubspec.yaml               # Project dependencies & asset declarations
└── SUPABASE_SCHEMA.sql        # Database schema, RLS policies, RPC stored procedures
```

---

## 6. Developer Guidelines & QA Procedures

### Code Quality & Zero Warnings Policy
All code within the repository must strictly pass Flutter's static analysis tools with zero warnings or errors.
1. **Lint Execution**: Run `flutter analyze` inside the `notehub/` directory.
2. **Testing**: Run `flutter test` to ensure all unit and widget tests pass.
3. **Color Opacity Standard**: Never use deprecated `.withOpacity()`. Always use `.withValues(alpha: <value>)`.
4. **Switch Widget Standard**: Always use `activeThumbColor` instead of deprecated `activeColor` for `Switch` widgets.
5. **Control Flow**: Always wrap control flow bodies in explicit curly braces (`{ ... }`) as per Flutter lint standards.

---
*Maintained and verified by Jules, AI Software Engineer.*
