# Supabase Configuration Guide for Serious Study

Since you are new to Supabase and Android apps, this guide will walk you through exactly how to set up your Supabase project to work with the app.

## 1. Authentication Redirects
This is necessary so that when a user clicks "Confirm" in their email, it redirects back to your app.

1.  Go to your **Supabase Dashboard**.
2.  Click on **Authentication** (the user icon) in the left sidebar.
3.  Click on **URL Configuration**.
4.  In the **Site URL** field, you can put your website or `https://example.com`.
5.  In the **Redirect URLs** section, click **Add URL** and enter:
    `io.supabase.flutternotehub://login-callback`
6.  Click **Save**.

## 2. Database Setup (Tables & RLS)
You need to create the tables and set up the security rules (Row Level Security).

1.  Go to the **SQL Editor** in the left sidebar.
2.  Click **New Query**.
3.  Copy all the code from the file `SUPABASE_SCHEMA.sql` in your project.
4.  Paste it into the SQL Editor.
5.  Click **Run**.

This will create all the tables (`profiles`, `documents`, `comments`, etc.), the security policies, and the functions for likes/dislikes.

**Troubleshooting SQL Errors:**
*   **"Permission Denied" or "Must be owner":** If you get an error about "storage.objects", don't worry. I have removed those parts from the script. Just follow Step 3 below to set up storage manually in the dashboard.

## 3. Storage Setup (For Documents & Covers)
The app needs a place to store the uploaded PDF files and cover images.

1.  Go to **Storage** (the bucket icon) in the left sidebar.
2.  Click **New Bucket**.
3.  Enter the name: `documents`
4.  **Important:** Toggle the **Public** switch to **ON**.
5.  Click **Save**.

### Setting Storage Policies (Crucial for Uploading)
After creating the bucket, you must allow users to upload files:
1.  In the **Storage** section, click on **Policies** (next to Buckets).
2.  Find the `documents` bucket.
3.  Click **New Policy** and then **For full customization**.
4.  **Policy 1: Public Access**
    *   Name: `Public Access`
    *   Allowed operations: `SELECT`
    *   Target roles: `public`
    *   Review and Save.
5.  **Policy 2: User Uploads**
    *   Name: `User Uploads`
    *   Allowed operations: `INSERT`
    *   Target roles: `authenticated`
    *   Definition (Expression): `(storage.foldername(name))[1] = auth.uid()::text`
    *   Review and Save.
6.  **Policy 3: User Deletes**
    *   Name: `User Deletes`
    *   Allowed operations: `DELETE`
    *   Target roles: `authenticated`
    *   Definition (Expression): `(storage.foldername(name))[1] = auth.uid()::text`
    *   Review and Save.

## 4. App Connection
Make sure your Flutter app is pointing to your Supabase project.

1.  Go to **Project Settings** (the gear icon) > **API**.
2.  Copy your **Project URL** and **anon public key**.
3.  In your Flutter project, open `notehub/lib/core/meta/app_meta.dart`.
4.  Replace the placeholder values with your URL and Key.

## 5. Summary of Functionalities
*   **Registration:** Uses `supabase.auth.signUp`.
*   **Notes Upload:** Saves to `documents` bucket and `documents` table.
*   **Likes/Dislikes:** Uses custom SQL functions (RPC).
*   **Follows/Comments/Notifications:** Handled via dedicated tables.

## 6. Realtime & Push Notifications
The app uses Supabase Realtime to show local push notifications on your device.

1.  Go to **Database** > **Replication**.
2.  Enable replication for the `notifications` table (Toggle the switch next to it).
3.  Ensure your Android device has internet access and you have granted notification permissions to the app.

---
**Need Help?**
*   **"Grey Space" or Blank Screens:** This usually means the database is empty or the schema wasn't fully applied. Run Step 2 again.
*   **"Registration failed":** Check if you have enabled Email Auth in your Supabase project.
*   **"Error saving notes":** Make sure the `documents` bucket exists and has the correct policies from Step 3.
