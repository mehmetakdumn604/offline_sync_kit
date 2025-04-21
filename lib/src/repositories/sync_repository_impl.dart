import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/sync_model.dart';
import '../models/sync_result.dart';
import '../network/network_client.dart';
import '../services/storage_service.dart';
import 'sync_repository.dart';

/// Implementation of the SyncRepository interface that handles synchronization
/// operations between local storage and remote server.
///
/// This class manages the full synchronization lifecycle including:
/// - Syncing individual items to the server
/// - Handling delta updates for specific model fields
/// - Performing bulk synchronization operations
/// - Pulling data from the server
/// - Creating, updating, and deleting items
class SyncRepositoryImpl implements SyncRepository {
  final NetworkClient _networkClient;
  final StorageService _storageService;

  /// Creates a new instance of SyncRepositoryImpl
  ///
  /// [networkClient] - Client for making network requests to the server
  /// [storageService] - Service for persisting data to local storage
  SyncRepositoryImpl({
    required NetworkClient networkClient,
    required StorageService storageService,
  }) : _networkClient = networkClient,
       _storageService = storageService;

  /// Synchronizes a single item with the server
  ///
  /// Attempts to create or update the item on the server based on its current state.
  /// If successful, marks the item as synced in local storage.
  ///
  /// [item] - The model instance to synchronize
  /// Returns a [SyncResult] indicating success or failure
  @override
  Future<SyncResult> syncItem<T extends SyncModel>(T item) async {
    try {
      // Skip already synced items
      if (item.isSynced) {
        return SyncResult.noChanges();
      }

      final stopwatch = Stopwatch()..start();
      late T? result;

      // If we've previously tried to sync this item and it failed,
      // attempt to update it, otherwise try to create it
      if (item.syncError.isNotEmpty && item.syncAttempts > 0) {
        result = await updateItem<T>(item);
      } else {
        result = await createItem<T>(item);
      }

      stopwatch.stop();

      if (result != null) {
        // Mark the item as synced in storage
        await _storageService.markAsSynced<T>(item.id, item.modelType);
        return SyncResult.success(
          processedItems: 1,
          timeTaken: stopwatch.elapsed,
        );
      } else {
        // Mark sync as failed and record the error
        await _storageService.markSyncFailed<T>(
          item.id,
          item.modelType,
          'Failed to sync item',
        );
        return SyncResult.failed(
          error: 'Failed to sync item',
          timeTaken: stopwatch.elapsed,
        );
      }
    } catch (e) {
      // Handle any exceptions during sync process
      await _storageService.markSyncFailed<T>(
        item.id,
        item.modelType,
        e.toString(),
      );
      return SyncResult.failed(error: e.toString());
    }
  }

