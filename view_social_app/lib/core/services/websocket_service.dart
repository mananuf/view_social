import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// WebSocket event types matching backend implementation
enum WebSocketEventType {
  messageSent,
  messageRead,
  messageDelivered,
  typingStarted,
  typingStopped,
  paymentReceived,
  postLiked,
  userOnline,
  userOffline,
  error,
}

/// WebSocket event data
class WebSocketEvent {
  final WebSocketEventType type;
  final Map<String, dynamic> data;

  WebSocketEvent({required this.type, required this.data});

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = _parseEventType(typeStr);

    return WebSocketEvent(type: type, data: json);
  }

  static WebSocketEventType _parseEventType(String typeStr) {
    switch (typeStr) {
      case 'message_sent':
        return WebSocketEventType.messageSent;
      case 'message_read':
        return WebSocketEventType.messageRead;
      case 'message_delivered':
        return WebSocketEventType.messageDelivered;
      case 'typing_started':
        return WebSocketEventType.typingStarted;
      case 'typing_stopped':
        return WebSocketEventType.typingStopped;
      case 'payment_received':
        return WebSocketEventType.paymentReceived;
      case 'post_liked':
        return WebSocketEventType.postLiked;
      case 'user_online':
        return WebSocketEventType.userOnline;
      case 'user_offline':
        return WebSocketEventType.userOffline;
      case 'error':
        return WebSocketEventType.error;
      default:
        return WebSocketEventType.error;
    }
  }
}

/// WebSocket service for real-time communication
class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<WebSocketEvent>? _eventController;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _pingInterval = Duration(seconds: 30);

  // Online status tracking
  final Map<String, bool> _onlineStatus = {};
  final StreamController<Map<String, bool>> _onlineStatusController =
      StreamController<Map<String, bool>>.broadcast();

  // Typing indicators
  final Map<String, Set<String>> _typingUsers = {};
  final StreamController<Map<String, Set<String>>> _typingController =
      StreamController<Map<String, Set<String>>>.broadcast();

  // Message delivery status
  final Map<String, String> _messageStatus =
      {}; // messageId -> status (sent/delivered/read)
  final StreamController<Map<String, String>> _messageStatusController =
      StreamController<Map<String, String>>.broadcast();

  Stream<WebSocketEvent> get events => _eventController!.stream;
  Stream<Map<String, bool>> get onlineStatus => _onlineStatusController.stream;
  Stream<Map<String, Set<String>>> get typingIndicators =>
      _typingController.stream;
  Stream<Map<String, String>> get messageStatus =>
      _messageStatusController.stream;

  bool get isConnected => _channel != null;

  /// Connect to WebSocket server
  Future<void> connect() async {
    if (_isConnecting || isConnected) {
      return;
    }

    _isConnecting = true;
    _shouldReconnect = true;

    try {
      // Close existing connection if any
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }

      // Get auth token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);

      if (token == null) {
        throw Exception('No auth token available');
      }

      // Build WebSocket URL with ws:// scheme
      final wsUrl = AppConstants.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');

      // Remove any trailing slashes and build clean URL
      final cleanUrl = wsUrl.endsWith('/')
          ? wsUrl.substring(0, wsUrl.length - 1)
          : wsUrl;
      final uri = Uri.parse('$cleanUrl/ws?token=$token');

      print('🔌 Connecting to WebSocket: $uri');

      // Create WebSocket channel with explicit IOWebSocketChannel
      _channel = IOWebSocketChannel.connect(uri);
      _eventController = StreamController<WebSocketEvent>.broadcast();

      // Listen to WebSocket messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
        cancelOnError: false,
      );

      // Start ping timer to keep connection alive
      _startPingTimer();

      _reconnectAttempts = 0;
      _isConnecting = false;

      print('✅ WebSocket connected');
    } catch (e) {
      _isConnecting = false;
      print('❌ WebSocket connection error: $e');
      _scheduleReconnect();
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final json = jsonDecode(message as String) as Map<String, dynamic>;
      final event = WebSocketEvent.fromJson(json);

      // Handle specific event types
      switch (event.type) {
        case WebSocketEventType.userOnline:
          final userId = event.data['user_id'] as String;
          _onlineStatus[userId] = true;
          _onlineStatusController.add(Map.from(_onlineStatus));
          break;

        case WebSocketEventType.userOffline:
          final userId = event.data['user_id'] as String;
          _onlineStatus[userId] = false;
          _onlineStatusController.add(Map.from(_onlineStatus));
          break;

        case WebSocketEventType.typingStarted:
          final conversationId = event.data['conversation_id'] as String;
          final userId = event.data['user_id'] as String;
          _typingUsers.putIfAbsent(conversationId, () => {}).add(userId);
          _typingController.add(Map.from(_typingUsers));
          break;

        case WebSocketEventType.typingStopped:
          final conversationId = event.data['conversation_id'] as String;
          final userId = event.data['user_id'] as String;
          _typingUsers[conversationId]?.remove(userId);
          _typingController.add(Map.from(_typingUsers));
          break;

        case WebSocketEventType.messageSent:
          final messageId = event.data['message_id'] as String;
          _messageStatus[messageId] = 'sent';
          _messageStatusController.add(Map.from(_messageStatus));
          break;

        case WebSocketEventType.messageDelivered:
          final messageId = event.data['message_id'] as String;
          _messageStatus[messageId] = 'delivered';
          _messageStatusController.add(Map.from(_messageStatus));
          break;

        case WebSocketEventType.messageRead:
          final messageId = event.data['message_id'] as String;
          _messageStatus[messageId] = 'read';
          _messageStatusController.add(Map.from(_messageStatus));
          break;

        default:
          break;
      }

      // Broadcast event to listeners
      _eventController?.add(event);
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  /// Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _scheduleReconnect();
  }

  /// Handle WebSocket disconnection
  void _handleDisconnect() {
    print('WebSocket disconnected');
    _cleanup();
    _scheduleReconnect();
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectAttempts++;
    print(
      'Scheduling reconnect attempt $_reconnectAttempts/$_maxReconnectAttempts',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      connect();
    });
  }

  /// Start ping timer to keep connection alive
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (timer) {
      if (isConnected) {
        try {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        } catch (e) {
          print('Error sending ping: $e');
        }
      }
    });
  }

  /// Send typing indicator
  void sendTypingIndicator(String conversationId, bool isTyping) {
    if (!isConnected) return;

    try {
      final event = {
        'type': isTyping ? 'typing_started' : 'typing_stopped',
        'conversation_id': conversationId,
      };
      _channel?.sink.add(jsonEncode(event));
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }

  /// Mark message as read
  void markMessageAsRead(String messageId) {
    if (!isConnected) return;

    try {
      final event = {'type': 'message_read', 'message_id': messageId};
      _channel?.sink.add(jsonEncode(event));
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }

  /// Check if user is online
  bool isUserOnline(String userId) {
    return _onlineStatus[userId] ?? false;
  }

  /// Get typing users in a conversation
  Set<String> getTypingUsers(String conversationId) {
    return _typingUsers[conversationId] ?? {};
  }

  /// Get message delivery status
  String? getMessageStatus(String messageId) {
    return _messageStatus[messageId];
  }

  /// Cleanup resources
  void _cleanup() {
    _channel?.sink.close();
    _channel = null;
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  /// Disconnect from WebSocket
  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _cleanup();
    print('WebSocket disconnected manually');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _eventController?.close();
    _onlineStatusController.close();
    _typingController.close();
    _messageStatusController.close();
  }
}
