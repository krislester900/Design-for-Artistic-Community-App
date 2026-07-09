-- ============================================================
-- SEED : Extension ontologie Dessin & Planche de Manga
-- Ajoute des concepts techniques pour l'adaptation au dessin
-- et la composition de planches de manga
-- ============================================================

-- ============================================================
-- 1. TAXONOMIE (nouveaux nœuds dans l'arbre)
-- ============================================================
INSERT INTO ontology_taxonomy (slug, label, level, path, order_index)
SELECT * FROM (VALUES
  -- Sous-catégories Dessin (niveau 3 sous dessin)
  ('dessin-croquis',    'Croquis & Esquisses',   3, ARRAY['art','art-visuel','dessin','dessin-croquis'],    1),
  ('dessin-figure',     'Dessin de figure',       3, ARRAY['art','art-visuel','dessin','dessin-figure'],     2),
  ('dessin-anatomique', 'Dessin anatomique',      3, ARRAY['art','art-visuel','dessin','dessin-anatomique'], 3),
  ('dessin-technique',  'Dessin technique',       3, ARRAY['art','art-visuel','dessin','dessin-technique'],  4),

  -- Sous-catégories BD/Manga (niveau 2-3)
  ('decoupage',         'Découpage & Storyboard', 3, ARRAY['art','bd-manga','storyboard','decoupage'], 1),
  ('planche',           'Composition de planche', 2, ARRAY['art','bd-manga','planche'],                1),
  ('encrage',           'Encrage & Tramage',      2, ARRAY['art','bd-manga','encrage'],                2),
  ('narration-vm',      'Narration visuelle',     2, ARRAY['art','bd-manga','narration-vm'],           3)
) AS v(slug, label, level, path, order_index)
WHERE NOT EXISTS (SELECT 1 FROM ontology_taxonomy t WHERE t.slug = v.slug);

-- ============================================================
-- 2. CONCEPTS DESSIN
-- ============================================================
INSERT INTO ontology_concepts (slug, label, description, category, icon, difficulty, metadata)
SELECT * FROM (VALUES
  -- --- TECHNIQUES DE DESSIN ---
  ('trait', 'Trait & Ligne',
   E'Fondement du dessin. Qualité du trait : pression, vitesse, épaisseur, fluidité. '
   'Un trait peut être affirmé, hachuré, continu, brisé, calligraphique.',
   'technique', '✏️', 'debutant',
   '{"related_tags":["lineart","contour","calligraphie"],"styles":["manga","sketch","realism"]}'),

  ('hachure', 'Hachure & Cross-hatching',
   E'Technique d''ombrage par lignes parallèles ou croisées. Plus les lignes sont serrées, '
   'plus la zone est sombre. Fondamentale en gravure, encre et manga.',
   'technique', '〰️', 'intermediaire',
   '{"related_tags":["shading","ink","stippling","hatching"],"density_range":"60-300lpi"}'),

  ('ombrage', 'Ombrage & Modelé',
   E'Rendu des volumes par la lumière et l''ombre. Comprend les zones d''ombre propre, '
   'd''ombre portée, de demi-teinte et de reflet.',
   'technique', '🌓', 'intermediaire',
   '{"related_tags":["shading","volume","light","shadow","chiaroscuro"]}'),

  ('gesture-drawing', 'Gesture Drawing',
   E'Technique de croquis rapide visant à capturer le mouvement, le geste et l''énergie '
   'd''un sujet en quelques secondes. Essentiel pour les poses dynamiques de manga.',
   'technique', '🏃', 'debutant',
   '{"related_tags":["croquis","movement","pose","dynamic","action"],"duration_seconds":"30-120"}'),

  ('anatomie-artistique', 'Anatomie Artistique',
   E'Étude de la structure du corps humain adaptée au dessin. Comprend les proportions, '
   'les masses musculaires, le squelette et les proportions du visage.',
   'technique', '🦴', 'avance',
   '{"related_tags":["anatomy","proportions","muscles","skeleton","figure"]}'),

  ('proportion', 'Proportion & Mesure',
   E'Systèmes de proportions pour le dessin de figure : canon 8 têtes, 7 têtes (manga), '
   'proportions du visage, ratios du corps.',
   'technique', '📏', 'intermediaire',
   '{"related_tags":["canon","head-ratio","measurement","golden-ratio"]}'),

  ('croquis', 'Croquis & Esquisse',
   E'Dessin préparatoire rapide. Capture l''essence d''un sujet avant le rendu final. '
   'Base de tout processus créatif en BD et manga.',
   'technique', '✍️', 'debutant',
   '{"related_tags":["sketch","draft","rough","thumbnails"]}'),

  ('encaissement', 'Encrage au trait',
   E'Technique de reprise du crayonné à l''encre. Exige un trait sûr et définitif. '
   'Comprend le choix de la plume, du pinceau ou du stylo technique.',
   'technique', '🖊️', 'avance',
   '{"related_tags":["inking","lineart","pen","brush","fineliner"]}'),

  -- --- THÉORIES DU DESSIN ---
  ('valeur-tonale', 'Valeur Tonale',
   E'Échelle des gris du blanc au noir. Indépendante de la couleur, elle structure '
   'le contraste, le volume et la profondeur dans un dessin.',
   'theorie', '🔲', 'debutant',
   '{"related_tags":["value","tonal","grayscale","shading","chiaroscuro"]}'),

  ('contraste', 'Contraste',
   E'Opposition entre éléments (clair/foncé, grand/petit, lisse/texturé). '
   'Le contraste crée l''impact visuel et guide l''œil dans une planche.',
   'theorie', '⚫', 'debutant',
   '{"related_tags":["contrast","emphasis","focal-point","composition"]}'),

  ('perspective-atmospherique', 'Perspective Atmosphérique',
   E'Effet de profondeur par la dégradation des contrastes et des couleurs avec '
   'l''éloignement. Les lointains sont plus pâles, plus bleutés, moins détaillés.',
   'theorie', '🌄', 'intermediaire',
   '{"related_tags":["depth","aerial-perspective","background","landscape"]}'),

  ('composition-dynamique', 'Composition Dynamique',
   E'Organisation des éléments pour créer du mouvement, de la tension ou de l''équilibre. '
   'Diagonales, lignes de force, règle des tiers, nombre d''or.',
   'technique', '📐', 'intermediaire',
   '{"related_tags":["composition","dynamic","golden-ratio","rule-of-thirds"]}'),

  -- --- MEDIUMS DE DESSIN ---
  ('crayon-graphite', 'Crayon Graphite',
   E'Crayon à base de graphite, de H (dur) à B (tendre). Le 2B est le standard '
   'pour le croquis, le 6B pour les ombres profondes.',
   'medium', '✏️', 'debutant',
   '{"related_tags":["pencil","graphite","hb","sketch","shading"],"hardness_range":"9H-9B"}'),

  ('fusain', 'Fusain',
   E'Bâton de bois carbonisé pour le dessin. Permet des noirs profonds et des '
   'effets de matière. Idéal pour les études d''ombrage et les nus.',
   'medium', '🟤', 'intermediaire',
   '{"related_tags":["charcoal","shading","mass-drawing","gesture"]}'),

  ('encre-chine', 'Encre de Chine',
   E'Encre noire indélébile à base de noir de fumée. Utilisée en manga, encre '
   'et calligraphie. Se travaille au pinceau, à la plume ou au stylo.',
   'medium', '🖌️', 'intermediaire',
   '{"related_tags":["ink","sumi","india-ink","brush","pen"],"types":["liquide","baton","pastille"]}'),

  ('pierre-noire', 'Pierre Noire',
   E'Roche tendre (schiste carbonifère) utilisée pour le dessin. Donne des traits '
   'gras et veloutés. Prisée par les dessinateurs classiques et de BD.',
   'medium', '⛰️', 'avance',
   '{"related_tags":["black-stone","chalk","classical-drawing","portrait"]}'),

  ('stylo-technique', 'Stylo Technique',
   E'Stylo à pointe tubulaire (0.05-2.0mm) à encre waterproof. Utilisé en manga '
   'et illustration pour un trait régulier et précis.',
   'medium', '🖊️', 'debutant',
   '{"related_tags":["fineliner","technical-pen","manga","inking"],"tip_sizes_mm":"0.05-2.0"}'),

  ('marqueur', 'Marqueur & Feutre',
   E'Marqueur à alcool (Copic, Promarker) ou à eau. Permet des aplats de couleur '
   'et des dégradés rapides. Très utilisé en concept art et manga couleur.',
   'medium', '🖍️', 'intermediaire',
   '{"related_tags":["marker","copic","alcohol-marker","concept-art"]}'),

  ('pastel-sec', 'Pastel Sec',
   E'Bâton de pigment pur aggloméré. Produit des couleurs vives et un rendu velouté. '
   'Se fixe après application pour éviter l''effacement.',
   'medium', '🖍️', 'avance',
   '{"related_tags":["pastel","soft-pastel","portrait","landscape"]}'),

  -- --- OUTILS DE DESSIN ---
  ('carnet-croquis', 'Carnet de Croquis',
   E'Carnet à spirale ou relié pour le dessin sur le vif. Le grammage du papier '
   '(90-200g/m²) détermine les techniques utilisables.',
   'outil', '📓', 'debutant',
   '{"related_tags":["sketchbook","journal","moleskine","field-drawing"],"paper_weights":"90-200gsm"}'),

  ('gomme', 'Gomme & Estompe',
   E'Outils de correction et de modelé. Gomme classique, mie de pain (pour '
   'éclaircir), gomme électrique. L''estompe étale le fusain/graphite.',
   'outil', '🧹', 'debutant',
   '{"related_tags":["eraser","kneaded-eraser","blending-stump","tortillon"]}'),

  ('tablette-dessin', 'Tablette Graphique',
   E'Périphérique de dessin numérique avec ou sans écran. Surface sensible à la '
   'pression (2048-8192 niveaux). Standard du dessin manga moderne.',
   'outil', '💻', 'intermediaire',
   '{"related_tags":["graphic-tablet","wacom","ipad","procreate","clip-studio"],"pressure_levels":"2048-8192"}'),

  -- --- FORMATS DE DESSIN ---
  ('croquis-rapide', 'Croquis Rapide',
   E'Dessin exécuté en un temps limité (30s-5min). Vise à capturer l''essentiel : '
   'geste, proportion, attitude. Base des exercices d''échauffement.',
   'format', '⏱️', 'debutant',
   '{"related_tags":["quick-sketch","gesture","thumbnail","warmup"],"duration_seconds":"30-300"}'),

  ('portrait-dessin', 'Portrait Dessiné',
   E'Représentation d''une personne mettant l''accent sur le visage et l''expression. '
   'Comprend les proportions du visage, les plans, les valeurs.',
   'format', '👤', 'intermediaire',
   '{"related_tags":["portrait","face","expression","likeness","manga-face"]}'),

  ('etude-anatomique', 'Étude Anatomique',
   E'Dessin d''étude du corps humain : écorché, squelette, muscles, proportions. '
   'Base indispensable pour le dessin de personnage manga réaliste.',
   'format', '🦾', 'avance',
   '{"related_tags":["anatomy","ecorche","muscle-study","skeleton","figure-drawing"]}')
) AS v(slug, label, description, category, icon, difficulty, metadata)
WHERE NOT EXISTS (SELECT 1 FROM ontology_concepts c WHERE c.slug = v.slug);

-- ============================================================
-- 3. CONCEPTS PLANCHE DE MANGA
-- ============================================================
INSERT INTO ontology_concepts (slug, label, description, category, icon, difficulty, metadata)
SELECT * FROM (VALUES
  -- --- FORMATS DE PLANCHE ---
  ('planche-manga', 'Planche de Manga',
   E'Page de bande dessinée japonaise. Se lit de droite à gauche, de haut en bas. '
   'Composée de koma (cases) organisés en gô (bandes) verticales.',
   'format', '📄', 'intermediaire',
   '{"related_tags":["manga-page","layout","b4","original"],"page_sizes":["B4 original","A4 print"],"reading_direction":"right-to-left"}'),

  ('koma', 'Koma / Case de Manga (コマ)',
   E'Unité de base de la narration en manga. Chaque case représente un instant, '
   'un geste, un dialogue. La taille et la forme du koma rythment la lecture.',
   'format', '🔲', 'intermediaire',
   '{"related_tags":["panel","frame","cell","gutter","page-layout"]}'),

  ('double-page', 'Double Page',
   E'Planche s''étalant sur deux pages. Utilisée pour les scènes panoramiques, '
   'les combats épiques ou les révélations. Point central du chapitre.',
   'format', '📖', 'avance',
   '{"related_tags":["spread","panoramic","center-spread","climax"]}'),

  ('page-choc', 'Page Choc (Splash Page)',
   E'Page entière ou presque entièrement occupée par une grande illustration. '
   'Marque un moment clé. En manga, souvent utilisée comme introduction ou climax.',
   'format', '💥', 'intermediaire',
   '{"related_tags":["splash-page","full-page","spread","dramatic","establishing"]}'),

  -- --- TECHNIQUES DE PLANCHE ---
  ('decoupage-manga', 'Découpage / Panel Breakdown',
   E'Art de diviser la page en cases. Détermine le rythme, le flux de lecture '
   'et les points d''emphase. Un bon découpage sert la lisibilité et l''émotion.',
   'technique', '✂️', 'avance',
   '{"related_tags":["grid","panel-layout","flow","timing","decoupage","gutter"]}'),

  ('composition-planche', 'Composition de Planche',
   E'Organisation spatiale des éléments dans la page : équilibre des masses de '
   'noir et blanc, placement des bulles, tailles relatives des cases.',
   'technique', '🌀', 'avance',
   '{"related_tags":["page-composition","black-white-balance","flow","eye-guide"]}'),

  ('rythme-narratif', 'Rythme Narratif',
   E'Tempo de l''histoire créé par la taille et le nombre de cases. '
   'Petites cases → action rapide, tensions. Grandes cases → pause, émotion, impact.',
   'technique', '🎵', 'avance',
   '{"related_tags":["pacing","tempo","rhythm","timing","slow-fast"]}'),

  ('lignes-action', 'Lignes d''Action / Effets (効果線)',
   E'Lignes rayonnantes ou parallèles qui expriment le mouvement, la vitesse, '
   'l''impact ou l''émotion. Appelées aussi "speed lines" ou "action lines".',
   'technique', '💨', 'debutant',
   '{"related_tags":["speed-lines","effect-lines","action-lines","movement","koka-sen"],"types":["straight","curved","burst","flow"]}'),

  ('trame-screentone', 'Trame / Screentone (スクリーントーン)',
   E'Film adhésif tramé collé sur le dessin pour créer des textures, des ombres '
   'ou des dégradés sans hachurer. Remplacée par le tramage numérique.',
   'technique', '🔳', 'intermediaire',
   '{"related_tags":["screentone","tone","screen-tone","shading","texture"],"types":["dot","gradation","texture","pattern","flash","star","cloud"]}'),

  ('tramage-numerique', 'Tramage Numérique',
   E'Application de trames par logiciel (Clip Studio, Photoshop). Permets des '
   'calques de ton, dégradés, motifs vectoriels. Standard du manga moderne.',
   'technique', '💠', 'intermediaire',
   '{"related_tags":["digital-tone","clip-studio","layer-tone","gradation","pattern"]}'),

  ('encrage-manga', 'Encrage Manga (Gペン・丸ペン)',
   E'Technique d''encrage spécifique au manga. Utilise la plume G (G-pen) pour '
   'le trait principal, la plume ronde (maru-pen) pour les détails fins.',
   'technique', '🪶', 'avance',
   '{"related_tags":["inking","g-pen","maru-pen","saji-pen","cabi-pen","manga-ink"],"pen_types":["G-pen","maru-pen","kabura-pen","saji-pen"]}'),

  ('pinceau-manga', 'Pinceau & Brosse',
   E'Pinceau traditionnel japonais ou brosse synthétique pour l''encrage. '
   'Permet un trait expressif avec variation d''épaisseur.',
   'medium', '🖌️', 'avance',
   '{"related_tags":["brush","fude","sumi-brush","ink-wash","expressive-line"]}'),

  ('contraste-noir-blanc', 'Contraste Noir & Blanc',
   E'Gestion des masses de noir et blanc dans la page. Le manga utilise un '
   'contrôle précis des zones noires (bêta, silouettes) pour l''impact visuel.',
   'technique', '⬛', 'intermediaire',
   '{"related_tags":["black-mass","silhouette","chiaroscuro","negative-space","spot-black"]}'),

  ('deformation-expression', 'Déformation Expressive',
   E'Distorsion volontaire des proportions (grandes yeux, têtes larges) pour '
   'l''expressivité. Distinctive du manga, surtout dans les genres comiques et SD.',
   'technique', '😱', 'debutant',
   '{"related_tags":["exaggeration","squash-stretch","expression","sd","chibi"]}'),

  ('decor-arriere-plan', 'Décor & Arrière-plan',
   E'Fond de case qui plante le décor et l''ambiance. En manga, peut être très '
   'détaillé (Katsuhiro Otomo) ou minimaliste (claire-voie, fond blanc).',
   'technique', '🏙️', 'intermediaire',
   '{"related_tags":["background","environment","setting","perspective","cityscape"]}'),

  -- --- NARRATION & GENRES ---
  ('narration-visuelle', 'Narration Visuelle',
   E'Art de raconter une histoire par les images et l''enchaînement des cases. '
   'Le manga excelle dans le "montage" visuel proche du cinéma.',
   'theorie', '🎬', 'intermediaire',
   '{"related_tags":["visual-storytelling","montage","cinematic","flow","reading"]}'),

  ('cliffhanger-page', 'Cliffhanger & Page Turn',
   E'Technique narrative où la dernière case d''une page crée un suspense qui '
   'pousse le lecteur à tourner la page. Essentiel dans les manga chapitre.',
   'technique', '⏯️', 'intermediaire',
   '{"related_tags":["cliffhanger","page-turn","suspense","hook","chapter-end"]}'),

  ('gekiga', 'Gekiga (劇画)',
   E'Style de manga réaliste et adulte, né dans les années 1960. Contraire au '
   'manga enfantin. Traite de sujets sérieux avec un dessin naturaliste.',
   'genre', '🎭', 'avance',
   '{"related_tags":["gekiga","drama","realistic","mature","alternative-manga"],"influenced_by":["cinema-noir","documentary"]}'),

  ('chibi', 'Chibi / Super Déformed (SD)',
   E'Style de représentation où le personnage a une tête surdimensionnée (1:1 '
   'voire 1:2 corps/tête). Utilisé pour l''expressivité comique ou mignonne.',
   'style', '🌟', 'debutant',
   '{"related_tags":["chibi","super-deformed","sd","cute","comical","deformed"],"head_body_ratio":"1:1_to_1:3"}'),

  ('bento-composition', 'Composition "Bentō"',
   E'Principe de composition de planche qui organise les cases comme un bentō : '
   'chaque case a sa place dédiée, l''ensemble forme un tout équilibré.',
   'technique', '🍱', 'intermediaire',
   '{"related_tags":["bento","layout","grid","balance","japanese-aesthetics"]}'),

  ('manga-couleur', 'Manga en Couleur',
   E'Approche moderne du manga en couleur (numérique). Utilise des aplats plats, '
   'des dégradés logiciels et des trames colorées. Différent de l''aquarelle.',
   'technique', '🌈', 'intermediaire',
   '{"related_tags":["digital-color","flat-color","cel-shading","webtoon","anime-style"]}'),

  ('expression-manga', 'Expressions Manga (表情)',
   E'Code graphique des expressions faciales en manga. Yeux en spirale (vertige), '
   'veine (colère), goutte (embarras), nez qui saigne (excitation).',
   'technique', '😊', 'debutant',
   '{"related_tags":["manga-expression","anime-face","comical-face","emotion-icons"],"common_expressions":["spiral-eyes","nose-bleed","sweat-drop","anger-vein","glassy-eyes"]}')
) AS v(slug, label, description, category, icon, difficulty, metadata)
WHERE NOT EXISTS (SELECT 1 FROM ontology_concepts c WHERE c.slug = v.slug);

-- ============================================================
-- 4. RELATIONS
-- ============================================================
-- On insère avec des sous-requêtes pour résoudre les IDs
-- Hiérarchie : est_un
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'est_un', 1.0, e.descr
FROM (VALUES
  ('croquis-rapide',    'croquis',            'Le croquis rapide est un type de croquis'),
  ('etude-anatomique',  'dessin-anatomique',  'L''étude anatomique est une forme de dessin anatomique'),
  ('chibi',             'manga',              'Le style chibi/SD est un sous-genre du manga'),
  ('gekiga',            'manga',              'Le gekiga est un genre de manga réaliste'),
  ('koma',              'planche-manga',      'Le koma est l''unité de base de la planche de manga'),
  ('double-page',       'planche-manga',      'Une double page est un type de planche'),
  ('page-choc',         'planche-manga',      'Une page choc/splash est un type de planche')
) AS e(src, tgt, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'est_un'
);

-- Appartient à (concept → domaine)
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'appartient_a', 1.0, e.descr
FROM (VALUES
  ('trait',             'dessin',             'Le trait est le fondement du dessin'),
  ('hachure',           'dessin',             'La hachure est une technique de dessin'),
  ('ombrage',           'dessin',             'L''ombrage est une technique de dessin'),
  ('gesture-drawing',   'dessin',             'Le gesture drawing est une pratique de dessin'),
  ('croquis',           'dessin',             'Le croquis est une pratique fondamentale du dessin'),
  ('anatomie-artistique','dessin',             'L''anatomie artistique est une discipline du dessin'),
  ('planche-manga',     'bd-manga',           'La planche est le format principal de la BD/manga'),
  ('decoupage-manga',   'planche-manga',      'Le découpage est la technique de composition de planche'),
  ('composition-planche','planche-manga',     'La composition organise les éléments de la planche'),
  ('encrage-manga',     'bd-manga',           'L''encrage est une étape clé de la BD/manga'),
  ('trame-screentone',  'bd-manga',           'La trame/screentone est spécifique à la BD/manga'),
  ('narration-visuelle','bd-manga',           'La narration visuelle est le cœur de la BD/manga')
) AS e(src, tgt, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'appartient_a'
);

-- Contient (concept parent → concept enfant)
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'contient', e.weight, e.descr
FROM (VALUES
  ('valeur-tonale',       'contraste',          1.0, 'La valeur tonale inclut la notion de contraste'),
  ('theorie-couleurs',    'valeur-tonale',      0.6, 'La théorie des couleurs inclut la valeur tonale'),
  ('composition-dynamique','perspective',        0.7, 'La composition dynamique peut intégrer la perspective'),
  ('decoupage-manga',     'rythme-narratif',     1.0, 'Le découpage détermine le rythme narratif'),
  ('decoupage-manga',     'composition-planche', 0.8, 'Le découpage inclut la composition de planche'),
  ('composition-planche', 'contraste-noir-blanc',0.8, 'La composition de planche gère le contraste N&B'),
  ('narration-visuelle',  'cliffhanger-page',    0.7, 'La narration visuelle utilise le cliffhanger'),
  ('narration-visuelle',  'rythme-narratif',     1.0, 'La narration visuelle intègre le rythme narratif'),
  ('anatomie-artistique', 'proportion',          1.0, 'L''anatomie inclut l''étude des proportions'),
  ('expression-manga',    'deformation-expression',0.9,'Les expressions manga utilisent la déformation expressive')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'contient'
);

-- Utilise
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'utilise', e.weight, e.descr
FROM (VALUES
  ('encrage-manga',       'encre-chine',         1.0, 'L''encrage manga utilise l''encre de Chine'),
  ('encrage-manga',       'stylo-technique',     0.7, 'L''encrage moderne utilise aussi le stylo technique'),
  ('encrage-manga',       'pinceau-manga',       0.8, 'L''encrage traditionnel utilise le pinceau'),
  ('hachure',             'stylo-technique',     0.8, 'La hachure se pratique au stylo technique ou à la plume'),
  ('trame-screentone',    'tramage-numerique',   0.9, 'La screentone traditionnelle utilise le tramage numérique comme équivalent moderne'),
  ('manga-couleur',       'tablette-dessin',     0.9, 'Le manga couleur moderne utilise la tablette graphique'),
  ('decor-arriere-plan',  'perspective',         0.9, 'Le dessin de décor utilise la perspective'),
  ('decor-arriere-plan',  'perspective-atmospherique', 0.7, 'Le décor utilise la perspective atmosphérique'),
  ('gesture-drawing',     'carnet-croquis',      0.8, 'Le gesture drawing se pratique dans un carnet de croquis'),
  ('gesture-drawing',     'crayon-graphite',     0.7, 'Le gesture drawing utilise le crayon graphite'),
  ('croquis',             'carnet-croquis',      0.9, 'Le croquis utilise le carnet comme support'),
  ('croquis',             'gomme',               0.5, 'Le croquis utilise la gomme pour les corrections'),
  ('anatomie-artistique', 'etude-anatomique',    0.9, 'L''anatomie artistique utilise l''étude anatomique comme format'),
  ('portrait-dessin',     'expression-manga',    0.7, 'Le portrait dessiné peut utiliser les expressions manga'),
  ('chibi',               'deformation-expression',1.0,'Le style chibi utilise la déformation expressive')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'utilise'
);

-- Requiert
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'requiert', e.weight, e.descr
FROM (VALUES
  ('dessin',              'trait',               1.0, 'Le dessin requiert la maîtrise du trait'),
  ('portrait-dessin',     'proportion',          1.0, 'Le portrait requiert la connaissance des proportions'),
  ('portrait-dessin',     'expression-manga',    0.7, 'Le portrait manga requiert la maîtrise des expressions'),
  ('planche-manga',       'decoupage-manga',     1.0, 'La planche requiert un découpage'),
  ('planche-manga',       'encrage-manga',       0.8, 'La planche finalisée requiert l''encrage'),
  ('ombrage',             'valeur-tonale',       1.0, 'L''ombrage requiert la compréhension de la valeur tonale'),
  ('decoupage-manga',     'narration-visuelle',  1.0, 'Le découpage requiert des bases de narration visuelle'),
  ('manga',               'narration-visuelle',  0.9, 'Le manga requiert la narration visuelle'),
  ('manga',               'planche-manga',       1.0, 'Le manga s''exprime via la planche'),
  ('etude-anatomique',    'anatomie-artistique', 1.0, 'L''étude anatomique requiert des connaissances en anatomie artistique'),
  ('double-page',         'composition-planche', 0.9, 'La double page requiert une composition maîtrisée')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'requiert'
);

-- Influence
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'influence', e.weight, e.descr
FROM (VALUES
  ('manga',               'planche-manga',       1.0, 'Le genre manga influence le format et la composition de ses planches'),
  ('gekiga',              'manga',               0.8, 'Le gekiga a influencé le manga réaliste adulte'),
  ('decoupage-manga',     'rythme-narratif',     0.8, 'Le découpage influence directement le rythme de lecture'),
  ('cinema',              'decoupage-manga',     0.7, 'Le cinéma influence fortement le découpage manga (angles, montage)'),
  ('imagerie-japonaise',  'expression-manga',    0.6, 'L''imagerie traditionnelle japonaise influence les expressions manga'),
  ('manga',               'webtoon',             0.7, 'Le manga a influencé le format webtoon coréen'),
  ('composition-dynamique','composition-planche',0.7, 'La composition dynamique influence la composition de planche')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'influence'
);

-- Similaire à
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'similaire_a', e.weight, e.descr
FROM (VALUES
  ('hachure',             'trame-screentone',    0.6, 'La hachure et la screentone sont deux méthodes d''ombrage'),
  ('planche-manga',       'storyboard',          0.7, 'La planche de manga partage des principes avec le storyboard'),
  ('gesture-drawing',     'croquis-rapide',      0.8, 'Le gesture drawing et le croquis rapide sont très proches'),
  ('narration-visuelle',  'cinema',              0.6, 'La narration visuelle en manga partage des codes avec le cinéma'),
  ('composition-planche', 'composition-dynamique',0.7, 'La composition de planche est une composition dynamique appliquée à la page')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'similaire_a'
);

-- Complimente
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'complimente', e.weight, e.descr
FROM (VALUES
  ('trame-screentone',    'hachure',             0.8, 'La screentone et la hachure se complètent dans l''ombrage manga'),
  ('lignes-action',       'contraste-noir-blanc',0.7, 'Les lignes d''action renforcent le contraste N&B'),
  ('encrage-manga',       'trame-screentone',    0.9, 'L''encrage et le tramage sont complémentaires en manga'),
  ('narration-visuelle',  'controle-du-temps',   0.6, 'La narration complémente la gestion du temps en BD'),
  ('ombre-propre',        'ombre-portee',        0.9, 'Les ombres propres et portées se complètent pour le modelé'),
  ('page-choc',           'double-page',         0.6, 'La page choc et la double page sont des formats complémentaires pour l''impact')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'complimente'
);

-- Précède
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'precede', e.weight, e.descr
FROM (VALUES
  ('croquis',             'encaissement',        1.0, 'Le croquis précède l''encrage dans le processus de création'),
  ('crayon-graphite',     'encre-chine',         0.8, 'Le crayonné précède l''encrage en BD/manga'),
  ('gesture-drawing',     'croquis',             0.7, 'Le gesture drawing précède le croquis détaillé'),
  ('storyboard',          'planche-manga',       0.9, 'Le storyboard précède la réalisation de la planche'),
  ('decoupage-manga',     'encrage-manga',       1.0, 'Le découpage précède l''encrage final')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'precede'
);

-- S'applique à
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 's_applique_a', e.weight, e.descr
FROM (VALUES
  ('valeur-tonale',       'ombrage',             1.0, 'La valeur tonale s''applique à l''ombrage'),
  ('theorie-couleurs',    'manga-couleur',       0.8, 'La théorie des couleurs s''applique au manga couleur'),
  ('perspective',         'decor-arriere-plan',  1.0, 'La perspective s''applique au décor d''arrière-plan'),
  ('proportion',          'portrait-dessin',     1.0, 'Les proportions s''appliquent au portrait dessiné'),
  ('composition-dynamique','decoupage-manga',    0.8, 'La composition dynamique s''applique au découpage manga'),
  ('narration-visuelle',  'cliffhanger-page',    1.0, 'La narration visuelle s''applique au cliffhanger en fin de page'),
  ('contraste',           'planche-manga',       0.9, 'La gestion du contraste s''applique à la planche manga'),
  ('composition',         'composition-planche', 0.8, 'Les règles de composition s''appliquent à la planche'),
  ('anatomie-artistique', 'portrait-dessin',     0.8, 'L''anatomie artistique s''applique au portrait dessiné'),
  ('deformation-expression', 'chibi',            1.0, 'La déformation expressive s''applique au style chibi')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 's_applique_a'
);
