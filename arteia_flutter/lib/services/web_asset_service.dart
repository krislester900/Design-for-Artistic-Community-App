import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Serveur HTTP local qui sert les assets Flutter via http://localhost.
/// 
/// Android WebView bloque le chargement croisé de fichiers depuis file://
/// (restriction de sécurité Chromium). Ce serveur contourne ce problème
/// en extrayant les assets dans le cache de l'app et les servant sur localhost.
class LocalWebServer {
  static HttpServer? _server;
  static const int _port = 8787;
  static String? _cacheRoot;
  static bool _initialized = false;

  /// Démarre le serveur et extrait tous les assets de jeux dans le cache.
  static Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    try {
      final tempDir = await getTemporaryDirectory();
      _cacheRoot = '${tempDir.path}/arteia_web_assets';
      await Directory(_cacheRoot!).create(recursive: true);

      // Extraire tous les assets web vers le cache
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final allAssets = manifest.listAssets();
      final webAssets = allAssets.where(
        (a) => a.startsWith('assets/games/') || a.startsWith('assets/vynora_playlist/'),
      ).toList();

      for (final assetPath in webAssets) {
        try {
          // assetPath = "assets/games/simple_card_stack/index.html"
          // on veut : _cacheRoot/assets/games/simple_card_stack/index.html
          final destFile = File('$_cacheRoot/$assetPath');
          if (!await destFile.exists()) {
            await destFile.parent.create(recursive: true);
            final data = await rootBundle.load(assetPath);
            await destFile.writeAsBytes(data.buffer.asUint8List());
          }
        } catch (e) {
          debugPrint('LocalWebServer: skip $assetPath – $e');
        }
      }

      // Démarrer le serveur HTTP
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
      _server!.listen(_handleRequest);
      _initialized = true;
      debugPrint('✅ LocalWebServer démarré sur http://localhost:$_port');
    } catch (e) {
      debugPrint('⚠️ LocalWebServer échec: $e');
    }
  }

  static void _handleRequest(HttpRequest request) async {
    final uriPath = request.uri.path;
    // Normalize: /assets/games/... → _cacheRoot/assets/games/...
    final filePath = '$_cacheRoot$uriPath';
    final file = File(filePath);

    try {
      if (await file.exists()) {
        final mimeType = _mimeType(file.path);
        request.response.headers
          ..set('Content-Type', mimeType)
          ..set('Access-Control-Allow-Origin', '*');
        await request.response.addStream(file.openRead());
      } else {
        request.response.statusCode = 404;
        request.response.write('Not found: $uriPath');
      }
    } catch (e) {
      request.response.statusCode = 500;
      request.response.write('Error: $e');
    } finally {
      await request.response.close();
    }
  }

  /// Retourne l'URL localhost pour un asset donné.
  /// 
  /// Exemple : getUrl('assets/games/simple_card_stack/index.html')
  ///   → 'http://localhost:8787/assets/games/simple_card_stack/index.html'
  static String getUrl(String assetPath) {
    return 'http://localhost:$_port/$assetPath';
  }

  static String _mimeType(String path) {
    if (path.endsWith('.html')) return 'text/html; charset=utf-8';
    if (path.endsWith('.js') || path.endsWith('.mjs')) return 'application/javascript';
    if (path.endsWith('.css')) return 'text/css';
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.svg')) return 'image/svg+xml';
    if (path.endsWith('.woff2')) return 'font/woff2';
    if (path.endsWith('.woff')) return 'font/woff';
    if (path.endsWith('.json')) return 'application/json';
    return 'application/octet-stream';
  }

  static Future<void> dispose() async {
    await _server?.close(force: true);
    _server = null;
    _initialized = false;
  }
}
