import 'dart:async';
import 'package:path_provider/path_provider.dart';

import 'models/sync_model.dart';
import 'models/sync_options.dart';
import 'models/sync_result.dart';
import 'models/sync_status.dart';
import 'network/default_network_client.dart';
import 'network/network_client.dart';
import 'repositories/sync_repository_impl.dart';
import 'services/connectivity_service.dart';
import 'services/storage_service.dart';
import 'sync_engine.dart';

typedef ModelFactory<T extends SyncModel> =
    T Function(Map<String, dynamic> json);

class OfflineSyncManager {
  static OfflineSyncManager? _instance;

  final SyncEngine _syncEngine;
  final Map<String, ModelFactory> _modelFactories = {};
  final StorageService _storageService;
  final ConnectivityService _connectivityService;
  late StreamSubscription<bool> _connectivitySubscription;

  OfflineSyncManager._({
    required SyncEngine syncEngine,
    required StorageService storageService,
    required ConnectivityService connectivityService,
  }) : _syncEngine = syncEngine,
       _storageService = storageService,
       _connectivityService = connectivityService {
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivityService.connectionStream.listen((
      isConnected,
    ) {
      if (isConnected) {
        _syncEngine.syncAllPending();
      }
    });
  }

  static Future<OfflineSyncManager> initialize({
    required String baseUrl,
    NetworkClient? networkClient,
    ConnectivityService? connectivityService,
    StorageService? storageService,
    SyncOptions? syncOptions,
  }) async {
    if (_instance != null) {
      return _instance!;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final dbPath = '${appDocDir.path}/offline_sync.db';

    final options = syncOptions ?? const SyncOptions();
    final connectivity = connectivityService ?? ConnectivityServiceImpl();
    final defaultNetworkClient =
        networkClient ?? DefaultNetworkClient(baseUrl: baseUrl);

    StorageService storage;
    if (storageService != null) {
      storage = storageService;
    } else {
      throw UnimplementedError(
        'Storage service must be provided. Implement a concrete class for StorageService.',
      );
    }

    final syncRepository = SyncRepositoryImpl(
      networkClient: defaultNetworkClient,
      storageService: storage,
    );

    final syncEngine = SyncEngine(
      repository: syncRepository,
      storageService: storage,
      connectivityService: connectivity,
      options: options,
    );

    _instance = OfflineSyncManager._(
      syncEngine: syncEngine,
      storageService: storage,
      connectivityService: connectivity,
    );

    return _instance!;
  }

  static OfflineSyncManager get instance {
    if (_instance == null) {
      throw StateError(
        'OfflineSyncManager not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  void registerModelFactory<T extends SyncModel>(
    String modelType,
    ModelFactory<T> factory,
  ) {
    _modelFactories[modelType] = factory;
    _syncEngine.registerModelType(modelType);
  }

  Future<void> saveModel<T extends SyncModel>(T model) async {
    await _storageService.save<T>(model);

    if (model.isSynced == false) {
      _syncEngine.syncItem<T>(model);
    }
  }

  Future<void> saveModels<T extends SyncModel>(List<T> models) async {
    await _storageService.saveAll<T>(models);

    final unsyncedModels = models.where((model) => !model.isSynced).toList();

    if (unsyncedModels.isNotEmpty) {
      _syncEngine.syncAll<T>(unsyncedModels);
    }
  }

  Future<void> updateModel<T extends SyncModel>(T model) async {
    await _storageService.update<T>(model);

    if (model.isSynced == false) {
      _syncEngine.syncItem<T>(model);
    }
  }

  Future<void> deleteModel<T extends SyncModel>(
    String id,
    String modelType,
  ) async {
    await _storageService.delete<T>(id, modelType);
  }

  Future<T?> getModel<T extends SyncModel>(String id, String modelType) async {
    return _storageService.get<T>(id, modelType);
  }

  Future<List<T>> getAllModels<T extends SyncModel>(String modelType) async {
    return _storageService.getAll<T>(modelType);
  }

  Future<SyncResult> syncAll() async {
    return _syncEngine.syncAllPending();
  }

  Future<SyncResult> syncByModelType(String modelType) async {
    return _syncEngine.syncByModelType(modelType);
  }

  Future<SyncResult> pullFromServer<T extends SyncModel>(
    String modelType, {
    DateTime? since,
  }) async {
    return _syncEngine.pullFromServer<T>(modelType, since: since);
  }

  Stream<SyncStatus> get syncStatusStream => _syncEngine.statusStream;

  Future<SyncStatus> get currentStatus => _syncEngine.getCurrentStatus();

  Future<void> startPeriodicSync() async {
    await _syncEngine.startPeriodicSync();
  }

  Future<void> stopPeriodicSync() async {
    await _syncEngine.stopPeriodicSync();
  }

  Future<void> dispose() async {
    _connectivitySubscription.cancel();
    _syncEngine.dispose();
    await _storageService.close();
  }
}
