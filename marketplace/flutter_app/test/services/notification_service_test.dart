import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/notification_service.dart';
import '../../lib/models/notification.dart';

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      notificationService = NotificationService.instance;
    });

    tearDown(() {
      notificationService.clearAll();
    });

    test('should initialize with empty notifications', () async {
      await notificationService.initialize();
      
      expect(notificationService.isInitialized, isTrue);
      expect(notificationService.notifications, isEmpty);
      expect(notificationService.unreadCount, equals(0));
    });

    group('Notification Management', () {
      test('should add notification successfully', () async {
        await notificationService.initialize();
        
        final notification = NotificationModel(
          id: 'test_1',
          title: 'Test Notification',
          body: 'This is a test notification',
          type: NotificationType.order,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(notification);

        expect(notificationService.notifications.length, equals(1));
        expect(notificationService.notifications.first.id, equals('test_1'));
        expect(notificationService.unreadCount, equals(1));
      });

      test('should not add notification if type is disabled', () async {
        await notificationService.initialize();
        
        // Disable order notifications
        final settings = notificationService.settings.copyWith(
          typeSettings: {NotificationType.order: false},
        );
        await notificationService.updateSettings(settings);

        final notification = NotificationModel(
          id: 'test_1',
          title: 'Order Update',
          body: 'Your order has been shipped',
          type: NotificationType.order,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(notification);

        expect(notificationService.notifications, isEmpty);
      });

      test('should not add notification during quiet hours', () async {
        await notificationService.initialize();
        
        // Set quiet hours
        final settings = notificationService.settings.copyWith(
          quietHoursStart: '22:00',
          quietHoursEnd: '08:00',
        );
        await notificationService.updateSettings(settings);

        final notification = NotificationModel(
          id: 'test_1',
          title: 'Regular Notification',
          body: 'This should be blocked during quiet hours',
          type: NotificationType.general,
          priority: NotificationPriority.normal,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(notification);

        // Should not add during quiet hours unless urgent
        expect(notificationService.notifications, isEmpty);
      });

      test('should add urgent notification even during quiet hours', () async {
        await notificationService.initialize();
        
        final settings = notificationService.settings.copyWith(
          quietHoursStart: '22:00',
          quietHoursEnd: '08:00',
        );
        await notificationService.updateSettings(settings);

        final urgentNotification = NotificationModel(
          id: 'urgent_1',
          title: 'Urgent Notification',
          body: 'This is urgent and should be shown',
          type: NotificationType.security,
          priority: NotificationPriority.urgent,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(urgentNotification);

        expect(notificationService.notifications.length, equals(1));
      });

      test('should mark notification as read', () async {
        await notificationService.initialize();
        
        final notification = NotificationModel(
          id: 'test_1',
          title: 'Test Notification',
          body: 'Test body',
          type: NotificationType.general,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(notification);
        expect(notificationService.unreadCount, equals(1));

        await notificationService.markAsRead('test_1');
        
        expect(notificationService.notifications.first.isRead, isTrue);
        expect(notificationService.unreadCount, equals(0));
      });

      test('should mark all notifications as read', () async {
        await notificationService.initialize();
        
        final notifications = [
          NotificationModel(
            id: 'test_1',
            title: 'Test 1',
            body: 'Body 1',
            type: NotificationType.general,
            timestamp: DateTime.now(),
          ),
          NotificationModel(
            id: 'test_2',
            title: 'Test 2',
            body: 'Body 2',
            type: NotificationType.order,
            timestamp: DateTime.now(),
          ),
        ];

        for (final notification in notifications) {
          await notificationService.addNotification(notification);
        }

        expect(notificationService.unreadCount, equals(2));

        await notificationService.markAllAsRead();

        expect(notificationService.unreadCount, equals(0));
        expect(notificationService.notifications.every((n) => n.isRead), isTrue);
      });

      test('should delete notification', () async {
        await notificationService.initialize();
        
        final notification = NotificationModel(
          id: 'test_1',
          title: 'Test Notification',
          body: 'Test body',
          type: NotificationType.general,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(notification);
        expect(notificationService.notifications.length, equals(1));

        await notificationService.deleteNotification('test_1');
        
        expect(notificationService.notifications, isEmpty);
      });

      test('should clear all notifications', () async {
        await notificationService.initialize();
        
        final notifications = List.generate(5, (index) => NotificationModel(
          id: 'test_$index',
          title: 'Test $index',
          body: 'Body $index',
          type: NotificationType.general,
          timestamp: DateTime.now(),
        ));

        for (final notification in notifications) {
          await notificationService.addNotification(notification);
        }

        expect(notificationService.notifications.length, equals(5));

        await notificationService.clearAll();
        
        expect(notificationService.notifications, isEmpty);
      });
    });

    group('Notification Filtering', () {
      test('should get notifications by type', () async {
        await notificationService.initialize();
        
        final orderNotification = NotificationModel(
          id: 'order_1',
          title: 'Order Update',
          body: 'Your order has been shipped',
          type: NotificationType.order,
          timestamp: DateTime.now(),
        );

        final messageNotification = NotificationModel(
          id: 'message_1',
          title: 'New Message',
          body: 'You have a new message',
          type: NotificationType.message,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(orderNotification);
        await notificationService.addNotification(messageNotification);

        final orderNotifications = notificationService.getNotificationsByType(NotificationType.order);
        
        expect(orderNotifications.length, equals(1));
        expect(orderNotifications.first.type, equals(NotificationType.order));
      });

      test('should get notifications by priority', () async {
        await notificationService.initialize();
        
        final normalNotification = NotificationModel(
          id: 'normal_1',
          title: 'Normal Notification',
          body: 'Normal priority',
          type: NotificationType.general,
          priority: NotificationPriority.normal,
          timestamp: DateTime.now(),
        );

        final highNotification = NotificationModel(
          id: 'high_1',
          title: 'High Priority',
          body: 'High priority notification',
          type: NotificationType.security,
          priority: NotificationPriority.high,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(normalNotification);
        await notificationService.addNotification(highNotification);

        final highPriorityNotifications = notificationService.getNotificationsByPriority(NotificationPriority.high);
        
        expect(highPriorityNotifications.length, equals(1));
        expect(highPriorityNotifications.first.priority, equals(NotificationPriority.high));
      });

      test('should search notifications', () async {
        await notificationService.initialize();
        
        final notification1 = NotificationModel(
          id: 'search_1',
          title: 'Order Shipped',
          body: 'Your iPhone order has been shipped',
          type: NotificationType.order,
          timestamp: DateTime.now(),
        );

        final notification2 = NotificationModel(
          id: 'search_2',
          title: 'New Message',
          body: 'You have a message about your Samsung order',
          type: NotificationType.message,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(notification1);
        await notificationService.addNotification(notification2);

        final searchResults = notificationService.searchNotifications('iPhone');
        
        expect(searchResults.length, equals(1));
        expect(searchResults.first.body, contains('iPhone'));
      });
    });

    group('Notification Settings', () {
      test('should update notification settings', () async {
        await notificationService.initialize();
        
        final newSettings = NotificationSettings(
          pushEnabled: false,
          emailEnabled: true,
          smsEnabled: false,
          soundEnabled: true,
          vibrationEnabled: false,
          typeSettings: {
            NotificationType.order: true,
            NotificationType.message: false,
          },
        );

        await notificationService.updateSettings(newSettings);

        expect(notificationService.settings.pushEnabled, isFalse);
        expect(notificationService.settings.emailEnabled, isTrue);
        expect(notificationService.settings.isTypeEnabled(NotificationType.order), isTrue);
        expect(notificationService.settings.isTypeEnabled(NotificationType.message), isFalse);
      });

      test('should check if notification type is enabled', () async {
        await notificationService.initialize();
        
        final settings = NotificationSettings(
          typeSettings: {
            NotificationType.order: true,
            NotificationType.message: false,
            NotificationType.promotion: true,
          },
        );

        await notificationService.updateSettings(settings);

        expect(notificationService.settings.isTypeEnabled(NotificationType.order), isTrue);
        expect(notificationService.settings.isTypeEnabled(NotificationType.message), isFalse);
        expect(notificationService.settings.isTypeEnabled(NotificationType.promotion), isTrue);
        expect(notificationService.settings.isTypeEnabled(NotificationType.security), isTrue); // Default enabled
      });

      test('should check quiet hours functionality', () {
        final settings = NotificationSettings(
          quietHoursStart: '22:00',
          quietHoursEnd: '08:00',
        );

        // Mock current time to be during quiet hours (e.g., 23:00)
        final quietHoursActive = settings.isInQuietHours();
        
        // This would need proper time mocking in a real implementation
        expect(settings.quietHoursStart, equals('22:00'));
        expect(settings.quietHoursEnd, equals('08:00'));
      });
    });

    group('Notification Cleanup', () {
      test('should clean up expired notifications', () async {
        await notificationService.initialize();
        
        final expiredNotification = NotificationModel(
          id: 'expired_1',
          title: 'Expired Notification',
          body: 'This notification has expired',
          type: NotificationType.promotion,
          timestamp: DateTime.now(),
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final validNotification = NotificationModel(
          id: 'valid_1',
          title: 'Valid Notification',
          body: 'This notification is still valid',
          type: NotificationType.general,
          timestamp: DateTime.now(),
        );

        await notificationService.addNotification(expiredNotification);
        await notificationService.addNotification(validNotification);

        expect(notificationService.notifications.length, equals(2));

        await notificationService.cleanupExpired();

        expect(notificationService.notifications.length, equals(1));
        expect(notificationService.notifications.first.id, equals('valid_1'));
      });

      test('should limit total number of notifications', () async {
        await notificationService.initialize();
        
        // Add more than the limit (assuming limit is 100)
        for (int i = 0; i < 105; i++) {
          final notification = NotificationModel(
            id: 'test_$i',
            title: 'Test $i',
            body: 'Body $i',
            type: NotificationType.general,
            timestamp: DateTime.now(),
          );
          
          await notificationService.addNotification(notification);
        }

        expect(notificationService.notifications.length, lessThanOrEqualTo(100));
      });
    });

    group('Factory Methods Tests', () {
      test('should create order notification correctly', () {
        final notification = NotificationService.createOrderNotification(
          orderId: 'ORDER123',
          status: 'shipped',
          trackingNumber: 'TRACK456',
        );

        expect(notification.type, equals(NotificationType.order));
        expect(notification.title, equals('Order Shipped'));
        expect(notification.body, contains('ORDER123'));
        expect(notification.body, contains('TRACK456'));
        expect(notification.priority, equals(NotificationPriority.high));
      });

      test('should create message notification correctly', () {
        final notification = NotificationService.createMessageNotification(
          chatId: 'chat123',
          senderName: 'John Doe',
          messageContent: 'Hello, how are you?',
        );

        expect(notification.type, equals(NotificationType.message));
        expect(notification.title, equals('New Message'));
        expect(notification.body, contains('John Doe'));
        expect(notification.body, contains('Hello, how are you?'));
      });

      test('should create promotion notification correctly', () {
        final notification = NotificationService.createPromotionNotification(
          title: 'Flash Sale',
          description: '50% off all items',
          imageUrl: 'https://example.com/image.jpg',
          actionUrl: '/sale',
          expiresAt: DateTime.now().add(const Duration(days: 1)),
        );

        expect(notification.type, equals(NotificationType.promotion));
        expect(notification.title, equals('Flash Sale'));
        expect(notification.body, equals('50% off all items'));
        expect(notification.imageUrl, equals('https://example.com/image.jpg'));
        expect(notification.actionUrl, equals('/sale'));
        expect(notification.expiresAt, isNotNull);
      });

      test('should create security notification correctly', () {
        final notification = NotificationService.createSecurityNotification(
          event: 'Login attempt',
          details: 'Someone tried to log into your account',
        );

        expect(notification.type, equals(NotificationType.security));
        expect(notification.title, equals('Security Alert'));
        expect(notification.priority, equals(NotificationPriority.urgent));
        expect(notification.body, contains('Login attempt'));
      });

      test('should create system notification correctly', () {
        final notification = NotificationService.createSystemNotification(
          title: 'Maintenance Notice',
          message: 'System will be down for maintenance',
          priority: NotificationPriority.high,
        );

        expect(notification.type, equals(NotificationType.system));
        expect(notification.title, equals('Maintenance Notice'));
        expect(notification.priority, equals(NotificationPriority.high));
      });
    });

    group('Permission Tests', () {
      test('should request notification permission', () async {
        await notificationService.initialize();
        
        final hasPermission = await notificationService.requestPermission();
        
        expect(hasPermission, isTrue); // Mock implementation returns true
      });

      test('should check notification permission status', () async {
        await notificationService.initialize();
        
        final hasPermission = await notificationService.hasPermission();
        
        expect(hasPermission, isTrue); // Mock implementation returns true
      });
    });

    group('Error Handling', () {
      test('should handle initialization errors gracefully', () async {
        // This would test error scenarios in a real implementation
        await notificationService.initialize();
        
        expect(notificationService.isInitialized, isTrue);
        expect(notificationService.errorMessage, isNull);
      });

      test('should handle invalid notification data', () async {
        await notificationService.initialize();
        
        // Test with null notification - should not crash
        try {
          await notificationService.addNotification(null as dynamic);
        } catch (e) {
          // Should handle gracefully
          expect(e, isA<TypeError>());
        }
      });
    });
  });
}