import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';
import '../models/connectivity_options.dart';

abstract class ConnectivityService {
  Stream<bool> get connectionStream;
  Future<bool> get isConnected;
  Future<bool> isConnectionSatisfied(ConnectivityOptions requirements);
}

class ConnectivityServiceImpl implements ConnectivityService {
  final Connectivity _connectivity;
  final BehaviorSubject<bool> _connectionSubject = BehaviorSubject<bool>();

  ConnectivityServiceImpl({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity() {
    _initConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
    } catch (e) {
      _connectionSubject.add(false);
    }
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final isConnected =
        results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
    _connectionSubject.add(isConnected);
  }

  @override
  Stream<bool> get connectionStream => _connectionSubject.stream;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
  }

  @override
  Future<bool> isConnectionSatisfied(ConnectivityOptions requirements) async {
    final results = await _connectivity.checkConnectivity();

    switch (requirements) {
      case ConnectivityOptions.any:
        return results.isNotEmpty &&
            results.any((result) => result != ConnectivityResult.none);
      case ConnectivityOptions.wifi:
        return results.contains(ConnectivityResult.wifi);
      case ConnectivityOptions.mobile:
        return results.contains(ConnectivityResult.mobile);
      case ConnectivityOptions.none:
        return true;
    }
  }

  void dispose() {
    _connectionSubject.close();
  }
}
