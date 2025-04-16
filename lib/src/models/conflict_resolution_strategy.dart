/// Defines the strategy to use when a conflict is detected during synchronization
enum ConflictResolutionStrategy {
  /// Server version always wins over the local version
  serverWins,

  /// Local version always wins over the server version
  clientWins,

  /// The most recently updated version wins
  lastUpdateWins,

  /// Custom resolution strategy using a provided resolver function
  custom,
}

/// Represents a data conflict between local and server versions
class SyncConflict<T> {
  /// The local version of the data
  final T localVersion;

  /// The server version of the data
  final T serverVersion;

  /// Creates a new conflict instance
  SyncConflict({required this.localVersion, required this.serverVersion});
}

/// Signature for a custom conflict resolver function
typedef ConflictResolver<T> = T Function(SyncConflict<T> conflict);

/// Handles conflict resolution for synchronization operations
class ConflictResolutionHandler {
  /// The strategy to use when resolving conflicts
  final ConflictResolutionStrategy strategy;

  /// Custom resolver function, required when using [ConflictResolutionStrategy.custom]
  final ConflictResolver? customResolver;

  /// Creates a new conflict resolution handler
  ///
  /// Parameters:
  /// - [strategy]: The conflict resolution strategy to use
  /// - [customResolver]: Custom resolver function, required when using [ConflictResolutionStrategy.custom]
  ConflictResolutionHandler({
    this.strategy = ConflictResolutionStrategy.lastUpdateWins,
    this.customResolver,
  }) {
    if (strategy == ConflictResolutionStrategy.custom &&
        customResolver == null) {
      throw ArgumentError(
        'Custom resolver function must be provided when using custom resolution strategy',
      );
    }
  }

  /// Resolves a conflict between local and server versions
  ///
  /// Parameters:
  /// - [conflict]: The conflict to resolve
  ///
  /// Returns the resolved version that should be used
  T resolveConflict<T>(SyncConflict<T> conflict) {
    switch (strategy) {
      case ConflictResolutionStrategy.serverWins:
        return conflict.serverVersion;

      case ConflictResolutionStrategy.clientWins:
        return conflict.localVersion;

      case ConflictResolutionStrategy.lastUpdateWins:
        // Check if both versions have updatedAt timestamps
        if (_hasUpdatedAtProperty(conflict.localVersion) &&
            _hasUpdatedAtProperty(conflict.serverVersion)) {
          // Use null-safe way to access the updatedAt properties
          final localVersion = conflict.localVersion as dynamic;
          final serverVersion = conflict.serverVersion as dynamic;

          final localTime = localVersion.updatedAt as DateTime;
          final serverTime = serverVersion.updatedAt as DateTime;

          // Return the most recently updated version
          return localTime.isAfter(serverTime)
              ? conflict.localVersion
              : conflict.serverVersion;
        }
        // Fallback to server version if timestamps can't be compared
        return conflict.serverVersion;

      case ConflictResolutionStrategy.custom:
        if (customResolver != null) {
          return customResolver!(conflict);
        }
        throw StateError('Custom resolver is null');
    }
  }

  /// Checks if the object has an updatedAt property that is not null
  bool _hasUpdatedAtProperty(dynamic object) {
    if (object == null) return false;

    try {
      return object.updatedAt != null && object.updatedAt is DateTime;
    } catch (_) {
      return false;
    }
  }
}
