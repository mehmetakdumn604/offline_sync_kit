import 'dart:async';
import 'models/sync_model.dart';
import 'models/sync_options.dart';
import 'models/sync_result.dart';
import 'models/sync_status.dart';
import 'repositories/sync_repository.dart';
import 'services/connectivity_service.dart';
import 'services/storage_service.dart';

class SyncEngine {
  final SyncRepository _repository;
  final StorageService _storageService;
  final ConnectivityService _connectivityService;
  final SyncOptions _options;

  final StreamController<SyncStatus> _statusController =
      StreamController<SyncStatus>.broadcast();

  Timer? _syncTimer;
  bool _isSyncing = false;
  final List<String> _registeredModelTypes = [];
  DateTime _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _pendingCount = 0;

  SyncEngine({
    required SyncRepository repository,
    required StorageService storageService,
    required ConnectivityService connectivityService,
    SyncOptions? options,
  }) : _repository = repository,
       _storageService = storageService,
       _connectivityService = connectivityService,
       _options = options ?? const SyncOptions() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _storageService.initialize();
    _lastSyncTime = await _storageService.getLastSyncTime();
    _pendingCount = await _storageService.getPendingCount();

    _updateStatus();

    _connectivityService.connectionStream.listen((isConnected) {
      _updateStatus(isConnected: isConnected);

      if (isConnected &&
          _options.autoSync &&
          _pendingCount > 0 &&
          !_isSyncing) {
        _triggerSync();
      }
    });

