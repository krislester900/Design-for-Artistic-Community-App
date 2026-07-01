-- ============================================================
-- SEED COMPLET : Connaissances + Ontologie + Configuration
-- À exécuter APRÈS les schémas
-- ============================================================

-- 1. BASE DE CONNAISSANCES (11 articles experts)
INSERT INTO ai_knowledge_base (category, title, content, tags, source) VALUES
('visual', 'Théorie des couleurs',
'La théorie des couleurs est essentielle en art visuel.

Cercle chromatique : Les couleurs primaires (rouge, bleu, jaune) sont la base. Les secondaires (vert, orange, violet) sont obtenues par mélange.

Harmonies :
- Complémentaires : couleurs opposées sur le cercle (bleu/orange) → contraste fort
- Analogues : couleurs voisines (bleu, bleu-vert, vert) → harmonie douce
- Triadiques : 3 couleurs équidistantes → équilibre dynamique
- Monochromes : variations d''une seule couleur → élégance

Psychologie des couleurs :
- Rouge : passion, énergie, urgence
- Bleu : calme, confiance, professionnalisme
- Vert : nature, croissance, harmonie
- Jaune : joie, optimisme, attention
- Violet : créativité, luxe, spiritualité
- Orange : chaleur, enthousiasme
- Noir : puissance, élégance, mystère
- Blanc : pureté, simplicité, espace

Conseil : Utilise la règle 60-30-10 : 60% couleur dominante, 30% secondaire, 10% d''accent.',
ARRAY['couleurs', 'théorie', 'composition', 'débutant'], 'expert'),

('visual', 'Composition en arts visuels',
'Les règles de composition pour des oeuvres visuelles percutantes :
1. Règle des tiers : Divise l''image en 3x3, place les éléments clés sur les intersections.
2. Nombre d''or (1.618) : Proportion naturelle présente dans l''art depuis la Renaissance.
3. Lignes directrices : Utilise des lignes (routes, rivières, regards) pour guider l''oeil.
4. Symétrie vs Asymétrie : La symétrie apporte calme et équilibre. L''asymétrie crée du dynamisme.
5. Espace négatif : Le vide autour du sujet est aussi important que le sujet lui-même.
6. Profondeur : Crée de la profondeur avec premier plan, plan moyen, arrière-plan.
7. Cadrage : Utilise des éléments naturels (fenêtres, arches) pour encadrer le sujet.
8. Rythme : La répétition de formes, couleurs ou textures crée un mouvement visuel.',
ARRAY['composition', 'technique', 'avancé'], 'expert'),

('visual', 'Techniques de dessin',
'Techniques de dessin essentielles :
CROQUIS RAPIDE : 30 secondes à 2 minutes par pose, capture l''essence du mouvement.
OMBRES ET LUMIÈRES : Source de lumière à déterminer d''abord. 5-7 valeurs du blanc au noir.
Hachures : lignes parallèles pour les ombres. Hachures croisées pour plus de profondeur.
PERSPECTIVE : 1 point de fuite (route), 2 points (bâtiment), 3 points (plongée/contre-plongée).
PROPORTIONS DU VISAGE : Yeux à mi-hauteur de la tête. Entre les yeux = largeur d''un oeil.
Conseil : Dessine 10 minutes chaque jour pour progresser rapidement.',
ARRAY['dessin', 'technique', 'proportions', 'ombres'], 'expert'),

