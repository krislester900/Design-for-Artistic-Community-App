-- ============================================================
-- SCHÉMA ENTRAÎNEMENT LoRA SUR PLANCHES MANGA
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_manga_references (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  style_id BIGINT REFERENCES ai_manga_styles(id),
  image_url TEXT NOT NULL,
  caption TEXT,
  source TEXT DEFAULT 'upload',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refs_style ON ai_manga_references(style_id);
CREATE INDEX IF NOT EXISTS idx_refs_user ON ai_manga_references(user_id);

CREATE TABLE IF NOT EXISTS ai_training_jobs (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  style_id BIGINT REFERENCES ai_manga_styles(id),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'preparing', 'training', 'completed', 'failed')),
  replicate_job_id TEXT,
  lora_url TEXT,
  instance_prompt TEXT NOT NULL,
  reference_count INTEGER DEFAULT 0,
  progress DECIMAL(3,2) DEFAULT 0,
  error_message TEXT,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_jobs_style ON ai_training_jobs(style_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON ai_training_jobs(status);

ALTER TABLE ai_manga_references ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_training_jobs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own references"
  ON ai_manga_references FOR ALL
  USING (auth.uid() = user_id);

CREATE POLICY "Public read training jobs"
  ON ai_training_jobs FOR SELECT
  USING (true);
