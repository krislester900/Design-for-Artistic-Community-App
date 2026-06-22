import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ColorAnalysisService {
  /// Analyse les couleurs dominantes d'une image
  /// Retourne une liste de couleurs principales (max 5)
  static Future<List<Color>> extractDominantColors(ImageProvider imageProvider) async {
    try {
      final completer = Completer<ui.Image>();
      final stream = imageProvider.resolve(const ImageConfiguration());
      final listener = ImageStreamListener((ImageInfo info, bool synchronousCall) {
        completer.complete(info.image);
      });
      stream.addListener(listener);
      
      final ui.Image image = await completer.future;
      stream.removeListener(listener);
      
      // Convertir en byte data
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return [Colors.grey];
      
      final pixels = byteData.buffer.asUint8List();
      final colorMap = <int, int>{};
      
      // Échantillonner les pixels (1 pixel sur 10 pour la performance)
      for (int i = 0; i < pixels.length; i += 40) {
        final r = pixels[i];
        final g = pixels[i + 1];
        final b = pixels[i + 2];
        final a = pixels[i + 3];
        
        if (a < 128) continue; // Ignorer les pixels transparents
        
        // Quantifier les couleurs (réduire à 32 niveaux par canal)
        final quantized = ((r ~/ 8) << 16) | ((g ~/ 8) << 8) | (b ~/ 8);
        colorMap[quantized] = (colorMap[quantized] ?? 0) + 1;
      }
      
      // Trier par fréquence
      final sorted = colorMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      
      // Prendre les 5 couleurs les plus fréquentes
      final dominantColors = sorted.take(5).map((entry) {
        final r = ((entry.key >> 16) & 0xFF) * 8 + 4;
        final g = ((entry.key >> 8) & 0xFF) * 8 + 4;
        final b = (entry.key & 0xFF) * 8 + 4;
        return Color.fromRGBO(r, g, b, 1.0);
      }).toList();
      
      return dominantColors.isNotEmpty ? dominantColors : [Colors.grey];
    } catch (e) {
      return [Colors.grey];
    }
  }
  
  /// Génère des tags basés sur les couleurs dominantes
  static List<String> generateColorTags(List<Color> colors) {
    final tags = <String>[];
    
    for (final color in colors) {
      final hsl = HSLColor.fromColor(color);
      final hue = hsl.hue;
      final saturation = hsl.saturation;
      final lightness = hsl.lightness;
      
      // Tags basés sur la teinte
      if (saturation > 0.3) {
        if (hue < 15 || hue >= 345) tags.add('Rouge');
        else if (hue < 45) tags.add('Orange');
        else if (hue < 75) tags.add('Jaune');
        else if (hue < 150) tags.add('Vert');
        else if (hue < 210) tags.add('Cyan');
        else if (hue < 270) tags.add('Bleu');
        else if (hue < 300) tags.add('Violet');
        else tags.add('Magenta');
      }
      
      // Tags basés sur la luminosité
      if (lightness < 0.3) tags.add('Sombre');
      else if (lightness > 0.7) tags.add('Clair');
      
      // Tags basés sur la saturation
      if (saturation < 0.2) tags.add('Pastel');
      else if (saturation > 0.8) tags.add('Vif');
    }
    
    return tags.toSet().toList(); // Supprimer les doublons
  }
  
  /// Détermine le mood général basé sur les couleurs
  static String getMoodFromColors(List<Color> colors) {
    if (colors.isEmpty) return 'Neutre';
    
    var totalHue = 0.0;
    var totalSaturation = 0.0;
    var totalLightness = 0.0;
    
    for (final color in colors) {
      final hsl = HSLColor.fromColor(color);
      totalHue += hsl.hue;
      totalSaturation += hsl.saturation;
      totalLightness += hsl.lightness;
    }
    
    final avgHue = totalHue / colors.length;
    final avgSaturation = totalSaturation / colors.length;
    final avgLightness = totalLightness / colors.length;
    
    // Mood basé sur la teinte
    if (avgSaturation < 0.3) {
      if (avgLightness < 0.4) return 'Mélancolique';
      else if (avgLightness > 0.7) return 'Épuré';
      return 'Calme';
    }
    
    if (avgHue < 30 || avgHue >= 330) {
      if (avgSaturation > 0.6) return 'Énergique';
      return 'Chaleureux';
    } else if (avgHue < 90) {
      return 'Optimiste';
    } else if (avgHue < 150) {
      return 'Naturel';
    } else if (avgHue < 210) {
      return 'Serein';
    } else if (avgHue < 270) {
      if (avgLightness < 0.5) return 'Mystérieux';
      return 'Fraîcheur';
    } else {
      if (avgSaturation > 0.7) return 'Créatif';
      return 'Rêveur';
    }
  }
}