('music', 'Théorie musicale de base',
'Les fondamentaux de la théorie musicale :
GAMMES : Majeure (do, ré, mi, fa, sol, la, si → joyeux), Mineure (la, si, do, ré, mi, fa, sol → mélancolique), Pentatonique (5 notes → improvisation).
ACCORDS : Majeur (do-mi-sol → stable), Mineur (do-mib-sol → triste), 7ème (do-mi-sol-sib → jazz), Suspendu (sus2, sus4 → tension).
PROGRESSIONS POPULAIRES : I-V-vi-IV (C-G-Am-F → pop), ii-V-I (Dm-G-C → jazz), vi-IV-I-V (Am-F-C-G → ballade).
RYTHME : Tempo en BPM (60 lent, 120 modéré, 180+ rapide). Signature 4/4 (standard), 3/4 (valse), 6/8 (ternaire).
Conseil : Apprends tes gammes dans toutes les tonalités.',
ARRAY['théorie', 'accords', 'gammes', 'débutant'], 'expert'),

('music', 'Production musicale home-studio',
'Guide pour produire de la musique chez soi :
ÉQUIPEMENT : Ordinateur + DAW, Interface audio (Focusrite), Microphone (SM57/SM7B), Casque studio (ATH-M50x), Clavier MIDI.
ÉTAPES : 1. Composition (structure) 2. Arrangement (instruments) 3. Mixage (EQ, compression, réverbe) 4. Mastering (finalisation).
TECHNIQUES DE MIXAGE : EQ (coupe 80Hz), Compression (ratio 4:1 voix), Réverbération (room/hall), Delay (1/4 note).
NORMES : Spotify -14 LUFS, YouTube -13 LUFS, Apple Music -16 LUFS.
Conseil : 80% du son vient de l''arrangement, pas du mixage.',
ARRAY['production', 'home-studio', 'mixage', 'avancé'], 'expert'),

('writing', 'Techniques d''écriture créative',
'Techniques pour améliorer ton écriture :
SHOW DON''T TELL : Au lieu de "il était triste" → "ses épaules s''affaissèrent".
STRUCTURES : Linéaire (début-milieu-fin), Non-linéaire (flashbacks), En boucle, Multi-points de vue.
LES 3 ACTES : Acte 1 (25% - présentation + incident), Acte 2 (50% - conflits), Acte 3 (25% - climax + résolution).
FIGURES DE STYLE : Métaphore ("le temps est un fleuve"), Comparaison, Personnification, Allitération.
EXERCICE : Écris 15 minutes par jour sans t''arrêter (free writing).',
ARRAY['écriture', 'technique', 'narration', 'style'], 'expert'),

('writing', 'Poésie : formes et techniques',
'Guide des formes poétiques :
SONNET (14 vers) : 2 quatrains + 2 tercets. Rimes embrassées (ABBA ABBA) puis plates (CCD EED).
HAÏKU (3 vers) : 5-7-5 syllabes. Évoque un instant de nature. Saisonnier (kigo).
VERS LIBRE : Pas de règle de métrique. Rythme naturel. Images fortes.
TECHNIQUES : Enjambement, Césure, Assonance (répétition voyelles), Consonance (répétition consonnes).
Conseil : Lis de la poésie à voix haute pour sentir le rythme.',
ARRAY['poésie', 'écriture', 'formes', 'technique'], 'expert'),

('comics', 'Storyboard et mise en page BD',
'Les bases du storyboard pour la BD :
STRUCTURE : 4 à 6 cases par page. Case large = moment important. Petites cases = action rapide.
TYPES DE PLANS : Plan large (décor), Plan moyen (personnage), Gros plan (émotion), Très gros plan (intensité).
SENS DE LECTURE : Manga japonais (droite vers gauche), BD franco-belge (gauche vers droite).
BULLES : Ronde (dialogue), Nuage (pensée), Dentelée (cri). Onomatopées (BANG, WHAM, ZZZ).
CONSEILS : Varie les angles de vue. Contre-plongées pour les héros. Dernière case = cliffhanger.',
ARRAY['BD', 'storyboard', 'mise en page', 'technique'], 'expert'),

