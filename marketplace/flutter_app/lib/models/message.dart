import 'package:flutter/material.dart';

/// Message type enumeration
enum MessageType {
  text,
  image,
  file,
  product,
  order,
  location,
  system,
  typing
}

/// Message status enumeration
enum MessageStatus {
  sending,
  sent,
  delivered,
  read,
  failed
}

/// Message model for chat communication
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String? receiverId;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final MessageStatus status;
  final String? replyToId;
  final Map<String, dynamic>? metadata;
  final List<String> attachments;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.receiverId,
    required this.type,
    required this.content,
    required this.timestamp,
    this.status = MessageStatus.sending,
    this.replyToId,
    this.metadata,
    this.attachments = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      chatId: json['chat_id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      type: MessageType.values.firstWhere((e) => e.name == json['type']),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      status: MessageStatus.values.firstWhere((e) => e.name == json['status']),
      replyToId: json['reply_to_id'],
      metadata: json['metadata'],
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'type': type.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'reply_to_id': replyToId,
      'metadata': metadata,
      'attachments': attachments,
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? receiverId,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    MessageStatus? status,
    String? replyToId,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      replyToId: replyToId ?? this.replyToId,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
    );
  }

  bool get isFromCurrentUser => senderId == 'current_user'; // In real app, check against auth
  bool get isSystem => type == MessageType.system;
  bool get hasAttachments => attachments.isNotEmpty;
  bool get isReply => replyToId != null;

  IconData get typeIcon {
    switch (type) {
      case MessageType.text:
        return Icons.message;
      case MessageType.image:
        return Icons.image;
      case MessageType.file:
        return Icons.attach_file;
      case MessageType.product:
        return Icons.shopping_cart;
      case MessageType.order:
        return Icons.receipt;
      case MessageType.location:
        return Icons.location_on;
      case MessageType.system:
        return Icons.info;
      case MessageType.typing:
        return Icons.more_horiz;
    }
  }

  Color getStatusColor(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Colors.grey;
      case MessageStatus.sent:
        return Colors.grey;
      case MessageStatus.delivered:
        return Colors.blue;
      case MessageStatus.read:
        return Colors.green;
      case MessageStatus.failed:
        return Colors.red;
    }
  }

  /// Create a text message
  static Message text({
    required String content,
    required String chatId,
    required String senderId,
    String? receiverId,
    String? replyToId,
  }) {
    return Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
      replyToId: replyToId,
    );
  }

  /// Create an image message
  static Message image({
    required String imageUrl,
    required String chatId,
    required String senderId,
    String? receiverId,
    String? caption,
  }) {
    return Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.image,
      content: caption ?? '',
      timestamp: DateTime.now(),
      attachments: [imageUrl],
    );
  }

  /// Create a product message
  static Message product({
    required String productId,
    required String productName,
    required String chatId,
    required String senderId,
    String? receiverId,
    Map<String, dynamic>? productData,
  }) {
    return Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      type: MessageType.product,
      content: productName,
      timestamp: DateTime.now(),
      metadata: {
        'product_id': productId,
        ...?productData,
      },
    );
  }

  /// Create a system message
  static Message system({
    required String content,
    required String chatId,
  }) {
    return Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: chatId,
      senderId: 'system',
      type: MessageType.system,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.delivered,
    );
  }

  /// Create mock messages for testing
  static List<Message> mockMessages(String chatId) {
    return [
      Message.system(
        content: 'Chat started',
        chatId: chatId,
      ),
      Message.text(
        content: 'Hi! I\'m interested in your product. Is it still available?',
        chatId: chatId,
        senderId: 'current_user',
        receiverId: 'seller_123',
      ),
      Message.text(
        content: 'Hello! Yes, it\'s still available. Would you like to know more details?',
        chatId: chatId,
        senderId: 'seller_123',
        receiverId: 'current_user',
      ).copyWith(
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: MessageStatus.read,
      ),
      Message.product(
        productId: 'prod_123',
        productName: 'Wireless Bluetooth Headphones',
        chatId: chatId,
        senderId: 'seller_123',
        receiverId: 'current_user',
        productData: {
          'price': 99.99,
          'image_url': 'https://example.com/headphones.jpg',
          'in_stock': true,
        },
      ).copyWith(
        timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
        status: MessageStatus.read,
      ),
      Message.text(
        content: 'That looks perfect! What\'s the condition and do you offer warranty?',
        chatId: chatId,
        senderId: 'current_user',
        receiverId: 'seller_123',
      ).copyWith(
        timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
        status: MessageStatus.delivered,
      ),
      Message.text(
        content: 'It\'s brand new, unopened. Comes with 1-year manufacturer warranty. Free shipping if you order today!',
        chatId: chatId,
        senderId: 'seller_123',
        receiverId: 'current_user',
      ).copyWith(
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: MessageStatus.read,
      ),
      Message.image(
        imageUrl: 'https://example.com/product_package.jpg',
        chatId: chatId,
        senderId: 'seller_123',
        receiverId: 'current_user',
        caption: 'Here\'s the actual package',
      ).copyWith(
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        status: MessageStatus.read,
      ),
      Message.text(
        content: 'Great! How can I place the order?',
        chatId: chatId,
        senderId: 'current_user',
        receiverId: 'seller_123',
      ).copyWith(
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MessageStatus.sent,
      ),
    ];
  }
}

