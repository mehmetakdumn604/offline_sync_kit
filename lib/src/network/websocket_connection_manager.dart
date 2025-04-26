import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import '../models/sync_event.dart';
import '../models/sync_event_type.dart';
import '../models/websocket_config.dart';

/// WebSocket connection states
enum WebSocketConnectionState {
  /// Connection is closed
  closed,

  /// Connection is being established
  connecting,

  /// Connection is open
  open,

  /// Reconnection is being attempted
  reconnecting,

  /// Connection error occurred
  error,
}

/// WebSocket message handler type
typedef WebSocketMessageHandler = void Function(Map<String, dynamic> message);

/// WebSocket connection manager.
///
/// This class manages WebSocket connections, including connecting, disconnecting,
/// reconnecting and broadcasting events related to the connection state.
class WebSocketConnectionManager {
  /// WebSocket configuration
  final WebSocketConfig config;

  /// WebSocket connection
  WebSocket? _socket;

  /// Connection state
  WebSocketConnectionState _state = WebSocketConnectionState.closed;

  /// Reconnection attempt count
  int _reconnectAttempts = 0;

  /// Ping/Pong timer
  Timer? _pingTimer;

  /// Reconnection timer
  Timer? _reconnectTimer;

  /// Connection state controller
  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();

  /// Event controller
  final _eventController = StreamController<SyncEvent>.broadcast();

  /// Message handlers
  final List<WebSocketMessageHandler> _messageHandlers = [];

  /// Event stream
  Stream<SyncEvent> get eventStream => _eventController.stream;

  /// Connection state stream
  Stream<WebSocketConnectionState> get stateStream => _stateController.stream;

  /// Current connection state
  WebSocketConnectionState get state => _state;

  /// Whether the connection is open
  bool get isConnected => _state == WebSocketConnectionState.open;

  /// Creates a new WebSocketConnectionManager instance.
  ///
  /// [serverUrl] WebSocket server URL
  /// [pingInterval] ping interval in seconds
  /// [reconnectDelay] reconnection delay in milliseconds
  /// [maxReconnectAttempts] maximum number of reconnection attempts
  WebSocketConnectionManager({
    required String serverUrl,
    int pingInterval = 30,
    int reconnectDelay = 5000,
    int maxReconnectAttempts = 10,
  }) : config = WebSocketConfig(
         serverUrl: serverUrl,
         pingInterval: pingInterval,
         reconnectDelay: reconnectDelay,
         maxReconnectAttempts: maxReconnectAttempts,
       );

  /// Creates a new WebSocketConnectionManager instance with a custom config.
  ///
  /// [config] WebSocket configuration options
  WebSocketConnectionManager.withConfig(this.config);

  /// Adds a message handler
  void addMessageHandler(WebSocketMessageHandler handler) {
    if (!_messageHandlers.contains(handler)) {
      _messageHandlers.add(handler);
    }
  }

  /// Removes a message handler
  void removeMessageHandler(WebSocketMessageHandler handler) {
    _messageHandlers.remove(handler);
  }

  /// Initiates a WebSocket connection.
  ///
  /// If the connection is successfully established, [onOpen] is called.
  /// If a connection error occurs, reconnection is scheduled.
  Future<void> connect() async {
    if (_state == WebSocketConnectionState.open ||
        _state == WebSocketConnectionState.connecting) {
      return;
    }

    _updateState(WebSocketConnectionState.connecting);

    try {
      _socket = await WebSocket.connect(config.serverUrl);
      _updateState(WebSocketConnectionState.open);
      _reconnectAttempts = 0;
      _setupSocketListeners();
      _startPingTimer();

      _emitEvent(
        SyncEvent(
          type: SyncEventType.connectionEstablished,
          message: config.connectionEstablishedMessage,
        ),
      );
    } catch (e) {
      _updateState(WebSocketConnectionState.error);
      _emitEvent(
        SyncEvent(
          type: SyncEventType.connectionFailed,
          message: '${config.connectionFailedMessage}: $e',
          data: {'error': e.toString()},
        ),
      );
      _scheduleReconnect();
    }
  }

  /// Closes the WebSocket connection.
  Future<void> disconnect() async {
    _cancelTimers();

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }

    _updateState(WebSocketConnectionState.closed);

