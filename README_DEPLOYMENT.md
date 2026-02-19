# Serious Study - Deployment & Verification Guide

This guide will walk you through the final steps to get **Serious Study** running on your Android phone and verify that the Supabase backend is working perfectly.

---

## Part 1: Supabase Backend Setup (Final Check)

Before opening the app, make sure your Supabase project is configured correctly:

### 1. Database Schema
- Go to your [Supabase Dashboard](https://supabase.com/dashboard).
- Open the **SQL Editor** tab on the left.
- Open the `SUPABASE_SCHEMA.sql` file provided in the project root.
- Copy the entire content and paste it into the Supabase SQL Editor.
- Click **Run**. You should see "Success". If it says "already exists", don't worry—the script handles that gracefully now.

### 2. Storage Buckets
- Go to the **Storage** tab on the left.
- Create a new bucket named `documents`.
- **CRITICAL**: Make sure the bucket is set to **Public** (so users can see the cover images and download notes).

### 3. Authentication
- Go to **Authentication > Providers**.
- Ensure **Email** is enabled.
- (Optional) Disable "Confirm Email" if you want users to log in immediately without checking their inbox during testing.

---

## Part 2: How to Verify the Backend is Working

Once the app is open, here is how you can tell everything is connected properly:

### 1. Test Registration
- Open the app and click **"New student? Register for MU Community"**.
- Create an account.
- **Verification**: Go to Supabase **Authentication > Users**. You should see your new email listed there!

### 2. Test Profile Update
- Go to the **Profile** tab (last icon in the bottom bar).
- Click **Edit Profile**. Change your name and add "Maths, Coding" as academic interests.
- **Verification**: Go to Supabase **Table Editor > profiles**. You should see your updated name and interests in the rows.

### 3. Test Upload (Direct & Link)
- Go to the **Upload** tab (+ icon).
- **Direct**: Upload a small PDF and a cover image.
- **Link**: Toggle to "External Link", paste a Google Drive URL, and add a cover.
- **Verification**:
    - Go to Supabase **Storage > documents**. You should see your files inside folders named after your User ID.
    - Go to Supabase **Table Editor > documents**. You should see the records with `is_external` set correctly.

---

## Part 3: Build & Install the Android APK

To get the app on your physical phone, follow these steps:

### 1. Prepare your Environment
Ensure you have the Flutter SDK installed on your computer. If you haven't, follow the [official Flutter guide](https://docs.flutter.dev/get-started/install).

### 2. Run the Build Command
Open your terminal/command prompt, navigate to the `notehub` folder, and run:
```bash
flutter build apk --release
```

### 3. Locate the File
Once finished, Flutter will tell you where the file is. Usually, it is here:
`notehub/build/app/outputs/flutter-apk/app-release.apk`

### 4. Install on your Phone
1.  **Transfer the File**: Send the `app-release.apk` to your phone via USB cable, Google Drive, or WhatsApp.
2.  **Enable Unknown Sources**: When you try to open the `.apk` on your Android phone, it might say "Blocked by Play Protect".
    - Click **Settings** or **Install Anyway**.
    - You may need to enable "Allow installation from this source" in your phone settings.
3.  **Open and Enjoy**: The app will now be installed as "Serious Study" on your home screen!

---

## Troubleshooting Tips
- **App doesn't load feed?** Double-check your Supabase URL and Anon Key in `lib/core/meta/app_meta.dart`.
- **Upload fails?** Ensure the `documents` bucket exists in Supabase Storage and is set to **Public**.
- **Images not showing?** Ensure your storage policies allow "Public" read access (the SQL script handles this, but worth checking).

**Success!** You now have a production-grade community app for Mumbai University.
