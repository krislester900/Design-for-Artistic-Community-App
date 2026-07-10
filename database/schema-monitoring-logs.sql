-- Table de logs structurés pour les edge functions
CREATE TABLE IF NOT EXISTS ai_logs (
  id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  level         TEXT NOT NULL DEFAULT 'info' CHECK (level IN ('debug','info','warn','error','fatal')),
  source        TEXT NOT NULL,
  function_name TEXT NOT NULL DEFAULT '',
  message       TEXT NOT NULL,
  metadata      JSONB DEFAULT '{}',
  duration_ms   INTEGER,
  style_slug    TEXT,
  planche_id    TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_logs_level ON ai_logs(level);
CREATE INDEX IF NOT EXISTS idx_ai_logs_source ON ai_logs(source);
CREATE INDEX IF NOT EXISTS idx_ai_logs_created ON ai_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_logs_style ON ai_logs(style_slug);

-- Fonction helper pour insérer un log depuis les edge functions
CREATE OR REPLACE FUNCTION insert_ai_log(
  p_level TEXT,
  p_source TEXT,
  p_function_name TEXT,
  p_message TEXT,
  p_metadata JSONB DEFAULT '{}',
  p_duration_ms INTEGER DEFAULT NULL,
  p_style_slug TEXT DEFAULT NULL,
  p_planche_id TEXT DEFAULT NULL
) RETURNS BIGINT AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO ai_logs (level, source, function_name, message, metadata, duration_ms, style_slug, planche_id)
  VALUES (p_level, p_source, p_function_name, p_message, p_metadata, p_duration_ms, p_style_slug, p_planche_id)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
