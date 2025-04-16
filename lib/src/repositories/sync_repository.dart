import 'dart:async';
import '../models/sync_model.dart';
import '../models/sync_result.dart';

abstract class SyncRepository {
  Future<SyncResult> syncItem<T extends SyncModel>(T item);

  /// Synchronizes only the changed fields of an item with the server
  ///
  /// This method sends only the delta (changed fields) of the model to reduce
  /// bandwidth and improve performance.
  ///
  /// Parameters:
  /// - [item]: The model to synchronize
  /// - [changedFields]: Map of field names to their new values
  ///
  /// Returns a [SyncResult] with the outcome of the operation
  Future<SyncResult> syncDelta<T extends SyncModel>(
    T item,
    Map<String, dynamic> changedFields,
  );

  Future<SyncResult> syncAll<T extends SyncModel>(
    List<T> items, {
    bool bidirectional = true,
  });

  Future<SyncResult> pullFromServer<T extends SyncModel>(
    String modelType,
    DateTime? lastSyncTime,
  );

  Future<T?> createItem<T extends SyncModel>(T item);

  Future<T?> updateItem<T extends SyncModel>(T item);

  Future<bool> deleteItem<T extends SyncModel>(T item);

  Future<List<T>> fetchItems<T extends SyncModel>(
    String modelType, {
    DateTime? since,
  });
}
