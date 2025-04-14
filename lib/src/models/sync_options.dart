import 'package:equatable/equatable.dart';
import 'connectivity_options.dart';

class SyncOptions extends Equatable {
  final Duration syncInterval;
  final int maxRetryAttempts;
  final bool autoSync;
  final bool bidirectionalSync;
  final ConnectivityOptions connectivityRequirement;
  final int batchSize;
  final Duration retryBackoffFactor;
  final Duration initialBackoffDelay;
  final Duration maxBackoffDelay;

  const SyncOptions({
    this.syncInterval = const Duration(minutes: 15),
    this.maxRetryAttempts = 5,
    this.autoSync = true,
    this.bidirectionalSync = true,
    this.connectivityRequirement = ConnectivityOptions.any,
    this.batchSize = 10,
    this.retryBackoffFactor = const Duration(seconds: 2),
    this.initialBackoffDelay = const Duration(seconds: 1),
    this.maxBackoffDelay = const Duration(minutes: 5),
  });

  SyncOptions copyWith({
    Duration? syncInterval,
    int? maxRetryAttempts,
    bool? autoSync,
    bool? bidirectionalSync,
    ConnectivityOptions? connectivityRequirement,
    int? batchSize,
    Duration? retryBackoffFactor,
    Duration? initialBackoffDelay,
    Duration? maxBackoffDelay,
  }) {
    return SyncOptions(
      syncInterval: syncInterval ?? this.syncInterval,
      maxRetryAttempts: maxRetryAttempts ?? this.maxRetryAttempts,
      autoSync: autoSync ?? this.autoSync,
      bidirectionalSync: bidirectionalSync ?? this.bidirectionalSync,
      connectivityRequirement:
          connectivityRequirement ?? this.connectivityRequirement,
      batchSize: batchSize ?? this.batchSize,
      retryBackoffFactor: retryBackoffFactor ?? this.retryBackoffFactor,
      initialBackoffDelay: initialBackoffDelay ?? this.initialBackoffDelay,
      maxBackoffDelay: maxBackoffDelay ?? this.maxBackoffDelay,
    );
  }

  @override
  List<Object?> get props => [
    syncInterval,
    maxRetryAttempts,
    autoSync,
    bidirectionalSync,
    connectivityRequirement,
    batchSize,
    retryBackoffFactor,
    initialBackoffDelay,
    maxBackoffDelay,
  ];
}
