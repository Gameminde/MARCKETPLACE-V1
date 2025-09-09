import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification.dart';
import '../services/websocket_service.dart';

/// Notification service for managing push notifications and in-app notifications
class NotificationService extends ChangeNotifier {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._internal();
  
  NotificationService._internal();

  // Dependencies
  late WebSocketService _webSocketService;
  SharedPreferences? _prefs;

  // State
  final List<NotificationModel> _notifications = [];
  NotificationSettings _settings = NotificationSettings.defaultSettings();
  
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  NotificationSettings get settings => _settings;

  List<NotificationModel> get unreadNotifications => 
      _notifications.where((n) => !n.isRead && !n.isExpired).toList();

  int get unreadCount => unreadNotifications.length;

  List<NotificationModel> get recentNotifications => 
      _notifications.where((n) => !n.isExpired).take(10).toList();

  /// Initialize notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);
      
      _webSocketService = WebSocketService();
      _prefs = await SharedPreferences.getInstance();
      
      // Listen to WebSocket notifications
      _webSocketService.notificationStream.listen(_handleWebSocketNotification);
      
      // Load cached data
      await _loadCachedData();
      
      // Load initial notifications
      await _loadNotifications();
      
      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
      
    } catch (e) {
      debugPrint('Failed to initialize NotificationService: $e');
      _setError('Failed to initialize notification service');
    } finally {
      _setLoading(false);
    }
  }

  /// Add a new notification
  Future<void> addNotification(NotificationModel notification) async {
    try {
      // Check if notifications are enabled for this type
      if (!_settings.isTypeEnabled(notification.type)) {
        return;
      }

      // Check priority filtering
      if (notification.priority.index < _settings.minimumPriority.index) {
        return;
      }

      // Check quiet hours
      if (_settings.isInQuietHours() && notification.priority != NotificationPriority.urgent) {
        return;
      }

      // Add to list (insert at beginning for newest first)
      _notifications.insert(0, notification);
      
      // Limit total notifications
      if (_notifications.length > 100) {
        _notifications.removeRange(100, _notifications.length);
      }

      await _cacheNotifications();
      notifyListeners();

      // Show local notification if enabled
      if (_settings.pushEnabled) {
        await _showLocalNotification(notification);
      }

    } catch (e) {
      debugPrint('Error adding notification: $e');
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        await _cacheNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      await _cacheNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      _notifications.removeWhere((n) => n.id == notificationId);
      await _cacheNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      _notifications.clear();
      await _cacheNotifications();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
    }
  }

  /// Update notification settings
  Future<void> updateSettings(NotificationSettings newSettings) async {
    try {
      _settings = newSettings;
      await _cacheSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
    }
  }

  /// Get notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type && !n.isExpired).toList();
  }

  /// Get notifications by priority
  List<NotificationModel> getNotificationsByPriority(NotificationPriority priority) {
    return _notifications.where((n) => n.priority == priority && !n.isExpired).toList();
  }

  /// Search notifications
  List<NotificationModel> searchNotifications(String query) {
    final lowercaseQuery = query.toLowerCase();
    return _notifications.where((n) =>
      n.title.toLowerCase().contains(lowercaseQuery) ||
      n.body.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  /// Clean up expired notifications
  Future<void> cleanupExpired() async {
    try {
      final initialCount = _notifications.length;
      _notifications.removeWhere((n) => n.isExpired);
      
      if (_notifications.length != initialCount) {
        await _cacheNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error cleaning up expired notifications: $e');
    }
  }

  /// Request notification permission (mock implementation)
  Future<bool> requestPermission() async {
    try {
      // In a real app, this would request system notification permission
      await Future.delayed(const Duration(milliseconds: 500));
      return true;
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check if notification permission is granted (mock implementation)
  Future<bool> hasPermission() async {
    try {
      // In a real app, this would check system notification permission
      await Future.delayed(const Duration(milliseconds: 100));
      return true;
    } catch (e) {
      debugPrint('Error checking notification permission: $e');
      return false;
    }
  }

  // =============================================================================
  // PRIVATE HELPER METHODS
  // =============================================================================

  /// Handle incoming WebSocket notifications
  void _handleWebSocketNotification(WebSocketMessage wsMessage) {
    try {
      if (wsMessage.type != WebSocketMessageType.notification) return;

      final data = wsMessage.data;
      final notification = NotificationModel.fromJson(data['notification']);
      
      addNotification(notification);
    } catch (e) {
      debugPrint('Error handling WebSocket notification: $e');
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification(NotificationModel notification) async {
    try {
      // In a real app, this would use a plugin like flutter_local_notifications
      // For now, we'll just log it
      debugPrint('📱 Local Notification: ${notification.title} - ${notification.body}');
      
      // Mock notification sound/vibration
      if (_settings.soundEnabled) {
        debugPrint('🔊 Playing notification sound');
      }
      if (_settings.vibrationEnabled) {
        debugPrint('📳 Vibrating device');
      }
    } catch (e) {
      debugPrint('Error showing local notification: $e');
    }
  }

  /// Load notifications from cache or API
  Future<void> _loadNotifications() async {
    try {
      // In a real app, this would fetch from API
      // For now, load mock data if none cached
      if (_notifications.isEmpty) {
        final mockNotifications = NotificationModel.mockNotifications();
        _notifications.addAll(mockNotifications);
        await _cacheNotifications();
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  /// Load cached data
  Future<void> _loadCachedData() async {
    try {
      // Load cached notifications
      final notificationsJson = _prefs?.getString('notifications');
      if (notificationsJson != null) {
        final List<dynamic> notificationsList = jsonDecode(notificationsJson);
        _notifications.clear();
        _notifications.addAll(
          notificationsList.map((data) => NotificationModel.fromJson(data))
        );
      }

      // Load cached settings
      final settingsJson = _prefs?.getString('notification_settings');
      if (settingsJson != null) {
        _settings = NotificationSettings.fromJson(jsonDecode(settingsJson));
      }
    } catch (e) {
      debugPrint('Error loading cached notification data: $e');
    }
  }

  /// Cache notifications
  Future<void> _cacheNotifications() async {
    try {
      final notificationsList = _notifications.map((n) => n.toJson()).toList();
      await _prefs?.setString('notifications', jsonEncode(notificationsList));
    } catch (e) {
      debugPrint('Error caching notifications: $e');
    }
  }

  /// Cache settings
  Future<void> _cacheSettings() async {
    try {
      await _prefs?.setString('notification_settings', jsonEncode(_settings.toJson()));
    } catch (e) {
      debugPrint('Error caching notification settings: $e');
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

  // =============================================================================
  // NOTIFICATION FACTORY METHODS
  // =============================================================================

  /// Create order notification
  static NotificationModel createOrderNotification({
    required String orderId,
    required String status,
    String? trackingNumber,
  }) {
    String title;
    String body;
    NotificationPriority priority = NotificationPriority.normal;

    switch (status.toLowerCase()) {
      case 'confirmed':
        title = 'Order Confirmed';
        body = 'Your order #$orderId has been confirmed and is being processed.';
        break;
      case 'shipped':
        title = 'Order Shipped';
        body = 'Your order #$orderId has been shipped${trackingNumber != null ? '. Tracking: $trackingNumber' : ''}';
        priority = NotificationPriority.high;
        break;
      case 'delivered':
        title = 'Order Delivered';
        body = 'Your order #$orderId has been delivered. Enjoy your purchase!';
        priority = NotificationPriority.high;
        break;
      case 'cancelled':
        title = 'Order Cancelled';
        body = 'Your order #$orderId has been cancelled. Refund will be processed shortly.';
        priority = NotificationPriority.high;
        break;
      default:
        title = 'Order Update';
        body = 'Your order #$orderId status has been updated to: $status';
    }

    return NotificationModel(
      id: 'order_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      type: NotificationType.order,
      priority: priority,
      timestamp: DateTime.now(),
      actionUrl: '/orders/$orderId',
      actionLabel: 'View Order',
      data: {
        'order_id': orderId,
        'status': status,
        if (trackingNumber != null) 'tracking_number': trackingNumber,
      },
    );
  }

  /// Create message notification
  static NotificationModel createMessageNotification({
    required String chatId,
    required String senderName,
    required String messageContent,
  }) {
    return NotificationModel(
      id: 'message_${chatId}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Message',
      body: '$senderName: ${messageContent.length > 50 ? '${messageContent.substring(0, 50)}...' : messageContent}',
      type: NotificationType.message,
      timestamp: DateTime.now(),
      actionUrl: '/chat/$chatId',
      actionLabel: 'View Message',
      data: {
        'chat_id': chatId,
        'sender_name': senderName,
      },
    );
  }

  /// Create promotion notification
  static NotificationModel createPromotionNotification({
    required String title,
    required String description,
    String? imageUrl,
    String? actionUrl,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: description,
      type: NotificationType.promotion,
      timestamp: DateTime.now(),
      imageUrl: imageUrl,
      actionUrl: actionUrl,
      actionLabel: actionUrl != null ? 'Shop Now' : null,
      expiresAt: expiresAt,
    );
  }

  /// Create security notification
  static NotificationModel createSecurityNotification({
    required String event,
    required String details,
  }) {
    return NotificationModel(
      id: 'security_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Security Alert',
      body: '$event: $details',
      type: NotificationType.security,
      priority: NotificationPriority.urgent,
      timestamp: DateTime.now(),
      actionUrl: '/security',
      actionLabel: 'Review Security',
    );
  }

  /// Create system notification
  static NotificationModel createSystemNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
  }) {
    return NotificationModel(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: message,
      type: NotificationType.system,
      priority: priority,
      timestamp: DateTime.now(),
    );
  }
}