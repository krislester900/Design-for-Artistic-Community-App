-- ============================================================
-- SYSTÈME DE LIKES ET COMMENTAIRES
-- ============================================================

-- 1. TABLE DES LIKES
CREATE TABLE IF NOT EXISTS post_likes (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  post_id BIGINT REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, post_id)
);

CREATE INDEX idx_likes_post ON post_likes(post_id);
CREATE INDEX idx_likes_user ON post_likes(user_id);

ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Likes are publicly readable"
  ON post_likes FOR SELECT USING (true);

CREATE POLICY "Users can insert own likes"
  ON post_likes FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own likes"
  ON post_likes FOR DELETE
  USING (auth.uid() = user_id);

-- 2. TABLE DES COMMENTAIRES
CREATE TABLE IF NOT EXISTS post_comments (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  post_id BIGINT REFERENCES public.posts(id) ON DELETE CASCADE NOT NULL,
  content TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 1000),
  parent_id BIGINT REFERENCES post_comments(id) ON DELETE CASCADE, -- Pour les réponses
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_comments_post ON post_comments(post_id);
CREATE INDEX idx_comments_user ON post_comments(user_id);
CREATE INDEX idx_comments_parent ON post_comments(parent_id);

ALTER TABLE post_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Comments are publicly readable"
  ON post_comments FOR SELECT USING (true);

CREATE POLICY "Users can insert own comments"
  ON post_comments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own comments"
  ON post_comments FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments"
  ON post_comments FOR DELETE
  USING (auth.uid() = user_id);

-- 3. FONCTIONS RPC pour incrémenter/décrémenter les compteurs
CREATE OR REPLACE FUNCTION increment_likes(post_id BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts
  SET likes_count = COALESCE(likes_count, 0) + 1
  WHERE id = post_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_likes(post_id BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts
  SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0)
  WHERE id = post_id;
END;
$$;

CREATE OR REPLACE FUNCTION increment_comments(post_id BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts
  SET comments_count = COALESCE(comments_count, 0) + 1
  WHERE id = post_id;
END;
$$;

CREATE OR REPLACE FUNCTION decrement_comments(post_id BIGINT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  UPDATE public.posts
  SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0)
  WHERE id = post_id;
END;
$$;

-- 4. VUE POUR LES STATS D'ENGAGEMENT
CREATE VIEW post_engagement_stats AS
SELECT
  p.id as post_id,
  p.title,
  p.user_id,
  COALESCE(l.likes_count, 0) as likes,
  COALESCE(c.comments_count, 0) as comments,
  COALESCE(l.likes_count, 0) + COALESCE(c.comments_count, 0) as total_engagement
FROM public.posts p
LEFT JOIN (
  SELECT post_id, COUNT(*) as likes_count
  FROM post_likes
  GROUP BY post_id
) l ON p.id = l.post_id
LEFT JOIN (
  SELECT post_id, COUNT(*) as comments_count
  FROM post_comments
  GROUP BY post_id
) c ON p.id = c.post_id
ORDER BY total_engagement DESC;