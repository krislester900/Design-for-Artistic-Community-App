-- ============================================================
-- SCHÉMA SOURCES PINTEREST POUR COLLECTE AUTOMATIQUE
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_pinterest_sources (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  board_url TEXT NOT NULL UNIQUE,
  username TEXT NOT NULL,
  board_name TEXT NOT NULL,
  style_id BIGINT REFERENCES ai_manga_styles(id),
  style_slug TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  last_fetched_at TIMESTAMPTZ,
  last_pin_id TEXT,
  total_collected INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_pinterest_style ON ai_pinterest_sources(style_slug);
CREATE INDEX IF NOT EXISTS idx_pinterest_active ON ai_pinterest_sources(is_active);

ALTER TABLE ai_manga_styles ADD COLUMN IF NOT EXISTS auto_train BOOLEAN DEFAULT false;
ALTER TABLE ai_manga_styles ADD COLUMN IF NOT EXISTS last_auto_train_at TIMESTAMPTZ;

ALTER TABLE ai_pinterest_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read pinterest sources"
  ON ai_pinterest_sources FOR SELECT
  USING (true);