('comics', 'Création de personnages manga',
'Guide pour créer des personnages de manga :
ANATOMIE : Tête 1/5 du corps total. Yeux grands et expressifs à mi-hauteur. Cheveux volumineux.
TYPES : Shōnen (mâchoire carrée), Shōjo (visage rond, grands yeux), Chibi (tête énorme), Méchant (mâchoire anguleuse).
EXPRESSIONS : Joie (yeux en arc), Tristesse (yeux mi-clos + larme), Colère (sourcils froncés + veine), Surprise (yeux ronds).
Conseil : Crée une fiche personnage avec histoire, forces et faiblesses.',
ARRAY['manga', 'personnages', 'dessin', 'création'], 'expert'),

('technique', 'Comment surmonter le blocage créatif',
'Stratégies pour dépasser le blocage créatif :
1. CHANGER DE MÉDIUM : Si tu dessines, essaie la musique. Le changement stimule de nouvelles connexions.
2. CONTRAINTES CRÉATIVES : "Dessine avec ta main non-dominante", "Compose avec seulement 2 accords".
3. ROUTINE VS INSPIRATION : 70% routine, 30% inspiration. L''inspiration vient en créant.
4. EXERCICES : Free writing 10 minutes, Gribouillage sans réfléchir, Collage, Marche 20 minutes.
5. ENVIRONNEMENT : Espace dédié, musique adaptée, écran bleu réduit 1h avant.
Rappelle-toi : Le perfectionnisme est l''ennemi de la création.',
ARRAY['créativité', 'blocage', 'motivation', 'psychologie'], 'expert'),

('technique', 'Les 7 principes du design',
'Les principes fondamentaux du design :
1. ÉQUILIBRE : Symétrique (formel), Asymétrique (dynamique), Radial (centré).
2. CONTRASTE : Hiérarchie visuelle. Oppose grand/petit, clair/sombre.
3. EMPHASE : Un point focal par composition. Utilise couleur, taille, espace.
4. PROPORTION : Échelle relative. Nombre d''or (1.618). Important = grand.
5. RYTHME : Répétition, alternance, progression.
6. UNITÉ : Palette limitée (3-5 couleurs). Max 2 polices.
7. ESPACE BLANC : Aussi important que le contenu. Améliore lisibilité.
Application : Analyse tes designs préférés avec ces 7 principes.',
ARRAY['design', 'principes', 'composition', 'théorie'], 'expert'),

('style', 'Mouvements artistiques majeurs',
'Panorama des mouvements artistiques :
RENAISSANCE (1400-1600) : Perspective, réalisme, lumière. Artistes : De Vinci, Michel-Ange.
IMPRESSIONNISME (1870-1890) : Couleurs pures, lumière naturelle. Monet, Renoir.
ART NOUVEAU (1890-1910) : Lignes courbes, motifs végétaux. Mucha, Gaudi.
CUBISME (1907-1920) : Formes géométriques, perspectives multiples. Picasso, Braque.
SURRÉALISME (1920-1950) : Rêves, inconscient. Dalí, Magritte.
POP ART (1950-1970) : Culture populaire, couleurs vives. Warhol, Lichtenstein.
ART NUMÉRIQUE (2000+) : Pixels, algorithmes, NFT. Beeple, Fewocious.',
ARRAY['histoire de l''art', 'mouvements', 'culture', 'inspiration'], 'expert')
ON CONFLICT DO NOTHING;

