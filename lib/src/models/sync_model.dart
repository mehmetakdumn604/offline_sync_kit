import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Base abstract class for all models that need offline synchronization.
///
/// All models that should be synchronized with a remote API should extend this class.
/// It includes all necessary properties for tracking sync state (sync status, timestamps, etc.).
///
/// Example:
/// ```dart
/// class Todo extends SyncModel {
///   final String title;
///   final bool isCompleted;
///
///   Todo({
///     super.id,
///     super.createdAt,
///     super.updatedAt,
///     super.isSynced,
///     required this.title,
///     this.isCompleted = false,
///   });
///
///   @override
///   String get endpoint => 'todos';
///
///   @override
///   String get modelType => 'todo';
///
///   @override
///   Map<String, dynamic> toJson() {
///     return {
///       'id': id,
///       'title': title,
///       'isCompleted': isCompleted,
///     };
///   }
///
///   @override
///   Todo copyWith({...}) {
///     // Implementation
///   }
/// }
/// ```
abstract class SyncModel extends Equatable {
  /// Unique identifier for the model instance (UUID v4)
  final String id;

  /// Timestamp when the model was first created
  final DateTime createdAt;

  /// Timestamp of the most recent update
  final DateTime updatedAt;

  /// Flag indicating whether this model has been synced with the server
  final bool isSynced;

  /// Error message for the last failed sync attempt, empty if none
  final String syncError;

  /// Number of failed sync attempts for this model
  final int syncAttempts;

  /// Creates a new SyncModel instance
  ///
  /// If [id] is not provided, a new UUID v4 will be generated
  /// If [createdAt] or [updatedAt] are not provided, the current time is used
  /// A new model is not synced by default ([isSynced] = false)
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

  /// The API endpoint for this model type (without leading slash)
  ///
  /// For example: 'todos', 'users', 'products'
  String get endpoint;

  /// A unique string identifier for this model type
  ///
  /// This is used to identify different model types in storage
  /// For example: 'todo', 'user', 'product'
  String get modelType;

  /// Converts the model to a JSON map for API requests and storage
  Map<String, dynamic> toJson();

  /// Creates a copy of this model with optionally modified properties
  ///
  /// Allows updating a model immutably. Make sure to implement
  /// this in derived classes to handle custom fields.
  SyncModel copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? syncError,
    int? syncAttempts,
  });

  /// Marks this model as successfully synchronized with the server
  ///
  /// Returns a new instance with [isSynced] = true and cleared [syncError]
  SyncModel markAsSynced() {
    return copyWith(isSynced: true, syncError: '', updatedAt: DateTime.now());
  }

  /// Marks this model as failed to synchronize
  ///
  /// Returns a new instance with [isSynced] = false, increased [syncAttempts],
  /// and the [error] message stored in [syncError]
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
