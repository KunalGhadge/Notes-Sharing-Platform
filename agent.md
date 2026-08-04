# Developer Guide & Maintenance Manual - Serious Study (NoteHub)

This document serves as the primary system manual, developer guide, and codebase maintenance handbook for **Serious Study** (formerly known as **NoteHub**). Written from an AI and human developer perspective, it provides an in-depth, technical exploration of the application's overall performance strategies, architectural design patterns, state management flows, database configuration, security implementations, and zero-warning maintenance guidelines.

---

## Technical Architecture & Core Stack

Serious Study is an academic note-sharing and social networking platform engineered exclusively for the Mumbai University student community. The application uses a decoupled serverless design with a **Flutter** client and a **Supabase** backend.

```
       +-------------------------------------------------------------+
       |                        FLUTTER CLIENT                       |
       |                                                             |
       |   +-------------------+  GetX State  +-------------------+  |
       |   |    UI WIDGETS     |<------------>|    CONTROLLERS    |  |
       |   |  (Material 3 &    |              | (AuthController,  |  |
       |   |   Glassmorphic)   |              |  HomeController,  |  |
       |   +-------------------+              |  DocumentController) |
       |             |                        +-------------------+  |
       |             | Local Caching                    |            |
       |             v                                  |            |
       |   +-------------------+                        |            |
       |   |   HIVE DATABASE   |                        |            |
       |   | (user, downloads) |                        |            |
       |   +-------------------+                        |            |
       +------------------------------------------------|------------+
                                                        |
                                       Supabase HTTPS   | Auth / JWT
                                       & Realtime Stream| Postgres RPCs
                                                        v
       +-------------------------------------------------------------+
       |                       SUPABASE BACKEND                      |
       |                                                             |
       |   +-------------------+              +-------------------+  |
       |   |   SUPABASE AUTH   |              |  SUPABASE STORAGE |  |
       |   |  (JWT & Session)  |              | (PDFs/Thumbnails) |  |
       |   +-------------------+              +-------------------+  |
       |             |                                  |            |
       |             | Identity                         | RLS        |
       |             +-----------------+----------------+            |
       |                               |                             |
       |                               v                             |
       |                   +-----------------------+                 |
       |                   |  POSTGRES DATABASE    |                 |
       |                   |  - Row Level Security |                 |
       |                   |  - RPC Triggers       |                 |
       |                   +-----------------------+                 |
       +-------------------------------------------------------------+
```

### 1. Frontend Framework & SDK
- **Framework**: Flutter 3.24+ (Channel Stable)
- **Dart SDK**: `^3.5.4` — Crucial for avoiding color and control structure warnings through modern API methods.
- **State Management**: **GetX v4.6.6** — Handles clean Separation of Concerns (SoC) via independent reactive controllers, navigation/routing, and globally available dependency injections.
- **Local Persistent Storage**: **Hive v2.2.3** & **Hive Flutter v1.1.0** — Fast, lightweight, NoSQL object database used for instant launch rendering and session persistence.
- **Network Stack**: **Supabase Flutter SDK v2.12.0** (with underneath **Postgrest** and **GoTrue** sub-libraries) for DB/Auth interaction and **Dio v5.9.1** for custom network file streaming/caching.

### 2. Backend Cloud (Supabase Serverless)
- **Database Engine**: PostgreSQL with Postgres Extensions (`uuid-ossp`, `pg_crypto`).
- **Authorization Enforcement**: Row Level Security (RLS) policies on every application table.
- **Realtime Synchronizations**: Postgrest changes stream published from `public.documents` directly into GetX listeners.
- **Asset Storage**: Supabase Buckets with explicit prefix and RLS check policies to store covers and PDF documents securely.

---

## 1. Deep Performance Audit

High rendering performance and database optimization are top-tier priorities to accommodate students using low-end mobile devices under erratic mobile networks.

### Reactive State Management & Lazy Initializations
State management is handled asynchronously by **GetX**. The app utilizes lazy initialization (`Get.put()`) to spin up controllers only when their specific screens are accessed. For instance:
- `HomeController` is instantiated on `Home` initialization and automatically unsubscribes its active PostgreSQL stream during `onClose`:
  ```dart
  @override
  void onClose() {
    _stream?.unsubscribe();
    super.onClose();
  }
  ```
- Controllers use reactive properties (`RxList`, `RxBool`, `.obs`) paired with `Obx` or `GetBuilder` widgets to ensure only the necessary nodes of the element tree re-render upon state updates.

