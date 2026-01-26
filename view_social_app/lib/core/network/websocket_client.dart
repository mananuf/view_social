import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class WebSocketClient {
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  Timer? _heartbeatTimer;
  bool _isConnected = false;
  
  Stream<Map<String, dynamic>> get messageStream => 
      _messageController?.stream ?? const Stream.empty();
  
  bool get isConnected => _isConnected;
  
  Future<void> connect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.accessTokenKey);
      
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      final uri = Uri.parse('${AppConstants.wsUrl}?token=$token');
      _channel = WebSocketChannel.connect(uri);
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      
      _channel!.stream.listen(
        (data) {
          final message = jsonDecode(data as String) as Map<String, dynamic>;
          _messageController!.add(message);
        },
        onDone: () {
          _isConnected = false;
          _cleanup();
        },
        onError: (error) {
          _isConnected = false;
          _cleanup();
        },
      );
      
      _isConnected = true;
      _startHeartbeat();
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }
  
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 30),
      (timer) {
        if (_isConnected) {
          sendMessage({'type': 'ping'});
        }
      },
    );
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }
  
  void disconnect() {
    _isConnected = false;
    _cleanup();
  }
  
  void _cleanup() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _messageController?.close();
    _channel = null;
    _messageController = null;
    _heartbeatTimer = null;
  }
}