import 'dart:async';
import 'package:flutter/material.dart';
import 'package:offline_sync_kit/offline_sync_kit.dart';

// A singleton to manage encryption settings
class EncryptionManager {
  static final EncryptionManager _instance = EncryptionManager._internal();

  factory EncryptionManager() => _instance;

  EncryptionManager._internal();

  // Stream controller to notify listeners when encryption settings change
  final StreamController<bool> _encryptionStatusController =
      StreamController<bool>.broadcast();

  // Current encryption status
  bool _isEncryptionEnabled = true;

  // Getter for encryption status
  bool get isEncryptionEnabled => _isEncryptionEnabled;

  // Stream to listen for encryption status changes
  Stream<bool> get encryptionStatusStream => _encryptionStatusController.stream;

  // Initialize encryption manager
  Future<void> initialize() async {
    // In a real app, you would get the initial state from somewhere persistent
    _isEncryptionEnabled = true;
    _encryptionStatusController.add(_isEncryptionEnabled);
  }

  // Enable encryption with the given key
  Future<void> enableEncryption(String key) async {
    try {
      // Call the OfflineSyncManager to enable encryption
      OfflineSyncManager.instance.enableEncryption(key);

      _isEncryptionEnabled = true;
      _encryptionStatusController.add(_isEncryptionEnabled);

      debugPrint('Encryption enabled with key: $key');
    } catch (e) {
      debugPrint('Error enabling encryption: $e');
      rethrow;
    }
  }

  // Disable encryption
  Future<void> disableEncryption() async {
    try {
      // Call the OfflineSyncManager to disable encryption
      OfflineSyncManager.instance.disableEncryption();

      _isEncryptionEnabled = false;
      _encryptionStatusController.add(_isEncryptionEnabled);

      debugPrint('Encryption disabled');
    } catch (e) {
      debugPrint('Error disabling encryption: $e');
      rethrow;
    }
  }

  // Toggle encryption with the given key (if enabling)
  Future<void> toggleEncryption(bool enabled, [String? key]) async {
    if (enabled) {
      if (key == null || key.isEmpty) {
        throw ArgumentError(
          'Encryption key must be provided when enabling encryption',
        );
      }
      await enableEncryption(key);
    } else {
      await disableEncryption();
    }
  }

  // Dispose resources
  void dispose() {
    _encryptionStatusController.close();
  }
}
