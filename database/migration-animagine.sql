-- ============================================================
-- Migration: SDXL → Animagine XL 4.0
-- Amélioration massive : base model manga natif, 500 images/style
-- ============================================================

-- Mettre à jour tous les styles existants vers Animagine XL 4.0
UPDATE ai_manga_styles
SET
  model_owner = 'rocketdigitalai',
  model_name = 'animagine-xl-4.0',
  model_version = '7af46ee494f1cf196d49a8592737f4eb789e34a5a995751b23a869d19f5dc2ba',
  num_inference_steps = 25,
  guidance_scale = 6.0
WHERE model_owner = 'stability-ai' OR model_version = '39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b';

-- Reset training status for styles without enough images
UPDATE ai_manga_styles
SET training_status = 'collecting'
WHERE reference_count < 200 AND training_status = 'ready';

SELECT '✅ Migration Animagine XL 4.0 terminée: ' || COUNT(*) || ' styles mis à jour'
FROM ai_manga_styles
WHERE model_owner = 'rocketdigitalai';
