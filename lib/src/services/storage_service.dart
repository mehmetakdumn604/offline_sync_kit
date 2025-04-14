import 'dart:async';
import '../models/sync_model.dart';

abstract class StorageService {
  Future<void> initialize();

  Future<T?> get<T extends SyncModel>(String id, String modelType);

  Future<List<T>> getAll<T extends SyncModel>(String modelType);

  Future<List<T>> getPending<T extends SyncModel>(String modelType);

  Future<void> save<T extends SyncModel>(T model);

  Future<void> saveAll<T extends SyncModel>(List<T> models);

  Future<void> update<T extends SyncModel>(T model);

  Future<void> delete<T extends SyncModel>(String id, String modelType);

  Future<void> markAsSynced<T extends SyncModel>(String id, String modelType);

  Future<void> markSyncFailed<T extends SyncModel>(
    String id,
    String modelType,
    String error,
  );

  Future<int> getPendingCount();

  Future<DateTime> getLastSyncTime();

  Future<void> setLastSyncTime(DateTime time);

  Future<void> clearAll();

  Future<void> close();
}
