import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import '../services/websocket_service.dart';

/// Messaging service for chat functionality
class MessagingService extends ChangeNotifier {
  static MessagingService? _instance;
  static MessagingService get instance => _instance ??= MessagingService._internal();
  
  MessagingService._internal();

  // Dependencies
  late WebSocketService _webSocketService;
  SharedPreferences? _prefs;

  // State
  final Map<String, List<Message>> _chatMessages = {};
  final Map<String, ChatRoom> _chatRooms = {};
  final Map<String, StreamController<Message>> _messageStreams = {};
  final Map<String, Timer> _typingTimers = {};
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ChatRoom> get chatRooms => _chatRooms.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  /// Initialize messaging service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      
      _webSocketService = WebSocketService.instance;
      _prefs = await SharedPreferences.getInstance();
      
      // Listen to WebSocket messages
      _webSocketService.messageStream.listen(_handleWebSocketMessage);
      
      // Load cached data
      await _loadCachedData();
      
      // Load initial chat rooms
      await _loadChatRooms();
      
      _isInitialized = true;
      debugPrint('MessagingService initialized successfully');
      
    } catch (e) {
      debugPrint('Failed to initialize MessagingService: $e');
      _setError('Failed to initialize messaging service');
    } finally {
      _setLoading(false);
    }
  }

  /// Get messages for a specific chat
  List<Message> getMessages(String chatId) {
    return _chatMessages[chatId] ?? [];
  }

  /// Get message stream for real-time updates
  Stream<Message> getMessageStream(String chatId) {
    if (!_messageStreams.containsKey(chatId)) {
      _messageStreams[chatId] = StreamController<Message>.broadcast();
    }
    return _messageStreams[chatId]!.stream;
  }

  /// Get chat room by ID
  ChatRoom? getChatRoom(String chatId) {
    return _chatRooms[chatId];
  }

  /// Get or create chat room for product inquiry
  Future<ChatRoom?> getOrCreateProductChat(String productId, String sellerId) async {
    try {
      // Check if chat already exists
      final existingChat = _chatRooms.values.firstWhere(
        (chat) => chat.productId == productId && 
                  chat.participants.any((p) => p.id == sellerId),
        orElse: () => throw StateError('Not found'),
      );
      
      return existingChat;
        } catch (e) {
      // Chat doesn't exist, create new one
    }

    return await _createProductChat(productId, sellerId);
  }

  /// Send a message
  Future<bool> sendMessage(Message message) async {
    try {
      // Add to local messages immediately
      if (!_chatMessages.containsKey(message.chatId)) {
        _chatMessages[message.chatId] = [];
      }
      _chatMessages[message.chatId]!.add(message);

      // Update chat room's last message
      if (_chatRooms.containsKey(message.chatId)) {
        _chatRooms[message.chatId] = _chatRooms[message.chatId]!.copyWith(
          lastMessage: message,
          updatedAt: message.timestamp,
        );
      }

      // Notify listeners
      notifyListeners();
      _messageStreams[message.chatId]?.add(message);

      // Send via WebSocket
      _webSocketService.sendMessage(
        type: WebSocketMessageType.chatMessage,
        data: {
          'conversation_id': message.chatId,
          'content': message.content,
          'metadata': {},
        },
        channel: 'chat_${message.chatId}',
      );

      // Update message status to sent
      final updatedMessage = message.copyWith(status: MessageStatus.sent);
      _updateMessageStatus(message.id, MessageStatus.sent);

      // Cache the message
      await _cacheMessages(message.chatId);

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      _updateMessageStatus(message.id, MessageStatus.failed);
      return false;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final messages = _chatMessages[chatId] ?? [];
      bool hasUpdates = false;

      for (final message in messages) {
        if (!message.isFromCurrentUser && message.status != MessageStatus.read) {
          final updatedMessage = message.copyWith(status: MessageStatus.read);
          final index = messages.indexOf(message);
          messages[index] = updatedMessage;
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        // Update chat room unread count
        if (_chatRooms.containsKey(chatId)) {
          _chatRooms[chatId] = _chatRooms[chatId]!.copyWith(unreadCount: 0);
        }

        notifyListeners();
        await _cacheMessages(chatId);

        // Send read receipt via WebSocket
        _webSocketService.markMessagesRead(
          conversationId: chatId,
          messageIds: messages.map((m) => m.id).toList(),
        );
      }
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  /// Start typing indicator
  Future<void> startTyping(String chatId) async {
    try {
      _webSocketService.sendTypingIndicator(
        conversationId: chatId,
        isTyping: true,
      );
    } catch (e) {
      debugPrint('Error starting typing: $e');
    }
  }

  /// Stop typing indicator
  Future<void> stopTyping(String chatId) async {
    try {
      _webSocketService.sendTypingIndicator(
        conversationId: chatId,
        isTyping: false,
      );
    } catch (e) {
      debugPrint('Error stopping typing: $e');
    }
  }

  /// Delete a message
  Future<bool> deleteMessage(String messageId, String chatId) async {
    try {
      final messages = _chatMessages[chatId] ?? [];
      messages.removeWhere((m) => m.id == messageId);
      
      notifyListeners();
      await _cacheMessages(chatId);

      // Send delete request via WebSocket
      _webSocketService.sendMessage(
        type: WebSocketMessageType.chatMessage,
        data: {
          'action': 'delete_message',
          'message_id': messageId,
          'chat_id': chatId,
        },
        channel: 'chat_$chatId',
      );

      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  /// Load messages for a chat room
  Future<void> loadMessages(String chatId, {int limit = 50, int offset = 0}) async {
    try {
      // In a real app, this would make an API call
      // For now, load from cache or create mock data
      if (!_chatMessages.containsKey(chatId)) {
        _chatMessages[chatId] = Message.mockMessages(chatId);
        await _cacheMessages(chatId);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      _setError('Failed to load messages');
    }
  }

  /// Search messages
  Future<List<Message>> searchMessages(String query, {String? chatId}) async {
    try {
      final allMessages = chatId != null 
          ? _chatMessages[chatId] ?? []
          : _chatMessages.values.expand((messages) => messages).toList();

      return allMessages.where((message) =>
        message.content.toLowerCase().contains(query.toLowerCase())
      ).toList();
    } catch (e) {
      debugPrint('Error searching messages: $e');
      return [];
    }
  }

  /// Get total unread count across all chats
  int getTotalUnreadCount() {
    return _chatRooms.values.fold(0, (sum, chat) => sum + chat.unreadCount);
  }

  /// Archive a chat
  Future<void> archiveChat(String chatId) async {
    try {
      if (_chatRooms.containsKey(chatId)) {
        _chatRooms[chatId] = _chatRooms[chatId]!.copyWith(
          metadata: {
            ...?_chatRooms[chatId]!.metadata,
            'archived': true,
          },
        );
        notifyListeners();
        await _cacheChatRooms();
      }
    } catch (e) {
      debugPrint('Error archiving chat: $e');
    }
  }

  /// Delete a chat
  Future<void> deleteChat(String chatId) async {
    try {
      _chatRooms.remove(chatId);
      _chatMessages.remove(chatId);
      _messageStreams[chatId]?.close();
      _messageStreams.remove(chatId);
      
      notifyListeners();
      await _cacheChatRooms();
      await _prefs?.remove('messages_$chatId');
    } catch (e) {
      debugPrint('Error deleting chat: $e');
    }
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(WebSocketMessage wsMessage) {
    try {
      if (wsMessage.type != WebSocketMessageType.chat) return;

      final data = wsMessage.data;
      final action = data['action'];

      switch (action) {
        case 'new_message':
          _handleNewMessage(Message.fromJson(data['message']));
          break;
        case 'message_status_update':
          _handleMessageStatusUpdate(data['message_id'], data['status']);
          break;
        case 'typing_start':
          _handleTypingStart(data['chat_id'], data['user_id']);
          break;
        case 'typing_stop':
          _handleTypingStop(data['chat_id'], data['user_id']);
          break;
        case 'chat_created':
          _handleChatCreated(ChatRoom.fromJson(data['chat']));
          break;
        case 'user_online':
          _handleUserOnlineStatus(data['user_id'], true);
          break;
        case 'user_offline':
          _handleUserOnlineStatus(data['user_id'], false);
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  /// Handle new incoming message
  void _handleNewMessage(Message message) {
    if (!_chatMessages.containsKey(message.chatId)) {
      _chatMessages[message.chatId] = [];
    }
    
    _chatMessages[message.chatId]!.add(message);

    // Update chat room
    if (_chatRooms.containsKey(message.chatId)) {
      final currentUnread = _chatRooms[message.chatId]!.unreadCount;
      _chatRooms[message.chatId] = _chatRooms[message.chatId]!.copyWith(
        lastMessage: message,
        updatedAt: message.timestamp,
        unreadCount: message.isFromCurrentUser ? currentUnread : currentUnread + 1,
      );
    }

    notifyListeners();
    _messageStreams[message.chatId]?.add(message);
    _cacheMessages(message.chatId);
  }

  /// Handle message status update
  void _handleMessageStatusUpdate(String messageId, String status) {
    for (final chatId in _chatMessages.keys) {
      final messages = _chatMessages[chatId]!;
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      
      if (messageIndex != -1) {
        final messageStatus = MessageStatus.values.firstWhere((s) => s.name == status);
        messages[messageIndex] = messages[messageIndex].copyWith(status: messageStatus);
        notifyListeners();
        _cacheMessages(chatId);
        break;
      }
    }
  }

  /// Handle typing start
  void _handleTypingStart(String chatId, String userId) {
    if (_chatRooms.containsKey(chatId)) {
      final participants = _chatRooms[chatId]!.participants;
      final participantIndex = participants.indexWhere((p) => p.id == userId);
      
      if (participantIndex != -1) {
        participants[participantIndex] = participants[participantIndex].copyWith(isTyping: true);
        notifyListeners();

        // Auto-stop typing after timeout
        _typingTimers[userId]?.cancel();
        _typingTimers[userId] = Timer(const Duration(seconds: 5), () {
          _handleTypingStop(chatId, userId);
        });
      }
    }
  }

  /// Handle typing stop
  void _handleTypingStop(String chatId, String userId) {
    if (_chatRooms.containsKey(chatId)) {
      final participants = _chatRooms[chatId]!.participants;
      final participantIndex = participants.indexWhere((p) => p.id == userId);
      
      if (participantIndex != -1) {
        participants[participantIndex] = participants[participantIndex].copyWith(isTyping: false);
        notifyListeners();
      }
    }
    
    _typingTimers[userId]?.cancel();
    _typingTimers.remove(userId);
  }

  /// Handle new chat creation
  void _handleChatCreated(ChatRoom chatRoom) {
    _chatRooms[chatRoom.id] = chatRoom;
    notifyListeners();
    _cacheChatRooms();
  }

  /// Handle user online status
  void _handleUserOnlineStatus(String userId, bool isOnline) {
    for (final chatRoom in _chatRooms.values) {
      final participantIndex = chatRoom.participants.indexWhere((p) => p.id == userId);
      if (participantIndex != -1) {
        chatRoom.participants[participantIndex] = chatRoom.participants[participantIndex].copyWith(
          isOnline: isOnline,
          lastSeen: isOnline ? null : DateTime.now(),
        );
      }
    }
    notifyListeners();
  }

  /// Update message status
  void _updateMessageStatus(String messageId, MessageStatus status) {
    for (final chatId in _chatMessages.keys) {
      final messages = _chatMessages[chatId]!;
      final messageIndex = messages.indexWhere((m) => m.id == messageId);
      
      if (messageIndex != -1) {
        messages[messageIndex] = messages[messageIndex].copyWith(status: status);
        notifyListeners();
        _cacheMessages(chatId);
        break;
      }
    }
  }

  /// Create a new product chat
  Future<ChatRoom> _createProductChat(String productId, String sellerId) async {
    final chatId = 'chat_${DateTime.now().millisecondsSinceEpoch}';
    
    final chatRoom = ChatRoom(
      id: chatId,
      title: 'Product Inquiry',
      participants: [
        const ChatParticipant(
          id: 'current_user',
          name: 'You',
        ),
        ChatParticipant(
          id: sellerId,
          name: 'Seller', // In real app, fetch seller name
          role: 'seller',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      productId: productId,
      type: ChatRoomType.product,
    );

    _chatRooms[chatId] = chatRoom;
    
    // Add welcome message
    final welcomeMessage = Message.system(
      content: 'Chat started for product inquiry',
      chatId: chatId,
    );
    
    _chatMessages[chatId] = [welcomeMessage];
    
    notifyListeners();
    await _cacheChatRooms();
    await _cacheMessages(chatId);

    return chatRoom;
  }

  /// Load chat rooms
  Future<void> _loadChatRooms() async {
    try {
      // In a real app, this would fetch from API
      // For now, load mock data or cached data
      if (_chatRooms.isEmpty) {
        final mockRooms = ChatRoom.mockChatRooms();
        for (final room in mockRooms) {
          _chatRooms[room.id] = room;
          
          // Load messages for each room
          if (!_chatMessages.containsKey(room.id)) {
            _chatMessages[room.id] = Message.mockMessages(room.id);
          }
        }
        await _cacheChatRooms();
      }
    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
    }
  }

  /// Load cached data
  Future<void> _loadCachedData() async {
    try {
      // Load cached chat rooms
      final chatRoomsJson = _prefs?.getString('chat_rooms');
      if (chatRoomsJson != null) {
        final List<dynamic> roomsList = jsonDecode(chatRoomsJson);
        for (final roomData in roomsList) {
          final room = ChatRoom.fromJson(roomData);
          _chatRooms[room.id] = room;
        }
      }

      // Load cached messages for each chat room
      for (final chatId in _chatRooms.keys) {
        final messagesJson = _prefs?.getString('messages_$chatId');
        if (messagesJson != null) {
          final List<dynamic> messagesList = jsonDecode(messagesJson);
          _chatMessages[chatId] = messagesList
              .map((msgData) => Message.fromJson(msgData))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  /// Cache chat rooms
  Future<void> _cacheChatRooms() async {
    try {
      final roomsList = _chatRooms.values.map((room) => room.toJson()).toList();
      await _prefs?.setString('chat_rooms', jsonEncode(roomsList));
    } catch (e) {
      debugPrint('Error caching chat rooms: $e');
    }
  }

  /// Cache messages for a specific chat
  Future<void> _cacheMessages(String chatId) async {
    try {
      final messages = _chatMessages[chatId] ?? [];
      final messagesList = messages.map((msg) => msg.toJson()).toList();
      await _prefs?.setString('messages_$chatId', jsonEncode(messagesList));
    } catch (e) {
      debugPrint('Error caching messages for chat $chatId: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Dispose resources
  @override
  void dispose() {
    for (final controller in _messageStreams.values) {
      controller.close();
    }
    for (final timer in _typingTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}