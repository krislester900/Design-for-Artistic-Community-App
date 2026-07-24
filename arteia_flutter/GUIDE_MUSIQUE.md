# 🎵 Guide pour ajouter des musiques dans Vynora

## Comment ajouter une musique

### 1. Trouver l'ID YouTube
- Ouvre la vidéo YouTube
- L'ID est dans l'URL : `https://www.youtube.com/watch?v=**dQw4w9WgXcQ**
- Exemple : `https://www.youtube.com/watch?v=dQw4w9WgXcQ` → ID = `dQw4w9WgXcQ`

### 2. Trouver une image de cover
- Utilise une URL d'image (ex: `https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop`)
- Ou télécharge l'image dans `arteia_flutter/assets/images/covers/` et utilise le chemin local

### 3. Ajouter la chanson dans la liste

Ouvre le fichier `arteia_flutter/lib/pages/music_page.dart` et modifie la liste `_defaultSongs` :

```dart
Song(
  id: 'song-10',  // Incrémente l'ID
  title: 'Titre de ta chanson',
  artist: 'Nom de l\'artiste',
  albumName: 'Nom de l\'album',
  year: 2024,
  youtubeId: 'ID_YOUTUBE_ICI',
  albumCover: 'URL_DE_L_IMAGE_OU_CHEMIN_LOCAL',
),
```

## Exemple complet

```dart
Song(
  id: 'song-10',
  title: 'Bohemian Rhapsody',
  artist: 'Queen',
  albumName: 'A Night at the Opera',
  year: 1975,
  youtubeId: 'fJ9rUzIMcZQ',
  albumCover: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
),
```

## Structure de la liste actuelle

- **10 chansons** de démonstration avec covers Unsplash
- Toutes les covers sont des URLs externes (pas besoin de télécharger)
- Les YouTube IDs sont des vidéos réelles

## Pour utiliser des covers locales

1. Crée le dossier `arteia_flutter/assets/images/covers/`
2. Télécharge tes images dans ce dossier
3. Utilise le chemin : `'assets/images/covers/ta_image.jpg'`
4. Ajoute le dossier dans `pubspec.yaml` :

```yaml
flutter:
  assets:
    - assets/images/covers/
```

## Couleurs du thème Vynora

- **Fond principal** : `#000000` (noir)
- **Fond secondaire** : `#111111` (gris très foncé)
- **Texte principal** : `#FFFFFF` (blanc)
- **Texte secondaire** : `#9CA3AF` (gris clair)
- **Batterie verte** : `#4ADE80` (vert)
- **Glow blanc** : `#30FFFFFF` (blanc transparent)

## Build de l'APK

```bash
cd arteia_flutter
flutter build apk --release --android-skip-build-dependency-validation
```

L'APK sera dans : `build\app\outputs\flutter-apk\app-release.apk`