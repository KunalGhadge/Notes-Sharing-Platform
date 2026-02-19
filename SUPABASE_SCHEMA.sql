-- SUPABASE SCHEMA FOR SERIOUS STUDY (UPDATED FOR EXTERNAL LINKS)

-- 1. Profiles Table (Linked to Auth.Users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  institute TEXT DEFAULT 'Mumbai University',
  profile_url TEXT,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone." ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile." ON profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile." ON profiles
  FOR UPDATE USING (auth.uid() = id);

-- 2. Documents Table
CREATE TABLE documents (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  topic TEXT,
  description TEXT,
  cover_url TEXT,
  document_url TEXT NOT NULL,
  document_name TEXT,
  is_external BOOLEAN DEFAULT FALSE,
  likes_count INT DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS on documents
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Documents are viewable by everyone." ON documents
  FOR SELECT USING (true);

CREATE POLICY "Users can upload their own documents." ON documents
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own documents." ON documents
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own documents." ON documents
  FOR DELETE USING (auth.uid() = user_id);

-- 3. Likes Table
CREATE TABLE likes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE NOT NULL,
  UNIQUE(user_id, document_id)
);

ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes are viewable by everyone." ON likes
  FOR SELECT USING (true);

CREATE POLICY "Users can like documents." ON likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike documents." ON likes
  FOR DELETE USING (auth.uid() = user_id);

-- 4. Bookmarks Table
CREATE TABLE bookmarks (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  document_id UUID REFERENCES documents(id) ON DELETE CASCADE NOT NULL,
  UNIQUE(user_id, document_id)
);

ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own bookmarks." ON bookmarks
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can bookmark documents." ON bookmarks
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unbookmark documents." ON bookmarks
  FOR DELETE USING (auth.uid() = user_id);

-- 5. Follows Table
CREATE TABLE follows (
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  PRIMARY KEY (follower_id, following_id)
);

ALTER TABLE follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Follows are viewable by everyone." ON follows
  FOR SELECT USING (true);

CREATE POLICY "Users can follow others." ON follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow others." ON follows
  FOR DELETE USING (auth.uid() = follower_id);

-- Functions for Atomic Increments
CREATE OR REPLACE FUNCTION increment_likes(doc_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE documents
  SET likes_count = likes_count + 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_likes(doc_id UUID)
RETURNS void AS $$
BEGIN
  UPDATE documents
  SET likes_count = likes_count - 1
  WHERE id = doc_id;
END;
$$ LANGUAGE plpgsql;

-- Storage Buckets Setup (Run these in Supabase Dashboard)
-- 1. 'documents' - Public bucket for notes and covers
-- 2. 'avatars' - Public bucket for profile pictures
