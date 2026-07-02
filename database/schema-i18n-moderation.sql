-- ==========================================================
-- Schéma : Internationalisation (i18n) & Modération
-- ==========================================================

-- ==================== INTERNATIONALISATION ====================

CREATE TABLE IF NOT EXISTS translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  fr TEXT NOT NULL,
  en TEXT NOT NULL,
  es TEXT,
  de TEXT,
  it TEXT,
  pt TEXT,
  ar TEXT,
  zh TEXT,
  context TEXT,
  namespace TEXT NOT NULL DEFAULT 'app',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_translations_key ON translations(key);
CREATE INDEX IF NOT EXISTS idx_translations_namespace ON translations(namespace);

-- Langues disponibles
CREATE TABLE IF NOT EXISTS supported_languages (
  code TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  native_name TEXT NOT NULL,
  flag TEXT NOT NULL,
  is_rtl BOOLEAN NOT NULL DEFAULT false,
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0
);

INSERT INTO supported_languages (code, name, native_name, flag, is_rtl, sort_order) VALUES
  ('fr', 'Français', 'Français', '🇫🇷', false, 1),
  ('en', 'English', 'English', '🇬🇧', false, 2),
  ('es', 'Español', 'Español', '🇪🇸', false, 3),
  ('de', 'Deutsch', 'Deutsch', '🇩🇪', false, 4),
  ('it', 'Italiano', 'Italiano', '🇮🇹', false, 5),
  ('pt', 'Português', 'Português', '🇵🇹', false, 6),
  ('ar', 'العربية', 'العربية', '🇸🇦', true, 7),
  ('zh', '中文', '中文', '🇨🇳', false, 8)
ON CONFLICT (code) DO NOTHING;

-- Profil de langue de l'utilisateur
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS preferred_language TEXT NOT NULL DEFAULT 'fr';
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS auto_translate BOOLEAN NOT NULL DEFAULT false;

-- ==================== MODÉRATION ====================

-- Types de signalements
CREATE TABLE IF NOT EXISTS report_reasons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  label_fr TEXT NOT NULL,
  label_en TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('content', 'user', 'spam', 'safety', 'other')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  sort_order INT NOT NULL DEFAULT 0
);

INSERT INTO report_reasons (code, label_fr, label_en, category, sort_order) VALUES
  ('spam', 'Spam ou pub', 'Spam or advertising', 'spam', 1),
  ('harassment', 'Harcèlement', 'Harassment', 'safety', 2),
  ('hate_speech', 'Discours de haine', 'Hate speech', 'safety', 3),
  ('violence', 'Contenu violent', 'Violent content', 'safety', 4),
  ('nudity', 'Nudité ou contenu sexuel', 'Nudity or sexual content', 'content', 5),
  ('copyright', 'Violation de copyright', 'Copyright violation', 'content', 6),
  ('impersonation', 'Usurpation d''identité', 'Impersonation', 'user', 7),
  ('false_info', 'Fausse information', 'False information', 'content', 8),
  ('self_harm', 'Auto-mutilation ou suicide', 'Self-harm or suicide', 'safety', 9),
  ('other', 'Autre', 'Other', 'other', 10)
ON CONFLICT (code) DO NOTHING;

-- Table des signalements
CREATE TABLE IF NOT EXISTS reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reported_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('post', 'comment', 'message', 'profile', 'story')),
  content_id TEXT,
  reason_id UUID NOT NULL REFERENCES report_reasons(id),
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  action_taken TEXT,
  moderator_id UUID REFERENCES profiles(id),
  moderator_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_created ON reports(created_at DESC);

-- Table des bannissements
CREATE TABLE IF NOT EXISTS bans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  moderator_id UUID NOT NULL REFERENCES profiles(id),
  reason TEXT NOT NULL,
  report_id UUID REFERENCES reports(id),
  is_permanent BOOLEAN NOT NULL DEFAULT false,
  expires_at TIMESTAMPTZ,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  lifted_at TIMESTAMPTZ,
  lifted_by UUID REFERENCES profiles(id)
);

