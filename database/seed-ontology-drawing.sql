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
  ('dessin-croquis',    'Croquis & Esquisses',   3, ARRAY['art','art-visuel','dessin','dessin-croquis'],    1),
  ('dessin-figure',     'Dessin de figure',       3, ARRAY['art','art-visuel','dessin','dessin-figure'],     2),
  ('dessin-anatomique', 'Dessin anatomique',      3, ARRAY['art','art-visuel','dessin','dessin-anatomique'], 3),
  ('dessin-technique',  'Dessin technique',       3, ARRAY['art','art-visuel','dessin','dessin-technique'],  4),
  ('decoupage',         'Decoupage & Storyboard', 3, ARRAY['art','bd-manga','storyboard','decoupage'], 1),
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
  ('trait', 'Trait & Ligne',
   E'Fondement du dessin. Qualite du trait : pression, vitesse, epaisseur, fluidite. '
   'Un trait peut etre affirme, hachure, continu, brise, calligraphique.',
   'technique', 'pencil', 'debutant',
   '{"related_tags":["lineart","contour","calligraphie"],"styles":["manga","sketch","realism"]}'::jsonb),

  ('hachure', 'Hachure & Cross-hatching',
   E'Technique d''ombrage par lignes paralleles ou croisees.',
   'technique', 'shading', 'intermediaire',
   '{"related_tags":["shading","ink","stippling","hatching"],"density_range":"60-300lpi"}'::jsonb),

  ('ombrage', 'Ombrage & Modele',
   E'Rendu des volumes par la lumiere et l''ombre.',
   'technique', 'light', 'intermediaire',
   '{"related_tags":["shading","volume","light","shadow","chiaroscuro"]}'::jsonb),

  ('gesture-drawing', 'Gesture Drawing',
   E'Technique de croquis rapide pour capturer le mouvement.',
   'technique', 'running', 'debutant',
   '{"related_tags":["croquis","movement","pose","dynamic","action"],"duration_seconds":"30-120"}'::jsonb),

  ('anatomie-artistique', 'Anatomie Artistique',
   E'Etude de la structure du corps humain adaptee au dessin.',
   'technique', 'skeleton', 'avance',
   '{"related_tags":["anatomy","proportions","muscles","skeleton","figure"]}'::jsonb),

  ('proportion', 'Proportion & Mesure',
   E'Systemes de proportions pour le dessin de figure.',
   'technique', 'ruler', 'intermediaire',
   '{"related_tags":["canon","head-ratio","measurement","golden-ratio"]}'::jsonb),

  ('croquis', 'Croquis & Esquisse',
   E'Dessin preparatoire rapide.',
   'technique', 'sketch', 'debutant',
   '{"related_tags":["sketch","draft","rough","thumbnails"]}'::jsonb),

  ('encaissement', 'Encrage au trait',
   E'Technique de reprise du crayonne a l''encre.',
   'technique', 'pen', 'avance',
   '{"related_tags":["inking","lineart","pen","brush","fineliner"]}'::jsonb),

  ('valeur-tonale', 'Valeur Tonale',
   E'Echelle des gris du blanc au noir.',
   'theorie', 'grayscale', 'debutant',
   '{"related_tags":["value","tonal","grayscale","shading","chiaroscuro"]}'::jsonb),

  ('contraste', 'Contraste',
   E'Opposition entre elements.',
   'theorie', 'contrast', 'debutant',
   '{"related_tags":["contrast","emphasis","focal-point","composition"]}'::jsonb),

  ('perspective-atmospherique', 'Perspective Atmospherique',
   E'Effet de profondeur par degradation des contrastes.',
   'theorie', 'mountain', 'intermediaire',
   '{"related_tags":["depth","aerial-perspective","background","landscape"]}'::jsonb),

  ('composition-dynamique', 'Composition Dynamique',
   E'Organisation des elements pour creer du mouvement.',
   'technique', 'triangle', 'intermediaire',
   '{"related_tags":["composition","dynamic","golden-ratio","rule-of-thirds"]}'::jsonb),

  ('crayon-graphite', 'Crayon Graphite',
   E'Crayon a base de graphite, de H (dur) a B (tendre).',
   'medium', 'pencil', 'debutant',
   '{"related_tags":["pencil","graphite","hb","sketch","shading"],"hardness_range":"9H-9B"}'::jsonb),

  ('fusain', 'Fusain',
   E'Baton de bois carbonise pour le dessin.',
   'medium', 'charcoal', 'intermediaire',
   '{"related_tags":["charcoal","shading","mass-drawing","gesture"]}'::jsonb),

  ('encre-chine', 'Encre de Chine',
   E'Encre noire indelebile a base de noir de fumee.',
   'medium', 'ink', 'intermediaire',
   '{"related_tags":["ink","sumi","india-ink","brush","pen"],"types":["liquide","baton","pastille"]}'::jsonb),

  ('pierre-noire', 'Pierre Noire',
   E'Roche tendre (schiste carbonifere) utilisee pour le dessin.',
   'medium', 'stone', 'avance',
   '{"related_tags":["black-stone","chalk","classical-drawing","portrait"]}'::jsonb),

  ('stylo-technique', 'Stylo Technique',
   E'Stylo a pointe tubulaire a encre waterproof.',
   'medium', 'pen', 'debutant',
   '{"related_tags":["fineliner","technical-pen","manga","inking"],"tip_sizes_mm":"0.05-2.0"}'::jsonb),

  ('marqueur', 'Marqueur & Feutre',
   E'Marqueur a alcool ou a eau.',
   'medium', 'marker', 'intermediaire',
   '{"related_tags":["marker","copic","alcohol-marker","concept-art"]}'::jsonb),

  ('pastel-sec', 'Pastel Sec',
   E'Baton de pigment pur agglomere.',
   'medium', 'pastel', 'avance',
   '{"related_tags":["pastel","soft-pastel","portrait","landscape"]}'::jsonb),

  ('carnet-croquis', 'Carnet de Croquis',
   E'Carnet a spirale ou relie pour le dessin sur le vif.',
   'outil', 'notebook', 'debutant',
   '{"related_tags":["sketchbook","journal","moleskine","field-drawing"],"paper_weights":"90-200gsm"}'::jsonb),

  ('gomme', 'Gomme & Estompe',
   E'Outils de correction et de modele.',
   'outil', 'eraser', 'debutant',
   '{"related_tags":["eraser","kneaded-eraser","blending-stump","tortillon"]}'::jsonb),

  ('tablette-dessin', 'Tablette Graphique',
   E'Peripherique de dessin numerique.',
   'outil', 'tablet', 'intermediaire',
   '{"related_tags":["graphic-tablet","wacom","ipad","procreate","clip-studio"],"pressure_levels":"2048-8192"}'::jsonb),

  ('croquis-rapide', 'Croquis Rapide',
   E'Dessin execute en un temps limite.',
   'format', 'timer', 'debutant',
   '{"related_tags":["quick-sketch","gesture","thumbnail","warmup"],"duration_seconds":"30-300"}'::jsonb),

  ('portrait-dessin', 'Portrait Dessine',
   E'Representation d''une personne.',
   'format', 'person', 'intermediaire',
   '{"related_tags":["portrait","face","expression","likeness","manga-face"]}'::jsonb),

  ('etude-anatomique', 'Etude Anatomique',
   E'Dessin d''etude du corps humain.',
   'format', 'muscle', 'avance',
   '{"related_tags":["anatomy","ecorche","muscle-study","skeleton","figure-drawing"]}'::jsonb)
) AS v(slug, label, description, category, icon, difficulty, metadata)
WHERE NOT EXISTS (SELECT 1 FROM ontology_concepts c WHERE c.slug = v.slug);

