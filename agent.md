# Serious Study (NoteHub) Developer Guide & Technical Maintenance Manual

This manual provides a developer-centric technical breakdown of the **Serious Study** application (historically known as *NoteHub*). This guide covers performance optimization, UI/UX architecture, database mechanics, relational schema constraints, state flow, and security policies. It serves as the primary system manual for current and future engineers maintaining or scaling the application.

---

## 1. Executive Stack Overview & Project Evolution
Serious Study is a premium notes-sharing and academic networking mobile application designed specifically for the Mumbai University student community.

Originally structured around a custom legacy Django/MongoDB backend with basic/insecure session-less credentials and raw open media buckets, the platform has undergone a complete architectural modernization. It now utilizes:
- **Frontend Architecture**: Flutter SDK (v3.24+ / stable channel) with Dart SDK (^3.5.4).
- **Backend Architecture**: Serverless Supabase infrastructure providing real-time data synchronization, PostgreSQL core engine, Managed JWT Authentication, and Object Storage.
- **State Management**: Reactive and decoupled GetX pattern.
- **Local Persistence**: Hive high-performance NoSQL local caches.

---

## 2. Comprehensive Directory Structure & Architectural Blueprint

```
notehub/
├── android/                  # Android native runner config (MultiDex, compileSdk 36, Java 17)
├── assets/                   # High-quality Vector Graphics (SVG), Lottie JSON animations
├── ios/                      # iOS native configurations
├── lib/                      # Core application source code
│   ├── controller/           # Decoupled state management (GetX Controllers)
│   │   ├── auth_controller.dart             # Authentication flows, session mapping & userBox caching
│   │   ├── bottom_navigation_controller.dart # Main shell navigation state
│   │   ├── comment_controller.dart          # Threaded nested comments and reply trees
│   │   ├── connection_controller.dart       # Network connectivity listener
│   │   ├── document_controller.dart         # Document management (Liking, Bookmarking, Deletion)
│   │   ├── download_controller.dart         # Local offline file retrieval state
│   │   ├── file_controller.dart             # Document upload preparations and validations
│   │   ├── home_controller.dart             # Sticky-sorted feeds, official updates pagination
│   │   ├── notification_controller.dart     # User-specific & global notification triggers
│   │   ├── post_controller.dart             # Post creations (note / tweet type boundaries)
│   │   ├── profile_controller.dart          # Local profile views and interactive edits
│   │   ├── profile_user_controller.dart     # External user profile inspections
│   │   ├── remote_config_controller.dart    # Live dynamic JSON configurations without App Store reviews
│   │   ├── search_controller.dart           # Advanced filtered text indices
│   │   ├── showcase_controller.dart         # Contextual onboarding and walkthrough cues
│   │   └── upload_controller.dart           # Form fields, external URLs, file sizing limits (10MB)
│   ├── core/                 # Shared configurations, helpers, styles
│   │   ├── config/           # Theme palettes and typographies (Premium Deep Blue)
│   │   │   ├── color.dart                   # Hex palettes, Glassmorphism gradients
│   │   │   └── typography.dart              # Custom text weights & sizes
│   │   ├── helper/           # Utility integrations
│   │   │   ├── custom_icon.dart             # Custom icon geometries
│   │   │   ├── hive_boxes.dart              # Local userBox and downloadsBox interfaces
│   │   │   └── image_helper.dart            # Compresses JPEG to 1024x1024 resolution at 70% quality
│   │   └── meta/             # System config credentials
│   │       └── app_meta.dart                # Supabase URL, anon keys, static branding labels
│   ├── model/                # Fully typed JSON/Hive Models
│   │   ├── document_model.dart              # Model mapping documents, tweets, urls & counts
│   │   ├── mini_user_model.dart             # Compact sender/receiver metadata structures
│   │   ├── post_model.dart                  # Post metadata configurations
│   │   ├── user_model.dart                  # User session and institute data (Hive registered)
│   │   └── user_model.g.dart                # Automatically generated type adapters
│   ├── service/              # Low-level systems
│   │   ├── file_caching.dart                # Dio and path_provider download cache managers
│   │   ├── file_download.dart               # Chunk-based download mechanics
│   │   └── notification_service.dart        # Local push triggers
│   ├── view/                 # Glassmorphic Material 3 interfaces and views
│   │   ├── auth_screen/                     # Clean onboarding and login panels
│   │   ├── bottom_footer/                   # Persistent navigation bottom shells
│   │   ├── connection_screen/               # Off-line dynamic overlay banners
│   │   ├── document_screen/                 # Threaded commentary details & download triggers
│   │   ├── home_screen/                     # Sticky feeds, tab filters and announcements
│   │   ├── notification_screen/             # Real-time activity feeds
│   │   ├── official_screen/                 # Administrative verified academic updates
│   │   ├── onboarding_screen/               # Introductory tour
│   │   ├── profile_screen/                  # Profile configurations
│   │   ├── search_screen/                   # Fast filtered querying interfaces
│   │   ├── settings_screen/                 # About Serious Study details & legal licenses
│   │   ├── splash_screen/                   # Animated startup screens
│   │   ├── upload_screen/                   # Upload flow (note vs tweet toggle, file vs url)
│   │   └── widgets/                         # Reusable premium styled buttons, cards & shimmers
│   ├── layout.dart           # Entry layout skeleton wrapping BottomNavigation views
│   └── main.dart             # Global Entrypoint (Initializes Supabase, Local Notifications, and Hive Adapters)
└── test/
    └── dummy_test.dart       # Continuous Integration baseline testing block (asserts true == true)
```

