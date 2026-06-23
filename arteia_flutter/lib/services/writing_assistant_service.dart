class WritingAssistantService {
  static final Map<String, List<String>> _styleSuggestions = {
    'poetry': [
      'Utilise des métaphores visuelles fortes',
      'Joue avec les rythmes et les sonorités',
      'Évoque des émotions par l\'imagerie sensorielle',
      'Contraste le concret et l\'abstrait',
    ],
    'fiction': [
      'Montre, ne dis pas : utilise des actions pour révéler les émotions',
      'Crée des dialogues qui révèlent la personnalité',
      'Utilise les cinq sens pour immerger le lecteur',
      'Varie le rythme des phrases pour créer du suspense',
    ],
    'description': [
      'Peins avec des mots : utilise des détails précis',
      'Évoque les sensations plutôt que de les nommer',
      'Crée des images mentales fortes',
      'Joue avec les contrastes et les oppositions',
    ],
  };

  static final Map<String, List<String>> _tonCorrections = {
    'mélancolique': ['adoucis le ton', 'utilise des métaphores nocturnes', 'privilégie les mots doux-amers'],
    'énergique': ['utilise des phrases courtes et dynamiques', 'privilégie les verbes d\'action', 'rythme soutenu'],
    'poétique': ['joue avec les sonorités', 'utilise des comparaisons', 'crée des images surréalistes'],
    'minimaliste': ['va à l\'essentiel', 'chaque mot compte', 'suggère plus que tu ne décris'],
  };

  static String getSuggestion(String contentType) {
    final suggestions = _styleSuggestions[contentType] ?? _styleSuggestions['fiction']!;
    return suggestions[suggestions.length % suggestions.length];
  }

  static String getTonCorrection(String ton) {
    final corrections = _tonCorrections[ton] ?? _tonCorrections['poétique']!;
    return corrections[corrections.length % corrections.length];
  }

  static String completeSentence(String start) {
    final completions = [
      'et c\'est ainsi que l\'art prit vie sous ses doigts.',
      'comme si le temps lui-même s\'arrêtait pour contempler.',
      'dans un tourbillon de couleurs et d\'émotions.',
      'chaque trait révélant un peu plus de son âme.',
      'là où la réalité rejoint l\'imaginaire.',
      'et le public retint son souffle, émerveillé.',
    ];
    return '$start ${completions[start.length % completions.length]}';
  }
}