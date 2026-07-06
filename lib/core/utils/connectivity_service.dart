import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _sub;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Broadcasts true when online, false when offline
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _controller.stream;

  void _init() {
    // Check initial state
    _connectivity.checkConnectivity().then(_handleResults);
    // Subscribe to changes
    _sub = _connectivity.onConnectivityChanged.listen(_handleResults);
  }

  void _handleResults(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    if (wasOnline != _isOnline) {
      _controller.add(_isOnline);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _controller.close();
    super.dispose();
  }
}