CREATE INDEX IF NOT EXISTS idx_bans_user ON bans(user_id);
CREATE INDEX IF NOT EXISTS idx_bans_active ON bans(is_active);

-- Table des logs de modération automatique (IA)
CREATE TABLE IF NOT EXISTS auto_moderation_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  content_id TEXT NOT NULL,
  content_type TEXT NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id),
  action TEXT NOT NULL CHECK (action IN ('approved', 'flagged', 'rejected', 'quarantined')),
  confidence_score DECIMAL(5,4) NOT NULL,
  categories_flagged TEXT[],
  reason TEXT,
  ai_model TEXT NOT NULL DEFAULT 'arteia-moderator-v1',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auto_moderation_user ON auto_moderation_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_auto_moderation_action ON auto_moderation_logs(action);

-- Mots et patterns à modérer
CREATE TABLE IF NOT EXISTS moderation_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pattern TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('word', 'regex', 'pattern', 'domain')),
  category TEXT NOT NULL DEFAULT 'spam',
  severity TEXT NOT NULL DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
  auto_action TEXT NOT NULL DEFAULT 'flag' CHECK (auto_action IN ('allow', 'flag', 'reject', 'quarantine')),
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ==================== RLS ====================

ALTER TABLE translations ENABLE ROW LEVEL SECURITY;
ALTER TABLE supported_languages ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE bans ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_moderation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_rules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "translations_select" ON translations FOR SELECT USING (true);
CREATE POLICY "languages_select" ON supported_languages FOR SELECT USING (true);

CREATE POLICY "reports_insert" ON reports FOR INSERT WITH CHECK (reporter_id = auth.uid());
CREATE POLICY "reports_select_mod" ON reports FOR SELECT
  USING (reporter_id = auth.uid() OR EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "reports_update_mod" ON reports FOR UPDATE
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "bans_select" ON bans FOR SELECT USING (true);
CREATE POLICY "bans_insert" ON bans FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

CREATE POLICY "moderation_logs_select" ON auto_moderation_logs FOR SELECT USING (true);
CREATE POLICY "moderation_rules_select" ON moderation_rules FOR SELECT USING (true);

-- ==================== FONCTIONS ====================

-- Vérifier si un utilisateur est banni
CREATE OR REPLACE FUNCTION is_user_banned(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_ban RECORD;
BEGIN
  SELECT * INTO v_ban FROM bans
  WHERE user_id = p_user_id AND is_active = true
  AND (is_permanent = true OR expires_at > NOW())
  LIMIT 1;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Signaler un contenu automatiquement (IA)
CREATE OR REPLACE FUNCTION auto_report_content(
  p_content_id TEXT,
  p_content_type TEXT,
  p_user_id UUID,
  p_reason TEXT,
  p_confidence DECIMAL
)
RETURNS UUID AS $$
DECLARE
  v_action TEXT;
  v_report_id UUID;
BEGIN
  -- Déterminer l'action selon la sévérité
  IF p_confidence >= 0.9 THEN
    v_action := 'reject';
  ELSIF p_confidence >= 0.7 THEN
    v_action := 'quarantined';
  ELSIF p_confidence >= 0.5 THEN
    v_action := 'flag';
  ELSE
    v_action := 'approved';
  END IF;

  -- Journaliser
  INSERT INTO auto_moderation_logs (
    content_id, content_type, user_id, action,
    confidence_score, reason, categories_flagged
  ) VALUES (
    p_content_id, p_content_type, p_user_id, v_action,
    p_confidence, p_reason, ARRAY[p_reason]
  );

  -- Si action sévère, créer un signalement
  IF v_action IN ('reject', 'quarantined') THEN
    INSERT INTO reports (reporter_id, reported_user_id, content_type, content_id, reason_id, description, status)
    VALUES (
      '00000000-0000-0000-0000-000000000000', -- Système
      p_user_id,
      p_content_type,
      p_content_id,
      (SELECT id FROM report_reasons WHERE code = 'other' LIMIT 1),
      'Signalé automatiquement - ' || p_reason,
      'pending'
    ) RETURNING id INTO v_report_id;
  END IF;

  RETURN v_report_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;