-- ============================================================
-- 3. CONCEPTS PLANCHE DE MANGA
-- ============================================================
INSERT INTO ontology_concepts (slug, label, description, category, icon, difficulty, metadata)
SELECT * FROM (VALUES
  ('planche-manga', 'Planche de Manga',
   E'Page de bande dessinee japonaise.',
   'format', 'page', 'intermediaire',
   '{"related_tags":["manga-page","layout","b4","original"],"page_sizes":["B4 original","A4 print"],"reading_direction":"right-to-left"}'::jsonb),

  ('koma', 'Koma / Case de Manga',
   E'Unite de base de la narration en manga.',
   'format', 'square', 'intermediaire',
   '{"related_tags":["panel","frame","cell","gutter","page-layout"]}'::jsonb),

  ('double-page', 'Double Page',
   E'Planche s''etalant sur deux pages.',
   'format', 'book', 'avance',
   '{"related_tags":["spread","panoramic","center-spread","climax"]}'::jsonb),

  ('page-choc', 'Page Choc (Splash Page)',
   E'Page entiere occupee par une grande illustration.',
   'format', 'star', 'intermediaire',
   '{"related_tags":["splash-page","full-page","spread","dramatic","establishing"]}'::jsonb),

  ('decoupage-manga', 'Decoupage / Panel Breakdown',
   E'Art de diviser la page en cases.',
   'technique', 'scissors', 'avance',
   '{"related_tags":["grid","panel-layout","flow","timing","decoupage","gutter"]}'::jsonb),

  ('composition-planche', 'Composition de Planche',
   E'Organisation spatiale des elements dans la page.',
   'technique', 'spiral', 'avance',
   '{"related_tags":["page-composition","black-white-balance","flow","eye-guide"]}'::jsonb),

  ('rythme-narratif', 'Rythme Narratif',
   E'Tempo de l''histoire cree par la taille des cases.',
   'technique', 'music', 'avance',
   '{"related_tags":["pacing","tempo","rhythm","timing","slow-fast"]}'::jsonb),

  ('lignes-action', 'Lignes d''Action / Effets',
   E'Lignes qui expriment le mouvement et la vitesse.',
   'technique', 'wind', 'debutant',
   '{"related_tags":["speed-lines","effect-lines","action-lines","movement","koka-sen"],"types":["straight","curved","burst","flow"]}'::jsonb),

  ('trame-screentone', 'Trame / Screentone',
   E'Film adhesif trame pour creer des textures.',
   'technique', 'grid', 'intermediaire',
   '{"related_tags":["screentone","tone","screen-tone","shading","texture"],"types":["dot","gradation","texture","pattern","flash","star","cloud"]}'::jsonb),

  ('tramage-numerique', 'Tramage Numerique',
   E'Application de trames par logiciel.',
   'technique', 'diamond', 'intermediaire',
   '{"related_tags":["digital-tone","clip-studio","layer-tone","gradation","pattern"]}'::jsonb),

  ('encrage-manga', 'Encrage Manga',
   E'Technique d''encrage specifique au manga.',
   'technique', 'feather', 'avance',
   '{"related_tags":["inking","g-pen","maru-pen","saji-pen","cabi-pen","manga-ink"],"pen_types":["G-pen","maru-pen","kabura-pen","saji-pen"]}'::jsonb),

  ('pinceau-manga', 'Pinceau & Brosse',
   E'Pinceau traditionnel japonais pour l''encrage.',
   'medium', 'brush', 'avance',
   '{"related_tags":["brush","fude","sumi-brush","ink-wash","expressive-line"]}'::jsonb),

  ('contraste-noir-blanc', 'Contraste Noir & Blanc',
   E'Gestion des masses de noir et blanc dans la page.',
   'technique', 'black-square', 'intermediaire',
   '{"related_tags":["black-mass","silhouette","chiaroscuro","negative-space","spot-black"]}'::jsonb),

  ('deformation-expression', 'Deformation Expressive',
   E'Distorsion volontaire des proportions.',
   'technique', 'scream', 'debutant',
   '{"related_tags":["exaggeration","squash-stretch","expression","sd","chibi"]}'::jsonb),

  ('decor-arriere-plan', 'Decor & Arriere-plan',
   E'Fond de case qui plante le decor.',
   'technique', 'city', 'intermediaire',
   '{"related_tags":["background","environment","setting","perspective","cityscape"]}'::jsonb),

  ('narration-visuelle', 'Narration Visuelle',
   E'Art de raconter une histoire par les images.',
   'theorie', 'film', 'intermediaire',
   '{"related_tags":["visual-storytelling","montage","cinematic","flow","reading"]}'::jsonb),

  ('cliffhanger-page', 'Cliffhanger & Page Turn',
   E'Technique narrative de suspense en fin de page.',
   'technique', 'next', 'intermediaire',
   '{"related_tags":["cliffhanger","page-turn","suspense","hook","chapter-end"]}'::jsonb),

  ('gekiga', 'Gekiga',
   E'Style de manga realiste et adulte.',
   'genre', 'theater', 'avance',
   '{"related_tags":["gekiga","drama","realistic","mature","alternative-manga"],"influenced_by":["cinema-noir","documentary"]}'::jsonb),

  ('chibi', 'Chibi / Super Deformed (SD)',
   E'Style de representation a tete surdimensionnee.',
   'style', 'star', 'debutant',
   '{"related_tags":["chibi","super-deformed","sd","cute","comical","deformed"],"head_body_ratio":"1:1_to_1:3"}'::jsonb),

  ('bento-composition', 'Composition Bento',
   E'Principe de composition de planche organisee comme un bento.',
   'technique', 'bento', 'intermediaire',
   '{"related_tags":["bento","layout","grid","balance","japanese-aesthetics"]}'::jsonb),

  ('manga-couleur', 'Manga en Couleur',
   E'Approche moderne du manga en couleur.',
   'technique', 'rainbow', 'intermediaire',
   '{"related_tags":["digital-color","flat-color","cel-shading","webtoon","anime-style"]}'::jsonb),

  ('expression-manga', 'Expressions Manga',
   E'Code graphique des expressions faciales en manga.',
   'technique', 'smile', 'debutant',
   '{"related_tags":["manga-expression","anime-face","comical-face","emotion-icons"],"common_expressions":["spiral-eyes","nose-bleed","sweat-drop","anger-vein","glassy-eyes"]}'::jsonb)
) AS v(slug, label, description, category, icon, difficulty, metadata)
WHERE NOT EXISTS (SELECT 1 FROM ontology_concepts c WHERE c.slug = v.slug);

