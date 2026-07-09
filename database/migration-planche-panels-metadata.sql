ALTER TABLE ai_planche_panels ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
