-- ============================================================
-- SCHÉMA GÉNÉRATEUR MANGA / STYLES MANGAS
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_manga_styles (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  name TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  mangaka TEXT NOT NULL,
  description TEXT,
  model_owner TEXT NOT NULL DEFAULT 'stability-ai',
  model_name TEXT NOT NULL DEFAULT 'sdxl',
  model_version TEXT NOT NULL,
  prompt_template TEXT NOT NULL,
  negative_prompt TEXT DEFAULT '',
  width INTEGER DEFAULT 1024,
  height INTEGER DEFAULT 1024,
  num_inference_steps INTEGER DEFAULT 30,
  guidance_scale DECIMAL(4,2) DEFAULT 7.0,
  style_tags TEXT[] DEFAULT '{}',
  sample_image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  generation_count INTEGER DEFAULT 0,
  lora_url TEXT,
  lora_scale DECIMAL(3,2) DEFAULT 0.8,
  training_status TEXT DEFAULT 'untrained' CHECK (training_status IN ('untrained', 'collecting', 'training', 'ready', 'failed')),
  reference_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_manga_styles_slug ON ai_manga_styles(slug);
CREATE INDEX IF NOT EXISTS idx_manga_styles_active ON ai_manga_styles(is_active);

CREATE TABLE IF NOT EXISTS ai_generations (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  style_id BIGINT REFERENCES ai_manga_styles(id),
  prompt TEXT NOT NULL,
  image_url TEXT NOT NULL,
  is_liked BOOLEAN DEFAULT false,
  likes_count INTEGER DEFAULT 0,
  metadata JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_generations_user ON ai_generations(user_id);
CREATE INDEX IF NOT EXISTS idx_generations_style ON ai_generations(style_id);
CREATE INDEX IF NOT EXISTS idx_generations_liked ON ai_generations(is_liked);

ALTER TABLE ai_manga_styles ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_generations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public read manga styles"
  ON ai_manga_styles FOR SELECT
  USING (true);

CREATE POLICY "Users can insert own generations"
  ON ai_generations FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view own generations"
  ON ai_generations FOR SELECT
  USING (auth.uid() = user_id);

-- Seed data
INSERT INTO ai_manga_styles (name, slug, mangaka, description, model_version, prompt_template, negative_prompt, width, height, style_tags) VALUES

('Bleach', 'tite-kubo', 'Tite Kubo',
'Style dynamique et élégant de Tite Kubo (Bleach) : traits acérés, personnages stylés, poses dramatiques, designs de mode élaborés.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, 1girl, bleach manga style by tite kubo, sharp bold ink lines, detailed eyes, {prompt}, dynamic pose, fashion-forward character design, dramatic composition, black and white manga with subtle color accents',
'photorealistic, 3d, western comic, rough sketch, unfinished, ugly, deformed, blurry',
1024, 1024,
ARRAY['shonen', 'action', 'stylish', 'dramatic']),

('One Piece', 'eiichiro-oda', 'Eiichiro Oda',
'Style expressif et aventureux d''Eiichiro Oda (One Piece) : proportions exagérées, visages ultra-expressifs, designs uniques.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, 1boy, one piece manga style by eiichiro oda, extremely expressive face, exaggerated proportions, {prompt}, dynamic adventure pose, bold outlines, unique character design, shonen manga, straw hat pirate theme, rubbery movement',
'realistic proportions, dark and gritty, minimalist, horror, realistic face, thin body',
1024, 1024,
ARRAY['shonen', 'adventure', 'expressive', 'exaggerated']),

('Berserk', 'kentaro-miura', 'Kentaro Miura',
'Style sombre et ultra-détaillé de Kentaro Miura (Berserk) : hachures croisées, médiéval-fantastique gothique, ambiance tragique.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, kentaro miura berserk manga style, incredibly detailed cross-hatching, dark medieval fantasy, gothic architecture, {prompt}, intricate armor details, dramatic chiaroscuro, heavy ink work, dark seinen manga, epic tragic atmosphere',
'bright colors, cartoon, simple lines, chibi, cute, happy, simple shading',
1024, 768,
ARRAY['seinen', 'dark fantasy', 'detailed', 'gothic']),

('Naruto', 'masashi-kishimoto', 'Masashi Kishimoto',
'Style ninja dynamique de Masashi Kishimoto (Naruto) : coiffures distinctives, bandeaux, sceaux, actions de combat intenses.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, 1boy, naruto manga style by masashi kishimoto, dynamic ninja action pose, distinctive spiky hair, ninja headband, {prompt}, hand signs, strong facial expression, detailed eyes, shonen manga, wind effects',
'realistic, muted colors, simple backgrounds, horror, mecha',
1024, 1024,
ARRAY['shonen', 'ninja', 'action', 'dynamic']),

('Dragon Ball', 'akira-toriyama', 'Akira Toriyama',
'Style iconique d''Akira Toriyama (Dragon Ball) : lignes nettes, personnages musclés, cheveux hérissés, aura énergétique.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, 1boy, dragon ball manga style by akira toriyama, clean bold lines, muscular character design, spiky hair, {prompt}, bright vibrant colors, dynamic flying pose, energy aura, battle shonen manga, martial arts',
'realistic proportions, dark, horror, detailed soft shading, thin body, sad',
1024, 1024,
ARRAY['shonen', 'martial arts', 'action', 'iconic']),

('Hunter × Hunter', 'yoshihiro-togashi', 'Yoshihiro Togashi',
'Style varié de Yoshihiro Togashi (HxH, Yu Yu Hakusho) : designs uniques, textures détaillées, créatures originales.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, 1boy, hunter x hunter manga style by yoshihiro togashi, unique character design, detailed textures, varied line weight, {prompt}, expressive eyes, nen aura effects, dynamic composition, adventure shonen manga',
'simple art, mecha, horror, romantic, chibi, generic anime style',
1024, 1024,
ARRAY['shonen', 'adventure', 'unique', 'tactical']),

('Junji Ito', 'junji-ito', 'Junji Ito',
'Style horrifique méticuleux de Junji Ito : détails obsessionnels, corps humains tordus, spirales, beauté mêlée d''effroi.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, junji ito manga art style, meticulous detail, unsettling horror atmosphere, {prompt}, intricate spiral patterns, body horror, realistic detailed backgrounds, beautiful yet terrifying, psychological horror, black and white manga',
'happy, bright colors, cartoon, cute, simple, action pose, shonen, romance',
768, 1024,
ARRAY['horror', 'psychological', 'detailed', 'dark']),

('CLAMP', 'clamp', 'CLAMP',
'Style élégant et raffiné de CLAMP (Cardcaptor Sakura, Tsubasa) : longs membres fins, costumes détaillés, ambiance onirique.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, 1girl, clamp manga art style, elegant beautiful character design, long flowing limbs, detailed stylish costumes, {prompt}, delicate linework, shojo manga aesthetics, large expressive eyes, ethereal dreamy atmosphere, magical girl vibe',
'rough sketch, thick messy lines, action shonen, horror, realistic proportions, buff characters',
1024, 1024,
ARRAY['shojo', 'magical', 'elegant', 'ethereal'])

ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  prompt_template = EXCLUDED.prompt_template,
  negative_prompt = EXCLUDED.negative_prompt,
  style_tags = EXCLUDED.style_tags;
