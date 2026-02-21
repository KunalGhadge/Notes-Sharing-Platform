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

## 3. Storage Setup (For Documents & Covers)
The app needs a place to store the uploaded PDF files and cover images.

1.  Go to **Storage** (the bucket icon) in the left sidebar.
2.  Click **New Bucket**.
3.  Enter the name: `documents`
4.  **Important:** Toggle the **Public** switch to **ON**. (This allows users to view the documents).
5.  Click **Save**.

## 4. App Connection
Make sure your Flutter app is pointing to your Supabase project.

1.  Go to **Project Settings** (the gear icon) > **API**.
2.  Copy your **Project URL** and **anon public key**.
3.  In your Flutter project, open `notehub/lib/core/meta/app_meta.dart`.
4.  Replace the placeholder values with your URL and Key:
    ```dart
    static const String supabaseUrl = "YOUR_SUPABASE_URL";
    static const String supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY";
    ```

## 5. Summary of Functionalities
Here is how the app interacts with Supabase for each feature:

*   **Registration:** Uses `supabase.auth.signUp`. After the user confirms their email, the app automatically creates a profile entry for them in the `profiles` table.
*   **Login:** Uses `supabase.auth.signInWithPassword`.
*   **Notes Upload:** Saves the files to the `documents` storage bucket and creates a record in the `documents` database table.
*   **Likes/Dislikes:** Uses a custom SQL function (RPC) to atomically update counts, and saves the interaction in the `interactions` table.
*   **Follows:** Adds/removes records in the `follows` table.
*   **Comments:** Adds records to the `comments` table.
*   **Notifications:** Automatically sends notifications (like when someone comments) via the `notifications` table.

---
**Need Help?** If you see any "Registration failed" or "Error" messages, double-check that you ran the SQL script in Step 2 and created the Storage bucket in Step 3.
