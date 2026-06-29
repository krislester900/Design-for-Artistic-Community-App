-- Table pour stocker les conversations avec l'assistant IA
CREATE TABLE IF NOT EXISTS ai_conversations (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  user_message TEXT NOT NULL,
  assistant_reply TEXT NOT NULL,
  context_type TEXT DEFAULT 'general',
  tokens_used INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour requêtes rapides
CREATE INDEX idx_ai_conversations_user_id ON ai_conversations(user_id);
CREATE INDEX idx_ai_conversations_created_at ON ai_conversations(created_at DESC);

-- Sécurité : RLS
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;

-- Chaque utilisateur ne voit que ses propres conversations
CREATE POLICY "Users can view own conversations"
  ON ai_conversations FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversations"
  ON ai_conversations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Vue pour les statistiques d'utilisation
CREATE VIEW ai_usage_stats AS
SELECT 
  user_id,
  COUNT(*) as total_conversations,
  SUM(tokens_used) as total_tokens,
  MAX(created_at) as last_interaction
FROM ai_conversations
GROUP BY user_id;