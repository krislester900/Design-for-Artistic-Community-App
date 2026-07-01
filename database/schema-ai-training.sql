-- ============================================================
-- SCHÉMA D'ENTRAÎNEMENT & AMÉLIORATION DE L'ASSISTANT IA
-- ============================================================

-- 1. BASE DE CONNAISSANCES ARTISTIQUES (RAG)
CREATE TABLE IF NOT EXISTS ai_knowledge_base (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  category TEXT NOT NULL CHECK (category IN ('visual', 'music', 'writing', 'comics', 'general', 'technique', 'style')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  source TEXT DEFAULT 'expert',
  usage_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index sur catégorie
CREATE INDEX idx_knowledge_category ON ai_knowledge_base(category);

-- 2. ENTRAÎNEMENT : Paires question-réponse de qualité
CREATE TABLE IF NOT EXISTS ai_training_data (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  category TEXT,
  question TEXT NOT NULL,
  answer TEXT NOT NULL,
  quality_score INTEGER DEFAULT 3 CHECK (quality_score BETWEEN 1 AND 5),
  is_approved BOOLEAN DEFAULT false,
  is_used_in_training BOOLEAN DEFAULT false,
  used_in_fine_tuning BOOLEAN DEFAULT false,
  token_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. FEEDBACK DES UTILISATEURS
CREATE TABLE IF NOT EXISTS ai_feedback (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  conversation_id BIGINT REFERENCES ai_conversations(id),
  rating INTEGER CHECK (rating BETWEEN 1 AND 5),
  is_helpful BOOLEAN DEFAULT true,
  feedback_text TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_feedback_user ON ai_feedback(user_id);
CREATE INDEX idx_feedback_rating ON ai_feedback(rating);

-- 4. MÉTRIQUES DE PERFORMANCE
CREATE TABLE IF NOT EXISTS ai_performance_metrics (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  total_queries INTEGER DEFAULT 0,
  avg_response_time_ms INTEGER DEFAULT 0,
  openai_calls INTEGER DEFAULT 0,
  local_fallback_calls INTEGER DEFAULT 0,
  avg_tokens_per_query INTEGER DEFAULT 0,
  unique_users INTEGER DEFAULT 0,
  satisfaction_score DECIMAL(3,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(date)
);

-- 5. PROMPTS SYSTÈME VERSIONNÉS
CREATE TABLE IF NOT EXISTS ai_system_prompts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  version TEXT NOT NULL,
  category TEXT NOT NULL,
  prompt_text TEXT NOT NULL,
  is_active BOOLEAN DEFAULT false,
  performance_score DECIMAL(3,2) DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_active_prompts ON ai_system_prompts(is_active, category);

-- ============================================================
-- VUES D'ANALYSE
-- ============================================================

-- Top questions fréquentes
CREATE VIEW ai_faq_view AS
SELECT 
  question,
  COUNT(*) as frequency,
  AVG(quality_score) as avg_quality,
  string_agg(DISTINCT category, ', ') as categories
FROM ai_training_data
WHERE is_approved = true
GROUP BY question
HAVING COUNT(*) > 1
ORDER BY frequency DESC;

-- Connaissances les plus utiles
CREATE VIEW ai_top_knowledge AS
SELECT 
  category,
  title,
  content,
  usage_count,
  helpful_count,
  ROUND(helpful_count::DECIMAL / GREATEST(usage_count, 1), 2) as helpful_ratio
FROM ai_knowledge_base
ORDER BY helpful_ratio DESC, usage_count DESC;

-- Performance quotidienne
CREATE VIEW ai_daily_performance AS
SELECT 
  date,
  total_queries,
  avg_response_time_ms,
  ROUND(local_fallback_calls::DECIMAL / GREATEST(total_queries, 1) * 100, 1) as fallback_pct,
  satisfaction_score
FROM ai_performance_metrics
ORDER BY date DESC;

-- ============================================================
-- SÉCURITÉ RLS
-- ============================================================

ALTER TABLE ai_knowledge_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_training_data ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_system_prompts ENABLE ROW LEVEL SECURITY;

-- Lecture publique de la connaissance
CREATE POLICY "Knowledge base is publicly readable"
  ON ai_knowledge_base FOR SELECT
  USING (true);

-- Les utilisateurs peuvent donner leur feedback
CREATE POLICY "Users can insert feedback"
  ON ai_feedback FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own feedback"
  ON ai_feedback FOR SELECT
  USING (auth.uid() = user_id);

-- Seuls les admins peuvent modifier la base de connaissances
CREATE POLICY "Admins can manage knowledge"
  ON ai_knowledge_base FOR ALL
  USING (EXISTS (
    SELECT 1 FROM auth.users 
    WHERE id = auth.uid() AND raw_user_meta_data->>'is_admin' = 'true'
  ));

-- ============================================================
-- FONCTIONS UTILES
-- ============================================================

-- Marquer une connaissance comme utile
CREATE OR REPLACE FUNCTION mark_knowledge_helpful(
  knowledge_id BIGINT,
  was_helpful BOOLEAN
) RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE ai_knowledge_base SET
    usage_count = usage_count + 1,
    helpful_count = helpful_count + CASE WHEN was_helpful THEN 1 ELSE 0 END
  WHERE id = knowledge_id;
END;
$$;

-- Collecter les stats quotidiennes
CREATE OR REPLACE FUNCTION collect_ai_stats()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO ai_performance_metrics (
    date,
    total_queries,
    unique_users,
    satisfaction_score
  )
  SELECT
    CURRENT_DATE,
    COUNT(*) as queries,
    COUNT(DISTINCT user_id) as users,
    COALESCE(AVG(f.rating)::DECIMAL(3,2), 0) as satisfaction
  FROM ai_conversations c
  LEFT JOIN ai_feedback f ON f.conversation_id = c.id
  WHERE c.created_at::date = CURRENT_DATE
  ON CONFLICT (date) DO UPDATE SET
    total_queries = EXCLUDED.total_queries,
    unique_users = EXCLUDED.unique_users,
    satisfaction_score = EXCLUDED.satisfaction_score;
END;
$$;

-- Nettoyer les conversations trop anciennes (garder 90 jours)
CREATE OR REPLACE FUNCTION cleanup_old_conversations()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM ai_conversations
  WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$;