  /// Synchronizes only specific fields of a model that have changed
  ///
  /// This is more efficient than syncing the entire object when only
  /// a few fields have been modified.
  ///
  /// [item] - The model containing changes
  /// [changedFields] - Map of field names to their new values
  /// Returns a [SyncResult] indicating the outcome
  @override
  Future<SyncResult> syncDelta<T extends SyncModel>(
    T item,
    Map<String, dynamic> changedFields,
  ) async {
    try {
      // Skip if no sync is needed based on the changed fields
      if (item.isSynced && !item.hasChanges) {
        return SyncResult.success(processedItems: 0);
      }

      final endpoint = '${item.endpoint}/${item.id}';
      // Send a PUT request with only the changed fields
      final response = await _networkClient.put(endpoint, body: changedFields);

      if (response.isSuccessful) {
        // Update item in local storage
        final updatedModel = item.markAsSynced() as T;
        await _storageService.save<T>(updatedModel);

        return SyncResult.success(processedItems: 1);
      } else {
        // Handle failed sync attempt
        final failedModel =
            item.markSyncFailed(
                  'Sync failed with status: ${response.statusCode}',
                )
                as T;
        await _storageService.save<T>(failedModel);

        return SyncResult.failed(
          error: 'Sync failed for item ${item.id}: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error syncing delta for item ${item.id}: $e');
      // Mark as failed in case of exception
      final failedModel = item.markSyncFailed(e.toString()) as T;
      await _storageService.save<T>(failedModel);

      return SyncResult.failed(
        error: 'Error in delta sync for item ${item.id}: $e',
      );
    }
  }

  /// Synchronizes multiple items in a batch operation
  ///
  /// [items] - List of models to synchronize
  /// [bidirectional] - If true, also pulls updates from server after pushing local changes
  /// Returns a [SyncResult] with information about the sync operation
  @override
  Future<SyncResult> syncAll<T extends SyncModel>(
    List<T> items, {
    bool bidirectional = true,
  }) async {
    if (items.isEmpty) {
      return SyncResult.noChanges();
    }

    final stopwatch = Stopwatch()..start();
    int processedItems = 0;
    int failedItems = 0;
    final errorMessages = <String>[];

    // Process each item individually
    for (final item in items) {
      final result = await syncItem<T>(item);

      if (result.isSuccessful) {
        processedItems++;
        await _storageService.markAsSynced<T>(item.id, item.modelType);
      } else {
        failedItems++;
        if (result.errorMessages.isNotEmpty) {
          errorMessages.addAll(result.errorMessages);
        }
      }
    }

    stopwatch.stop();

    // If bidirectional sync is enabled, pull updates from server
    if (bidirectional && items.isNotEmpty) {
      final modelType = items.first.modelType;
      final lastSyncTime = await _storageService.getLastSyncTime();

      // Get model factory from first item's type if available
      final modelFactory = items.first.toJson;
      Map<String, dynamic Function(Map<String, dynamic>)> factoryMap = {
        modelType: (json) => modelFactory as dynamic,
      };

      await pullFromServer<T>(
        modelType,
        lastSyncTime,
        modelFactories: factoryMap,
      );
      await _storageService.setLastSyncTime(DateTime.now());
    }

    // Return appropriate result based on success/failure counts
    if (failedItems == 0 && processedItems > 0) {
      return SyncResult(
        status: SyncResultStatus.success,
        processedItems: processedItems,
        timeTaken: stopwatch.elapsed,
      );
    } else if (failedItems > 0 && processedItems > 0) {
      return SyncResult(
        status: SyncResultStatus.partial,
        processedItems: processedItems,
        failedItems: failedItems,
        errorMessages: errorMessages,
        timeTaken: stopwatch.elapsed,
      );
    } else {
      return SyncResult(
        status: SyncResultStatus.failed,
        failedItems: failedItems,
        errorMessages: errorMessages,
        timeTaken: stopwatch.elapsed,
      );
    }
  }

  /// Retrieves data from the server and updates local storage
  ///
  /// [modelType] - The type of model to retrieve
  /// [lastSyncTime] - Optional timestamp to only fetch items changed since this time
  /// Returns a [SyncResult] with information about the operation
  @override
  Future<SyncResult> pullFromServer<T extends SyncModel>(
    String modelType,
    DateTime? lastSyncTime, {
    Map<String, dynamic Function(Map<String, dynamic>)>? modelFactories,
  }) async {
    try {
      final items = await fetchItems<T>(
        modelType,
        since: lastSyncTime,
        modelFactories: modelFactories,
      );

      if (items.isEmpty) {
        return SyncResult.noChanges();
      }

      // Save all fetched items to local storage
      await _storageService.saveAll<T>(items);

      return SyncResult.success(processedItems: items.length);
    } catch (e) {
      return SyncResult.failed(error: e.toString());
    }
  }

  /// Creates a new item on the server
  ///
  /// [item] - The model to create on the server
  /// Returns the created model with updated sync status or null if failed
  @override
  Future<T?> createItem<T extends SyncModel>(T item) async {
    try {
      final response = await _networkClient.post(
        item.endpoint,
        body: item.toJson(),
      );

      if (response.isSuccessful || response.isCreated) {
        return item.markAsSynced() as T;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Updates an existing item on the server
  ///
  /// [item] - The model with updated data to send to the server
  /// Returns the updated model with sync status or null if failed
  @override
  Future<T?> updateItem<T extends SyncModel>(T item) async {
    try {
      final response = await _networkClient.put(
        '${item.endpoint}/${item.id}',
        body: item.toJson(),
      );

      if (response.isSuccessful) {
        return item.markAsSynced() as T;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Deletes an item from the server
  ///
  /// [item] - The model to delete
  /// Returns true if deletion was successful, false otherwise
  @override
  Future<bool> deleteItem<T extends SyncModel>(T item) async {
    try {
      final response = await _networkClient.delete(
        '${item.endpoint}/${item.id}',
      );

      return response.isSuccessful || response.isNoContent;
    } catch (e) {
      return false;
    }
  }

  /// Fetches items of a specific model type from the server
  ///
  /// [modelType] - The type of model to fetch
  /// [since] - Optional timestamp to only fetch items modified since this time
  /// [limit] - Optional maximum number of items to fetch
  /// [offset] - Optional offset for pagination
  /// [modelFactories] - Map of model factories to create instances from JSON
  /// Returns a list of model instances
  @override
  Future<List<T>> fetchItems<T extends SyncModel>(
    String modelType, {
    DateTime? since,
    int? limit,
    int? offset,
    Map<String, dynamic Function(Map<String, dynamic>)>? modelFactories,
  }) async {
    try {
      // Ensure we have a factory for this model type
      final factory = modelFactories?[modelType];
      if (factory == null) {
        throw Exception('No model factory registered for $modelType');
      }

      // Build query parameters
      final queryParams = <String, String>{};
      if (since != null) {
        queryParams['since'] = since.toIso8601String();
      }
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }
      if (offset != null) {
        queryParams['offset'] = offset.toString();
      }

      // Get model endpoint from a temporary instance or use modelType
      final endpoint = modelType.toLowerCase();

      // Fetch data from server
      final response = await _networkClient.get(
        endpoint,
        queryParameters: queryParams,
      );

      if (!response.isSuccessful) {
        throw Exception('Failed to fetch items: ${response.statusCode}');
      }

      // Parse response data
      List<dynamic> dataList;

      if (response.data is List) {
        dataList = response.data as List<dynamic>;
      } else if (response.data is Map<String, dynamic> &&
          (response.data as Map<String, dynamic>).containsKey('data')) {
        final dataMap = response.data as Map<String, dynamic>;
        dataList = dataMap['data'] as List<dynamic>? ?? [];
      } else {
        dataList = [];
      }

      // Convert to model instances using factory
      final items =
          dataList
              .map((item) {
                if (item is! Map<String, dynamic>) {
                  return null; // Skip invalid items
                }
                try {
                  return factory(item) as T;
                } catch (e) {
                  debugPrint('Error creating model from JSON: $e');
                  return null;
                }
              })
              .where((item) => item != null)
              .cast<T>()
              .toList();

      return items;
    } catch (e) {
      debugPrint('Error fetching items of type $modelType: $e');
      return [];
    }
  }
}
