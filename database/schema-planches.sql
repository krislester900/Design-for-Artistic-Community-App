-- ============================================================
-- SCHÉMA GÉNÉRATEUR DE PLANCHE MANGA
-- Planches multi-cases avec découpage, composition et rendu SDXL
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_planche_layouts (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  slug TEXT NOT NULL UNIQUE,
  name TEXT NOT NULL,
  description TEXT,
  panel_count INTEGER NOT NULL,
  thumbnail TEXT,
  layout_data JSONB NOT NULL,
  tags TEXT[] DEFAULT '{}',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_planches (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  style_slug TEXT NOT NULL REFERENCES ai_manga_styles(slug),
  layout_slug TEXT REFERENCES ai_planche_layouts(slug),
  title TEXT NOT NULL DEFAULT '',
  page_number INTEGER DEFAULT 1,
  total_pages INTEGER DEFAULT 1,
  scene_prompt TEXT NOT NULL,
  characters JSONB DEFAULT '[]',
  status TEXT DEFAULT 'generating' CHECK (status IN ('generating', 'completed', 'failed')),
  image_url TEXT,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS ai_planche_panels (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  planche_id BIGINT NOT NULL REFERENCES ai_planches(id) ON DELETE CASCADE,
  panel_index INTEGER NOT NULL,
  x_pct DECIMAL(5,2) NOT NULL,
  y_pct DECIMAL(5,2) NOT NULL,
  width_pct DECIMAL(5,2) NOT NULL,
  height_pct DECIMAL(5,2) NOT NULL,
  scene_description TEXT NOT NULL DEFAULT '',
  dialogue TEXT DEFAULT '',
  narration TEXT DEFAULT '',
  prompt_sdxl TEXT DEFAULT '',
  image_url TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'generating', 'completed', 'failed')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(planche_id, panel_index)
);

CREATE INDEX IF NOT EXISTS idx_planches_user ON ai_planches(user_id);
CREATE INDEX IF NOT EXISTS idx_planches_style ON ai_planches(style_slug);
CREATE INDEX IF NOT EXISTS idx_planche_panels_planche ON ai_planche_panels(planche_id);

ALTER TABLE ai_planches ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_planche_panels ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_planche_layouts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can CRUD own planches"
  ON ai_planches FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own panels"
  ON ai_planche_panels FOR SELECT
  USING (planche_id IN (SELECT id FROM ai_planches WHERE user_id = auth.uid()));

CREATE POLICY "Users can insert own panels"
  ON ai_planche_panels FOR INSERT
  WITH CHECK (planche_id IN (SELECT id FROM ai_planches WHERE user_id = auth.uid()));

CREATE POLICY "Public read planche layouts"
  ON ai_planche_layouts FOR SELECT
  USING (true);

INSERT INTO ai_planche_layouts (slug, name, description, panel_count, layout_data, tags) VALUES

('splash', 'Page pleine (Splash)',
 'Une grande illustration unique occupant toute la page. Pour scènes d''ouverture, climax ou révélations.',
 1, '{"panels": [{"x":0,"y":0,"w":100,"h":100,"label":"Splash"}]}',
 ARRAY['splash', 'pleine-page', 'climax']),

('4-panel', 'Grille 2×2 standard',
 'Découpage classique en 4 cases égales (2×2). Ryhtme narratif équilibré pour scènes dialoguées.',
 4, '{"panels": [{"x":0,"y":0,"w":50,"h":50,"label":"Case 1"},{"x":50,"y":0,"w":50,"h":50,"label":"Case 2"},{"x":0,"y":50,"w":50,"h":50,"label":"Case 3"},{"x":50,"y":50,"w":50,"h":50,"label":"Case 4"}]}',
 ARRAY['grille', '4-cases', 'standard']),

('5-panel-hero', 'Héros + 4 cases',
 'Grande case supérieure (100%×50%) + 4 petites en bas (2×2). Met en valeur le décor ou le personnage principal.',
 5, '{"panels": [{"x":0,"y":0,"w":100,"h":50,"label":"Case héro"},{"x":0,"y":50,"w":50,"h":25,"label":"Case 2"},{"x":50,"y":50,"w":50,"h":25,"label":"Case 3"},{"x":0,"y":75,"w":50,"h":25,"label":"Case 4"},{"x":50,"y":75,"w":50,"h":25,"label":"Case 5"}]}',
 ARRAY['hero', '5-cases', 'introduction']),

('6-panel', 'Grille 3×2',
 '6 cases égales en 3 colonnes × 2 rangées. Idéal pour scènes d''action rapide avec beaucoup d''étapes.',
 6, '{"panels": [{"x":0,"y":0,"w":33.33,"h":50,"label":"Case 1"},{"x":33.33,"y":0,"w":33.33,"h":50,"label":"Case 2"},{"x":66.66,"y":0,"w":33.33,"h":50,"label":"Case 3"},{"x":0,"y":50,"w":33.33,"h":50,"label":"Case 4"},{"x":33.33,"y":50,"w":33.33,"h":50,"label":"Case 5"},{"x":66.66,"y":50,"w":33.33,"h":50,"label":"Case 6"}]}',
 ARRAY['grille', '6-cases', 'action']),

('vertical-tris', 'Triptyque vertical',
 '3 bandes verticales (large, étroite, large) en 3 rangées. RYthme narratif descendant, influence gekiga.',
 3, '{"panels": [{"x":0,"y":0,"w":100,"h":40,"label":"Bande 1"},{"x":15,"y":40,"w":70,"h":25,"label":"Bande 2"},{"x":0,"y":65,"w":100,"h":35,"label":"Bande 3"}]}',
 ARRAY['vertical', '3-cases', 'cinematic']),

('4-panel-bento', 'Composition Bentō asymétrique',
 'Disposition asymétrique inspirée du bentō : grande case à gauche + 3 petites à droite. Pour révélation + réaction.',
 4, '{"panels": [{"x":0,"y":0,"w":55,"h":100,"label":"Grande case"},{"x":55,"y":0,"w":45,"h":33,"label":"Réaction 1"},{"x":55,"y":33,"w":45,"h":33,"label":"Réaction 2"},{"x":55,"y":66,"w":45,"h":34,"label":"Réaction 3"}]}',
 ARRAY['asymétrique', 'bento', '4-cases', 'dramatique']),

('6-panel-montage', 'Montage cinématique 2×3',
 '2 grandes lignes horizontales avec cases de tailles variables. Imite le montage cinéma : plans larges alternés avec plans serrés.',
 6, '{"panels": [{"x":0,"y":0,"w":60,"h":50,"label":"Plan large"},{"x":60,"y":0,"w":40,"h":50,"label":"Plan serré"},{"x":0,"y":50,"w":35,"h":25,"label":"Détail"},{"x":35,"y":50,"w":30,"h":25,"label":"Action"},{"x":65,"y":50,"w":35,"h":25,"label":"Réaction"},{"x":35,"y":75,"w":65,"h":25,"label":"Plan large fin"}]}',
 ARRAY['cinéma', 'montage', '6-cases', 'dynamique']),

('splash-bottom', 'Splash + bande inférieure',
 'Grande case (100%×70%) + 3 cases en bande horizontale en bas (30%). Pour scène dramatique avec conséquences.',
 4, '{"panels": [{"x":0,"y":0,"w":100,"h":70,"label":"Splash dramatique"},{"x":0,"y":70,"w":33.33,"h":30,"label":"Conséquence 1"},{"x":33.33,"y":70,"w":33.33,"h":30,"label":"Conséquence 2"},{"x":66.66,"y":70,"w":33.33,"h":30,"label":"Conséquence 3"}]}',
 ARRAY['splash', '4-cases', 'dramatique', 'climax'])

ON CONFLICT (slug) DO NOTHING;
