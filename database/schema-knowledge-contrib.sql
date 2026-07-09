-- ============================================================
-- SCHÉMA : Contribution utilisateur à la base de connaissances
-- ============================================================

-- Table des propositions d'articles par les utilisateurs
CREATE TABLE IF NOT EXISTS ai_knowledge_proposals (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('visual', 'music', 'writing', 'comics', 'general', 'technique', 'style')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT[] DEFAULT '{}',
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_proposals_status ON ai_knowledge_proposals(status);
CREATE INDEX idx_proposals_user ON ai_knowledge_proposals(user_id);
CREATE INDEX idx_proposals_category ON ai_knowledge_proposals(category);

-- RLS
ALTER TABLE ai_knowledge_proposals ENABLE ROW LEVEL SECURITY;

-- Lecture : les utilisateurs voient leurs propres propositions
CREATE POLICY "Users can view own proposals"
  ON ai_knowledge_proposals FOR SELECT
  USING (auth.uid() = user_id);

-- Lecture : les admins voient tout
CREATE POLICY "Admins can view all proposals"
  ON ai_knowledge_proposals FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'is_admin' = 'true'
  ));

-- Insertion : tout utilisateur connecté peut proposer
CREATE POLICY "Users can create proposals"
  ON ai_knowledge_proposals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Mise à jour : les utilisateurs peuvent éditer leurs propositions en attente
CREATE POLICY "Users can update own pending proposals"
  ON ai_knowledge_proposals FOR UPDATE
  USING (auth.uid() = user_id AND status = 'pending')
  WITH CHECK (auth.uid() = user_id AND status = 'pending');

-- Mise à jour : les admins peuvent changer le statut
CREATE POLICY "Admins can update any proposal"
  ON ai_knowledge_proposals FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM auth.users WHERE id = auth.uid() AND raw_user_meta_data->>'is_admin' = 'true'
  ));

-- Suppression : les utilisateurs suppriment leurs propres propositions en attente
CREATE POLICY "Users can delete own pending proposals"
  ON ai_knowledge_proposals FOR DELETE
  USING (auth.uid() = user_id AND status = 'pending');
