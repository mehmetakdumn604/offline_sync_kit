import 'dart:async';
import 'dart:convert';
import '../models/sync_model.dart';
import '../models/sync_result.dart';
import '../network/network_client.dart';
import '../services/storage_service.dart';
import 'sync_repository.dart';

class SyncRepositoryImpl implements SyncRepository {
  final NetworkClient _networkClient;
  final StorageService _storageService;

  SyncRepositoryImpl({
    required NetworkClient networkClient,
    required StorageService storageService,
  }) : _networkClient = networkClient,
       _storageService = storageService;

  @override
  Future<SyncResult> syncItem<T extends SyncModel>(T item) async {
    try {
      if (item.isSynced) {
        return SyncResult.noChanges();
      }

      final stopwatch = Stopwatch()..start();
      late T? result;

      if (item.syncError.isNotEmpty && item.syncAttempts > 0) {
        result = await updateItem<T>(item);
      } else {
        result = await createItem<T>(item);
      }

      stopwatch.stop();

      if (result != null) {
        await _storageService.markAsSynced<T>(item.id, item.modelType);
        return SyncResult.success(
          processedItems: 1,
          timeTaken: stopwatch.elapsed,
        );
      } else {
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
      await _storageService.markSyncFailed<T>(
        item.id,
        item.modelType,
        e.toString(),
      );
      return SyncResult.failed(error: e.toString());
    }
  }

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

    for (final item in items) {
      final result = await syncItem<T>(item);

      if (result.isSuccessful) {
        processedItems++;
      } else {
        failedItems++;
        if (result.errorMessages.isNotEmpty) {
          errorMessages.addAll(result.errorMessages);
        }
      }
    }

    stopwatch.stop();

    if (bidirectional && items.isNotEmpty) {
      final modelType = items.first.modelType;
      final lastSyncTime = await _storageService.getLastSyncTime();
      await pullFromServer<T>(modelType, lastSyncTime);
      await _storageService.setLastSyncTime(DateTime.now());
    }

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

  @override
  Future<SyncResult> pullFromServer<T extends SyncModel>(
    String modelType,
    DateTime? lastSyncTime,
  ) async {
    try {
      final items = await fetchItems<T>(modelType, since: lastSyncTime);

      if (items.isEmpty) {
        return SyncResult.noChanges();
      }

      await _storageService.saveAll<T>(items);

      return SyncResult.success(processedItems: items.length);
    } catch (e) {
      return SyncResult.failed(error: e.toString());
    }
  }

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

  @override
  Future<List<T>> fetchItems<T extends SyncModel>(
    String modelType, {
    DateTime? since,
  }) async {
    // This method would need a factory to create model instances
    // based on model type, which is beyond the scope of this example
    // In a real implementation, you would register model factories
    throw UnimplementedError(
      'Implementation requires model factories to be registered',
    );
  }
}
