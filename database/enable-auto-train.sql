-- Activer l'auto-entraînement pour tous les styles qui ont des sources Pinterest
UPDATE ai_manga_styles
SET auto_train = true
WHERE slug IN (
  SELECT DISTINCT style_slug FROM ai_pinterest_sources WHERE is_active = true
);

SELECT '✅ Auto-train activé pour ' || COUNT(*) || ' styles' as result
FROM ai_manga_styles
WHERE auto_train = true;
