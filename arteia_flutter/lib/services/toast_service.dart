import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

class ToastService {
  ToastService._();
  static final ToastService instance = ToastService._();

  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;
  BuildContext? _context;

  void init({GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey}) {
    _scaffoldMessengerKey = scaffoldMessengerKey;
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show({
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = _getMessenger();
    if (messenger == null) return null;

    final color = _colorForType(type);
    final icon = _iconForType(type);

    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
      duration: duration,
      action: actionLabel != null
          ? SnackBarAction(label: actionLabel, textColor: Colors.white, onPressed: onAction ?? () {})
          : null,
    );

    return messenger.showSnackBar(snackBar);
  }

  ScaffoldMessengerState? _getMessenger() {
    if (_scaffoldMessengerKey?.currentState != null) {
      return _scaffoldMessengerKey!.currentState;
    }
    if (_context != null && _context!.mounted) {
      return ScaffoldMessenger.maybeOf(_context!);
    }
    return null;
  }

  Color _colorForType(ToastType type) {
    switch (type) {
      case ToastType.success: return const Color(0xFF2ECC71);
      case ToastType.error: return const Color(0xFFE74C3C);
      case ToastType.warning: return const Color(0xFFF39C12);
      case ToastType.info: return const Color(0xFF7C5CFC);
    }
  }

  IconData _iconForType(ToastType type) {
    switch (type) {
      case ToastType.success: return Icons.check_circle;
      case ToastType.error: return Icons.error;
      case ToastType.warning: return Icons.warning_amber_rounded;
      case ToastType.info: return Icons.info_outline;
    }
  }
}
