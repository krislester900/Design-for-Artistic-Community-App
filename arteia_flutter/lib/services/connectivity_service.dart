import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum ConnectivityStatus { connected, disconnected, checking }

class ConnectivityService extends ChangeNotifier {
  ConnectivityStatus _status = ConnectivityStatus.checking;
  Timer? _checkTimer;

  ConnectivityStatus get status => _status;
  bool get isConnected => _status == ConnectivityStatus.connected;
  bool get isDisconnected => _status == ConnectivityStatus.disconnected;

  ConnectivityService() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _checkConnectivity();
    _checkTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      // Essayer de joindre le serveur Supabase
      final result = await http
          .get(Uri.parse('https://supabase.co'))
          .timeout(const Duration(seconds: 5));

      if (result.statusCode == 200 || result.statusCode == 404) {
        _status = ConnectivityStatus.connected;
      } else {
        _status = ConnectivityStatus.disconnected;
      }
    } catch (_) {
      // Vérifier aussi avec une requête DNS simple
      try {
        final socket = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(seconds: 3),
        );
        socket.destroy();
        _status = ConnectivityStatus.connected;
      } catch (_) {
        _status = ConnectivityStatus.disconnected;
      }
    }

    notifyListeners();
  }

  Future<bool> waitForConnection({Duration timeout = const Duration(seconds: 30)}) async {
    if (isConnected) return true;

    try {
      await Future.any([
        // Attendre que la connexion revienne
        () async {
          while (true) {
            await Future.delayed(const Duration(seconds: 1));
            if (isConnected) return true;
          }
        }(),
        Future.delayed(timeout, () => false),
      ]);
      return isConnected;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }
}