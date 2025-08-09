import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/constants.dart';
import '../models/models.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamController<WebSocketMessage>? _messageController;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  
  bool _isConnected = false;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const Duration pingInterval = Duration(seconds: 30);

  // Connection parameters
  int? _restaurantId;
  int? _userId;
  String? _userRole;
  String? _authToken;

  Stream<WebSocketMessage> get messageStream => _messageController?.stream ?? const Stream.empty();
  bool get isConnected => _isConnected;

  // Connect to WebSocket
  Future<void> connect({
    required int restaurantId,
    int? userId,
    String? userRole,
    String? authToken,
  }) async {
    _restaurantId = restaurantId;
    _userId = userId;
    _userRole = userRole ?? AppConstants.roleCustomer;
    _authToken = authToken;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    await _connect();
  }

  Future<void> _connect() async {
    try {
      if (_isConnected) {
        await disconnect();
      }

      _messageController = StreamController<WebSocketMessage>.broadcast();

      // Build WebSocket URL with query parameters
      final uri = Uri.parse(AppConstants.wsUrl).replace(
        queryParameters: {
          'restaurant_id': _restaurantId.toString(),
          if (_userId != null) 'user_id': _userId.toString(),
          if (_userRole != null) 'user_role': _userRole!,
          if (_authToken != null) 'token': _authToken!,
        },
      );

      _channel = WebSocketChannel.connect(uri);
      
      // Listen to messages
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      
      // Start ping timer
      _startPingTimer();
      
      print('WebSocket connected to restaurant $_restaurantId');
    } catch (e) {
      print('WebSocket connection error: $e');
      _handleError(e);
    }
  }

  // Disconnect from WebSocket
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _isConnected = false;
    
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    
    await _channel?.sink.close();
    _channel = null;
    
    await _messageController?.close();
    _messageController = null;
    
    print('WebSocket disconnected');
  }

  // Send message
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = json.encode(message);
        _channel!.sink.add(jsonMessage);
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    } else {
      print('WebSocket not connected, cannot send message');
    }
  }

  // Handle incoming messages
  void _handleMessage(dynamic data) {
    try {
      final Map<String, dynamic> messageData = json.decode(data);
      final message = WebSocketMessage.fromJson(messageData);
      
      // Handle specific message types
      switch (message.type) {
        case 'connection_established':
          print('WebSocket connection established');
          break;
        case 'pong':
          // Pong received, connection is alive
          break;
        case 'error':
          print('WebSocket error: ${message.data['message']}');
          break;
        default:
          // Forward message to listeners
          _messageController?.add(message);
      }
    } catch (e) {
      print('Error parsing WebSocket message: $e');
    }
  }

  // Handle WebSocket errors
  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    
    if (_shouldReconnect && _reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  // Handle WebSocket disconnection
  void _handleDisconnection() {
    print('WebSocket disconnected');
    _isConnected = false;
    
    if (_shouldReconnect && _reconnectAttempts < maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }

  // Schedule reconnection
  void _scheduleReconnect() {
    _reconnectAttempts++;
    print('Scheduling WebSocket reconnection attempt $_reconnectAttempts');
    
    _reconnectTimer = Timer(reconnectDelay, () async {
      if (_shouldReconnect) {
        await _connect();
      }
    });
  }

  // Start ping timer
  void _startPingTimer() {
    _pingTimer = Timer.periodic(pingInterval, (timer) {
      if (_isConnected) {
        sendMessage({
          'type': 'ping',
          'data': {'timestamp': DateTime.now().toIso8601String()},
        });
      }
    });
  }

  // Convenience methods for common message types
  void joinRoom(String room) {
    sendMessage({
      'type': 'join_room',
      'data': {'room': room},
    });
  }

  void requestOrderStatus(int orderId) {
    sendMessage({
      'type': 'order_status_request',
      'data': {'order_id': orderId},
    });
  }

  void sendKitchenNotification(Map<String, dynamic> data) {
    sendMessage({
      'type': 'kitchen_notification',
      'data': data,
    });
  }

  void updateServiceRequest(Map<String, dynamic> data) {
    sendMessage({
      'type': 'service_request_update',
      'data': data,
    });
  }

  void broadcastAnnouncement(String message) {
    sendMessage({
      'type': 'broadcast_announcement',
      'data': {'message': message},
    });
  }

  void getConnectionStats() {
    sendMessage({
      'type': 'get_connection_stats',
      'data': {},
    });
  }

  // Dispose resources
  void dispose() {
    disconnect();
  }
}