    if (_options.autoSync && _options.syncInterval.inSeconds > 0) {
      await startPeriodicSync();
    }
  }

  Stream<SyncStatus> get statusStream => _statusController.stream;

  Future<SyncStatus> getCurrentStatus() async {
    final isConnected = await _connectivityService.isConnected;
    return SyncStatus(
      isConnected: isConnected,
      isSyncing: _isSyncing,
      pendingChanges: _pendingCount,
      lastSyncTime: _lastSyncTime,
    );
  }

  void registerModelType(String modelType) {
    if (!_registeredModelTypes.contains(modelType)) {
      _registeredModelTypes.add(modelType);
    }
  }

  Future<SyncResult> syncItem<T extends SyncModel>(T item) async {
    registerModelType(item.modelType);

    final isConnected = await _connectivityService.isConnectionSatisfied(
      _options.connectivityRequirement,
    );

    if (!isConnected) {
      await _storageService.save(item);
      _pendingCount = await _storageService.getPendingCount();
      _updateStatus();
      return SyncResult.connectionError();
    }

    _setIsSyncing(true);

    try {
      final result = await _repository.syncItem(item);
      _lastSyncTime = DateTime.now();
      await _storageService.setLastSyncTime(_lastSyncTime);
      _pendingCount = await _storageService.getPendingCount();

      _updateStatus();
      _setIsSyncing(false);

      return result;
    } catch (e) {
      _setIsSyncing(false);
      return SyncResult.failed(error: e.toString());
    }
  }

  Future<SyncResult> syncAll<T extends SyncModel>(List<T> items) async {
    if (items.isEmpty) {
      return SyncResult.noChanges();
    }

    registerModelType(items.first.modelType);

    final isConnected = await _connectivityService.isConnectionSatisfied(
      _options.connectivityRequirement,
    );

    if (!isConnected) {
      await _storageService.saveAll(items);
      _pendingCount = await _storageService.getPendingCount();
      _updateStatus();
      return SyncResult.connectionError();
    }

    _setIsSyncing(true);

    try {
      final result = await _repository.syncAll(
        items,
        bidirectional: _options.bidirectionalSync,
      );

      _lastSyncTime = DateTime.now();
      await _storageService.setLastSyncTime(_lastSyncTime);
      _pendingCount = await _storageService.getPendingCount();

      _updateStatus();
      _setIsSyncing(false);

      return result;
    } catch (e) {
      _setIsSyncing(false);
      return SyncResult.failed(error: e.toString());
    }
  }

  Future<SyncResult> syncAllPending() async {
    final isConnected = await _connectivityService.isConnectionSatisfied(
      _options.connectivityRequirement,
    );

    if (!isConnected) {
      return SyncResult.connectionError();
    }

    if (_isSyncing) {
      return SyncResult.failed(error: 'Sync already in progress');
    }

    _setIsSyncing(true);

    try {
      SyncResult finalResult = SyncResult.noChanges();

      for (final modelType in _registeredModelTypes) {
        final result = await syncByModelType(modelType);

        if (result.status == SyncResultStatus.failed ||
            result.status == SyncResultStatus.partial) {
          finalResult = result;
        } else if (finalResult.status == SyncResultStatus.noChanges &&
            result.status == SyncResultStatus.success) {
          finalResult = result;
        }
      }

      _lastSyncTime = DateTime.now();
      await _storageService.setLastSyncTime(_lastSyncTime);
      _pendingCount = await _storageService.getPendingCount();

      _updateStatus();
      _setIsSyncing(false);

      return finalResult;
    } catch (e) {
      _setIsSyncing(false);
      return SyncResult.failed(error: e.toString());
    }
  }

  Future<SyncResult> syncByModelType(String modelType) async {
    final isConnected = await _connectivityService.isConnectionSatisfied(
      _options.connectivityRequirement,
    );

    if (!isConnected) {
      return SyncResult.connectionError();
    }

    if (_isSyncing) {
      return SyncResult.failed(error: 'Sync already in progress');
    }

    _setIsSyncing(true);

    try {
      final items = await _storageService.getPending(modelType);

      if (items.isEmpty) {
        _setIsSyncing(false);
        return SyncResult.noChanges();
      }

      final result = await _repository.syncAll(
        items,
        bidirectional: _options.bidirectionalSync,
      );

      _lastSyncTime = DateTime.now();
      await _storageService.setLastSyncTime(_lastSyncTime);
      _pendingCount = await _storageService.getPendingCount();

      _updateStatus();
      _setIsSyncing(false);

      return result;
    } catch (e) {
      _setIsSyncing(false);
      return SyncResult.failed(error: e.toString());
    }
  }

  Future<SyncResult> pullFromServer<T extends SyncModel>(
    String modelType, {
    DateTime? since,
  }) async {
    final isConnected = await _connectivityService.isConnectionSatisfied(
      _options.connectivityRequirement,
    );

    if (!isConnected) {
      return SyncResult.connectionError();
    }

    _setIsSyncing(true);

    try {
      final result = await _repository.pullFromServer<T>(
        modelType,
        since ?? _lastSyncTime,
      );

      _lastSyncTime = DateTime.now();
      await _storageService.setLastSyncTime(_lastSyncTime);

      _updateStatus();
      _setIsSyncing(false);

      return result;
    } catch (e) {
      _setIsSyncing(false);
      return SyncResult.failed(error: e.toString());
    }
  }

  Future<void> startPeriodicSync() async {
    stopPeriodicSync();

    if (_options.syncInterval.inSeconds > 0) {
      _syncTimer = Timer.periodic(_options.syncInterval, (_) => _triggerSync());
    }
  }

  Future<void> stopPeriodicSync() async {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> _triggerSync() async {
    if (!_isSyncing && _pendingCount > 0) {
      final isConnected = await _connectivityService.isConnectionSatisfied(
        _options.connectivityRequirement,
      );

      if (isConnected) {
        await syncAllPending();
      }
    }
  }

  void _setIsSyncing(bool value) {
    _isSyncing = value;
    _updateStatus();
  }

  void _updateStatus({bool? isConnected}) async {
    final connected = isConnected ?? await _connectivityService.isConnected;

    _statusController.add(
      SyncStatus(
        isConnected: connected,
        isSyncing: _isSyncing,
        pendingChanges: _pendingCount,
        lastSyncTime: _lastSyncTime,
      ),
    );
  }

  void dispose() {
    _syncTimer?.cancel();
    _statusController.close();
  }
}
