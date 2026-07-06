-- ============================================================
-- SCHÉMA SOURCES WEB POUR APPRENTISSAGE CONTINU
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_web_sources (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  url TEXT NOT NULL UNIQUE,
  category TEXT NOT NULL CHECK (category IN ('visual', 'music', 'writing', 'comics', 'general', 'technique', 'style')),
  language TEXT DEFAULT 'en',
  is_active BOOLEAN DEFAULT true,
  last_fetched_at TIMESTAMPTZ,
  articles_added INTEGER DEFAULT 0,
  last_error TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_web_sources_category ON ai_web_sources(category);
CREATE INDEX idx_web_sources_active ON ai_web_sources(is_active);

ALTER TABLE ai_web_sources ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read web sources"
  ON ai_web_sources FOR SELECT
  USING (true);

-- Ajouter colonne source_url à ai_knowledge_base si pas déjà
ALTER TABLE ai_knowledge_base ADD COLUMN IF NOT EXISTS source_url TEXT;
ALTER TABLE ai_knowledge_base ADD COLUMN IF NOT EXISTS source_updated_at TIMESTAMPTZ;
