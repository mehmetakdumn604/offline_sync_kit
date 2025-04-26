import 'package:equatable/equatable.dart';
import 'sync_event_type.dart';

/// A mapper for converting WebSocket event names to SyncEventType and vice versa.
///
/// This class allows customizing the event type mapping between WebSocket messages
/// and the application's SyncEventType enum, enabling full customization of event names.
class SyncEventMapper extends Equatable {
  /// Mapping from WebSocket event names to SyncEventType
  final Map<String, SyncEventType> eventNameToTypeMap;

  /// Mapping from SyncEventType to WebSocket event names
  final Map<SyncEventType, String> typeToEventNameMap;

  /// Creates a new SyncEventMapper with custom mappings.
  ///
  /// By default, it uses standard event names that match the SyncEventType enum names.
  /// These can be customized to match any WebSocket server's event naming conventions.
  const SyncEventMapper({
    Map<String, SyncEventType>? eventNameToTypeMap,
    Map<SyncEventType, String>? typeToEventNameMap,
  }) : eventNameToTypeMap = eventNameToTypeMap ?? _defaultEventNameToTypeMap,
       typeToEventNameMap = typeToEventNameMap ?? _defaultTypeToEventNameMap;

  /// Maps a WebSocket event name to a SyncEventType.
  ///
  /// Returns null if the event name does not have a defined mapping.
  SyncEventType? mapEventNameToType(String eventName) {
    return eventNameToTypeMap[eventName];
  }

  /// Maps a SyncEventType to a WebSocket event name.
  ///
  /// Returns the enum name as a fallback if no mapping is defined.
  String mapTypeToEventName(SyncEventType type) {
    return typeToEventNameMap[type] ?? type.name;
  }

  /// Creates a copy of this mapper with the specified fields replaced.
  SyncEventMapper copyWith({
    Map<String, SyncEventType>? eventNameToTypeMap,
    Map<SyncEventType, String>? typeToEventNameMap,
  }) {
    return SyncEventMapper(
      eventNameToTypeMap: eventNameToTypeMap ?? this.eventNameToTypeMap,
      typeToEventNameMap: typeToEventNameMap ?? this.typeToEventNameMap,
    );
  }

  /// Adds a new mapping or updates an existing one.
  SyncEventMapper withMapping(String eventName, SyncEventType type) {
    final updatedEventToType = Map<String, SyncEventType>.from(
      eventNameToTypeMap,
    )..putIfAbsent(eventName, () => type);

    final updatedTypeToEvent = Map<SyncEventType, String>.from(
      typeToEventNameMap,
    )..putIfAbsent(type, () => eventName);

    return SyncEventMapper(
      eventNameToTypeMap: updatedEventToType,
      typeToEventNameMap: updatedTypeToEvent,
    );
  }

  /// Default mapping from WebSocket event names to SyncEventType
  static const Map<String, SyncEventType> _defaultEventNameToTypeMap = {
    'modelUpdated': SyncEventType.modelUpdated,
    'modelAdded': SyncEventType.modelAdded,
    'modelDeleted': SyncEventType.modelDeleted,
    'syncCompleted': SyncEventType.syncCompleted,
    'syncStarted': SyncEventType.syncStarted,
    'syncError': SyncEventType.syncError,
    'connectionEstablished': SyncEventType.connectionEstablished,
    'connectionClosed': SyncEventType.connectionClosed,
    'connectionFailed': SyncEventType.connectionFailed,
    'reconnecting': SyncEventType.reconnecting,
    'conflictDetected': SyncEventType.conflictDetected,
    'conflictResolved': SyncEventType.conflictResolved,
  };

  /// Default mapping from SyncEventType to WebSocket event names
  static const Map<SyncEventType, String> _defaultTypeToEventNameMap = {
    SyncEventType.modelUpdated: 'modelUpdated',
    SyncEventType.modelAdded: 'modelAdded',
    SyncEventType.modelDeleted: 'modelDeleted',
    SyncEventType.syncCompleted: 'syncCompleted',
    SyncEventType.syncStarted: 'syncStarted',
    SyncEventType.syncError: 'syncError',
    SyncEventType.connectionEstablished: 'connectionEstablished',
    SyncEventType.connectionClosed: 'connectionClosed',
    SyncEventType.connectionFailed: 'connectionFailed',
    SyncEventType.reconnecting: 'reconnecting',
    SyncEventType.conflictDetected: 'conflictDetected',
    SyncEventType.conflictResolved: 'conflictResolved',
  };

  @override
  List<Object?> get props => [eventNameToTypeMap, typeToEventNameMap];
}
