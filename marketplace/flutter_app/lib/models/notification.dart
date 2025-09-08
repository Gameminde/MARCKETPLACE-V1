import 'package:flutter/material.dart';

/// Notification type enumeration
enum NotificationType {
  order('Order Update', Icons.shopping_bag, Color(0xFF4CAF50)),
  message('New Message', Icons.message, Color(0xFF2196F3)),
  promotion('Promotion', Icons.local_offer, Color(0xFFFF9800)),
  system('System', Icons.info, Color(0xFF607D8B)),
  payment('Payment', Icons.payment, Color(0xFF9C27B0)),
  shipping('Shipping', Icons.local_shipping, Color(0xFF3F51B5)),
  review('Review Request', Icons.star, Color(0xFFFFC107)),
  wishlist('Wishlist', Icons.favorite, Color(0xFFE91E63)),
  security('Security', Icons.security, Color(0xFFF44336)),
  social('Social', Icons.group, Color(0xFF795548));

  const NotificationType(this.displayName, this.icon, this.color);
  final String displayName;
  final IconData icon;
  final Color color;
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent
}

/// Notification model
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final String? actionUrl;
  final String? actionLabel;
  final DateTime? expiresAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.priority = NotificationPriority.normal,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.data,
    this.actionUrl,
    this.actionLabel,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      type: NotificationType.values.firstWhere((e) => e.name == json['type']),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      imageUrl: json['image_url'],
      data: json['data'],
      actionUrl: json['action_url'],
      actionLabel: json['action_label'],
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'priority': priority.name,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'image_url': imageUrl,
      'data': data,
      'action_url': actionUrl,
      'action_label': actionLabel,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? actionLabel,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      actionLabel: actionLabel ?? this.actionLabel,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get hasAction => actionUrl != null && actionLabel != null;

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

  /// Create mock notifications for testing
  static List<NotificationModel> mockNotifications() {
    final now = DateTime.now();
    
    return [
      NotificationModel(
        id: 'notif_1',
        title: 'Order Shipped',
        body: 'Your order #12345 has been shipped and is on its way!',
        type: NotificationType.shipping,
        priority: NotificationPriority.high,
        timestamp: now.subtract(const Duration(minutes: 5)),
        actionUrl: '/orders/12345',
        actionLabel: 'Track Order',
        data: {'order_id': '12345'},
      ),
      NotificationModel(
        id: 'notif_2',
        title: 'New Message',
        body: 'TechStore sent you a message about your inquiry',
        type: NotificationType.message,
        timestamp: now.subtract(const Duration(hours: 1)),
        actionUrl: '/chat/seller_123',
        actionLabel: 'View Message',
        data: {'chat_id': 'chat_1'},
      ),
      NotificationModel(
        id: 'notif_3',
        title: 'Flash Sale Alert!',
        body: 'Get 50% off on electronics. Limited time offer!',
        type: NotificationType.promotion,
        priority: NotificationPriority.normal,
        timestamp: now.subtract(const Duration(hours: 2)),
        imageUrl: 'https://example.com/sale_banner.jpg',
        actionUrl: '/promotions/flash-sale',
        actionLabel: 'Shop Now',
        expiresAt: now.add(const Duration(hours: 22)),
      ),
      NotificationModel(
        id: 'notif_4',
        title: 'Payment Successful',
        body: 'Your payment of \$99.99 has been processed successfully',
        type: NotificationType.payment,
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
        data: {'amount': 99.99, 'transaction_id': 'tx_789'},
      ),
      NotificationModel(
        id: 'notif_5',
        title: 'Review Request',
        body: 'How was your recent purchase? Share your experience!',
        type: NotificationType.review,
        timestamp: now.subtract(const Duration(days: 1)),
        actionUrl: '/reviews/new',
        actionLabel: 'Write Review',
        data: {'product_id': 'prod_123'},
      ),
      NotificationModel(
        id: 'notif_6',
        title: 'Wishlist Item on Sale',
        body: 'Wireless Headphones from your wishlist is now 30% off!',
        type: NotificationType.wishlist,
        timestamp: now.subtract(const Duration(days: 2)),
        imageUrl: 'https://example.com/headphones.jpg',
        actionUrl: '/products/headphones_456',
        actionLabel: 'View Deal',
        data: {'product_id': 'headphones_456', 'discount': 30},
      ),
      NotificationModel(
        id: 'notif_7',
        title: 'Security Alert',
        body: 'New login detected from unknown device. Was this you?',
        type: NotificationType.security,
        priority: NotificationPriority.urgent,
        timestamp: now.subtract(const Duration(days: 3)),
        isRead: true,
        actionUrl: '/security/sessions',
        actionLabel: 'Review Activity',
      ),
      NotificationModel(
        id: 'notif_8',
        title: 'System Maintenance',
        body: 'Scheduled maintenance will occur tonight from 2-4 AM',
        type: NotificationType.system,
        timestamp: now.subtract(const Duration(days: 5)),
        isRead: true,
      ),
    ];
  }
}

