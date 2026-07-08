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
'Style dynamique et élégant de Tite Kubo (Bleach) : traits acérés au sumi, personnages stylisés en noir et blanc, découpes dramatiques, designs de mode Avant-garde japonaise, ambiances spirituelles shinto.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, bleach manga style by tite kubo, sharp sumi ink linework, dynamic high-contrast shading, dramatic kimono and shinigami uniform designs, {prompt}, bold black-white compositions, spiritual themes, avant-garde fashion, intense emotional expression, action lines, screen tone textures, elegant character silhouettes',
'photorealistic, 3d rendering, western comic inking, rough unfinished sketch, deformed anatomy, blurry details, muted flat colors, generic anime',
1024, 1024,
ARRAY['shonen', 'action', 'stylish', 'dramatic', 'supernatural']),

('One Piece', 'eiichiro-oda', 'Eiichiro Oda',
'Style expressif et aventureux d''Eiichiro Oda (One Piece) : visages hyper-expressifs style Gum-Gum, proportions héroïques exagérées, designs de personnages farfelus, décors maritimes détaillés.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, one piece manga style by eiichiro oda, hyper-expressive facial reactions, exaggerated heroic proportions, bold clean outlines, {prompt}, rubbery stretchy dynamic poses, detailed maritime backgrounds, unique whimsical character designs, large emotional eyes, shonen action lines, adventure atmosphere, sunny vibrant mood',
'realistic proportions, dark gritty atmosphere, minimalist style, horror elements, thin frail body type, muted colors, sad expression',
1024, 1024,
ARRAY['shonen', 'adventure', 'expressive', 'exaggerated', 'whimsical']),

('Berserk', 'kentaro-miura', 'Kentaro Miura',
'Style dark fantasy médiéval ultra-détaillé de Kentaro Miura (Berserk) : hachures croisées minutieuses, architecture gothique vertigineuse, armures biomécaniques, tragédie épique au clair-obscur.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, berserk manga style by kentaro miura, incredibly intricate cross-hatching and screentone, dark medieval fantasy world, gothic cathedral architecture, {prompt}, detailed plate armor with organic designs, dramatic chiaroscuro lighting, heavy ink work, epic tragic composition, muscular heroic figures, supernatural horror elements, seinen dark fantasy atmosphere',
'bright cheerful colors, cartoon chibi style, simple linework, cute happy expressions, soft shading, modern setting, romantic comedy',
1024, 768,
ARRAY['seinen', 'dark fantasy', 'detailed', 'gothic', 'tragic']),

('Naruto', 'masashi-kishimoto', 'Masashi Kishimoto',
'Style ninja dynamique de Masashi Kishimoto (Naruto) : cheveux hérissés iconiques, bandeaux ninjas, sceaux manus, combat ninja acrobatique, ambiances japonaises féodales mêlées de moderne.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, naruto manga style by masashi kishimoto, dynamic ninja action combat poses, distinctive spiky character hairstyles, ninja headbands and flak jackets, {prompt}, hand signs for jutsu, intense battle expressions, detailed eye designs, wind and motion effects, shonen manga paneling, traditional japanese architecture elements, strong friendship themes',
'realistic muted colors, plain simple backgrounds, mecha robots, horror gore, sad depressed mood, static boring pose',
1024, 1024,
ARRAY['shonen', 'ninja', 'action', 'dynamic', 'martial']),

('Dragon Ball', 'akira-toriyama', 'Akira Toriyama',
'Style iconique d''Akira Toriyama (Dragon Ball) : lignes nettes sans bavure, personnages musclés aux proportions héroïques, cheveux hérissés iconiques, auras énergétiques flamboyantes, décors fantastiques.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, dragon ball manga style by akira toriyama, clean crisp bold ink lines, muscular heroic character proportions, iconic spiky anime hair, {prompt}, dynamic fighting aerial poses, glowing energy aura effects, bright vibrant color palette, martial arts battle composition, flying and ki blast action, shonen tournament atmosphere, determined expressions',
'realistic human proportions, dark horror atmosphere, detailed soft shading, thin weak body type, sad crying expression, muted desaturated colors',
1024, 1024,
ARRAY['shonen', 'martial arts', 'action', 'iconic', 'energetic']),

('Hunter × Hunter', 'yoshihiro-togashi', 'Yoshihiro Togashi',
'Style caméléon de Yoshihiro Togashi (HxH, Yu Yu Hakusho) : design unique par arc narratif, textures variées passant du simple au complexe, créatures originales, nen et pouvoirs tactiques.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, hunter x hunter manga style by yoshihiro togashi, unique character designs per arc, varied artistic texturing, {prompt}, nen aura ability effects, tactical battle composition, expressive eye designs, diverse creature designs, shonen adventure atmosphere, friends on a journey, card game and fighting elements',
'simple generic art, mecha robots, romantic shojo, horror body horror, chibi super deformed, gore, realistic style',
1024, 1024,
ARRAY['shonen', 'adventure', 'unique', 'tactical', 'versatile']),

('Junji Ito', 'junji-ito', 'Junji Ito',
'Style horrifique obsessionnel de Junji Ito : détails hyperréalistes malsains, corps humains distordus en spirales, beauté troublante mêlée d''effroi cosmique, décors réalistes rendus cauchemardesques.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, junji ito horror manga art style, obsessive meticulous realistic detail, unsettling psychological horror atmosphere, {prompt}, intricate spiral and pattern motifs, body horror and distortion, photorealistic detailed backgrounds, beautiful yet terrifying subjects, cosmic horror elements, black and white ink work, claustrophobic composition, dread inducing',
'happy joyful mood, bright vivid colors, cartoon cute style, action shonen pose, romantic scene, simple background, clean safe imagery',
768, 1024,
ARRAY['horror', 'psychological', 'detailed', 'dark', 'cosmic']),

('CLAMP', 'clamp', 'CLAMP',
'Style shojo élégant du collectif CLAMP (Cardcaptor Sakura, Tsubasa) : membres longs et fins stylisés, costumes extravagants aux couches multiples, ambiance onirique et romantique, ligne claire délicate.',
'39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b',
'masterpiece, best quality, clamp manga art style, elegant beautiful character design with long slender limbs, elaborate multi-layered costumes, {prompt}, delicate fine linework, shojo romantic aesthetics, large expressive sparkling eyes, flowing hair and fabric, ethereal dreamy atmosphere, magical girl transformation vibes, celestial and fantasy backgrounds, soft beautiful compositions',
'rough sketchy lines, thick messy ink, action shonen violence, horror gore, realistic body proportions, buff muscular characters, modern casual clothes',
1024, 1024,
ARRAY['shojo', 'magical', 'elegant', 'ethereal', 'romantic'])

ON CONFLICT (slug) DO UPDATE SET
  name = EXCLUDED.name,
  description = EXCLUDED.description,
  prompt_template = EXCLUDED.prompt_template,
  negative_prompt = EXCLUDED.negative_prompt,
  style_tags = EXCLUDED.style_tags;
