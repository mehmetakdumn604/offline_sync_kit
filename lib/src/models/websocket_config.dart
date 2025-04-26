import 'package:equatable/equatable.dart';

/// Configuration options for WebSocket connections.
///
/// This class allows customizing various aspects of WebSocket connections
/// including connection behavior, messages, and event handling.
class WebSocketConfig extends Equatable {
  /// The server URL for WebSocket connection
  final String serverUrl;

  /// Ping interval in seconds
  final int pingInterval;

  /// Reconnection delay in milliseconds
  final int reconnectDelay;

  /// Maximum number of reconnection attempts
  final int maxReconnectAttempts;

  /// Custom message for connection established event
  final String connectionEstablishedMessage;

  /// Custom message for connection closed event
  final String connectionClosedMessage;

  /// Custom message for connection failed event (without error details)
  final String connectionFailedMessage;

  /// Custom message for reconnection attempt event (without attempt details)
  final String reconnectingMessage;

  /// Custom message for request timeout error
  final String requestTimeoutMessage;

  /// Custom message for error when sending message
  final String errorSendingMessage;

  /// Custom message for error when sending request
  final String errorSendingRequestMessage;

  /// Custom message for client closed
  final String clientClosedMessage;

  /// Custom message for WebSocket connection closed error
  final String connectionClosedErrorMessage;

  /// Custom format for ping message
  final Map<String, dynamic> pingMessageFormat;

  /// Custom format for subscription message
  final Map<String, dynamic> Function(
    String channel,
    Map<String, dynamic>? parameters,
  )
  subscriptionMessageFormatter;

  /// Custom format for unsubscription message
  final Map<String, dynamic> Function(String channel)
  unsubscriptionMessageFormatter;

  /// Custom message type for subscription messages
  final String subscriptionMessageType;

  /// Custom message type for request messages
  final String requestMessageType;

  /// Creates a WebSocketConfig with customizable options.
  ///
  /// All parameters can be customized to personalize the WebSocket connection
  /// behavior and messaging.
  const WebSocketConfig({
    required this.serverUrl,
    this.pingInterval = 30,
    this.reconnectDelay = 5000,
    this.maxReconnectAttempts = 10,
    this.connectionEstablishedMessage = 'WebSocket connection established',
    this.connectionClosedMessage = 'WebSocket connection closed',
    this.connectionFailedMessage = 'WebSocket connection failed',
    this.reconnectingMessage = 'Reconnecting',
    this.requestTimeoutMessage = 'Request timed out',
    this.errorSendingMessage = 'Error sending message',
    this.errorSendingRequestMessage = 'Error sending request',
    this.clientClosedMessage = 'Client closed',
    this.connectionClosedErrorMessage = 'WebSocket connection closed',
    this.pingMessageFormat = const {'type': 'ping'},
    this.subscriptionMessageType = 'subscription',
    this.requestMessageType = 'request',
    Map<String, dynamic> Function(
      String channel,
      Map<String, dynamic>? parameters,
    )?
    subscriptionMessageFormatter,
    Map<String, dynamic> Function(String channel)?
    unsubscriptionMessageFormatter,
  }) : subscriptionMessageFormatter =
           subscriptionMessageFormatter ?? _defaultSubscriptionFormatter,
       unsubscriptionMessageFormatter =
           unsubscriptionMessageFormatter ?? _defaultUnsubscriptionFormatter;

  /// Creates a copy of this config with the specified fields replaced.
  WebSocketConfig copyWith({
    String? serverUrl,
    int? pingInterval,
    int? reconnectDelay,
    int? maxReconnectAttempts,
    String? connectionEstablishedMessage,
    String? connectionClosedMessage,
    String? connectionFailedMessage,
    String? reconnectingMessage,
    String? requestTimeoutMessage,
    String? errorSendingMessage,
    String? errorSendingRequestMessage,
    String? clientClosedMessage,
    String? connectionClosedErrorMessage,
    Map<String, dynamic>? pingMessageFormat,
    String? subscriptionMessageType,
    String? requestMessageType,
    Map<String, dynamic> Function(
      String channel,
      Map<String, dynamic>? parameters,
    )?
    subscriptionMessageFormatter,
    Map<String, dynamic> Function(String channel)?
    unsubscriptionMessageFormatter,
  }) {
    return WebSocketConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      pingInterval: pingInterval ?? this.pingInterval,
      reconnectDelay: reconnectDelay ?? this.reconnectDelay,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      connectionEstablishedMessage:
          connectionEstablishedMessage ?? this.connectionEstablishedMessage,
      connectionClosedMessage:
          connectionClosedMessage ?? this.connectionClosedMessage,
      connectionFailedMessage:
          connectionFailedMessage ?? this.connectionFailedMessage,
      reconnectingMessage: reconnectingMessage ?? this.reconnectingMessage,
      requestTimeoutMessage:
          requestTimeoutMessage ?? this.requestTimeoutMessage,
      errorSendingMessage: errorSendingMessage ?? this.errorSendingMessage,
      errorSendingRequestMessage:
          errorSendingRequestMessage ?? this.errorSendingRequestMessage,
      clientClosedMessage: clientClosedMessage ?? this.clientClosedMessage,
      connectionClosedErrorMessage:
          connectionClosedErrorMessage ?? this.connectionClosedErrorMessage,
      pingMessageFormat: pingMessageFormat ?? this.pingMessageFormat,
      subscriptionMessageType:
          subscriptionMessageType ?? this.subscriptionMessageType,
      requestMessageType: requestMessageType ?? this.requestMessageType,
      subscriptionMessageFormatter:
          subscriptionMessageFormatter ?? this.subscriptionMessageFormatter,
      unsubscriptionMessageFormatter:
          unsubscriptionMessageFormatter ?? this.unsubscriptionMessageFormatter,
    );
  }

  /// Default formatter for subscription messages
  static Map<String, dynamic> _defaultSubscriptionFormatter(
    String channel,
    Map<String, dynamic>? parameters,
  ) {
    return {
      'action': 'subscribe',
      'channel': channel,
      if (parameters != null) 'parameters': parameters,
    };
  }

  /// Default formatter for unsubscription messages
  static Map<String, dynamic> _defaultUnsubscriptionFormatter(String channel) {
    return {'action': 'unsubscribe', 'channel': channel};
  }

  @override
  List<Object?> get props => [
    serverUrl,
    pingInterval,
    reconnectDelay,
    maxReconnectAttempts,
    connectionEstablishedMessage,
    connectionClosedMessage,
    connectionFailedMessage,
    reconnectingMessage,
    requestTimeoutMessage,
    errorSendingMessage,
    errorSendingRequestMessage,
    clientClosedMessage,
    connectionClosedErrorMessage,
    pingMessageFormat,
    subscriptionMessageType,
    requestMessageType,
    // Function references are excluded from equality comparison
  ];
}
