/// An enum representing the types of events that occur in the synchronization system.
///
/// These events allow different components of an application
/// to monitor synchronization-related activities.
enum SyncEventType {
  /// When a connection is established
  connectionEstablished,

  /// When a connection is closed
  connectionClosed,

  /// When a connection fails
  connectionFailed,

  /// When reconnection is attempted
  reconnecting,

  /// Indicates that synchronization has started
  syncStarted,

  /// Indicates that synchronization has completed
  syncCompleted,

  /// Indicates an error during synchronization
  syncError,

  /// Indicates a model has been updated
  modelUpdated,

  /// Indicates a model has been added
  modelAdded,

  /// Indicates a model has been deleted
  modelDeleted,

  /// When a synchronization conflict is detected
  conflictDetected,

  /// When a conflict is resolved
  conflictResolved,
}
