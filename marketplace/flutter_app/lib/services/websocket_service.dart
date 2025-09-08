import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../core/config/environment.dart';

/// Message types for WebSocket communication
enum WebSocketMessageType {
  // System messages
  connection,
  disconnection,
  heartbeat,
  error,
  
  // User messages
  message,
  notification,
  typing,
  presence,
  
  // Order updates
  orderStatusUpdate,
  deliveryUpdate,
  paymentUpdate,
  
  // Product updates
  priceUpdate,
  stockUpdate,
  
  // Chat messages
  chatMessage,
  chatTyping,
  chatRead,
  
  // Live features
  liveUpdate,
  liveEvent,
}

/// WebSocket connection status
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket message model
class WebSocketMessage {
  final WebSocketMessageType type;
  final Map<String, dynamic> data;
  final String? id;
  final DateTime timestamp;
  final String? userId;
  final String? channel;

  const WebSocketMessage({
    required this.type,
    required this.data,
    this.id,
    required this.timestamp,
    this.userId,
    this.channel,
  });

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      type: WebSocketMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebSocketMessageType.message,
      ),
      data: json['data'] as Map<String, dynamic>,
      id: json['id'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['user_id'] as String?,
      channel: json['channel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'data': data,
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'user_id': userId,
      'channel': channel,
    };
  }
}

/// WebSocket service for real-time communication
class WebSocketService {
  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _reconnectDelay = Duration(seconds: 2);
  static const int _maxReconnectAttempts = 5;
  
  WebSocketChannel? _channel;
  StreamSubscription? _channelSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  
  String? _authToken;
  String? _userId;
  WebSocketStatus _status = WebSocketStatus.disconnected;
  int _reconnectAttempts = 0;
  
  // Stream controllers for different message types
  final _messageController = StreamController<WebSocketMessage>.broadcast();
  final _notificationController = StreamController<WebSocketMessage>.broadcast();
  final _orderUpdateController = StreamController<WebSocketMessage>.broadcast();
  final _chatController = StreamController<WebSocketMessage>.broadcast();
  final _presenceController = StreamController<WebSocketMessage>.broadcast();
  final _statusController = StreamController<WebSocketStatus>.broadcast();
  
  // Public streams
  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  Stream<WebSocketMessage> get notificationStream => _notificationController.stream;
  Stream<WebSocketMessage> get orderUpdateStream => _orderUpdateController.stream;
  Stream<WebSocketMessage> get chatStream => _chatController.stream;
  Stream<WebSocketMessage> get presenceStream => _presenceController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;
  
  // Getters
  WebSocketStatus get status => _status;
  bool get isConnected => _status == WebSocketStatus.connected;
  bool get isConnecting => _status == WebSocketStatus.connecting;
  
  /// Initialize WebSocket connection
  Future<void> connect({
    required String authToken,
    required String userId,
  }) async {
    if (isConnected || isConnecting) {
      log('WebSocket already connected or connecting');
      return;
    }
    
    _authToken = authToken;
    _userId = userId;
    
    await _establishConnection();
  }
  
  /// Disconnect WebSocket
  Future<void> disconnect() async {
    _setStatus(WebSocketStatus.disconnected);
    _stopHeartbeat();
    _stopReconnectTimer();
    
    await _channelSubscription?.cancel();
    await _channel?.sink.close(status.goingAway);
    
    _channel = null;
    _channelSubscription = null;
    _reconnectAttempts = 0;
    
    log('WebSocket disconnected');
  }
  
  /// Send message through WebSocket
  void sendMessage({
    required WebSocketMessageType type,
    required Map<String, dynamic> data,
    String? channel,
    String? id,
  }) {
    if (!isConnected) {
      log('Cannot send message: WebSocket not connected');
      return;
    }
    
    final message = WebSocketMessage(
      type: type,
      data: data,
      id: id ?? _generateMessageId(),
      timestamp: DateTime.now(),
      userId: _userId,
      channel: channel,
    );
    
    _channel?.sink.add(json.encode(message.toJson()));
  }
  
  /// Send chat message
  void sendChatMessage({
    required String conversationId,
    required String content,
    String? replyToId,
    Map<String, dynamic>? metadata,
  }) {
    sendMessage(
      type: WebSocketMessageType.chatMessage,
      data: {
        'conversation_id': conversationId,
        'content': content,
        'reply_to_id': replyToId,
        'metadata': metadata ?? {},
      },
      channel: 'chat_$conversationId',
    );
  }
  
  /// Send typing indicator
  void sendTypingIndicator({
    required String conversationId,
    required bool isTyping,
  }) {
    sendMessage(
      type: WebSocketMessageType.chatTyping,
      data: {
        'conversation_id': conversationId,
        'is_typing': isTyping,
      },
      channel: 'chat_$conversationId',
    );
  }
  
  /// Mark messages as read
  void markMessagesRead({
    required String conversationId,
    required List<String> messageIds,
  }) {
    sendMessage(
      type: WebSocketMessageType.chatRead,
      data: {
        'conversation_id': conversationId,
        'message_ids': messageIds,
      },
      channel: 'chat_$conversationId',
    );
  }
  
