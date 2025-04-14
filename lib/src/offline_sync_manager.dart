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

/// Function type for creating model instances from JSON
///
/// This typedef is used to register factory functions that can create model
/// instances from JSON data retrieved from the server or local storage.
typedef ModelFactory<T extends SyncModel> =
    T Function(Map<String, dynamic> json);

/// Main entry point for the offline synchronization framework
///
/// This class serves as the primary interface for applications to interact with
/// the offline synchronization system. It manages model registration, storage,
/// and synchronization with a remote API.
///
/// Usage:
/// ```dart
/// // Initialize the manager
/// await OfflineSyncManager.initialize(
///   baseUrl: 'https://api.example.com',
///   storageService: MyStorageService(),
/// );
///
/// // Register model factories
/// OfflineSyncManager.instance.registerModelFactory<Todo>(
///   'todo',
///   (json) => Todo.fromJson(json),
/// );
///
/// // Save and sync models
/// final todo = Todo(title: 'New task');
/// await OfflineSyncManager.instance.saveModel(todo);
/// ```
class OfflineSyncManager {
  /// Singleton instance of the OfflineSyncManager
  static OfflineSyncManager? _instance;

  /// The sync engine that performs the actual synchronization operations
  final SyncEngine _syncEngine;

  /// Map of model type names to factory functions for model creation
  final Map<String, ModelFactory> _modelFactories = {};

  /// Service for storing and retrieving data locally
  final StorageService _storageService;

  /// Service for monitoring network connectivity
  final ConnectivityService _connectivityService;

  /// Subscription to the connectivity service's connection stream
  late StreamSubscription<bool> _connectivitySubscription;

  /// Private constructor, use [initialize] instead
  ///
  /// This constructor is private to enforce the singleton pattern.
  /// Applications should use the [initialize] method to create and access
  /// the OfflineSyncManager.
  OfflineSyncManager._({
    required SyncEngine syncEngine,
    required StorageService storageService,
    required ConnectivityService connectivityService,
  }) : _syncEngine = syncEngine,
       _storageService = storageService,
       _connectivityService = connectivityService {
    _setupConnectivityListener();
  }

  /// Sets up a listener for connectivity changes
  ///
  /// When connectivity is restored, automatically attempt to sync pending changes.
  /// This ensures that data is synchronized as soon as a connection becomes available.
  void _setupConnectivityListener() {
    _connectivitySubscription = _connectivityService.connectionStream.listen((
      isConnected,
    ) {
      if (isConnected) {
        _syncEngine.syncAllPending();
      }
    });
  }

  /// Initializes the offline sync manager singleton
  ///
  /// This must be called before accessing the [instance].
  ///
  /// Parameters:
  /// - [baseUrl]: The base URL for the remote API
  /// - [networkClient]: Optional custom network client implementation
  /// - [connectivityService]: Optional custom connectivity service implementation
  /// - [storageService]: Required storage service implementation
  /// - [syncOptions]: Optional configuration options for synchronization
  ///
  /// Returns the initialized singleton instance
  ///
  /// Throws an [UnimplementedError] if no storage service is provided
  static Future<OfflineSyncManager> initialize({
    required String baseUrl,
    NetworkClient? networkClient,
    ConnectivityService? connectivityService,
    StorageService? storageService,
    SyncOptions? syncOptions,
  }) async {
    // Return existing instance if already initialized
    if (_instance != null) {
      return _instance!;
    }

    // Get application documents directory for storage if needed
    final appDocDir = await getApplicationDocumentsDirectory();

    // Use provided options or create default options
    final options = syncOptions ?? const SyncOptions();

    // Use provided connectivity service or create default implementation
    final connectivity = connectivityService ?? ConnectivityServiceImpl();

    // Use provided network client or create default implementation
    final defaultNetworkClient =
        networkClient ?? DefaultNetworkClient(baseUrl: baseUrl);

    // Validate storage service
    StorageService storage;
    if (storageService != null) {
      storage = storageService;
    } else {
      throw UnimplementedError(
        'Storage service must be provided. Implement a concrete class for StorageService.',
      );
    }

    // Create repository and sync engine
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

    // Create and store singleton instance
    _instance = OfflineSyncManager._(
      syncEngine: syncEngine,
      storageService: storage,
      connectivityService: connectivity,
    );

    return _instance!;
  }

