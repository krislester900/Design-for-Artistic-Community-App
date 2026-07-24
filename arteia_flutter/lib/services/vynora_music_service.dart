import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class VynoraSong {
  final String id;
  final String title;
  final String artist;
  final String youtubeId;
  final String albumName;
  final int year;
  String albumCover;

  VynoraSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.youtubeId,
    required this.albumName,
    required this.year,
    this.albumCover = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'youtubeId': youtubeId,
      'albumName': albumName,
      'year': year,
      'albumCover': albumCover,
    };
  }
}

class VynoraDatabase {
  static const _songs = [
    // Top 50 trending songs - covers loaded dynamically from iTunes API
    {
      'id': '1',
      'title': 'Anti-Hero',
      'artist': 'Taylor Swift',
      'youtubeId': 'b1kbLWvqugk',
      'albumName': 'Midnights',
      'year': 2022,
    },
    {
      'id': '2',
      'title': 'Flowers',
      'artist': 'Miley Cyrus',
      'youtubeId': 'G7KNmW9a75Y',
      'albumName': 'Endless Summer Vacation',
      'year': 2023,
    },
    {
      'id': '3',
      'title': 'Unholy',
      'artist': 'Sam Smith',
      'youtubeId': 'Uq9gPaIzbe8',
      'albumName': 'Gloria',
      'year': 2023,
    },
    {
      'id': '4',
      'title': 'As It Was',
      'artist': 'Harry Styles',
      'youtubeId': 'H5v3kku4y6Q',
      'albumName': "Harry's House",
      'year': 2022,
    },
    {
      'id': '5',
      'title': 'Heat Waves',
      'artist': 'Glass Animals',
      'youtubeId': 'mRD0-GxqHVo',
      'albumName': 'Dreamland',
      'year': 2020,
    },
    {
      'id': '6',
      'title': 'Stay',
      'artist': 'The Kid LAROI',
      'youtubeId': 'kTJczUoc26U',
      'albumName': 'F*CK LOVE 3: OVER YOU',
      'year': 2021,
    },
    {
      'id': '7',
      'title': 'Industry Baby',
      'artist': 'Lil Nas X',
      'youtubeId': 'UTHLKHL_whs',
      'albumName': 'MONTERO',
      'year': 2021,
    },
    {
      'id': '8',
      'title': 'Good 4 U',
      'artist': 'Olivia Rodrigo',
      'youtubeId': 'gNi_6U5Pm_o',
      'albumName': 'SOUR',
      'year': 2021,
    },
    {
      'id': '9',
      'title': 'Levitating',
      'artist': 'Dua Lipa',
      'youtubeId': 'TUVcZfQe-Kw',
      'albumName': 'Future Nostalgia',
      'year': 2020,
    },
    {
      'id': '10',
      'title': 'Blinding Lights',
      'artist': 'The Weeknd',
      'youtubeId': '4NRXx6U8ABQ',
      'albumName': 'After Hours',
      'year': 2020,
    },
    {
      'id': '11',
      'title': 'Watermelon Sugar',
      'artist': 'Harry Styles',
      'youtubeId': 'E07s5ZYydMg',
      'albumName': 'Fine Line',
      'year': 2019,
    },
    {
      'id': '12',
      'title': 'Bad Habits',
      'artist': 'Ed Sheeran',
      'youtubeId': 'orjz9wfgMOc',
      'albumName': '=',
      'year': 2021,
    },
    {
      'id': '13',
      'title': 'Montero (Call Me By Your Name)',
      'artist': 'Lil Nas X',
      'youtubeId': '6swmTBVI83k',
      'albumName': 'MONTERO',
      'year': 2021,
    },
    {
      'id': '14',
      'title': 'Peaches',
      'artist': 'Justin Bieber',
      'youtubeId': 'tQ0yjYUFKAE',
      'albumName': 'Justice',
      'year': 2021,
    },
    {
      'id': '15',
      'title': 'Kiss Me More',
      'artist': 'Doja Cat',
      'youtubeId': '0EVVKs6DQLo',
      'albumName': 'Planet Her',
      'year': 2021,
    },
    {
      'id': '16',
      'title': 'Save Your Tears',
      'artist': 'The Weeknd',
      'youtubeId': 'XXYlFuWEuKI',
      'albumName': 'After Hours',
      'year': 2020,
    },
    {
      'id': '17',
      'title': 'Drivers License',
      'artist': 'Olivia Rodrigo',
      'youtubeId': '7sVxqdQj8Ck',
      'albumName': 'SOUR',
      'year': 2021,
    },
    {
      'id': '18',
      'title': 'Dakiti',
      'artist': 'Bad Bunny',
      'youtubeId': 'k8ipTn3CnqQ',
      'albumName': 'El Ultimo Tour Del Mundo',
      'year': 2020,
    },
    {
      'id': '19',
      'title': 'Mood',
      'artist': '24kGoldn',
      'youtubeId': '3A2qN4BGmKU',
      'albumName': 'El Dorado',
      'year': 2020,
    },
    {
      'id': '20',
      'title': 'Savage Love',
      'artist': 'Jawsh 685',
      'youtubeId': '5LCuhWzDB2o',
      'albumName': 'Savage Love',
      'year': 2020,
    },
  ];