-- ============================================================
-- 4. RELATIONS
-- ============================================================
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'est_un', 1.0, e.descr
FROM (VALUES
  ('croquis-rapide',    'croquis',            'Le croquis rapide est un type de croquis'),
  ('etude-anatomique',  'dessin-anatomique',  'L''etude anatomique est une forme de dessin anatomique'),
  ('chibi',             'manga',              'Le style chibi/SD est un sous-genre du manga'),
  ('gekiga',            'manga',              'Le gekiga est un genre de manga realiste'),
  ('koma',              'planche-manga',      'Le koma est l''unite de base de la planche de manga'),
  ('double-page',       'planche-manga',      'Une double page est un type de planche'),
  ('page-choc',         'planche-manga',      'Une page choc/splash est un type de planche')
) AS e(src, tgt, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'est_un'
);

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
  ('decoupage-manga',   'planche-manga',      'Le decoupage est la technique de composition de planche'),
  ('composition-planche','planche-manga',     'La composition organise les elements de la planche'),
  ('encrage-manga',     'bd-manga',           'L''encrage est une etape cle de la BD/manga'),
  ('trame-screentone',  'bd-manga',           'La trame/screentone est specifique a la BD/manga'),
  ('narration-visuelle','bd-manga',           'La narration visuelle est le coeur de la BD/manga')
) AS e(src, tgt, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'appartient_a'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'contient', e.weight, e.descr
FROM (VALUES
  ('valeur-tonale',       'contraste',          1.0, 'La valeur tonale inclut la notion de contraste'),
  ('theorie-couleurs',    'valeur-tonale',      0.6, 'La theorie des couleurs inclut la valeur tonale'),
  ('composition-dynamique','perspective',        0.7, 'La composition dynamique peut integrer la perspective'),
  ('decoupage-manga',     'rythme-narratif',     1.0, 'Le decoupage determine le rythme narratif'),
  ('decoupage-manga',     'composition-planche', 0.8, 'Le decoupage inclut la composition de planche'),
  ('composition-planche', 'contraste-noir-blanc',0.8, 'La composition de planche gere le contraste N&B'),
  ('narration-visuelle',  'cliffhanger-page',    0.7, 'La narration visuelle utilise le cliffhanger'),
  ('narration-visuelle',  'rythme-narratif',     1.0, 'La narration visuelle integre le rythme narratif'),
  ('anatomie-artistique', 'proportion',          1.0, 'L''anatomie inclut l''etude des proportions'),
  ('expression-manga',    'deformation-expression',0.9,'Les expressions manga utilisent la deformation expressive')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'contient'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'utilise', e.weight, e.descr
FROM (VALUES
  ('encrage-manga',       'encre-chine',         1.0, 'L''encrage manga utilise l''encre de Chine'),
  ('encrage-manga',       'stylo-technique',     0.7, 'L''encrage moderne utilise aussi le stylo technique'),
  ('encrage-manga',       'pinceau-manga',       0.8, 'L''encrage traditionnel utilise le pinceau'),
  ('hachure',             'stylo-technique',     0.8, 'La hachure se pratique au stylo technique ou a la plume'),
  ('trame-screentone',    'tramage-numerique',   0.9, 'La screentone traditionnelle utilise le tramage numerique'),
  ('manga-couleur',       'tablette-dessin',     0.9, 'Le manga couleur moderne utilise la tablette graphique'),
  ('decor-arriere-plan',  'perspective',         0.9, 'Le dessin de decor utilise la perspective'),
  ('decor-arriere-plan',  'perspective-atmospherique', 0.7, 'Le decor utilise la perspective atmospherique'),
  ('gesture-drawing',     'carnet-croquis',      0.8, 'Le gesture drawing se pratique dans un carnet de croquis'),
  ('gesture-drawing',     'crayon-graphite',     0.7, 'Le gesture drawing utilise le crayon graphite'),
  ('croquis',             'carnet-croquis',      0.9, 'Le croquis utilise le carnet comme support'),
  ('croquis',             'gomme',               0.5, 'Le croquis utilise la gomme pour les corrections'),
  ('anatomie-artistique', 'etude-anatomique',    0.9, 'L''anatomie artistique utilise l''etude anatomique'),
  ('portrait-dessin',     'expression-manga',    0.7, 'Le portrait dessine peut utiliser les expressions manga'),
  ('chibi',               'deformation-expression',1.0,'Le style chibi utilise la deformation expressive')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'utilise'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'requiert', e.weight, e.descr
FROM (VALUES
  ('dessin',              'trait',               1.0, 'Le dessin requiert la maitrise du trait'),
  ('portrait-dessin',     'proportion',          1.0, 'Le portrait requiert la connaissance des proportions'),
  ('portrait-dessin',     'expression-manga',    0.7, 'Le portrait manga requiert la maitrise des expressions'),
  ('planche-manga',       'decoupage-manga',     1.0, 'La planche requiert un decoupage'),
  ('planche-manga',       'encrage-manga',       0.8, 'La planche finalisee requiert l''encrage'),
  ('ombrage',             'valeur-tonale',       1.0, 'L''ombrage requiert la comprehension de la valeur tonale'),
  ('decoupage-manga',     'narration-visuelle',  1.0, 'Le decoupage requiert des bases de narration visuelle'),
  ('manga',               'narration-visuelle',  0.9, 'Le manga requiert la narration visuelle'),
  ('manga',               'planche-manga',       1.0, 'Le manga s''exprime via la planche'),
  ('etude-anatomique',    'anatomie-artistique', 1.0, 'L''etude anatomique requiert des connaissances en anatomie artistique'),
  ('double-page',         'composition-planche', 0.9, 'La double page requiert une composition maitrisee')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'requiert'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'influence', e.weight, e.descr
FROM (VALUES
  ('manga',               'planche-manga',       1.0, 'Le genre manga influence le format de ses planches'),
  ('gekiga',              'manga',               0.8, 'Le gekiga a influence le manga realiste adulte'),
  ('decoupage-manga',     'rythme-narratif',     0.8, 'Le decoupage influence le rythme de lecture'),
  ('cinema',              'decoupage-manga',     0.7, 'Le cinema influence le decoupage manga'),
  ('imagerie-japonaise',  'expression-manga',    0.6, 'L''imagerie traditionnelle japonaise influence les expressions manga'),
  ('manga',               'webtoon',             0.7, 'Le manga a influence le format webtoon coreen'),
  ('composition-dynamique','composition-planche',0.7, 'La composition dynamique influence la composition de planche')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'influence'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'similaire_a', e.weight, e.descr
FROM (VALUES
  ('hachure',             'trame-screentone',    0.6, 'La hachure et la screentone sont deux methodes d''ombrage'),
  ('planche-manga',       'storyboard',          0.7, 'La planche de manga partage des principes avec le storyboard'),
  ('gesture-drawing',     'croquis-rapide',      0.8, 'Le gesture drawing et le croquis rapide sont tres proches'),
  ('narration-visuelle',  'cinema',              0.6, 'La narration visuelle en manga partage des codes avec le cinema'),
  ('composition-planche', 'composition-dynamique',0.7, 'La composition de planche est une composition dynamique appliquee a la page')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'similaire_a'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'complimente', e.weight, e.descr
FROM (VALUES
  ('trame-screentone',    'hachure',             0.8, 'La screentone et la hachure se completent'),
  ('lignes-action',       'contraste-noir-blanc',0.7, 'Les lignes d''action renforcent le contraste N&B'),
  ('encrage-manga',       'trame-screentone',    0.9, 'L''encrage et le tramage sont complementaires'),
  ('narration-visuelle',  'controle-du-temps',   0.6, 'La narration complete la gestion du temps en BD'),
  ('ombre-propre',        'ombre-portee',        0.9, 'Les ombres propres et portees se completent'),
  ('page-choc',           'double-page',         0.6, 'La page choc et la double page sont complementaires')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'complimente'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'precede', e.weight, e.descr
FROM (VALUES
  ('croquis',             'encaissement',        1.0, 'Le croquis precede l''encrage'),
  ('crayon-graphite',     'encre-chine',         0.8, 'Le crayonne precede l''encrage en BD/manga'),
  ('gesture-drawing',     'croquis',             0.7, 'Le gesture drawing precede le croquis detaille'),
  ('storyboard',          'planche-manga',       0.9, 'Le storyboard precede la realisation de la planche'),
  ('decoupage-manga',     'encrage-manga',       1.0, 'Le decoupage precede l''encrage final')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 'precede'
);

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 's_applique_a', e.weight, e.descr
FROM (VALUES
  ('valeur-tonale',       'ombrage',             1.0, 'La valeur tonale s''applique a l''ombrage'),
  ('theorie-couleurs',    'manga-couleur',       0.8, 'La theorie des couleurs s''applique au manga couleur'),
  ('perspective',         'decor-arriere-plan',  1.0, 'La perspective s''applique au decor d''arriere-plan'),
  ('proportion',          'portrait-dessin',     1.0, 'Les proportions s''appliquent au portrait dessine'),
  ('composition-dynamique','decoupage-manga',    0.8, 'La composition dynamique s''applique au decoupage manga'),
  ('narration-visuelle',  'cliffhanger-page',    1.0, 'La narration visuelle s''applique au cliffhanger'),
  ('contraste',           'planche-manga',       0.9, 'La gestion du contraste s''applique a la planche manga'),
  ('composition',         'composition-planche', 0.8, 'Les regles de composition s''appliquent a la planche'),
  ('anatomie-artistique', 'portrait-dessin',     0.8, 'L''anatomie artistique s''applique au portrait dessine'),
  ('deformation-expression', 'chibi',            1.0, 'La deformation expressive s''applique au style chibi')
) AS e(src, tgt, weight, descr)
JOIN ontology_concepts s ON s.slug = e.src
JOIN ontology_concepts t ON t.slug = e.tgt
WHERE NOT EXISTS (
  SELECT 1 FROM ontology_relations r
  WHERE r.source_id = s.id AND r.target_id = t.id AND r.relation_type = 's_applique_a'
);