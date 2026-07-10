import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class _WordEntry {
  final String word;
  int frequency;
  _WordEntry(this.word, this.frequency);
}

class WordPredictorService {
  static final WordPredictorService _instance = WordPredictorService._internal();
  factory WordPredictorService() => _instance;
  WordPredictorService._internal();

  // Prefix → mots candidats triés par fréquence
  Map<String, List<_WordEntry>> _prefixIndex = {};

  // Bigrammes : mot précédent → liste de (mot suivant, fréquence)
  Map<String, List<_WordEntry>> _bigrams = {};

  // Fréquence globale des mots
  Map<String, int> _wordFrequency = {};

  // Taille max du vocabulaire
  static const int _maxVocabSize = 5000;
  static const int _maxSuggestions = 5;

  // Fichier de persistance
  String? _storagePath;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _storagePath = '${dir.path}/word_predictor_cache.json';
    await _load();
    _seedCommonFrench();
  }

  void _seedCommonFrench() {
    const commonWords = [
      'je', 'tu', 'il', 'elle', 'on', 'nous', 'vous', 'ils', 'elles',
      'le', 'la', 'les', 'un', 'une', 'des', 'du', 'de', 'au', 'aux',
      'est', 'sont', 'était', 'sera', 'a', 'ont', 'avait', 'aura',
      'pas', 'plus', 'très', 'trop', 'peu', 'assez', 'beaucoup',
      'et', 'ou', 'mais', 'donc', 'car', 'ni', 'que', 'qui', 'quoi',
      'dans', 'sur', 'avec', 'pour', 'par', 'sans', 'chez', 'entre',
      'ce', 'cet', 'cette', 'ces', 'mon', 'ton', 'son', 'ma', 'ta', 'sa',
      'mes', 'tes', 'ses', 'nos', 'vos', 'leurs',
      'bonjour', 'merci', 'salut', 'oui', 'non', 'peut-être',
      'faire', 'voir', 'dire', 'avoir', 'être', 'aller', 'pouvoir',
      'vouloir', 'savoir', 'devoir', 'falloir', 'mettre', 'prendre',
      'beau', 'belle', 'bon', 'bonne', 'grand', 'grande', 'petit', 'petite',
      'super', 'magnifique', 'génial', 'bravo', 'félicitations',
      'art', 'musique', 'dessin', 'peinture', 'photo', 'film',
      'création', 'projet', 'idée', 'inspiration', 'couleur',
      'comment', 'pourquoi', 'quand', 'où', 'combien', 'quel',
    ];
    for (final word in commonWords) {
      _addToIndex(word, 5);
    }
    _seedBigrams();
  }

  void _seedBigrams() {
    const bigrams = [
      ['je', 'suis'], ['je', 'vais'], ['je', 'peux'], ['je', 'veux'],
      ['je', 'pense'], ['je', 'crois'], ['je', 'sais'],
      ['c\'est', 'super'], ['c\'est', 'génial'], ['c\'est', 'beau'],
      ['c\'est', 'magnifique'], ['c\'est', 'vrai'],
      ['tu', 'es'], ['tu', 'vas'], ['tu', 'peux'], ['tu', 'veux'],
      ['il', 'est'], ['elle', 'est'], ['nous', 'sommes'],
      ['vous', 'êtes'], ['ils', 'sont'], ['elles', 'sont'],
      ['merci', 'beaucoup'], ['merci', 'infiniment'],
      ['très', 'beau'], ['très', 'belle'], ['très', 'bon'],
      ['très', 'bien'], ['très', 'content'],
      ['un', 'peu'], ['un', 'grand'], ['une', 'belle'],
      ['d\'accord', 'merci'], ['d\'accord', 'oui'],
      ['pas', 'de'], ['pas', 'très'], ['pas', 'encore'],
      ['de', 'la'], ['de', 'le'], ['de', 'l\''], ['de', 'mon'],
      ['à', 'la'], ['à', 'mon'], ['au', 'revoir'],
      ['salut', 'comment'], ['bonjour', 'comment'],
    ];
    for (final pair in bigrams) {
      _addBigram(pair[0], pair[1], 3);
    }
  }

  void _addToIndex(String word, [int freq = 1]) {
    _wordFrequency[word] = (_wordFrequency[word] ?? 0) + freq;

    for (int i = 1; i <= word.length; i++) {
      final prefix = word.substring(0, i);
      _prefixIndex.putIfAbsent(prefix, () => []);
      final existing = _prefixIndex[prefix]!.where((e) => e.word == word).firstOrNull;
      if (existing != null) {
        existing.frequency += freq;
      } else {
        _prefixIndex[prefix]!.add(_WordEntry(word, freq));
      }
    }
  }

  void _addBigram(String prev, String next, [int freq = 1]) {
    _bigrams.putIfAbsent(prev, () => []);
    final existing = _bigrams[prev]!.where((e) => e.word == next).firstOrNull;
    if (existing != null) {
      existing.frequency += freq;
    } else {
      _bigrams[prev]!.add(_WordEntry(next, freq));
    }
  }

  void learn(String text) {
    final words = text.toLowerCase().split(RegExp(r'[\s\p{P}]+')).where((w) => w.isNotEmpty).toList();

    if (_wordFrequency.length > _maxVocabSize) {
      _pruneVocab();
    }

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      if (word.length < 2) continue;

      _addToIndex(word);

      if (i > 0) {
        _addBigram(words[i - 1], word);
      }
    }

    _save();
  }

  void _pruneVocab() {
    final sorted = _wordFrequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final keep = sorted.take(_maxVocabSize ~/ 2).map((e) => e.key).toSet();

    _wordFrequency.removeWhere((k, _) => !keep.contains(k));
    _prefixIndex.removeWhere((_, entries) {
      entries.removeWhere((e) => !keep.contains(e.word));
      return entries.isEmpty;
    });
    _bigrams.removeWhere((_, entries) {
      entries.removeWhere((e) => !keep.contains(e.word));
      return entries.isEmpty;
    });
  }

  /// Suggère des mots basés sur le préfixe courant + mot précédent (bigramme)
  List<String> suggest(String currentWord, {String? previousWord}) {
    if (currentWord.isEmpty) return [];

    final prefix = currentWord.toLowerCase();
    final candidates = <_WordEntry>[];

    // 1. Match bigramme si on a un mot précédent
    if (previousWord != null && _bigrams.containsKey(previousWord)) {
      final bigramMatches = _bigrams[previousWord]!
          .where((e) => e.word.startsWith(prefix))
          .toList();
      if (bigramMatches.isNotEmpty) {
        candidates.addAll(bigramMatches);
      }
    }

    // 2. Match préfixe général
    if (_prefixIndex.containsKey(prefix)) {
      for (final entry in _prefixIndex[prefix]!) {
        final existing = candidates.where((e) => e.word == entry.word).firstOrNull;
        if (existing != null) {
          existing.frequency += entry.frequency;
        } else {
          candidates.add(_WordEntry(entry.word, entry.frequency));
        }
      }
    }

    // 3. Trier par fréquence descendante, limiter
    candidates.sort((a, b) => b.frequency.compareTo(a.frequency));
    return candidates.take(_maxSuggestions).map((e) => e.word).toList();
  }

  Future<void> _save() async {
    if (_storagePath == null) return;
    try {
      final data = {
        'words': _wordFrequency.map((k, v) => MapEntry(k, v)),
        'bigrams': _bigrams.map((k, entries) => MapEntry(
            k, entries.map((e) => {'word': e.word, 'freq': e.frequency}).toList())),
      };
      final file = File(_storagePath!);
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<void> _load() async {
    if (_storagePath == null) return;
    try {
      final file = File(_storagePath!);
      if (!await file.exists()) return;
      final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      if (data['words'] is Map) {
        final words = data['words'] as Map<String, dynamic>;
        for (final entry in words.entries) {
          _addToIndex(entry.key, entry.value as int);
        }
      }

      if (data['bigrams'] is Map) {
        final bigrams = data['bigrams'] as Map<String, dynamic>;
        for (final entry in bigrams.entries) {
          for (final e in entry.value as List) {
            _addBigram(entry.key, e['word'], e['freq'] as int);
          }
        }
      }
    } catch (_) {}
  }
}