### Local persistent NoSQL Caching
Under `lib/core/helper/hive_boxes.dart`, the database defines localized memory tables to provide zero-latency launches:
- **`userBox`**: Persists `UserModel` (name, institute, username, follower count) locally. On startup, the profile view retrieves data immediately from Hive before calling Supabase, enabling an "Optimistic UI" response.
- **`downloadsBox`**: Tracks locally cached files' paths mapped to original document IDs.
  ```dart
  class HiveBoxes {
    static Box<UserModel> get userBox => Hive.box<UserModel>("user");
    static Box get downloadsBox => Hive.box("downloads");

    static String get userId => userBox.get("current")?.id ?? "";
    static String get username => userBox.get("current")?.username ?? "";
  }
  ```

### Advanced Media & Network Optimization
To prevent excessive bandwidth consumption:
1. **Adaptive Image Compression**: Cover thumbnails are compressed on-device before hitting Supabase storage using `flutter_image_compress` down to JPEG at 70% quality:
   ```dart
   static Future<File?> compressImage(File file) async {
     final filePath = file.absolute.path;
     final lastIndex = filePath.lastIndexOf(RegExp(r'.png|.jp'));
     final outPath = "${filePath.substring(0, lastIndex)}_compressed.jpg";
     return await FlutterImageCompress.compressAndGetFile(
       file.absolute.path, outPath, quality: 70,
     );
   }
   ```
2. **Specialized Download Caching**: Implemented under `lib/service/file_caching.dart` using `Dio` and `path_provider`. When downloading a PDF, the application searches the temporary local file paths cataloged in the `downloadsBox` before initiating a new HTTP request.

### Database Query Optimization & RPC Counters
To reduce payload overhead, document feeds are limited to **50 items** per fetch in `HomeController.fetchUpdates()` and **20 items** in `fetchOfficialUpdates()`.

Atomic interaction actions such as incrementing/decrementing likes are dispatched via Remote Procedure Calls (RPCs). Instead of fetching the record, modifying it, and saving it back (which introduces write locks and race conditions), the operation is handled directly inside PostgreSQL:
```sql
CREATE OR REPLACE FUNCTION increment_likes(p_document_id BIGINT)
RETURNS VOID AS $$
BEGIN
  UPDATE public.documents
  SET likes_count = likes_count + 1
  WHERE id = p_document_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

---

## 2. UI/UX & Aesthetics Design Audit

Serious Study features a high-end, contemporary **Material 3** theme combined with cohesive **Glassmorphism** cues designed to evoke an academic yet highly professional look.

```
+-----------------------------------------------------+
| [Profile Header: Premium Deep Blue Gradient]        |
|  +-----------------------------------------------+  |
|  | [Glassmorphic Container: 15% White + Blur]     |  |
|  | Name: Kunal Mishra                            |  |
|  | Institute: Mumbai University                  |  |
|  +-----------------------------------------------+  |
+-----------------------------------------------------+
| [Feed Tab]                                          |
|  - Card 1: Advanced OS Notes (Official Gold Star)   |
|  - Card 2: DBMS Query Cheat Sheet                   |
+-----------------------------------------------------+
```

### Color Palette & Typography
- **Core Branding**: Migrated from old purple to a Premium Deep Blue scheme (`#0D47A1`).
- **Primary Color**: `const Color(0xFF0D47A1)` used to seed the core Material 3 color palette.
- **Accents**: Gold (`const Color(0xFFB8860B)`) acts as the secondary indicator used exclusively for administrative badges, "Official" content switches, and verified tags.
- **Typography**: Uses the `GoogleFonts.poppins` and `GoogleFonts.inter` text themes to provide a highly legible, clean layout across different screen sizes.