  /// Subscribe to specific channels
  void subscribeToChannel(String channel) {
    sendMessage(
      type: WebSocketMessageType.connection,
      data: {
        'action': 'subscribe',
        'channel': channel,
      },
    );
  }
  
  /// Unsubscribe from channels
  void unsubscribeFromChannel(String channel) {
    sendMessage(
      type: WebSocketMessageType.connection,
      data: {
        'action': 'unsubscribe',
        'channel': channel,
      },
    );
  }
  
  /// Update user presence
  void updatePresence({
    required String status, // online, away, busy, offline
    String? customMessage,
  }) {
    sendMessage(
      type: WebSocketMessageType.presence,
      data: {
        'status': status,
        'custom_message': customMessage,
        'last_seen': DateTime.now().toIso8601String(),
      },
    );
  }
  
  /// Private methods
  Future<void> _establishConnection() async {
    try {
      _setStatus(WebSocketStatus.connecting);
      
      final wsUrl = '${Environment.wsUrl}?token=$_authToken&user_id=$_userId';
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Listen to incoming messages
      _channelSubscription = _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleConnectionClosed,
      );
      
      _setStatus(WebSocketStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
      
      log('WebSocket connected successfully');
      
      // Send initial presence
      updatePresence(status: 'online');
      
    } catch (e) {
      log('WebSocket connection failed: $e');
      _setStatus(WebSocketStatus.error);
      _scheduleReconnect();
    }
  }
  
  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String) as Map<String, dynamic>;
      final wsMessage = WebSocketMessage.fromJson(data);
      
      // Route message to appropriate stream
      switch (wsMessage.type) {
        case WebSocketMessageType.heartbeat:
          // Handle heartbeat response
          break;
          
        case WebSocketMessageType.notification:
          _notificationController.add(wsMessage);
          break;
          
        case WebSocketMessageType.orderStatusUpdate:
        case WebSocketMessageType.deliveryUpdate:
        case WebSocketMessageType.paymentUpdate:
          _orderUpdateController.add(wsMessage);
          break;
          
        case WebSocketMessageType.chatMessage:
        case WebSocketMessageType.chatTyping:
        case WebSocketMessageType.chatRead:
          _chatController.add(wsMessage);
          break;
          
        case WebSocketMessageType.presence:
          _presenceController.add(wsMessage);
          break;
          
        case WebSocketMessageType.error:
          log('WebSocket error: ${wsMessage.data}');
          _setStatus(WebSocketStatus.error);
          break;
          
        default:
          _messageController.add(wsMessage);
      }
      
    } catch (e) {
      log('Error parsing WebSocket message: $e');
    }
  }
  
  void _handleError(dynamic error) {
    log('WebSocket error: $error');
    _setStatus(WebSocketStatus.error);
    _scheduleReconnect();
  }
  
  void _handleConnectionClosed() {
    log('WebSocket connection closed');
    _setStatus(WebSocketStatus.disconnected);
    _stopHeartbeat();
    
    if (_reconnectAttempts < _maxReconnectAttempts) {
      _scheduleReconnect();
    }
  }
  
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      log('Max reconnect attempts reached');
      _setStatus(WebSocketStatus.error);
      return;
    }
    
    _setStatus(WebSocketStatus.reconnecting);
    _reconnectAttempts++;
    
    final delay = Duration(
      seconds: (_reconnectDelay.inSeconds * _reconnectAttempts).clamp(1, 30),
    );
    
    log('Scheduling reconnect in ${delay.inSeconds} seconds (attempt $_reconnectAttempts)');
    
    _reconnectTimer = Timer(delay, () {
      if (_authToken != null && _userId != null) {
        _establishConnection();
      }
    });
  }
  
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      if (isConnected) {
        sendMessage(
          type: WebSocketMessageType.heartbeat,
          data: {'timestamp': DateTime.now().toIso8601String()},
        );
      }
    });
  }
  
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  void _setStatus(WebSocketStatus status) {
    if (_status != status) {
      _status = status;
      _statusController.add(status);
      log('WebSocket status changed to: $status');
    }
  }
  
  String _generateMessageId() {
    return 'msg_${DateTime.now().millisecondsSinceEpoch}_${_userId ?? 'anonymous'}';
  }
  
  /// Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _notificationController.close();
    _orderUpdateController.close();
    _chatController.close();
    _presenceController.close();
    _statusController.close();
  }
}

/// WebSocket service singleton
class WebSocketManager {
  static final WebSocketManager _instance = WebSocketManager._internal();
  factory WebSocketManager() => _instance;
  WebSocketManager._internal();
  
  WebSocketService? _service;
  
  WebSocketService get service {
    _service ??= WebSocketService();
    return _service!;
  }
  
  /// Initialize WebSocket connection
  Future<void> initialize({
    required String authToken,
    required String userId,
  }) async {
    await service.connect(
      authToken: authToken,
      userId: userId,
    );
  }
  
  /// Cleanup
  void dispose() {
    _service?.dispose();
    _service = null;
  }
}