  static List<VynoraSong> getAllSongs() {
    return _songs.map((song) => VynoraSong(
      id: song['id'] as String,
      title: song['title'] as String,
      artist: song['artist'] as String,
      youtubeId: song['youtubeId'] as String,
      albumName: song['albumName'] as String,
      year: song['year'] as int,
    )).toList();
  }

  static VynoraSong? getSongById(String id) {
    try {
      final song = _songs.firstWhere((s) => s['id'] == id);
      return VynoraSong(
        id: song['id'] as String,
        title: song['title'] as String,
        artist: song['artist'] as String,
        youtubeId: song['youtubeId'] as String,
        albumName: song['albumName'] as String,
        year: song['year'] as int,
      );
    } catch (e) {
      return null;
    }
  }

  static List<VynoraSong> searchSongs(String query) {
    if (query.isEmpty) return getAllSongs();
    final lowerQuery = query.toLowerCase();
    return getAllSongs().where((song) =>
      song.title.toLowerCase().contains(lowerQuery) ||
      song.artist.toLowerCase().contains(lowerQuery) ||
      song.albumName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  static List<VynoraSong> getSongsByArtist(String artist) {
    if (artist.isEmpty) return getAllSongs();
    final lowerArtist = artist.toLowerCase();
    return getAllSongs().where((song) =>
      song.artist.toLowerCase().contains(lowerArtist)
    ).toList();
  }

  static List<VynoraSong> getRandomSongs(int count) {
    final random = Random();
    final shuffled = getAllSongs()..shuffle(random);
    return shuffled.take(count).toList();
  }
}

class ITunesAPIService {
  static const _baseUrl = 'https://itunes.apple.com/search';
  final Map<String, String> _coverCache = {};

  Future<String?> getAlbumCover(String artist, String track) async {
    final cacheKey = '${artist.toLowerCase()}-${track.toLowerCase()}';
    if (_coverCache.containsKey(cacheKey)) {
      return _coverCache[cacheKey];
    }

    try {
      final cleanArtist = _cleanTerm(artist);
      final cleanTrack = _cleanTerm(track);
      final query = Uri.encodeComponent('$cleanArtist $cleanTrack');
      final url = '$_baseUrl?term=$query&media=music&entity=song&limit=5';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final data = json.decode(response.body);
      if (data['resultCount'] == 0) return null;

      final results = data['results'] as List;
      final bestMatch = _findBestMatch(results, cleanArtist, cleanTrack);
      if (bestMatch != null && bestMatch['artworkUrl100'] != null) {
        final highQuality = (bestMatch['artworkUrl100'] as String).replaceFirst('100x100bb', '600x600bb');
        _coverCache[cacheKey] = highQuality;
        return highQuality;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>> getBatchCovers(List<VynoraSong> songs) async {
    final results = <String, String>{};

    for (var i = 0; i < songs.length; i++) {
      final song = songs[i];
      final cacheKey = '${song.artist.toLowerCase()}-${song.title.toLowerCase()}';

      if (_coverCache.containsKey(cacheKey)) {
        results[cacheKey] = _coverCache[cacheKey]!;
        continue;
      }

      final cover = await getAlbumCover(song.artist, song.title);
      if (cover != null) {
        results[cacheKey] = cover;
      }

      if (i < songs.length - 1) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    return results;
  }

  String getFallbackArtwork(String artist, String track) {
    final hash = _simpleHash(artist + track);
    final hue = hash % 360;
    final saturation = 30 + (hash % 40);
    final lightness = 20 + (hash % 30);

    return 'data:image/svg+xml;base64,${base64.encode(utf8.encode('''
      <svg width="600" height="600" viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg">
        <defs>
          <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" style="stop-color:hsl($hue, $saturation%, ${lightness + 10}%);stop-opacity:1" />
            <stop offset="100%" style="stop-color:hsl(${(hue + 60) % 360}, $saturation%, $lightness%);stop-opacity:1" />
          </linearGradient>
        </defs>
        <rect width="600" height="600" fill="url(#grad1)"/>
        <circle cx="300" cy="300" r="120" fill="none" stroke="rgba(255,255,255,0.3)" stroke-width="3"/>
        <circle cx="300" cy="300" r="80" fill="none" stroke="rgba(255,255,255,0.2)" stroke-width="2"/>
        <circle cx="300" cy="300" r="40" fill="rgba(255,255,255,0.2)"/>
        <circle cx="300" cy="300" r="15" fill="rgba(255,255,255,0.4)"/>
        <text x="300" y="480" text-anchor="middle" fill="rgba(255,255,255,0.8)" font-family="Arial, sans-serif" font-size="24" font-weight="300">${_truncate(artist, 20)}</text>
        <text x="300" y="520" text-anchor="middle" fill="rgba(255,255,255,0.6)" font-family="Arial, sans-serif" font-size="18" font-weight="300">${_truncate(track, 25)}</text>
      </svg>
    '''))}';
  }

  Map<String, dynamic>? _findBestMatch(List results, String artist, String track) {
    if (results.isEmpty) return null;

    final scored = results.map((result) {
      final resultArtist = _cleanTerm(result['artistName'] ?? '');
      final resultTrack = _cleanTerm(result['trackName'] ?? result['collectionName'] ?? '');

      var score = 0;
      if (resultArtist == artist) score += 20;
      else if (resultArtist.contains(artist) || artist.contains(resultArtist)) score += 10;

      if (resultTrack == track) score += 15;
      else if (resultTrack.contains(track) || track.contains(resultTrack)) score += 8;

      if (result['artworkUrl100'] != null) score += 5;

      return {'result': result, 'score': score};
    }).toList();

    scored.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));

    final best = scored.first;
    return best['score'] as int > 5 ? best['result'] as Map<String, dynamic> : null;
  }

  String _cleanTerm(String term) {
    return term
        .toLowerCase()
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'ft\.?.*'), '')
        .replaceAll(RegExp(r'feat\.?.*'), '')
        .replaceAll(RegExp(r'featuring.*'), '')
        .replaceAll(RegExp(r'\s*&\s*.*'), '')
        .replaceAll(RegExp(r'\s*x\s*.*'), '')
        .replaceAll(RegExp(r'\s*with\s*.*'), '')
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  int _simpleHash(String str) {
    var hash = 0;
    for (var i = 0; i < str.length; i++) {
      final char = str.codeUnitAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return hash.abs();
  }

  String _truncate(String text, int maxLength) {
    return text.length > maxLength ? text.substring(0, maxLength - 3) + '...' : text;
  }
}