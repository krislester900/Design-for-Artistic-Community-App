-- ==========================================================
-- Schéma : Collaborations artistiques
-- ==========================================================

CREATE TABLE IF NOT EXISTS collaboration_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  category TEXT NOT NULL,
  cover_image_url TEXT,
  roles TEXT[] NOT NULL DEFAULT '{}',
  max_collaborators INT NOT NULL DEFAULT 5,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
  is_open BOOLEAN NOT NULL DEFAULT true,
  tags TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_collab_creator ON collaboration_projects(creator_id);
CREATE INDEX IF NOT EXISTS idx_collab_status ON collaboration_projects(status);
CREATE INDEX IF NOT EXISTS idx_collab_category ON collaboration_projects(category);

-- Candidatures
CREATE TABLE IF NOT EXISTS collaboration_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES collaboration_projects(id) ON DELETE CASCADE,
  applicant_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  message TEXT,
  portfolio_url TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(project_id, applicant_id)
);

-- Contributeurs
CREATE TABLE IF NOT EXISTS collaboration_contributors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES collaboration_projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(project_id, user_id)
);

-- Messages du projet
CREATE TABLE IF NOT EXISTS collaboration_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES collaboration_projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  attachment_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Fichiers partagés
CREATE TABLE IF NOT EXISTS collaboration_files (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES collaboration_projects(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  file_url TEXT NOT NULL,
  file_name TEXT NOT NULL,
  file_size INT NOT NULL DEFAULT 0,
  file_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE collaboration_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaboration_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaboration_contributors ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaboration_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE collaboration_files ENABLE ROW LEVEL SECURITY;

CREATE POLICY "collab_select" ON collaboration_projects FOR SELECT USING (true);
CREATE POLICY "collab_insert" ON collaboration_projects FOR INSERT WITH CHECK (creator_id = auth.uid());
CREATE POLICY "collab_update" ON collaboration_projects FOR UPDATE
  USING (creator_id = auth.uid() OR auth.uid() IN (SELECT user_id FROM collaboration_contributors WHERE project_id = id));

CREATE POLICY "applications_select" ON collaboration_applications FOR SELECT
  USING (applicant_id = auth.uid() OR auth.uid() IN (SELECT creator_id FROM collaboration_projects WHERE id = project_id));
CREATE POLICY "applications_insert" ON collaboration_applications FOR INSERT WITH CHECK (applicant_id = auth.uid());
CREATE POLICY "applications_update" ON collaboration_applications FOR UPDATE
  USING (auth.uid() IN (SELECT creator_id FROM collaboration_projects WHERE id = project_id));

CREATE POLICY "contributors_select" ON collaboration_contributors FOR SELECT USING (true);
CREATE POLICY "messages_select" ON collaboration_messages FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM collaboration_contributors WHERE project_id = project_id));
CREATE POLICY "messages_insert" ON collaboration_messages FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT user_id FROM collaboration_contributors WHERE project_id = project_id));

CREATE POLICY "files_select" ON collaboration_files FOR SELECT
  USING (auth.uid() IN (SELECT user_id FROM collaboration_contributors WHERE project_id = project_id));
CREATE POLICY "files_insert" ON collaboration_files FOR INSERT
  WITH CHECK (auth.uid() IN (SELECT user_id FROM collaboration_contributors WHERE project_id = project_id));