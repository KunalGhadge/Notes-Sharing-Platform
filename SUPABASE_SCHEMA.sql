-- SUPABASE SCHEMA FOR SERIOUS STUDY (PRODUCTION READY & BULLETPROOF)

-- 1. Enable Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  institute TEXT DEFAULT 'Mumbai University',
  academic_interests TEXT[] DEFAULT '{}',
  profile_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    -- Select Policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Public profiles are viewable by everyone.') THEN
        CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
    END IF;
    -- Insert Policy (Needed for Registration)
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can insert their own profile.') THEN
        CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id OR auth.uid() IS NULL);
    END IF;
    -- Update Policy
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'profiles' AND policyname = 'Users can update own profile.') THEN
        CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);
    END IF;
END $$;

-- 3. Documents Table
CREATE TABLE IF NOT EXISTS public.documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  topic TEXT,
  description TEXT,
  cover_url TEXT,
  document_url TEXT NOT NULL,
  document_name TEXT,
  is_external BOOLEAN DEFAULT FALSE,
  likes_count INT DEFAULT 0,
  dislikes_count INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'documents' AND policyname = 'Documents are viewable by everyone.') THEN
        CREATE POLICY "Documents are viewable by everyone." ON public.documents FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'documents' AND policyname = 'Users can upload their own documents.') THEN
        CREATE POLICY "Users can upload their own documents." ON public.documents FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'documents' AND policyname = 'Users can delete their own documents.') THEN
        CREATE POLICY "Users can delete their own documents." ON public.documents FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 4. Comments Table
CREATE TABLE IF NOT EXISTS public.comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'comments' AND policyname = 'Comments are viewable by everyone.') THEN
        CREATE POLICY "Comments are viewable by everyone." ON public.comments FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'comments' AND policyname = 'Users can post comments.') THEN
        CREATE POLICY "Users can post comments." ON public.comments FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
END $$;

-- 5. Interactions (Likes & Dislikes)
CREATE TABLE IF NOT EXISTS public.interactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE NOT NULL,
  type TEXT CHECK (type IN ('like', 'dislike')),
  UNIQUE(user_id, document_id)
);

ALTER TABLE public.interactions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'interactions' AND policyname = 'Interactions are viewable by everyone.') THEN
        CREATE POLICY "Interactions are viewable by everyone." ON public.interactions FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'interactions' AND policyname = 'Users can interact.') THEN
        CREATE POLICY "Users can interact." ON public.interactions FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'interactions' AND policyname = 'Users can remove interaction.') THEN
        CREATE POLICY "Users can remove interaction." ON public.interactions FOR DELETE USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'interactions' AND policyname = 'Users can update interaction.') THEN
        CREATE POLICY "Users can update interaction." ON public.interactions FOR UPDATE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 6. Notifications Table
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  receiver_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  content TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can view their own notifications.') THEN
        CREATE POLICY "Users can view their own notifications." ON public.notifications FOR SELECT USING (auth.uid() = receiver_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'System can insert notifications.') THEN
        -- Allow insertion for system-generated notifications triggered by other users
        CREATE POLICY "System can insert notifications." ON public.notifications FOR INSERT WITH CHECK (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'notifications' AND policyname = 'Users can mark as read.') THEN
        CREATE POLICY "Users can mark as read." ON public.notifications FOR UPDATE USING (auth.uid() = receiver_id);
    END IF;
END $$;

-- 7. Bookmarks
CREATE TABLE IF NOT EXISTS public.bookmarks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  document_id UUID REFERENCES public.documents(id) ON DELETE CASCADE NOT NULL,
  UNIQUE(user_id, document_id)
);

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bookmarks' AND policyname = 'Users can view their own bookmarks.') THEN
        CREATE POLICY "Users can view their own bookmarks." ON public.bookmarks FOR SELECT USING (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bookmarks' AND policyname = 'Users can create bookmarks.') THEN
        CREATE POLICY "Users can create bookmarks." ON public.bookmarks FOR INSERT WITH CHECK (auth.uid() = user_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'bookmarks' AND policyname = 'Users can delete bookmarks.') THEN
        CREATE POLICY "Users can delete bookmarks." ON public.bookmarks FOR DELETE USING (auth.uid() = user_id);
    END IF;
END $$;

-- 8. Follows
CREATE TABLE IF NOT EXISTS public.follows (
  follower_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
  PRIMARY KEY (follower_id, following_id)
);

ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'follows' AND policyname = 'Follows are viewable by everyone.') THEN
        CREATE POLICY "Follows are viewable by everyone." ON public.follows FOR SELECT USING (true);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'follows' AND policyname = 'Users can follow others.') THEN
        CREATE POLICY "Users can follow others." ON public.follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'follows' AND policyname = 'Users can unfollow others.') THEN
        CREATE POLICY "Users can unfollow others." ON public.follows FOR DELETE USING (auth.uid() = follower_id);
    END IF;
END $$;

-- 9. Atomic Increment Functions (SECURITY DEFINER to bypass RLS)
CREATE OR REPLACE FUNCTION increment_likes(doc_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET likes_count = likes_count + 1 WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_likes(doc_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET likes_count = likes_count - 1 WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_dislikes(doc_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET dislikes_count = dislikes_count + 1 WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION decrement_dislikes(doc_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE public.documents SET dislikes_count = dislikes_count - 1 WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Automatically create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, display_name, institute)
  VALUES (
    new.id,
    COALESCE(new.email, 'user_' || substr(new.id::text, 1, 8)),
    COALESCE(new.raw_user_meta_data->>'display_name', 'User'),
    COALESCE(new.raw_user_meta_data->>'institute', 'Mumbai University')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for profile creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