-- 2. ONTOLOGIE : Taxonomie
INSERT INTO ontology_taxonomy (slug, label, level, path, order_index) VALUES
('art', 'Art', 0, ARRAY['art'], 1),
('art-visuel', 'Art visuel', 1, ARRAY['art', 'art-visuel'], 2),
('musique', 'Musique', 1, ARRAY['art', 'musique'], 3),
('ecriture', 'Écriture', 1, ARRAY['art', 'ecriture'], 4),
('bd-manga', 'BD/Manga', 1, ARRAY['art', 'bd-manga'], 5),
('peinture', 'Peinture', 2, ARRAY['art', 'art-visuel', 'peinture'], 6),
('dessin', 'Dessin', 2, ARRAY['art', 'art-visuel', 'dessin'], 7),
('photographie', 'Photographie', 2, ARRAY['art', 'art-visuel', 'photographie'], 8),
('sculpture', 'Sculpture', 2, ARRAY['art', 'art-visuel', 'sculpture'], 9),
('art-numerique', 'Art numérique', 2, ARRAY['art', 'art-visuel', 'art-numerique'], 10),
('composition', 'Composition', 2, ARRAY['art', 'musique', 'composition'], 11),
('production', 'Production musicale', 2, ARRAY['art', 'musique', 'production'], 12),
('chant', 'Chant', 2, ARRAY['art', 'musique', 'chant'], 13),
('instrument', 'Instrument', 2, ARRAY['art', 'musique', 'instrument'], 14),
('poesie', 'Poésie', 2, ARRAY['art', 'ecriture', 'poesie'], 15),
('fiction', 'Fiction', 2, ARRAY['art', 'ecriture', 'fiction'], 16),
('scenario', 'Scénario', 2, ARRAY['art', 'ecriture', 'scenario'], 17),
('storyboard', 'Storyboard', 2, ARRAY['art', 'bd-manga', 'storyboard'], 18),
('character-design', 'Character design', 2, ARRAY['art', 'bd-manga', 'character-design'], 19),
('lettering', 'Lettrage', 2, ARRAY['art', 'bd-manga', 'lettering'], 20)
ON CONFLICT DO NOTHING;

-- 3. ONTOLOGIE : Concepts
INSERT INTO ontology_concepts (slug, label, category, description, icon, difficulty) VALUES
('theorie-couleurs', 'Théorie des couleurs', 'theorie', 'Science et art de l''utilisation des couleurs. Comprend le cercle chromatique, les harmonies et la psychologie.', '🎨', 'debutant'),
('cercle-chromatique', 'Cercle chromatique', 'theorie', 'Représentation circulaire des couleurs organisées par teinte.', '🔄', 'debutant'),
('composition', 'Composition visuelle', 'technique', 'Organisation des éléments dans une œuvre. Règle des tiers, nombre d''or.', '📐', 'intermediaire'),
('perspective', 'Perspective', 'technique', 'Technique de représentation de la profondeur et de l''espace tridimensionnel.', '📏', 'avance'),
('aquarelle', 'Aquarelle', 'medium', 'Peinture avec pigments dilués dans l''eau. Transparence et fluidité.', '💧', 'intermediaire'),
('huile', 'Peinture à l''huile', 'medium', 'Pigments mélangés à de l''huile. Dégradés riches et profondeur.', '🖌️', 'avance'),
('impressionnisme', 'Impressionnisme', 'mouvement', 'Mouvement (1870-1890) : touches de couleur pures, capture de la lumière.', '🌅', 'debutant'),
('cubisme', 'Cubisme', 'mouvement', 'Mouvement (1907-1920) : formes géométriques, perspectives multiples.', '🔶', 'intermediaire'),
('surrealisme', 'Surréalisme', 'mouvement', 'Mouvement (1920-1950) : inconscient, rêves, juxtapositions surprenantes.', '🌙', 'intermediaire'),
('vangogh', 'Vincent van Gogh', 'artiste', 'Peintre post-impressionniste (1853-1890). La Nuit étoilée, tournesols.', '🌻', NULL),
('picasso', 'Pablo Picasso', 'artiste', 'Artiste espagnol (1881-1973), co-fondateur du cubisme.', '🎭', NULL),
('gamme', 'Gamme musicale', 'theorie', 'Suite de notes ordonnées par hauteur. Majeure (joyeuse), mineure (mélancolique).', '🎵', 'debutant'),
('accord', 'Accord', 'theorie', 'Ensemble d''au moins trois notes jouées simultanément.', '🎹', 'debutant'),
('rythme', 'Rythme', 'theorie', 'Organisation des durées et des accents dans le temps.', '🥁', 'debutant'),
('blues', 'Blues', 'genre', 'Genre musical né au XIXe siècle. Base du jazz, rock et soul.', '🎸', 'debutant'),
('jazz', 'Jazz', 'genre', 'Genre caractérisé par l''improvisation, les syncopes et les accords complexes.', '🎷', 'intermediaire'),
('haiku', 'Haïku', 'format', 'Poème court japonais de 3 vers (5-7-5 syllabes) évoquant un instant.', '🌸', 'debutant'),
('sonnet', 'Sonnet', 'format', 'Poème de 14 vers avec structure de rimes spécifique.', '📜', 'avance'),
('manga', 'Manga', 'genre', 'Bande dessinée japonaise au sens de lecture droite-gauche.', '📚', 'debutant'),
('shonen', 'Shōnen', 'genre', 'Manga pour jeunes garçons : action, aventure, camaraderie.', '⚡', 'debutant'),
('blocage-creatif', 'Blocage créatif', 'theorie', 'Incapacité temporaire à créer. Solutions : changer de médium, contraintes.', '🚧', 'debutant')
ON CONFLICT DO NOTHING;

