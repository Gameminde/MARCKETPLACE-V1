import 'package:flutter/material.dart';

/// Support ticket priority levels
enum TicketPriority {
  low('Low', Colors.green),
  normal('Normal', Colors.blue),
  high('High', Colors.orange),
  urgent('Urgent', Colors.red);

  const TicketPriority(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// Support ticket status
enum TicketStatus {
  open('Open', Colors.blue),
  inProgress('In Progress', Colors.orange),
  waitingForResponse('Waiting for Response', Colors.amber),
  resolved('Resolved', Colors.green),
  closed('Closed', Colors.grey);

  const TicketStatus(this.displayName, this.color);
  final String displayName;
  final Color color;
}

/// Support ticket categories
enum TicketCategory {
  order('Order Issues', Icons.shopping_bag),
  payment('Payment Issues', Icons.payment),
  shipping('Shipping Issues', Icons.local_shipping),
  product('Product Issues', Icons.inventory_2),
  technical('Technical Issues', Icons.bug_report),
  account('Account Issues', Icons.person),
  refund('Refund Request', Icons.money_off),
  general('General Inquiry', Icons.help);

  const TicketCategory(this.displayName, this.icon);
  final String displayName;
  final IconData icon;
}

/// Support ticket model
class SupportTicket {
  final String id;
  final String userId;
  final String title;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? assignedAgentId;
  final String? assignedAgentName;
  final List<String> attachmentUrls;
  final Map<String, dynamic>? metadata;
  final List<TicketMessage> messages;

  const SupportTicket({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    this.priority = TicketPriority.normal,
    this.status = TicketStatus.open,
    required this.createdAt,
    required this.updatedAt,
    this.assignedAgentId,
    this.assignedAgentName,
    this.attachmentUrls = const [],
    this.metadata,
    this.messages = const [],
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      description: json['description'],
      category: TicketCategory.values.firstWhere((e) => e.name == json['category']),
      priority: TicketPriority.values.firstWhere((e) => e.name == json['priority']),
      status: TicketStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      assignedAgentId: json['assigned_agent_id'],
      assignedAgentName: json['assigned_agent_name'],
      attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
      metadata: json['metadata'],
      messages: (json['messages'] as List? ?? [])
          .map((m) => TicketMessage.fromJson(m))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category.name,
      'priority': priority.name,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'assigned_agent_id': assignedAgentId,
      'assigned_agent_name': assignedAgentName,
      'attachment_urls': attachmentUrls,
      'metadata': metadata,
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  SupportTicket copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    TicketCategory? category,
    TicketPriority? priority,
    TicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? assignedAgentId,
    String? assignedAgentName,
    List<String>? attachmentUrls,
    Map<String, dynamic>? metadata,
    List<TicketMessage>? messages,
  }) {
    return SupportTicket(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedAgentId: assignedAgentId ?? this.assignedAgentId,
      assignedAgentName: assignedAgentName ?? this.assignedAgentName,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      metadata: metadata ?? this.metadata,
      messages: messages ?? this.messages,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool get isOpen => status == TicketStatus.open || status == TicketStatus.inProgress;
  bool get needsResponse => status == TicketStatus.waitingForResponse;
  bool get isResolved => status == TicketStatus.resolved || status == TicketStatus.closed;

  /// Create mock support tickets
  static List<SupportTicket> mockTickets() {
    final now = DateTime.now();
    
    return [
      SupportTicket(
        id: 'ticket_1',
        userId: 'current_user',
        title: 'Order not delivered',
        description: 'My order #12345 was supposed to be delivered 3 days ago but I haven\'t received it yet.',
        category: TicketCategory.shipping,
        priority: TicketPriority.high,
        status: TicketStatus.inProgress,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 4)),
        assignedAgentId: 'agent_1',
        assignedAgentName: 'Sarah Johnson',
        metadata: {'order_id': '12345'},
        messages: [
          TicketMessage(
            id: 'msg_1',
            ticketId: 'ticket_1',
            senderId: 'current_user',
            senderName: 'You',
            content: 'My order #12345 was supposed to be delivered 3 days ago but I haven\'t received it yet.',
            isFromAgent: false,
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          TicketMessage(
            id: 'msg_2',
            ticketId: 'ticket_1',
            senderId: 'agent_1',
            senderName: 'Sarah Johnson',
            content: 'I apologize for the delay. Let me check the tracking information and contact the courier service for you.',
            isFromAgent: true,
            timestamp: now.subtract(const Duration(days: 1, hours: 8)),
          ),
          TicketMessage(
            id: 'msg_3',
            ticketId: 'ticket_1',
            senderId: 'agent_1',
            senderName: 'Sarah Johnson',
            content: 'Good news! I\'ve located your package. It will be delivered tomorrow by 5 PM. I\'ve also arranged for express delivery at no extra cost.',
            isFromAgent: true,
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
        ],
      ),
      SupportTicket(
        id: 'ticket_2',
        userId: 'current_user',
        title: 'Refund request for damaged item',
        description: 'The smartphone I received has a cracked screen. I would like to return it for a full refund.',
        category: TicketCategory.refund,
        priority: TicketPriority.normal,
        status: TicketStatus.resolved,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 1)),
        assignedAgentId: 'agent_2',
        assignedAgentName: 'Mike Chen',
        metadata: {'product_id': 'phone_123', 'order_id': '67890'},
        messages: [
          TicketMessage(
            id: 'msg_4',
            ticketId: 'ticket_2',
            senderId: 'current_user',
            senderName: 'You',
            content: 'The smartphone I received has a cracked screen. I would like to return it for a full refund.',
            isFromAgent: false,
            timestamp: now.subtract(const Duration(days: 5)),
            attachmentUrls: ['https://example.com/damaged_phone.jpg'],
          ),
          TicketMessage(
            id: 'msg_5',
            ticketId: 'ticket_2',
            senderId: 'agent_2',
            senderName: 'Mike Chen',
            content: 'I\'m sorry about the damaged item. I\'ve processed your refund and you should see the amount in your account within 3-5 business days.',
            isFromAgent: true,
            timestamp: now.subtract(const Duration(days: 1)),
          ),
        ],
      ),
      SupportTicket(
        id: 'ticket_3',
        userId: 'current_user',
        title: 'Account login issues',
        description: 'I can\'t log into my account. The app keeps saying "invalid credentials" even though I\'m sure my password is correct.',
        category: TicketCategory.technical,
        priority: TicketPriority.normal,
        status: TicketStatus.waitingForResponse,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        assignedAgentId: 'agent_3',
        assignedAgentName: 'Lisa Wang',
        messages: [
          TicketMessage(
            id: 'msg_6',
            ticketId: 'ticket_3',
            senderId: 'current_user',
            senderName: 'You',
            content: 'I can\'t log into my account. The app keeps saying "invalid credentials" even though I\'m sure my password is correct.',
            isFromAgent: false,
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
          TicketMessage(
            id: 'msg_7',
            ticketId: 'ticket_3',
            senderId: 'agent_3',
            senderName: 'Lisa Wang',
            content: 'Let me help you with that. Can you try resetting your password using the "Forgot Password" link? Also, please let me know which device and browser you\'re using.',
            isFromAgent: true,
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
        ],
      ),
    ];
  }
}

/// Support ticket message model
class TicketMessage {
  final String id;
  final String ticketId;
  final String senderId;
  final String senderName;
  final String content;
  final bool isFromAgent;
  final DateTime timestamp;
  final List<String> attachmentUrls;
  final bool isInternal;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.isFromAgent,
    required this.timestamp,
    this.attachmentUrls = const [],
    this.isInternal = false,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'],
      ticketId: json['ticket_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      content: json['content'],
      isFromAgent: json['is_from_agent'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
      attachmentUrls: List<String>.from(json['attachment_urls'] ?? []),
      isInternal: json['is_internal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'sender_id': senderId,
      'sender_name': senderName,
      'content': content,
      'is_from_agent': isFromAgent,
      'timestamp': timestamp.toIso8601String(),
      'attachment_urls': attachmentUrls,
      'is_internal': isInternal,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Support agent model
class SupportAgent {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final bool isOnline;
  final String department;
  final List<TicketCategory> specialties;
  final double rating;
  final int ticketsResolved;

  const SupportAgent({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.isOnline = false,
    required this.department,
    this.specialties = const [],
    this.rating = 0.0,
    this.ticketsResolved = 0,
  });

  factory SupportAgent.fromJson(Map<String, dynamic> json) {
    return SupportAgent(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      isOnline: json['is_online'] ?? false,
      department: json['department'],
      specialties: (json['specialties'] as List? ?? [])
          .map((s) => TicketCategory.values.firstWhere((e) => e.name == s))
          .toList(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      ticketsResolved: json['tickets_resolved'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'department': department,
      'specialties': specialties.map((s) => s.name).toList(),
      'rating': rating,
      'tickets_resolved': ticketsResolved,
    };
  }
}

/// FAQ model
class FAQ {
  final String id;
  final String question;
  final String answer;
  final TicketCategory category;
  final List<String> tags;
  final int viewCount;
  final bool isHelpful;

  const FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
    this.viewCount = 0,
    this.isHelpful = false,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      category: TicketCategory.values.firstWhere((e) => e.name == json['category']),
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: json['view_count'] ?? 0,
      isHelpful: json['is_helpful'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category.name,
      'tags': tags,
      'view_count': viewCount,
      'is_helpful': isHelpful,
    };
  }

  /// Mock FAQ data
  static List<FAQ> mockFAQs() {
    return [
      const FAQ(
        id: 'faq_1',
        question: 'How do I track my order?',
        answer: 'You can track your order by going to "My Orders" in your profile and clicking on the order you want to track. You\'ll see real-time updates and tracking information.',
        category: TicketCategory.order,
        tags: ['tracking', 'order', 'delivery'],
        viewCount: 1250,
        isHelpful: true,
      ),
      const FAQ(
        id: 'faq_2',
        question: 'What payment methods do you accept?',
        answer: 'We accept major credit cards (Visa, MasterCard, American Express), PayPal, Apple Pay, Google Pay, and bank transfers. All payments are secured with SSL encryption.',
        category: TicketCategory.payment,
        tags: ['payment', 'credit card', 'paypal'],
        viewCount: 890,
        isHelpful: true,
      ),
      const FAQ(
        id: 'faq_3',
        question: 'How do I return an item?',
        answer: 'To return an item, go to "My Orders", select the order, and click "Return Item". You have 30 days from delivery to return most items. Some restrictions apply to certain categories.',
        category: TicketCategory.refund,
        tags: ['return', 'refund', 'policy'],
        viewCount: 670,
        isHelpful: true,
      ),
      const FAQ(
        id: 'faq_4',
        question: 'Why is my account locked?',
        answer: 'Accounts are typically locked for security reasons after multiple failed login attempts. You can unlock your account by clicking "Forgot Password" or contacting support.',
        category: TicketCategory.account,
        tags: ['account', 'locked', 'security'],
        viewCount: 420,
      ),
      const FAQ(
        id: 'faq_5',
        question: 'How long does shipping take?',
        answer: 'Standard shipping takes 3-5 business days, while express shipping takes 1-2 business days. Free shipping is available on orders over \$50.',
        category: TicketCategory.shipping,
        tags: ['shipping', 'delivery', 'time'],
        viewCount: 980,
        isHelpful: true,
      ),
    ];
  }
}