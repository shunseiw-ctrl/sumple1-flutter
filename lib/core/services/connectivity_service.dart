import 'dart:async';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  Timer? _checkTimer;

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _controller.stream;

  void startMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(seconds: 15), (_) => _check());
    _check();
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _check() async {
    try {
      final wasOnline = _isOnline;
      if (kIsWeb) {
        _isOnline = await _checkWebConnectivity();
      } else {
        _isOnline = true;
      }
      if (wasOnline != _isOnline) {
        _controller.add(_isOnline);
      }
    } catch (_) {
      if (_isOnline) {
        _isOnline = false;
        _controller.add(false);
      }
    }
  }

  Future<bool> _checkWebConnectivity() async {
    try {
      return _checkNavigatorOnline();
    } catch (_) {
      return false;
    }
  }

  bool _checkNavigatorOnline() {
    if (kIsWeb) {
      return _webNavigatorOnline();
    }
    return true;
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}

bool _webNavigatorOnline() {
  try {
    return true;
  } catch (_) {
    return true;
  }
}
