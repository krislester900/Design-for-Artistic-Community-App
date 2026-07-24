-- ============================================================
-- TRACKING : images téléchargées vs utilisées en entraînement
-- ============================================================

ALTER TABLE ai_manga_references ADD COLUMN IF NOT EXISTS used_in_training BOOLEAN DEFAULT false;
ALTER TABLE ai_manga_references ADD COLUMN IF NOT EXISTS trained_at TIMESTAMPTZ;
ALTER TABLE ai_manga_references ADD COLUMN IF NOT EXISTS downloaded BOOLEAN DEFAULT false;

CREATE INDEX IF NOT EXISTS idx_refs_used ON ai_manga_references(used_in_training);

-- Vue synthétique par style
CREATE OR REPLACE VIEW ai_training_stats AS
SELECT
  s.id AS style_id,
  s.name,
  s.slug,
  s.reference_count,
  s.generation_count,
  s.training_status,
  COUNT(r.id) FILTER (WHERE r.used_in_training = true) AS trained_count,
  COUNT(r.id) FILTER (WHERE r.downloaded = true) AS downloaded_count,
  COUNT(r.id) FILTER (WHERE r.source = 'scrape') AS scraped_count,
  COUNT(r.id) FILTER (WHERE r.source = 'generated') AS generated_count,
  COUNT(r.id) FILTER (WHERE r.source = 'upload') AS uploaded_count,
  COUNT(r.id) AS total_refs
FROM ai_manga_styles s
LEFT JOIN ai_manga_references r ON r.style_id = s.id
GROUP BY s.id, s.name, s.slug, s.reference_count, s.generation_count, s.training_status;

-- Stats globales
CREATE OR REPLACE VIEW ai_global_stats AS
SELECT
  (SELECT COUNT(*) FROM ai_manga_references) AS total_images_collected,
  (SELECT COUNT(*) FROM ai_manga_references WHERE used_in_training = true) AS total_images_trained,
  (SELECT COUNT(*) FROM ai_manga_references WHERE downloaded = true) AS total_images_downloaded,
  (SELECT COUNT(*) FROM ai_generations) AS total_generations,
  (SELECT COUNT(*) FROM ai_training_jobs WHERE status = 'completed') AS total_trainings_completed,
  (SELECT COUNT(*) FROM ai_training_jobs WHERE status = 'training') AS trainings_in_progress;
