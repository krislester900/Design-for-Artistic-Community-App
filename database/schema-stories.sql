-- ==========================================================
-- Schéma : Stories éphémères (format 24h)
-- ==========================================================

CREATE TABLE IF NOT EXISTS stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  thumbnail_url TEXT,
  caption TEXT,
  duration_seconds INT DEFAULT 5,
  font_size INT DEFAULT 16,
  background_color TEXT DEFAULT '#000000',
  text_position TEXT DEFAULT 'bottom',
  stickers JSONB DEFAULT '[]',
  music_url TEXT,
  music_title TEXT,
  view_count INT NOT NULL DEFAULT 0,
  reaction_count INT NOT NULL DEFAULT 0,
  reply_count INT NOT NULL DEFAULT 0,
  is_spoiler BOOLEAN NOT NULL DEFAULT false,
  is_highlight BOOLEAN NOT NULL DEFAULT false,
  highlight_name TEXT,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT NOW() + INTERVAL '24 hours',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_stories_user ON stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_expires ON stories(expires_at);
CREATE INDEX IF NOT EXISTS idx_stories_created ON stories(created_at DESC);

-- Vues des stories
CREATE TABLE IF NOT EXISTS story_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  viewer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(story_id, viewer_id)
);

CREATE INDEX IF NOT EXISTS idx_story_views_story ON story_views(story_id);

-- Réactions aux stories (emojis)
CREATE TABLE IF NOT EXISTS story_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(story_id, user_id, emoji)
);

-- Réponses aux stories
CREATE TABLE IF NOT EXISTS story_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Points forts (highlights)
CREATE TABLE IF NOT EXISTS story_highlights (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  cover_image_url TEXT,
  stories UUID[] DEFAULT '{}',
  sort_order INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_highlights ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stories_select" ON stories FOR SELECT
  USING (expires_at > NOW() AND deleted_at IS NULL);

CREATE POLICY "stories_insert" ON stories FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "stories_update" ON stories FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "stories_delete" ON stories FOR DELETE
  USING (user_id = auth.uid());

CREATE POLICY "views_insert" ON story_views FOR INSERT
  WITH CHECK (viewer_id = auth.uid());

CREATE POLICY "reactions_insert" ON story_reactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "replies_insert" ON story_replies FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "highlights_select" ON story_highlights FOR SELECT USING (true);
CREATE POLICY "highlights_insert" ON story_highlights FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Fonction pour nettoyer les stories expirées
CREATE OR REPLACE FUNCTION cleanup_expired_stories()
RETURNS void AS $$
BEGIN
  UPDATE stories SET deleted_at = NOW()
  WHERE expires_at < NOW() AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger auto-cleanup
CREATE OR REPLACE FUNCTION check_story_expiry()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.expires_at <= NOW() THEN
    NEW.deleted_at := NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_story_expiry
  BEFORE INSERT ON stories
  FOR EACH ROW
  EXECUTE FUNCTION check_story_expiry();