### Glassmorphism Integration
Semi-transparent surfaces are built using custom glass layers (like `glassmorphism` container widgets or customized container decor) which blur underlying widgets.
- **Backing Color**: `Colors.white.withValues(alpha: 0.15)` or custom black masks.
- **Blur**: Radial or linear blurs using `BackdropFilter` with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)`.
- **Gradients**: Border and surface gradients like `AppGradients.premiumGradient` add a premium layered aesthetic.

### Shimmer and Feedback Assets
During asynchronous network loads, UI sections swap active rendering structures with `Shimmer` overlays to eliminate jarring page pops. Empty search fields, network timeouts, and success completions render cohesive Vector Graphics (`flutter_svg`) and custom Lottie animations to provide clear context-rich visual feedback.

---

## 3. Database Security & System Audit

Security is structured strictly within the Supabase backend layers, transforming database interactions from client-side instructions into authorization-safe execution pipelines.

### Relational Schema Design
The tables are defined inside `SUPABASE_SCHEMA.sql` under the `public` schema. Core schemas include:
1. **`profiles`**: Stores user identity metadata mapped strictly back to Supabase Auth (`auth.users`) through foreign key cascade restrictions.
2. **`documents`**: Contains note references. Includes an `is_official` boolean flag that marks verified or administrator-contributed documents. Supports both native storage URLs and standard external links (`is_external`).
3. **`interactions`**: Represents distinct user feedback (unique composite constraints on `(document_id, user_id)` ensure a user cannot multi-vote).
4. **`bookmarks`**: Connects documents to personal student collections.
5. **`comments`**: Threaded replies table utilizing recursive `parent_id` linking mapping to parent comment records.

### Row Level Security (RLS) Implementation
By enforcing RLS on every table, no user can write to tables unauthorized, even if they bypass the application and directly execute queries using the anon key.

- **`profiles` Policy**:
  - Anyone can query profile fields (to render posters' bios and names).
  - An owner can only insert/update their personal profile data where `id = auth.uid()`.

  *Vulnerability Fix*: A critical privilege escalation vulnerability was resolved by ensuring the `profiles` table update policy is restricted using a `WITH CHECK` constraint, preventing users from updating their own `is_admin` status:
  ```sql
  CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id AND is_admin = (SELECT is_admin FROM public.profiles WHERE id = auth.uid()));
  ```

- **`documents` Policy**:
  - Documents are public read-only to authenticated students.
  - Inserting, editing, or deleting is limited strictly to records where `user_id = auth.uid()`.

- **Official Status Verification**:
  To protect content authenticity, a custom Postgres Trigger restricts the `is_official` status to true *only* if the poster is a registered administrator:
  ```sql
  CREATE OR REPLACE FUNCTION check_official_permission()
  RETURNS TRIGGER AS $$
  DECLARE
    v_is_admin BOOLEAN;
  BEGIN
    SELECT is_admin INTO v_is_admin FROM public.profiles WHERE id = auth.uid();
    IF NEW.is_official = true AND (v_is_admin IS NULL OR v_is_admin = false) THEN
      RAISE EXCEPTION 'Only administrators can submit or mark documents as official.';
    END IF;
    RETURN NEW;
  END;
  $$ LANGUAGE plpgsql SET search_path = public;

  CREATE TRIGGER ensure_official_permission
  BEFORE INSERT OR UPDATE ON public.documents
  FOR EACH ROW EXECUTE FUNCTION check_official_permission();
  ```

---

## 4. Maintenance, Linting & QA Workflows

This section outlines the rules for contributing to the Serious Study codebase while keeping the static analysis perfectly warning-free under modern Flutter SDK versions.

### Required Software & Configuration
- **Flutter SDK**: `v3.24+` (Stable)
- **Dart SDK**: `^3.5.4`
- **Linter Rule Reference**: `analysis_options.yaml`

To check the app's health, run the analysis tool inside the `notehub/` folder:
```bash
cd notehub
flutter analyze
```

### Modern API Deprecation Replacements
1. **Switch To `.withValues(alpha: ...)`**:
   The standard `withOpacity(double opacity)` method is deprecated in Dart SDK 3.5.4+. Developers must convert color opacity adjustments to the new `.withValues(alpha: ...)` method:
   ```dart
   // DEPRECATED:
   // Color baseColor = Colors.white.withOpacity(0.15);

   // MODERNIZED STYLE:
   Color baseColor = Colors.white.withValues(alpha: 0.15);
   ```

2. **Switch Controls**:
   In `Switch` components, `activeColor` has been deprecated. Always replace it with `activeThumbColor` to ensure modern API compatibility:
   ```dart
   // DEPRECATED:
   // Switch(activeColor: Colors.blue)

   // MODERNIZED STYLE:
   Switch(activeThumbColor: Colors.blue)
   ```

3. **Flow Controls & Formatting**:
   All single-line `if` statements or loops must be formatted using curly braces (`{}`) to respect the `curly_braces_in_flow_control_structures` rules:
   ```dart
   // INVALID:
   if (input == null) return;

   // VALID:
   if (input == null) {
     return;
   }
   ```

4. **Correct Annotation Formatting**:
   When overriding empty errors or caught network timeouts with an empty block, ensure the `// ignore: empty_catches` directive is placed on its own line inside the block to avoid commenting out critical closing braces:
   ```dart
   // INVALID (closes/comments out code flow recursively):
   } catch (e) {// ignore: empty_catches}

   // VALID:
   } catch (e) {
     // ignore: empty_catches
   }
   ```

Following these strict development standards ensures the codebase remains robust, highly optimized, secure, and fully compliant with modern Flutter specifications.

---
*Maintained and Documented by Jules, AI Software Engineer.*
*Last updated: July 2026*
