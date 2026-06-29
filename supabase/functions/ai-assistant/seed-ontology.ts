// Seed : Ontologie artistique Arteïa
// Concepts, relations et taxonomie pour l'assistant IA

export const ONTOLOGY_SEED = {
  // === TAXONOMIE (arbre des catégories) ===
  taxonomy: [
    // Niveau 0 : Grands domaines
    { slug: "art", label: "Art", level: 0, path: ["art"] },
    { slug: "art-visuel", label: "Art visuel", parent: "art", level: 1, path: ["art", "art-visuel"] },
    { slug: "musique", label: "Musique", parent: "art", level: 1, path: ["art", "musique"] },
    { slug: "ecriture", label: "Écriture", parent: "art", level: 1, path: ["art", "ecriture"] },
    { slug: "bd-manga", label: "BD/Manga", parent: "art", level: 1, path: ["art", "bd-manga"] },
    
    // Niveau 2 : Sous-catégories
    { slug: "peinture", label: "Peinture", parent: "art-visuel", level: 2, path: ["art", "art-visuel", "peinture"] },
    { slug: "dessin", label: "Dessin", parent: "art-visuel", level: 2, path: ["art", "art-visuel", "dessin"] },
    { slug: "photographie", label: "Photographie", parent: "art-visuel", level: 2 },
    { slug: "sculpture", label: "Sculpture", parent: "art-visuel", level: 2 },
    { slug: "art-numerique", label: "Art numérique", parent: "art-visuel", level: 2 },
    
    // Musique
    { slug: "composition", label: "Composition", parent: "musique", level: 2 },
    { slug: "production", label: "Production musicale", parent: "musique", level: 2 },
    { slug: "chant", label: "Chant", parent: "musique", level: 2 },
    { slug: "instrument", label: "Instrument", parent: "musique", level: 2 },
    
    // Écriture
    { slug: "poesie", label: "Poésie", parent: "ecriture", level: 2 },
    { slug: "fiction", label: "Fiction", parent: "ecriture", level: 2 },
    { slug: "scenario", label: "Scénario", parent: "ecriture", level: 2 },
    
    // BD/Manga
    { slug: "storyboard", label: "Storyboard", parent: "bd-manga", level: 2 },
    { slug: "character-design", label: "Character design", parent: "bd-manga", level: 2 },
    { slug: "lettering", label: "Lettrage", parent: "bd-manga", level: 2 },
  ],

  // === CONCEPTS ===
  concepts: [
    // ART VISUEL - Techniques
    { slug: "theorie-couleurs", label: "Théorie des couleurs", category: "theorie",
      description: "Science et art de l'utilisation des couleurs. Comprend le cercle chromatique, les harmonies et la psychologie des couleurs.",
      icon: "🎨", difficulty: "debutant" },
    { slug: "cercle-chromatique", label: "Cercle chromatique", category: "theorie",
      description: "Représentation circulaire des couleurs organisées par teinte. Outil fondamental pour comprendre les relations entre couleurs.",
      icon: "🔄", difficulty: "debutant" },
    { slug: "composition", label: "Composition visuelle", category: "technique",
      description: "Organisation des éléments dans une œuvre. Inclut la règle des tiers, le nombre d'or, l'équilibre.",
      icon: "📐", difficulty: "intermediaire" },
    { slug: "perspective", label: "Perspective", category: "technique",
      description: "Technique de représentation de la profondeur et de l'espace tridimensionnel sur une surface plane.",
      icon: "📏", difficulty: "avance" },
    { slug: "aquarelle", label: "Aquarelle", category: "medium",
      description: "Technique de peinture utilisant des pigments dilués dans l'eau. Caractérisée par sa transparence et sa fluidité.",
      icon: "💧", difficulty: "intermediaire" },
    { slug: "huile", label: "Peinture à l'huile", category: "medium",
      description: "Technique utilisant des pigments mélangés à de l'huile. Permet des dégradés riches et une grande profondeur.",
      icon: "🖌️", difficulty: "avance" },
      
    // ART VISUEL - Styles/Mouvements
    { slug: "impressionnisme", label: "Impressionnisme", category: "mouvement",
      description: "Mouvement artistique (1870-1890) caractérisé par des touches de couleur pures et la capture de la lumière naturelle.",
      icon: "🌅", difficulty: "debutant" },
    { slug: "cubisme", label: "Cubisme", category: "mouvement",
      description: "Mouvement (1907-1920) qui décompose les objets en formes géométriques et perspectives multiples.",
      icon: "🔶", difficulty: "intermediaire" },
    { slug: "surrealisme", label: "Surréalisme", category: "mouvement",
      description: "Mouvement (1920-1950) explorant l'inconscient, les rêves et les juxtapositions surprenantes.",
      icon: "🌙", difficulty: "intermediaire" },
    { slug: "minimalisme", label: "Minimalisme", category: "style",
      description: "Style caractérisé par la simplicité, l'épure et la réduction à l'essentiel.",
      icon: "⬜", difficulty: "debutant" },

    // ARTISTES
    { slug: "davinci", label: "Léonard de Vinci", category: "artiste",
      description: "Artiste et inventeur de la Renaissance (1452-1519). Célèbre pour La Joconde, La Cène, et ses études anatomiques.",
      icon: "👨‍🎨" },
    { slug: "vangogh", label: "Vincent van Gogh", category: "artiste",
      description: "Peintre post-impressionniste néerlandais (1853-1890). Connu pour La Nuit étoilée et ses tournesols.",
      icon: "🌻" },
    { slug: "picasso", label: "Pablo Picasso", category: "artiste",
      description: "Artiste espagnol (1881-1973), co-fondateur du cubisme. Périodes bleue, rose et cubiste.",
      icon: "🎭" },

    // MUSIQUE - Concepts
    { slug: "gamme", label: "Gamme musicale", category: "theorie",
      description: "Suite de notes ordonnées par hauteur. La gamme majeure sonne joyeuse, la mineure mélancolique.",
      icon: "🎵", difficulty: "debutant" },
    { slug: "accord", label: "Accord", category: "theorie",
      description: "Ensemble d'au moins trois notes jouées simultanément. Base de l'harmonie musicale.",
      icon: "🎹", difficulty: "debutant" },
    { slug: "rythme", label: "Rythme", category: "theorie",
      description: "Organisation des durées et des accents dans le temps. Donne le groove et l'énergie.",
      icon: "🥁", difficulty: "debutant" },
    { slug: "blues", label: "Blues", category: "genre",
      description: "Genre musical né au XIXe siècle dans le sud des États-Unis. Base du jazz, rock et soul.",
      icon: "🎸", difficulty: "debutant" },
    { slug: "jazz", label: "Jazz", category: "genre",
      description: "Genre musical caractérisé par l'improvisation, les syncopes et les accords complexes.",
      icon: "🎷", difficulty: "intermediaire" },

    // ÉCRITURE
    { slug: "haiku", label: "Haïku", category: "format",
      description: "Poème court japonais de 3 vers (5-7-5 syllabes) évoquant un instant de nature.",
      icon: "🌸", difficulty: "debutant" },
    { slug: "sonnet", label: "Sonnet", category: "format",
      description: "Poème de 14 vers avec une structure de rimes spécifique. Popularisé par Pétrarque et Shakespeare.",
      icon: "📜", difficulty: "avance" },
    { slug: "nouvelle", label: "Nouvelle", category: "format",
      description: "Récit court et intense, généralement focalisé sur un seul événement ou personnage.",
      icon: "📖", difficulty: "intermediaire" },
    { slug: "show-dont-tell", label: "Show don't tell", category: "technique",
      description: "Technique d'écriture qui consiste à montrer les émotions via des actions plutôt que les décrire.",
      icon: "🎭", difficulty: "intermediaire" },

    // BD/MANGA
    { slug: "manga", label: "Manga", category: "genre",
      description: "Bande dessinée japonaise caractérisée par son sens de lecture droite-gauche et ses codes graphiques distincts.",
      icon: "📚", difficulty: "debutant" },
    { slug: "shonen", label: "Shōnen", category: "genre",
      description: "Manga pour jeunes garçons, axé sur l'action, l'aventure et la camaraderie.",
      icon: "⚡", difficulty: "debutant" },
    { slug: "shojo", label: "Shōjo", category: "genre",
      description: "Manga pour jeunes filles, axé sur les relations, les émotions et la romance.",
      icon: "💕", difficulty: "debutant" },
    { slug: "onomatopee", label: "Onomatopée", category: "technique",
      description: "Mots imitant des sons (BOOM, WHAM, ZZZ). Essentiels en BD pour retranscrire l'ambiance sonore.",
      icon: "💥", difficulty: "debutant" },

    // CONCEPTS GÉNÉRAUX
    { slug: "blocage-creatif", label: "Blocage créatif", category: "theorie",
      description: "Incapacité temporaire à créer ou trouver l'inspiration. Solutions : changer de médium, contraintes, routine.",
      icon: "🚧", difficulty: "debutant" },
    { slug: "feedback-artistique", label: "Feedback artistique", category: "technique",
      description: "Retour constructif sur une œuvre. Doit être spécifique, équilibré et orienté vers la progression.",
      icon: "💬", difficulty: "intermediaire" },
  ],

  // === RELATIONS ===
  relations: [
    // Hiérarchie : est_un
    { source: "haiku", target: "poesie", type: "est_un", weight: 1.0 },
    { source: "sonnet", target: "poesie", type: "est_un", weight: 1.0 },
    { source: "nouvelle", target: "fiction", type: "est_un", weight: 1.0 },
    { source: "manga", target: "bd-manga", type: "est_un", weight: 1.0 },
    { source: "shonen", target: "manga", type: "est_un", weight: 1.0 },
    { source: "shojo", target: "manga", type: "est_un", weight: 1.0 },
    { source: "aquarelle", target: "peinture", type: "est_un", weight: 1.0 },
    { source: "huile", target: "peinture", type: "est_un", weight: 1.0 },
    { source: "blues", target: "musique", type: "est_un", weight: 1.0 },
    { source: "jazz", target: "musique", type: "est_un", weight: 1.0 },

    // Influence
    { source: "impressionnisme", target: "vangogh", type: "influence", weight: 0.9,
      description: "Van Gogh a été profondément influencé par l'impressionnisme après son arrivée à Paris" },
    { source: "cubisme", target: "picasso", type: "influence", weight: 0.9,
      description: "Picasso a co-fondé le cubisme avec Braque" },
    { source: "blues", target: "jazz", type: "influence", weight: 0.8,
      description: "Le jazz est né du blues et du ragtime" },

    // Contient
    { source: "theorie-couleurs", target: "cercle-chromatique", type: "contient", weight: 1.0 },
    { source: "composition", target: "perspective", type: "contient", weight: 0.7 },

    // Utilise
    { source: "aquarelle", target: "theorie-couleurs", type: "utilise", weight: 0.8 },
    { source: "composition", target: "show-dont-tell", type: "similaire_a", weight: 0.6,
      description: "La composition visuelle et le 'show don't tell' partagent le même principe de guider le spectateur/lecteur" },

    // Exemple (œuvres -> artistes ou mouvements)
    { source: "davinci", target: "impressionnisme", type: "precede", weight: 0.5,
      description: "De Vinci a précédé l'impressionnisme de plusieurs siècles" },
    { source: "surrealisme", target: "blocage-creatif", type: "contredit", weight: 0.4,
      description: "Le surréalisme embrasse l'inconscient comme source de création, contrairement au blocage" },
  ]
};