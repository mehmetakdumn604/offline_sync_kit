import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

abstract class SyncModel extends Equatable {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String syncError;
  final int syncAttempts;

  SyncModel({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.syncError = '',
    this.syncAttempts = 0,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  String get endpoint;

  String get modelType;

  Map<String, dynamic> toJson();

  SyncModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? syncError,
    int? syncAttempts,
  });

  SyncModel markAsSynced() {
    return copyWith(isSynced: true, syncError: '', updatedAt: DateTime.now());
  }

  SyncModel markSyncFailed(String error) {
    return copyWith(
      isSynced: false,
      syncError: error,
      syncAttempts: syncAttempts + 1,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    updatedAt,
    isSynced,
    syncError,
    syncAttempts,
  ];
}
