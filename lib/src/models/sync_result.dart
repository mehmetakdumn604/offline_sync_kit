import 'package:equatable/equatable.dart';

enum SyncResultStatus {
  success,
  failed,
  partial,
  noChanges,
  connectionError,
  serverError,
}

class SyncResult extends Equatable {
  final SyncResultStatus status;
  final int processedItems;
  final int failedItems;
  final List<String> errorMessages;
  final DateTime timestamp;
  final Duration timeTaken;

  SyncResult({
    required this.status,
    this.processedItems = 0,
    this.failedItems = 0,
    List<String>? errorMessages,
    DateTime? timestamp,
    this.timeTaken = Duration.zero,
  }) : errorMessages = errorMessages ?? [],
       timestamp = timestamp ?? DateTime.now();

  bool get isSuccessful =>
      status == SyncResultStatus.success ||
      status == SyncResultStatus.noChanges;

  @override
  List<Object?> get props => [
    status,
    processedItems,
    failedItems,
    errorMessages,
    timestamp,
    timeTaken,
  ];

  static SyncResult success({
    int processedItems = 0,
    Duration timeTaken = Duration.zero,
  }) {
    return SyncResult(
      status: SyncResultStatus.success,
      processedItems: processedItems,
      timeTaken: timeTaken,
    );
  }

  static SyncResult failed({
    String error = '',
    Duration timeTaken = Duration.zero,
  }) {
    return SyncResult(
      status: SyncResultStatus.failed,
      errorMessages: error.isNotEmpty ? [error] : [],
      timeTaken: timeTaken,
    );
  }

  static SyncResult noChanges() {
    return SyncResult(status: SyncResultStatus.noChanges);
  }

  static SyncResult connectionError() {
    return SyncResult(
      status: SyncResultStatus.connectionError,
      errorMessages: ['No internet connection available'],
    );
  }
}