    _emitEvent(
      SyncEvent(
        type: SyncEventType.connectionClosed,
        message: config.connectionClosedMessage,
      ),
    );
  }

  /// Sends a message over the WebSocket connection.
  ///
  /// [data] the data to send. This data will be converted to JSON.
  /// [eventType] the type of the message (optional).
  Future<void> send(Map<String, dynamic> data, {String? eventType}) async {
    if (!isConnected || _socket == null) {
      throw Exception('WebSocket connection is closed');
    }

    final message =
        eventType != null ? {'type': eventType, 'data': data} : data;

    try {
      _socket!.add(jsonEncode(message));
    } catch (e) {
      _emitEvent(
        SyncEvent(
          type: SyncEventType.syncError,
          message: '${config.errorSendingMessage}: $e',
          data: {'error': e.toString(), 'data': data},
        ),
      );
      rethrow;
    }
  }

  /// Subscribes to a channel.
  ///
  /// [channel] the name of the channel to subscribe to.
  /// [parameters] channel parameters (optional).
  Future<void> subscribe(
    String channel, {
    Map<String, dynamic>? parameters,
  }) async {
    await send(
      config.subscriptionMessageFormatter(channel, parameters),
      eventType: config.subscriptionMessageType,
    );
  }

  /// Unsubscribes from a channel.
  ///
  /// [channel] the name of the channel to unsubscribe from.
  Future<void> unsubscribe(String channel) async {
    await send(
      config.unsubscriptionMessageFormatter(channel),
      eventType: config.subscriptionMessageType,
    );
  }

  /// Sets up the socket listeners.
  void _setupSocketListeners() {
    _socket?.listen(
      (dynamic data) {
        _handleMessage(data);
      },
      onDone: () {
        _emitEvent(
          SyncEvent(
            type: SyncEventType.connectionClosed,
            message: config.connectionClosedMessage,
          ),
        );
        _updateState(WebSocketConnectionState.closed);
        _scheduleReconnect();
      },
      onError: (error) {
        _emitEvent(
          SyncEvent(
            type: SyncEventType.connectionFailed,
            message: 'WebSocket error: $error',
            data: {'error': error.toString()},
          ),
        );
        _updateState(WebSocketConnectionState.error);
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  /// Handles incoming messages.
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> message =
          data is String ? jsonDecode(data) : data;

      // Process "pong" messages (heartbeat check)
      if (message['type'] == 'pong') {
        return;
      }

      // Process model-related events
      if (message.containsKey('eventType')) {
        final String eventType = message['eventType'];

        SyncEventType? syncEventType;

        // Determine event type
        if (eventType == 'modelUpdated') {
          syncEventType = SyncEventType.modelUpdated;
        } else if (eventType == 'modelAdded') {
          syncEventType = SyncEventType.modelAdded;
        } else if (eventType == 'modelDeleted') {
          syncEventType = SyncEventType.modelDeleted;
        } else if (eventType == 'conflictDetected') {
          syncEventType = SyncEventType.conflictDetected;
        }

        if (syncEventType != null) {
          _emitEvent(
            SyncEvent(
              type: syncEventType,
              data: message['data'],
              message: message['message'] ?? '',
            ),
          );
        }
      }

      // Notify all message handlers
      notifyListeners(message);
    } catch (e) {
      debugPrint('Failed to process WebSocket message: $e');
    }
  }

  /// Updates the connection state and publishes the corresponding event.
  void _updateState(WebSocketConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Starts the ping timer.
  void _startPingTimer() {
    _cancelPingTimer();
    _pingTimer = Timer.periodic(Duration(seconds: config.pingInterval), (_) {
      if (isConnected) {
        try {
          _socket?.add(jsonEncode(config.pingMessageFormat));
        } catch (e) {
          debugPrint('Failed to send ping: $e');
        }
      }
    });
  }

  /// Cancels the ping timer.
  void _cancelPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Cancels the reconnection timer.
  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Cancels all timers.
  void _cancelTimers() {
    _cancelPingTimer();
    _cancelReconnectTimer();
  }

  /// Schedules a reconnection attempt.
  void _scheduleReconnect() {
    _cancelReconnectTimer();

    if (_reconnectAttempts >= config.maxReconnectAttempts) {
      _emitEvent(
        SyncEvent(
          type: SyncEventType.connectionFailed,
          message: 'Maximum reconnection attempts exceeded',
        ),
      );
      return;
    }

    _reconnectAttempts++;
    _updateState(WebSocketConnectionState.reconnecting);

    _emitEvent(
      SyncEvent(
        type: SyncEventType.reconnecting,
        message:
            '${config.reconnectingMessage} (Attempt: $_reconnectAttempts/${config.maxReconnectAttempts})',
        data: {
          'attempt': _reconnectAttempts,
          'maxAttempts': config.maxReconnectAttempts,
        },
      ),
    );

    // Exponential backoff strategy (1, 2, 4, 8, 16, ...)
    final delay =
        config.reconnectDelay * (1 << (_reconnectAttempts - 1).clamp(0, 5));

    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      connect();
    });
  }

  /// Notifies listeners of a message.
  ///
  /// Called for every message received over the WebSocket connection.
  void notifyListeners(Map<String, dynamic> message) {
    for (final handler in _messageHandlers) {
      try {
        handler(message);
      } catch (e) {
        debugPrint('Error processing message: $e');
      }
    }
  }

  /// Emits an event.
  void _emitEvent(SyncEvent event) {
    _eventController.add(event);
  }

  /// Cleans up resources.
  void dispose() {
    _cancelTimers();
    disconnect();
    _stateController.close();
    _eventController.close();
  }
}