---

## 3. High-Performance Optimization Strategies

Serious Study enforces key performance strategies to ensure optimal performance, low latency, and efficient bandwidth usage:

### 3.1. Local Caching with Hive (NoSQL)
- Rather than constantly invoking SQL queries to fetch static profile records, profile session metadata is cached locally inside `HiveBoxes` (`lib/core/helper/hive_boxes.dart`).
- **`userBox`**: Contains user profile parameters (`username`, `display_name`, `institute`, `profile_url`).
- **`downloadsBox`**: Tracks downloaded document hashes, local file system paths, and download dates. Allows instant UI response upon launching the "Downloads" view without checking server directories.

### 3.2. Optimistic UI Updates
- For features like `toggleLike()`, `toggleDislike()`, and `toggleBookmark()` in `DocumentController.dart`, the UI updates instantly.
- The controller updates values like `likes` count and `isLiked` status **locally before** waiting for backend API responses.
- If the server request fails, the controller catches the exception, rolls back the local parameters, and displays a clean error toast.

### 3.3. Sticky Feed Batching & Pagination
- The `HomeController` fetches feeds with a `limit(50)` on documents.
- It utilizes database-level sticky sorting (`order('created_at', ascending: false)`) combined with real-time updates through Supabase channels.
- Thumbnail loading utilizes `CachedNetworkImage` with customized disk-caching to avoid repetitive HTTP calls.

### 3.4. Pre-Upload Compressions
- Large assets can degrade network efficiency.
- The `UploadController` enforces a **10MB file limit** on direct uploads.
- The `ImageHelper.compressImage` utility automatically intercepts image uploads and compresses JPEGs to a maximum of `1024x1024` resolution at `70% quality`, protecting storage and user bandwidth.

---

## 4. UI/UX Paradigm: Material 3, Premium Deep Blue, & Glassmorphism

The application has been customized with an academic, elegant aesthetic:
- **Brand Theme Colors**: Built around an authoritative "Premium Deep Blue" (`#0D47A1` as the primary seed color). This color is present in headers, buttons, and state indicators.
- **Glassmorphic Gradients**:
  - Transparent white overlays (`Colors.white.withValues(alpha: 0.15)`) coupled with blur backdrops are applied to bottom navigation frames and settings menus.
  - Darker layers use `Colors.black.withValues(alpha: 0.65)` to create depth.
- **Zero Warnings Enforcement**:
  - Modern Flutter relies on `.withValues(alpha: ...)` instead of deprecated `.withOpacity(...)`.
  - All standard toggle switches use `activeThumbColor: const Color(0xFFB8860B)` to prevent deprecated `activeColor` layout bugs on Flutter 3.24+.
  - All conditional state renders wrapped in `Obx()` or flow-controls strictly enforce standard braces `{}` to satisfy Flutter static analyzer parameters.

---

## 5. Security & Relational Schema Mechanics

The core security of Serious Study relies on Supabase Auth, PostgreSQL constraints, and Row Level Security (RLS). This eliminates major security issues seen in legacy stacks.

### 5.1. Database Schema (`SUPABASE_SCHEMA.sql`)
The PostgreSQL database layout includes checks, foreign keys, and structural cascade delete rules:

