import 'package:equatable/equatable.dart';

class SyncStatus extends Equatable {
  final bool isConnected;
  final bool isSyncing;
  final int pendingChanges;
  final DateTime lastSyncTime;
  final String lastSyncError;
  final bool hasErrors;
  final int totalSynced;
  final double syncProgress;

  SyncStatus({
    this.isConnected = false,
    this.isSyncing = false,
    this.pendingChanges = 0,
    DateTime? lastSyncTime,
    this.lastSyncError = '',
    this.hasErrors = false,
    this.totalSynced = 0,
    this.syncProgress = 0.0,
  }) : lastSyncTime = lastSyncTime ?? DateTime.fromMillisecondsSinceEpoch(0);

  SyncStatus copyWith({
    bool? isConnected,
    bool? isSyncing,
    int? pendingChanges,
    DateTime? lastSyncTime,
    String? lastSyncError,
    bool? hasErrors,
    int? totalSynced,
    double? syncProgress,
  }) {
    return SyncStatus(
      isConnected: isConnected ?? this.isConnected,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      hasErrors: hasErrors ?? this.hasErrors,
      totalSynced: totalSynced ?? this.totalSynced,
      syncProgress: syncProgress ?? this.syncProgress,
    );
  }

  bool get needsSync => pendingChanges > 0;

  @override
  List<Object?> get props => [
    isConnected,
    isSyncing,
    pendingChanges,
    lastSyncTime,
    lastSyncError,
    hasErrors,
    totalSynced,
    syncProgress,
  ];
}
