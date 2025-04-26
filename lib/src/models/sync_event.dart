import 'package:equatable/equatable.dart';
import 'sync_event_type.dart';
import 'sync_model.dart';

/// A class representing an event occurring in the synchronization system.
///
/// This class contains information about events triggered by the
/// synchronization system, including relevant data and metadata.
class SyncEvent extends Equatable {
  /// The type of event
  final SyncEventType type;

  /// Message describing the event
  final String message;

  /// The model related to the event (optional)
  final SyncModel? model;

  /// Additional data related to the event
  final Map<String, dynamic>? data;

  /// Timestamp when the event occurred
  final DateTime timestamp;

  /// Creates a new SyncEvent instance.
  ///
  /// [type] event type, [message] event description,
  /// [model] related model (optional), [data] additional data (optional).
  /// [timestamp] defaults to current time if not provided.
  SyncEvent({
    required this.type,
    this.message = '',
    this.model,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [type, message, model, data, timestamp];

  @override
  String toString() {
    return 'SyncEvent{type: $type, message: $message, timestamp: $timestamp}';
  }

  /// Creates a copy of this event with the given fields replaced.
  SyncEvent copyWith({
    SyncEventType? type,
    String? message,
    SyncModel? model,
    Map<String, dynamic>? data,
    DateTime? timestamp,
  }) {
    return SyncEvent(
      type: type ?? this.type,
      message: message ?? this.message,
      model: model ?? this.model,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