```sql
-- Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  profile_url TEXT,
  institute TEXT,
  academic_interests TEXT[],
  bio TEXT,
  is_admin BOOLEAN DEFAULT false,
  followers INT DEFAULT 0,
  following INT DEFAULT 0,
  documents INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Documents Table
CREATE TABLE IF NOT EXISTS public.documents (
  id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  topic TEXT,
  description TEXT,
  document_url TEXT, -- Nullable to allow note-free textual Tweets
  document_name TEXT,
  cover_url TEXT,
  icon_name TEXT,
  likes_count INT DEFAULT 0,
  dislikes_count INT DEFAULT 0,
  is_external BOOLEAN DEFAULT false,
  is_official BOOLEAN DEFAULT false,
  post_type TEXT DEFAULT 'note' CHECK (post_type IN ('note', 'tweet')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);
```

### 5.2. Atomic Update Counter Functions (RPCs)
To prevent race conditions, the client does not directly increment values in tables. Instead, it triggers security-definer procedures (RPCs):

```sql
-- Example RPC: Atomic Like Increment
CREATE OR REPLACE FUNCTION public.increment_likes(doc_id BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE public.documents
  SET likes_count = likes_count + 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

Using `SECURITY DEFINER` lets authenticated users execute the procedure with system-level access to the table, keeping the underlying rows read-only to direct manipulation.

### 5.3. Row Level Security (RLS) Policy Mechanics
Row Level Security is active across all tables. This guarantees that users cannot alter another user's records.

- **Profiles Table Policies**:
  - **Read**: `FOR SELECT` is allowed for everyone (`USING (true)`).
  - **Create**: `FOR INSERT` with check `WITH CHECK (auth.uid() = id)` allows creating a profile matching the auth UID.
  - **Update**: `FOR UPDATE` is restricted to owners:
    ```sql
    CREATE POLICY "Users can update own profile" ON public.profiles
      FOR UPDATE USING (auth.uid() = id)
      WITH CHECK (auth.uid() = id AND is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
    ```
    *Note: The check blocks privilege escalation, preventing normal users from sending updates setting `is_admin = true`.*

- **Documents Table Policies**:
  - **Read**: `FOR SELECT USING (true)` lets all authenticated users view documents.
  - **Write**: `FOR INSERT WITH CHECK (auth.uid() = user_id)`.
  - **Modify**: `FOR ALL USING (auth.uid() = user_id)` ensures only the owner can delete or edit their documents.

- **Privilege Escalation Prevention for Content Verification**:
  Setting `is_official = true` on a document is restricted by database triggers. The trigger function `ensure_official_permission` verifies the user profile's `is_admin` status. If a non-admin tries to insert or update `is_official = true`, the transaction fails at the database level.
  ```sql
  CREATE OR REPLACE FUNCTION public.check_official_permission()
  RETURNS TRIGGER AS $$
  DECLARE
    v_is_admin BOOLEAN;
  BEGIN
    SET search_path = public;
    SELECT is_admin INTO v_is_admin FROM public.profiles WHERE id = auth.uid();
    IF NEW.is_official = true AND (v_is_admin IS NULL OR v_is_admin = false) THEN
      RAISE EXCEPTION 'Privilege Escalation Blocked: Non-admin users cannot publish official documents.';
    END IF;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SECURITY DEFINER;
  ```

---

## 6. Developer Workflows & Quality Assurance Procedures

To maintain high code quality and zero build warnings, developers must follow these workflows:

### 6.1. Verification and Static Analysis
Before committing changes, navigate to the Flutter project directory (`notehub/`) and execute:
```bash
# Clean project build files
flutter clean

# Resolve packages
flutter pub get

# Check code linting and verify Zero Warnings compliance
flutter analyze
```

If any errors or warnings are flagged, address them by matching modern styling conventions:
1. Wrap all single-line `if` statements with braces:
   ```dart
   if (condition) {
     doSomething();
   }
   ```
2. For intentional empty catch blocks, use the proper annotation:
   ```dart
   try {
     operation();
   } catch (e) {
     // ignore: empty_catches
   }
   ```

### 6.2. Running Tests
Ensure no regressions are introduced into the repository by running the test suite:
```bash
flutter test
```

### 6.3. Local Web Server Live Previews
To verify UI components or capture layouts:
1. Start the Flutter local web-server on a designated port:
   ```bash
   flutter run -d web-server --web-port 8080
   ```
2. Verify rendering and behavior across different screen sizes.

---
*Maintained and documented under the supervision of Jules, Lead AI Software Engineer.*