  /// Accesses the singleton instance of the offline sync manager
  ///
  /// Throws a [StateError] if [initialize] has not been called
  static OfflineSyncManager get instance {
    if (_instance == null) {
      throw StateError(
        'OfflineSyncManager not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  /// Registers a factory function for creating model instances of type [T]
  ///
  /// Parameters:
  /// - [modelType]: The unique identifier for this model type
  /// - [factory]: A function that creates model instances from JSON data
  ///
  /// This must be called for each model type before using other operations.
  /// The factory function is used to deserialize JSON data into model objects
  /// when retrieving data from local storage or the server.
  void registerModelFactory<T extends SyncModel>(
    String modelType,
    ModelFactory<T> factory,
  ) {
    _modelFactories[modelType] = factory;
    _syncEngine.registerModelType(modelType);
  }

  /// Saves a model to local storage and synchronizes it with the server if needed
  ///
  /// Parameters:
  /// - [model]: The model instance to save
  ///
  /// If the model is not already synced, it will be synchronized automatically.
  /// This method ensures that the model is both saved locally and sent to the server.
  Future<void> saveModel<T extends SyncModel>(T model) async {
    // First save the model to local storage
    await _storageService.save<T>(model);

    // Only trigger synchronization if the model is not already synced
    if (!model.isSynced) {
      // Wait for synchronization to complete
      await _syncEngine.syncItem<T>(model);
      // Mark the model as synced to prevent future sync attempts
      await _storageService.markAsSynced<T>(model.id, model.modelType);
    }
  }

  /// Saves multiple models to local storage and synchronizes unsynced models
  ///
  /// Parameters:
  /// - [models]: The list of model instances to save
  ///
  /// Only models that are not already synced will be synchronized.
  /// This method is more efficient than calling [saveModel] multiple times.
  Future<void> saveModels<T extends SyncModel>(List<T> models) async {
    if (models.isEmpty) {
      return;
    }

    // First save all models to local storage
    await _storageService.saveAll<T>(models);

    // Filter out models that are already synced
    final unsyncedModels = models.where((model) => !model.isSynced).toList();

    // Only attempt synchronization if there are unsynced models
    if (unsyncedModels.isNotEmpty) {
      await _syncEngine.syncAll<T>(unsyncedModels);
    }
  }

  /// Updates an existing model in local storage and synchronizes it if needed
  ///
  /// Parameters:
  /// - [model]: The model instance to update
  ///
  /// If the model is not already synced, it will be synchronized automatically.
  /// Use this method when you want to update an existing model's properties.
  Future<void> updateModel<T extends SyncModel>(T model) async {
    // Update the model in local storage
    await _storageService.update<T>(model);

    // Only trigger synchronization if the model is not already synced
    if (!model.isSynced) {
      await _syncEngine.syncItem<T>(model);
    }
  }

  /// Deletes a model from local storage
  ///
  /// Parameters:
  /// - [id]: The unique identifier of the model to delete
  /// - [modelType]: The type of the model to delete
  ///
  /// Note: This method only deletes the model locally. If you need to delete it
  /// on the server as well, you should implement that logic separately.
  Future<void> deleteModel<T extends SyncModel>(
    String id,
    String modelType,
  ) async {
    await _storageService.delete<T>(id, modelType);
  }

  /// Retrieves a single model from local storage by ID
  ///
  /// Parameters:
  /// - [id]: The unique identifier of the model to retrieve
  /// - [modelType]: The type of the model to retrieve
  ///
  /// Returns the model instance if found, null otherwise
  Future<T?> getModel<T extends SyncModel>(String id, String modelType) async {
    return _storageService.get<T>(id, modelType);
  }

  /// Retrieves all models of a specific type from local storage
  ///
  /// Parameters:
  /// - [modelType]: The type of models to retrieve
  ///
  /// Returns a list of all models of the specified type
  Future<List<T>> getAllModels<T extends SyncModel>(String modelType) async {
    return _storageService.getAll<T>(modelType);
  }

  /// Synchronizes all pending models with the server
  ///
  /// Returns a [SyncResult] containing the outcome of the synchronization
  ///
  /// This method attempts to synchronize all pending changes across all registered
  /// model types with the server. It's useful for ensuring that all local changes
  /// are reflected on the server.
  Future<SyncResult> syncAll() async {
    return _syncEngine.syncAllPending();
  }

  /// Synchronizes all models of a specific type with the server
  ///
  /// Parameters:
  /// - [modelType]: The type of models to synchronize
  ///
  /// Returns a [SyncResult] containing the outcome of the synchronization
  ///
  /// This method is useful when you want to sync only a specific type of model,
  /// rather than all pending changes.
  Future<SyncResult> syncByModelType(String modelType) async {
    return _syncEngine.syncByModelType(modelType);
  }

  /// Synchronizes a single model with the server
  ///
  /// Parameters:
  /// - [model]: The model instance to synchronize
  ///
  /// Returns a [SyncResult] containing the outcome of the synchronization
  ///
  /// This method is useful when you want to sync a specific model immediately,
  /// regardless of its current sync status.
  Future<SyncResult> syncItem<T extends SyncModel>(T model) async {
    return _syncEngine.syncItem<T>(model);
  }

  /// Fetches models from the server and saves them to local storage
  ///
  /// Parameters:
  /// - [modelType]: The type of models to fetch
  /// - [since]: Optional timestamp to fetch only models updated since that time
  ///
  /// Returns a [SyncResult] containing the outcome of the operation
  ///
  /// This method is particularly useful for downloading new or updated data from
  /// the server to ensure the local database is up-to-date.
  Future<SyncResult> pullFromServer<T extends SyncModel>(
    String modelType, {
    DateTime? since,
  }) async {
    return _syncEngine.pullFromServer<T>(modelType, since: since);
  }

  /// A stream of synchronization status updates
  ///
  /// Listen to this stream to be notified of changes in the synchronization status.
  /// This is useful for updating UI components that need to reflect the current
  /// synchronization state.
  Stream<SyncStatus> get syncStatusStream => _syncEngine.statusStream;

  /// The current synchronization status
  ///
  /// Returns a [SyncStatus] object containing the current status
  ///
  /// Use this method to get a snapshot of the current synchronization state,
  /// including whether the device is connected, if a sync is in progress,
  /// and how many changes are pending.
  Future<SyncStatus> get currentStatus => _syncEngine.getCurrentStatus();

  /// Starts periodic synchronization of models
  ///
  /// Synchronization will be performed according to the [SyncOptions]
  /// provided during initialization.
  ///
  /// This is useful for ensuring data is regularly synchronized without
  /// manual intervention.
  Future<void> startPeriodicSync() async {
    await _syncEngine.startPeriodicSync();
  }

  /// Stops periodic synchronization
  ///
  /// Call this method when you want to stop automatic synchronization,
  /// for example, to conserve battery or when the app goes into the background.
  Future<void> stopPeriodicSync() async {
    await _syncEngine.stopPeriodicSync();
  }

  /// Releases resources and cleans up
  ///
  /// Should be called when the application is closing or the manager is no longer needed.
  /// This ensures that all resources are properly released, including subscriptions,
  /// timers, and database connections.
  Future<void> dispose() async {
    await _connectivitySubscription.cancel();
    _syncEngine.dispose();
    await _storageService.close();
  }
}
