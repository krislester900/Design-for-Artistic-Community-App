import 'dart:math';

class PromptGeneratorService {
  static final Map<String, List<String>> _stylePrompts = {
    'visual': [
      'Imagine une œuvre surréaliste avec des couleurs {colors}',
      'Crée un croquis minimaliste inspiré par {influence}',
      'Développe une illustration numérique avec un mood {mood}',
      'Peins une aquarelle représentant {theme} en style {style}',
      'Conçois un portrait abstrait mêlant {color1} et {color2}',
    ],
    'music': [
      'Compose une mélodie {mood} avec des influences {influence}',
      'Crée un beat lo-fi inspiré par {influence}',
      'Fais un remix de ce morceau en ajoutant des éléments {style}',
      'Imagine une progression d\'accords qui évoque {mood}',
      'Produis un morceau ambient avec des textures {style}',
    ],
    'writing': [
      'Écris un poème sur le thème de {theme} avec un ton {mood}',
      'Développe une micro-fiction dont le personnage principal est {influence}',
      'Rédige un dialogue entre deux artistes sur {theme}',
      'Crée une description sensorielle évoquant {mood}',
      'Imagine une lettre d\'un artiste à son inspiration',
    ],
    'comics': [
      'Crée une planche de BD muette sur le thème {theme}',
      'Dessine un one-page comic avec un twist {mood}',
      'Imagine un storyboard pour une scène clé de {influence}',
      'Conçois un personnage de manga avec le style {style}',
      'Développe une courte séquence narrative sur {theme}',
    ],
  };

  static final List<String> _colors = ['chaudes', 'froides', 'pastel', 'vives', 'monochromes', 'complémentaires'];
  static final List<String> _moods = ['mélancolique', 'joyeux', 'mystérieux', 'énergique', 'rêveur', 'sombre', 'lumineux'];
  static final List<String> _themes = ['la nature', 'la ville', 'les rêves', 'le temps', 'les émotions', 'le cosmos', 'l\'eau', 'le feu'];
  static final List<String> _styles = ['impressionniste', 'surréaliste', 'minimaliste', 'baroque', 'moderne', 'classique', 'abstrait'];
  static final List<String> _influences = ['Van Gogh', 'Studio Ghibli', 'Hayao Miyazaki', 'Nujabes', 'Daft Punk', 'Miles Davis'];

  static String generatePrompt(String contentType, {Map<String, String>? context}) {
    final rand = Random();
    final prompts = _stylePrompts[contentType] ?? _stylePrompts['visual']!;
    final template = prompts[rand.nextInt(prompts.length)];

    return template
        .replaceAll('{colors}', _colors[rand.nextInt(_colors.length)])
        .replaceAll('{color1}', _colors[rand.nextInt(_colors.length)])
        .replaceAll('{color2}', _colors[rand.nextInt(_colors.length)])
        .replaceAll('{mood}', _moods[rand.nextInt(_moods.length)])
        .replaceAll('{theme}', _themes[rand.nextInt(_themes.length)])
        .replaceAll('{style}', _styles[rand.nextInt(_styles.length)])
        .replaceAll('{influence}', _influences[rand.nextInt(_influences.length)]);
  }

  static List<String> generateVariations(String contentType, {int count = 3}) {
    return List.generate(count, (_) => generatePrompt(contentType));
  }
}