/// Notification settings model
class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final Map<NotificationType, bool> typeSettings;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final NotificationPriority minimumPriority;

  const NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.smsEnabled = false,
    required this.typeSettings,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.minimumPriority = NotificationPriority.normal,
  });

  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      typeSettings: {
        for (NotificationType type in NotificationType.values) type: true,
      },
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final typeSettingsJson = json['type_settings'] as Map<String, dynamic>? ?? {};
    final typeSettings = <NotificationType, bool>{};
    
    for (NotificationType type in NotificationType.values) {
      typeSettings[type] = typeSettingsJson[type.name] ?? true;
    }

    return NotificationSettings(
      pushEnabled: json['push_enabled'] ?? true,
      emailEnabled: json['email_enabled'] ?? true,
      smsEnabled: json['sms_enabled'] ?? false,
      typeSettings: typeSettings,
      soundEnabled: json['sound_enabled'] ?? true,
      vibrationEnabled: json['vibration_enabled'] ?? true,
      quietHoursStart: json['quiet_hours_start'],
      quietHoursEnd: json['quiet_hours_end'],
      minimumPriority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['minimum_priority'],
        orElse: () => NotificationPriority.normal,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'type_settings': {
        for (NotificationType type in NotificationType.values)
          type.name: typeSettings[type] ?? true,
      },
      'sound_enabled': soundEnabled,
      'vibration_enabled': vibrationEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'minimum_priority': minimumPriority.name,
    };
  }

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    Map<NotificationType, bool>? typeSettings,
    bool? soundEnabled,
    bool? vibrationEnabled,
    String? quietHoursStart,
    String? quietHoursEnd,
    NotificationPriority? minimumPriority,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      typeSettings: typeSettings ?? this.typeSettings,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      minimumPriority: minimumPriority ?? this.minimumPriority,
    );
  }

  bool isTypeEnabled(NotificationType type) {
    return typeSettings[type] ?? true;
  }

  bool isInQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) return false;
    
    final now = TimeOfDay.now();
    final start = _parseTime(quietHoursStart!);
    final end = _parseTime(quietHoursEnd!);
    
    if (start.hour < end.hour || (start.hour == end.hour && start.minute < end.minute)) {
      // Same day range
      return _isTimeBetween(now, start, end);
    } else {
      // Overnight range
      return _isTimeBetween(now, start, const TimeOfDay(hour: 23, minute: 59)) ||
             _isTimeBetween(now, const TimeOfDay(hour: 0, minute: 0), end);
    }
  }

  TimeOfDay _parseTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isTimeBetween(TimeOfDay time, TimeOfDay start, TimeOfDay end) {
    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    return timeMinutes >= startMinutes && timeMinutes <= endMinutes;
  }
}