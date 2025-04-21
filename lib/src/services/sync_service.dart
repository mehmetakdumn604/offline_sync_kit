import 'dart:async';
import '../models/sync_model.dart';
import '../models/sync_result.dart';
import '../models/sync_status.dart';

abstract class SyncService {
  Stream<SyncStatus> get statusStream;

  Future<SyncResult> syncItem<T extends SyncModel>(T item);

  Future<SyncResult> syncAll<T extends SyncModel>(List<T> items);

  Future<SyncResult> syncAllPending();

  Future<SyncResult> syncByModelType(String modelType);

  Future<SyncResult> pullFromServer<T extends SyncModel>(
    String modelType, {
    DateTime? since,
    Map<String, dynamic Function(Map<String, dynamic>)>? modelFactories,
  });

  Future<void> startPeriodicSync();

  Future<void> stopPeriodicSync();

  Future<SyncStatus> getCurrentStatus();

  void dispose();
}
