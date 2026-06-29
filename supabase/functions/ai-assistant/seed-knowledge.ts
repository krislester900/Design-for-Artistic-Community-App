// Script de seed pour la base de connaissances artistiques
// À exécuter une fois : supabase functions deploy
// Puis insérer les données via l'API

export const KNOWLEDGE_SEED = [
  // === ART VISUEL ===
  {
    category: "visual",
    title: "Théorie des couleurs",
    content: `La théorie des couleurs est essentielle en art visuel. 
    
Cercle chromatique : Les couleurs primaires (rouge, bleu, jaune) sont la base. Les secondaires (vert, orange, violet) sont obtenues par mélange.

Harmonies :
- Complémentaires : couleurs opposées sur le cercle (bleu/orange) → contraste fort
- Analogues : couleurs voisines (bleu, bleu-vert, vert) → harmonie douce
- Triadiques : 3 couleurs équidistantes → équilibre dynamique
- Monochromes : variations d'une seule couleur → élégance

Psychologie des couleurs :
- Rouge : passion, énergie, urgence
- Bleu : calme, confiance, professionnalisme
- Vert : nature, croissance, harmonie
- Jaune : joie, optimisme, attention
- Violet : créativité, luxe, spiritualité
- Orange : chaleur, enthousiasme
- Noir : puissance, élégance, mystère
- Blanc : pureté, simplicité, espace

Conseil : Utilise la règle 60-30-10 : 60% couleur dominante, 30% secondaire, 10% d'accent.`,
    tags: ["couleurs", "théorie", "composition", "débutant"],
    source: "expert"
  },
  {
    category: "visual",
    title: "Composition en arts visuels",
    content: `Les règles de composition pour des œuvres visuelles percutantes :

1. Règle des tiers : Divise l'image en 3x3, place les éléments clés sur les intersections.

2. Nombre d'or (1.618) : Proportion naturelle présente dans l'art depuis la Renaissance.

3. Lignes directrices : Utilise des lignes (routes, rivières, regards) pour guider l'œil.

4. Symétrie vs Asymétrie : La symétrie apporte calme et équilibre. L'asymétrie crée du dynamisme.

5. Espace négatif : Le vide autour du sujet est aussi important que le sujet lui-même.

6. Profondeur : Crée de la profondeur avec premier plan, plan moyen, arrière-plan.

7. Cadrage : Utilise des éléments naturels (fenêtres, arches) pour encadrer le sujet.

8. Rythme : La répétition de formes, couleurs ou textures crée un mouvement visuel.

Exercice : Prends une photo et analyse sa composition selon ces règles.`,
    tags: ["composition", "technique", "avancé"],
    source: "expert"
  },
  {
    category: "visual",
    title: "Techniques de dessin",
    content: `Techniques de dessin essentielles :

CROQUIS RAPIDE (gesture drawing) :
- 30 secondes à 2 minutes par pose
- Capture l'essence du mouvement
- Utilise des lignes fluides et continues

OMBRES ET LUMIÈRES :
- Source de lumière : détermine d'abord d'où vient la lumière
- Valeurs : du blanc au noir en passant par 5-7 gris
- Hachures : lignes parallèles pour les ombres
- Hachures croisées : lignes qui se croisent pour plus de profondeur
- Estompage : dégradés doux au doigt ou à l'estompe

PERSPECTIVE :
- 1 point de fuite : route, couloir
- 2 points de fuite : bâtiment, coin de rue
- 3 points de fuite : vue plongeante ou contre-plongée

PROPORTIONS DU VISAGE (vue de face) :
- Les yeux sont à mi-hauteur de la tête
- Entre les yeux = largeur d'un œil
- Bouche alignée avec le centre des pupilles
- Oreilles entre les sourcils et le nez

Conseil : Dessine 10 minutes chaque jour pour progresser rapidement.`,
    tags: ["dessin", "technique", "proportions", "ombres"],
    source: "expert"
  },

  // === MUSIQUE ===
  {
    category: "music",
    title: "Théorie musicale de base",
    content: `Les fondamentaux de la théorie musicale pour créer :

GAMMES :
- Gamme majeure : do, ré, mi, fa, sol, la, si → son joyeux
- Gamme mineure : la, si, do, ré, mi, fa, sol → son mélancolique
- Pentatonique : 5 notes → idéal pour improviser

ACCORDS :
- Majeur (ex: Do Majeur = do-mi-sol) → joyeux, stable
- Mineur (ex: Do mineur = do-mib-sol) → triste, intense
- 7ème (ex: Do7 = do-mi-sol-sib) → jazz, bluesy
- Suspendu (sus2, sus4) → tension, attente

PROGRESSIONS POPULAIRES :
- I-V-vi-IV (ex: C-G-Am-F) → la plus utilisée en pop
- ii-V-I (ex: Dm-G-C) → standard jazz
- I-vi-IV-V (ex: C-Am-F-G) → doo-wop, rock 'n' roll
- vi-IV-I-V (ex: Am-F-C-G) → ballade émotionnelle

RYTHME :
- Tempo : vitesse en BPM (60 = lent, 120 = modéré, 180+ = rapide)
- Signature : 4/4 (standard), 3/4 (valse), 6/8 (ternaire)
- Syncope : accent sur les temps faibles → groove

Conseil : Apprends tes gammes dans toutes les tonalités, ça libère la créativité !`,
    tags: ["théorie", "accords", "gammes", "débutant"],
    source: "expert"
  },
  {
    category: "music",
    title: "Production musicale home-studio",
    content: `Guide pour produire de la musique chez soi :

ÉQUIPEMENT MINIMUM :
- Ordinateur + DAW (Ableton, FL Studio, Logic, Reaper)
- Interface audio (Focusrite Scarlett, Universal Audio)
- Microphone (Shure SM57 pour instruments, SM7B pour voix)
- Casque studio (Audio-Technica ATH-M50x, Beyerdynamic DT770)
- Clavier MIDI (Arturia KeyLab, Novation Launchkey)

ÉTAPES DE PRODUCTION :
1. Composition : écris la structure (intro, couplet, refrain, pont)
2. Arrangement : ajoute les instruments progressivement
3. Mixage : équilibre les niveaux, panoramique, EQ, compression
4. Mastering : finalise le son pour toutes les plateformes

TECHNIQUES DE MIXAGE :
- EQ : coupe les fréquences inutiles (80Hz et en dessous pour le kick)
- Compression : contrôle la dynamique (ratio 4:1 pour voix)
- Réverbération : crée de l'espace (room small pour proximité, hall pour ampleur)
- Delay : ajoute de la profondeur (1/4 note pour ambiance)

NORMES PLATEFORMES :
- Spotify : -14 LUFS intégré
- YouTube : -13 LUFS intégré
- Apple Music : -16 LUFS intégré

Conseil : 80% du son vient de l'arrangement, pas du mixage.`,
    tags: ["production", "home-studio", "mixage", "avancé"],
    source: "expert"
  },

  // === ÉCRITURE ===
  {
    category: "writing",
    title: "Techniques d'écriture créative",
    content: `Techniques pour améliorer ton écriture :

LE SHOW DON'T TELL :
- Au lieu de "il était triste" → "ses épaules s'affaissèrent, une larme glissa sur sa joue"
- Au lieu de "elle avait peur" → "son cœur battait si fort qu'elle l'entendait"

STRUCTURES NARRATIVES :
- Linéaire : début → milieu → fin (classique)
- Non-linéaire : flashbacks, ellipses (moderne)
- En boucle : fin qui rejoint le début (poétique)
- Multi-points de vue : plusieurs personnages (complexe)

LES 3 ACTES :
1. Acte 1 (25%) : Présentation du héros, incident déclencheur
2. Acte 2 (50%) : Conflits, obstacles, point de non-retour
3. Acte 3 (25%) : Climax, résolution, dénouement

FIGURES DE STYLE :
- Métaphore : "le temps est un fleuve"
- Comparaison : "beau comme un soleil couchant"
- Personnification : "le vent hurlait"
- Allitération : "pour qui sont ces serpents qui sifflent sur vos têtes"

EXERCICE : Écris 15 minutes par jour sans t'arrêter (free writing).`,
    tags: ["écriture", "technique", "narration", "style"],
    source: "expert"
  },
  {
    category: "writing",
    title: "Poésie : formes et techniques",
    content: `Guide des formes poétiques :

SONNET (14 vers) :
- 2 quatrains + 2 tercets
- Rimes embrassées (ABBA ABBA) puis plates (CCD EED)
- Thème : amour, nature, méditation

HAÏKU (3 vers) :
- 5-7-5 syllabes
- Évoque un instant de nature
- Saisonnier (kigo)

VERS LIBRE :
- Pas de règle de métrique
- Rythme naturel de la parole
- Utilisation d'images fortes

ACROSTICHE :
- Première lettre de chaque vers forme un mot

TECHNIQUES POÉTIQUES :
- Enjambement : phrase qui continue sur le vers suivant
- Césure : pause à l'intérieur d'un vers
- Assonance : répétition de sons voyelles
- Consonance : répétition de sons consonnes

Conseil : Lis de la poésie à voix haute pour sentir le rythme.`,
    tags: ["poésie", "écriture", "formes", "technique"],
    source: "expert"
  },

  // === BD/MANGA ===
  {
    category: "comics",
    title: "Storyboard et mise en page BD",
    content: `Les bases du storyboard pour la BD :

STRUCTURE DE PLANCHES :
- 4 à 6 cases par page (rythme de lecture)
- Case large = moment important, action lente
- Petites cases = action rapide, dialogue
- Pleine page = moment clé, révélation

TYPES DE PLANS :
- Plan large : décor, contexte
- Plan moyen : personnage en action
- Gros plan : émotion, détail
- Très gros plan : intensité dramatique

SENS DE LECTURE (manga) :
- Manga japonais : droite vers gauche
- BD franco-belge : gauche vers droite
- Important : toujours cohérent !

BULLES ET TEXTES :
- Bulle ronde : dialogue normal
- Bulle nuage : pensée, rêve
- Bulle dentelée : cri, colère
- Texte en dehors : narration
- Onomatopées : sons écrits (BANG, WHAM, ZZZ)

CONSEILS :
- Varie les angles de vue
- Utilise des contre-plongées pour les héros
- La première case doit accrocher le regard
- Dernière case = punchline ou cliffhanger`,
    tags: ["BD", "storyboard", "mise en page", "technique"],
    source: "expert"
  },
  {
    category: "comics",
    title: "Création de personnages manga",
    content: `Guide pour créer des personnages de manga :

ANATOMIE MANGA :
- Tête : 1/6 à 1/5 du corps total (vs 1/7-1/8 en réalité)
- Yeux : grands et expressifs, mi-hauteur du visage
- Nez et bouche : petits, partie inférieure du visage
- Cheveux : volumineux, souvent colorés

TYPES DE VISAGES :
- Shōnen (garçon) : mâchoire carrée, yeux moyens
- Shōjo (fille) : visage rond, grands yeux détaillés
- Chibi : tête énorme (1/2 du corps), mignon
- Méchant : mâchoire anguleuse, yeux bridés

EXPRESSIONS :
- Joie : yeux en arc, bouche ouverte
- Tristesse : yeux mi-clos, larme
- Colère : sourcils froncés, veine
- Surprise : yeux ronds, bouche en O
- Rougissement : lignes diagonales sur les joues

COSTUMES :
- Refletent la personnalité
- Couleurs symboliques (rouge = passion, bleu = calme)
- Accessoires distinctifs (bandeau, épée, bijou)

Conseil : Crée une fiche personnage avec son histoire, ses forces et faiblesses.`,
    tags: ["manga", "personnages", "dessin", "création"],
    source: "expert"
  },

  // === TECHNIQUES GÉNÉRALES ===
  {
    category: "technique",
    title: "Comment surmonter le blocage créatif",
    content: `Stratégies pour dépasser le blocage créatif :

1. CHANGER DE MÉDIUM
- Si tu dessines, essaie la musique
- Si tu écris, fais un croquis
- Le changement stimule de nouvelles connexions

2. CONTRAINTES CRÉATIVES
- "Dessine avec ta main non-dominante"
- "Écris un poème sans la lettre E"
- "Compose avec seulement 2 accords"
- Les limites libèrent la créativité

3. ROUTINE VS INSPIRATION
- 70% routine, 30% inspiration
- Crée à heure fixe chaque jour
- L'inspiration vient en créant, pas en attendant

4. EXERCICES ANTI-BLOCAGE :
- Free writing : écris sans t'arrêter 10 minutes
- Gribouillage : dessine sans réfléchir
- Collage : assemble des images au hasard
- Marche : 20 minutes de marche = boost créatif

5. ENVIRONNEMENT :
- Espace de travail dédié
- Musique adaptée (lo-fi, classique, nature)
- Écran bleu réduit 1h avant

Rappelle-toi : Le perfectionnisme est l'ennemi de la création.`,
    tags: ["créativité", "blocage", "motivation", "psychologie"],
    source: "expert"
  },
  {
    category: "technique",
    title: "Les 7 principes du design",
    content: `Les principes fondamentaux du design :

1. ÉQUILIBRE
- Symétrique : formel, stable
- Asymétrique : dynamique, moderne
- Radial : centré, circulaire

2. CONTRASTE
- Crée de l'hiérarchie visuelle
- Oppose : grand/petit, clair/sombre, lisse/texturé
- Sans contraste = design plat et ennuyeux

3. EMPHASE
- Un point focal par composition
- Utilise la couleur, la taille, l'espace
- Guide le regard du spectateur

4. PROPORTION
- Échelle relative des éléments
- Nombre d'or (1.618) pour l'harmonie
- Hiérarchie : important = grand

5. RYTHME
- Répétition d'éléments visuels
- Alternance de motifs
- Progression (du petit au grand)

6. UNITÉ
- Tous les éléments forment un tout cohérent
- Palette de couleurs limitée (3-5 couleurs)
- Typographie cohérente (max 2 polices)

7. ESPACE BLANC
- Aussi important que le contenu
- Améliore la lisibilité
- Donne une sensation de luxe

Application : Analyse tes designs préférés avec ces 7 principes.`,
    tags: ["design", "principes", "composition", "théorie"],
    source: "expert"
  },

  // === STYLES ARTISTIQUES ===
  {
    category: "style",
    title: "Mouvements artistiques majeurs",
    content: `Panorama des mouvements artistiques :

RENAISSANCE (1400-1600)
- Caractéristiques : perspective, réalisme, lumière
- Artistes : Léonard de Vinci, Michel-Ange, Raphaël
- Œuvres : La Joconde, La Création d'Adam

IMPRESSIONNISME (1870-1890)
- Caractéristiques : couleurs pures, lumière naturelle, touches visibles
- Artistes : Monet, Renoir, Degas
- Œuvres : Impression soleil levant, Les Nymphéas

ART NOUVEAU (1890-1910)
- Caractéristiques : lignes courbes, motifs végétaux, féminité
- Artistes : Mucha, Horta, Gaudi
- Œuvres : Les Saisons, Casa Batlló

CUBISME (1907-1920)
- Caractéristiques : formes géométriques, multiples perspectives
- Artistes : Picasso, Braque
- Œuvres : Les Demoiselles d'Avignon

SURRÉALISME (1920-1950)
- Caractéristiques : rêves, inconscient, juxtapositions étranges
- Artistes : Dalí, Magritte, Kahlo
- Œuvres : La Persistance de la mémoire

POP ART (1950-1970)
- Caractéristiques : culture populaire, couleurs vives, sérigraphie
- Artistes : Warhol, Lichtenstein
- Œuvres : Campbell's Soup Cans

ART NUMÉRIQUE (2000+)
- Caractéristiques : pixels, algorithmes, NFT
- Artistes : Beeple, Fewocious
- Œuvres : Everydays - The First 5000 Days`,
    tags: ["histoire de l'art", "mouvements", "culture", "inspiration"],
    source: "expert"
  }
];