/// Chat participant model
class ChatParticipant {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? role; // 'buyer', 'seller', 'admin'
  final bool isOnline;
  final DateTime? lastSeen;
  final bool isTyping;

  const ChatParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.role,
    this.isOnline = false,
    this.lastSeen,
    this.isTyping = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id'],
      name: json['name'],
      avatarUrl: json['avatar_url'],
      role: json['role'],
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : null,
      isTyping: json['is_typing'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'role': role,
      'is_online': isOnline,
      'last_seen': lastSeen?.toIso8601String(),
      'is_typing': isTyping,
    };
  }

  ChatParticipant copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? role,
    bool? isOnline,
    DateTime? lastSeen,
    bool? isTyping,
  }) {
    return ChatParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  String get statusText {
    if (isTyping) return 'typing...';
    if (isOnline) return 'online';
    if (lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(lastSeen!);
      
      if (difference.inMinutes < 1) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    }
    return 'offline';
  }
}

/// Chat room model
class ChatRoom {
  final String id;
  final String title;
  final String? description;
  final List<ChatParticipant> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? productId;
  final String? orderId;
  final ChatRoomType type;
  final Map<String, dynamic>? metadata;

  const ChatRoom({
    required this.id,
    required this.title,
    this.description,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.productId,
    this.orderId,
    this.type = ChatRoomType.direct,
    this.metadata,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      participants: (json['participants'] as List? ?? [])
          .map((p) => ChatParticipant.fromJson(p))
          .toList(),
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message'])
          : null,
      unreadCount: json['unread_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      productId: json['product_id'],
      orderId: json['order_id'],
      type: ChatRoomType.values.firstWhere((e) => e.name == json['type']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'participants': participants.map((p) => p.toJson()).toList(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'product_id': productId,
      'order_id': orderId,
      'type': type.name,
      'metadata': metadata,
    };
  }

  ChatRoom copyWith({
    String? id,
    String? title,
    String? description,
    List<ChatParticipant>? participants,
    Message? lastMessage,
    int? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? productId,
    String? orderId,
    ChatRoomType? type,
    Map<String, dynamic>? metadata,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productId: productId ?? this.productId,
      orderId: orderId ?? this.orderId,
      type: type ?? this.type,
      metadata: metadata ?? this.metadata,
    );
  }

  ChatParticipant? get otherParticipant {
    return participants.firstWhere(
      (p) => p.id != 'current_user',
      orElse: () => participants.first,
    );
  }

  bool get hasUnreadMessages => unreadCount > 0;
  bool get isProductChat => productId != null;
  bool get isOrderChat => orderId != null;

  /// Create mock chat rooms for testing
  static List<ChatRoom> mockChatRooms() {
    final now = DateTime.now();
    
    return [
      ChatRoom(
        id: 'chat_1',
        title: 'Chat with TechStore',
        participants: [
          const ChatParticipant(
            id: 'current_user',
            name: 'You',
          ),
          const ChatParticipant(
            id: 'seller_123',
            name: 'TechStore',
            avatarUrl: 'https://example.com/techstore_avatar.jpg',
            role: 'seller',
            isOnline: true,
          ),
        ],
        lastMessage: Message.text(
          content: 'Great! How can I place the order?',
          chatId: 'chat_1',
          senderId: 'current_user',
          receiverId: 'seller_123',
        ).copyWith(timestamp: now.subtract(const Duration(minutes: 5))),
        unreadCount: 0,
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(minutes: 5)),
        productId: 'prod_123',
        type: ChatRoomType.product,
      ),
      ChatRoom(
        id: 'chat_2',
        title: 'Chat with FashionHub',
        participants: [
          const ChatParticipant(
            id: 'current_user',
            name: 'You',
          ),
          const ChatParticipant(
            id: 'seller_456',
            name: 'FashionHub',
            avatarUrl: 'https://example.com/fashion_avatar.jpg',
            role: 'seller',
            isOnline: false,
            lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
        lastMessage: Message.text(
          content: 'Thank you for your purchase! Your order is being processed.',
          chatId: 'chat_2',
          senderId: 'seller_456',
          receiverId: 'current_user',
        ).copyWith(timestamp: now.subtract(const Duration(hours: 3))),
        unreadCount: 2,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        orderId: 'order_789',
        type: ChatRoomType.order,
      ),
      ChatRoom(
        id: 'chat_3',
        title: 'Support Chat',
        participants: [
          const ChatParticipant(
            id: 'current_user',
            name: 'You',
          ),
          const ChatParticipant(
            id: 'support_1',
            name: 'Customer Support',
            avatarUrl: 'https://example.com/support_avatar.jpg',
            role: 'admin',
            isOnline: true,
          ),
        ],
        lastMessage: Message.text(
          content: 'Is there anything else I can help you with?',
          chatId: 'chat_3',
          senderId: 'support_1',
          receiverId: 'current_user',
        ).copyWith(timestamp: now.subtract(const Duration(days: 2))),
        unreadCount: 0,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 2)),
        type: ChatRoomType.support,
      ),
    ];
  }
}

/// Chat room type enumeration
enum ChatRoomType {
  direct,
  product,
  order,
  support,
  group
}