-- 4. ONTOLOGIE : Relations
INSERT INTO ontology_relations (source_id, target_id, relation_type, weight)
SELECT s.id, t.id, 'est_un', 1.0
FROM ontology_concepts s, ontology_concepts t
WHERE (s.slug = 'haiku' AND t.slug = 'poesie')
   OR (s.slug = 'sonnet' AND t.slug = 'poesie')
   OR (s.slug = 'manga' AND t.slug = 'bd-manga')
   OR (s.slug = 'shonen' AND t.slug = 'manga')
   OR (s.slug = 'aquarelle' AND t.slug = 'peinture')
   OR (s.slug = 'huile' AND t.slug = 'peinture')
   OR (s.slug = 'blues' AND t.slug = 'musique')
   OR (s.slug = 'jazz' AND t.slug = 'musique')
ON CONFLICT DO NOTHING;

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight, description)
SELECT s.id, t.id, 'influence', 0.9, 'Van Gogh a été influencé par l''impressionnisme'
FROM ontology_concepts s, ontology_concepts t
WHERE s.slug = 'impressionnisme' AND t.slug = 'vangogh'
ON CONFLICT DO NOTHING;

INSERT INTO ontology_relations (source_id, target_id, relation_type, weight)
SELECT s.id, t.id, 'contient', 1.0
FROM ontology_concepts s, ontology_concepts t
WHERE (s.slug = 'theorie-couleurs' AND t.slug = 'cercle-chromatique')
ON CONFLICT DO NOTHING;

-- 5. Configurer les prompts système versionnés
INSERT INTO ai_system_prompts (version, category, prompt_text, is_active) VALUES
('1.0', 'general',
'Tu es "Arteïa Muse" ✨, assistant créatif d''Arteïa. Réponds en français avec des émojis artistiques. Inspire, conseille et motive les créateurs.', true),
('1.0', 'visual',
'Tu aides un artiste visuel. Propose des idées de composition, palettes de couleurs, techniques. Sois précis et inspirant.', true),
('1.0', 'music',
'Tu aides un musicien. Suggère des progressions d''accords, ambiances, arrangements. Connais la théorie musicale.', true)
ON CONFLICT DO NOTHING;

-- 6. Afficher le résumé
SELECT '✅ Seed terminé !' as result;
SELECT COUNT(*) || ' articles de connaissances' as knowledge FROM ai_knowledge_base;
SELECT COUNT(*) || ' concepts ontologiques' as concepts FROM ontology_concepts;
SELECT COUNT(*) || ' relations' as relations FROM ontology_relations;
SELECT COUNT(*) || ' catégories' as categories FROM ontology_taxonomy;