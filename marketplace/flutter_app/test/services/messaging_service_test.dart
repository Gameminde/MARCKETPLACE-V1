import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/services/messaging_service.dart';
import '../../lib/models/message.dart';

void main() {
  group('MessagingService Tests', () {
    late MessagingService messagingService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      messagingService = MessagingService.instance;
    });

    tearDown(() {
      messagingService.clearAllChats();
    });

    test('should initialize with empty chat rooms', () async {
      await messagingService.initialize();
      
      expect(messagingService.isInitialized, isTrue);
      expect(messagingService.chatRooms, isEmpty);
    });

    group('Chat Room Management', () {
      test('should create new chat room', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        expect(messagingService.chatRooms.length, equals(1));
        expect(messagingService.chatRooms.first.id, equals('chat_1'));
      });

      test('should get chat room by ID', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        final retrievedChat = messagingService.getChatRoom('chat_1');
        
        expect(retrievedChat, isNotNull);
        expect(retrievedChat!.id, equals('chat_1'));
      });

      test('should archive chat room', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);
        await messagingService.archiveChat('chat_1');

        final chat = messagingService.getChatRoom('chat_1');
        expect(chat?.metadata?['archived'], isTrue);
      });

      test('should delete chat room', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);
        expect(messagingService.chatRooms.length, equals(1));

        await messagingService.deleteChat('chat_1');
        expect(messagingService.chatRooms, isEmpty);
      });
    });

    group('Message Management', () {
      test('should send text message', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        final message = Message(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_1',
          content: 'Hello, how are you?',
          type: MessageType.text,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isFromCurrentUser: true,
        );

        await messagingService.sendMessage('chat_1', message);

        final messages = messagingService.getMessages('chat_1');
        expect(messages.length, equals(1));
        expect(messages.first.content, equals('Hello, how are you?'));
        expect(messages.first.status, equals(MessageStatus.sent));
      });

      test('should send image message', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        final message = Message(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_1',
          content: 'Check out this image!',
          type: MessageType.image,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isFromCurrentUser: true,
          attachments: ['https://example.com/image.jpg'],
        );

        await messagingService.sendMessage('chat_1', message);

        final messages = messagingService.getMessages('chat_1');
        expect(messages.length, equals(1));
        expect(messages.first.type, equals(MessageType.image));
        expect(messages.first.attachments.length, equals(1));
      });

      test('should send product message', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        final message = Message(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_1',
          content: 'iPhone 14 Pro',
          type: MessageType.product,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isFromCurrentUser: true,
          metadata: {
            'product_id': 'prod_123',
            'price': '999.99',
            'image_url': 'https://example.com/iphone.jpg',
          },
        );

        await messagingService.sendMessage('chat_1', message);

        final messages = messagingService.getMessages('chat_1');
        expect(messages.length, equals(1));
        expect(messages.first.type, equals(MessageType.product));
        expect(messages.first.metadata?['product_id'], equals('prod_123'));
      });

      test('should get messages for chat room', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        // Send multiple messages
        for (int i = 0; i < 3; i++) {
          final message = Message(
            id: 'msg_$i',
            chatId: 'chat_1',
            senderId: 'user_1',
            content: 'Message $i',
            type: MessageType.text,
            timestamp: DateTime.now(),
            status: MessageStatus.sending,
            isFromCurrentUser: true,
          );
          
          await messagingService.sendMessage('chat_1', message);
        }

        final messages = messagingService.getMessages('chat_1');
        expect(messages.length, equals(3));
      });

      test('should mark messages as read', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        final message = Message(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_2',  // From other user
          content: 'Hello!',
          type: MessageType.text,
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
          isFromCurrentUser: false,
        );

        await messagingService.sendMessage('chat_1', message);
        
        final chatBefore = messagingService.getChatRoom('chat_1');
        expect(chatBefore?.hasUnreadMessages, isTrue);
        expect(chatBefore?.unreadCount, equals(1));

        await messagingService.markMessagesAsRead('chat_1');

        final chatAfter = messagingService.getChatRoom('chat_1');
        expect(chatAfter?.hasUnreadMessages, isFalse);
        expect(chatAfter?.unreadCount, equals(0));
      });

      test('should search messages', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        final messages = [
          Message(
            id: 'msg_1',
            chatId: 'chat_1',
            senderId: 'user_1',
            content: 'Hello there!',
            type: MessageType.text,
            timestamp: DateTime.now(),
            status: MessageStatus.sent,
            isFromCurrentUser: true,
          ),
          Message(
            id: 'msg_2',
            chatId: 'chat_1',
            senderId: 'user_1',
            content: 'How are you doing?',
            type: MessageType.text,
            timestamp: DateTime.now(),
            status: MessageStatus.sent,
            isFromCurrentUser: true,
          ),
          Message(
            id: 'msg_3',
            chatId: 'chat_1',
            senderId: 'user_1',
            content: 'Check out this product!',
            type: MessageType.text,
            timestamp: DateTime.now(),
            status: MessageStatus.sent,
            isFromCurrentUser: true,
          ),
        ];

        for (final message in messages) {
          await messagingService.sendMessage('chat_1', message);
        }

        final searchResults = await messagingService.searchMessages('Hello');
        expect(searchResults.length, equals(1));
        expect(searchResults.first.content, contains('Hello'));
      });
    });

    group('Chat Types', () {
      test('should create product chat', () async {
        await messagingService.initialize();
        
        final productChat = await messagingService.createProductChat(
          productId: 'prod_123',
          sellerId: 'seller_1',
          buyerId: 'buyer_1',
        );

        expect(productChat.type, equals(ChatRoomType.product));
        expect(productChat.isProductChat, isTrue);
        expect(productChat.metadata?['product_id'], equals('prod_123'));
      });

      test('should create order chat', () async {
        await messagingService.initialize();
        
        final orderChat = await messagingService.createOrderChat(
          orderId: 'order_123',
          sellerId: 'seller_1',
          buyerId: 'buyer_1',
        );

        expect(orderChat.type, equals(ChatRoomType.order));
        expect(orderChat.isOrderChat, isTrue);
        expect(orderChat.metadata?['order_id'], equals('order_123'));
      });

      test('should create support chat', () async {
        await messagingService.initialize();
        
        final supportChat = await messagingService.createSupportChat('user_1');

        expect(supportChat.type, equals(ChatRoomType.support));
        expect(supportChat.title, contains('Customer Support'));
        
        // Should have auto-assigned agent
        final agentParticipant = supportChat.participants.firstWhere(
          (p) => p.role == 'admin',
        );
        expect(agentParticipant.name, equals('Support Agent'));
      });
    });

    group('Typing Indicators', () {
      test('should handle typing indicators', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        messagingService.setTyping('chat_1', 'user_2', true);
        
        final chat = messagingService.getChatRoom('chat_1');
        expect(chat?.participants.any((p) => p.isTyping), isTrue);

        messagingService.setTyping('chat_1', 'user_2', false);
        
        final chatAfter = messagingService.getChatRoom('chat_1');
        expect(chatAfter?.participants.any((p) => p.isTyping), isFalse);
      });
    });

    group('Online Status', () {
      test('should update participant online status', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2', isOnline: false),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        messagingService.updateParticipantStatus('chat_1', 'user_2', true);
        
        final chat = messagingService.getChatRoom('chat_1');
        final user2 = chat?.participants.firstWhere((p) => p.id == 'user_2');
        expect(user2?.isOnline, isTrue);
      });
    });

    group('Auto-responses', () {
      test('should send auto-response for support chat', () async {
        await messagingService.initialize();
        
        final supportChat = await messagingService.createSupportChat('user_1');

        final userMessage = Message(
          id: 'msg_1',
          chatId: supportChat.id,
          senderId: 'user_1',
          content: 'I need help with my order',
          type: MessageType.text,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isFromCurrentUser: true,
        );

        await messagingService.sendMessage(supportChat.id, userMessage);

        // Wait for auto-response
        await Future.delayed(const Duration(milliseconds: 100));

        final messages = messagingService.getMessages(supportChat.id);
        expect(messages.length, greaterThan(1));
        
        // Should have auto-response from agent
        final autoResponse = messages.firstWhere(
          (m) => m.senderId == 'support_agent' && m.type == MessageType.system,
        );
        expect(autoResponse.content, contains('Thank you for contacting'));
      });

      test('should send auto-response for product inquiry', () async {
        await messagingService.initialize();
        
        final productChat = await messagingService.createProductChat(
          productId: 'prod_123',
          sellerId: 'seller_1',
          buyerId: 'buyer_1',
        );

        final inquiryMessage = Message(
          id: 'msg_1',
          chatId: productChat.id,
          senderId: 'buyer_1',
          content: 'Is this product still available?',
          type: MessageType.text,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isFromCurrentUser: true,
        );

        await messagingService.sendMessage(productChat.id, inquiryMessage);

        // Wait for auto-response
        await Future.delayed(const Duration(milliseconds: 100));

        final messages = messagingService.getMessages(productChat.id);
        expect(messages.length, greaterThan(1));
        
        // Should have auto-response from seller
        final autoResponse = messages.lastWhere(
          (m) => m.senderId == 'seller_1' && m.type == MessageType.system,
        );
        expect(autoResponse.content, contains('Thanks for your interest'));
      });
    });

    group('Error Handling', () {
      test('should handle sending message to non-existent chat', () async {
        await messagingService.initialize();
        
        final message = Message(
          id: 'msg_1',
          chatId: 'non_existent_chat',
          senderId: 'user_1',
          content: 'Hello',
          type: MessageType.text,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isFromCurrentUser: true,
        );

        await messagingService.sendMessage('non_existent_chat', message);

        // Should not crash, but message status should be failed
        expect(message.status, equals(MessageStatus.failed));
      });

      test('should handle invalid message data', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        // Test with empty content
        final emptyMessage = Message(
          id: 'msg_1',
          chatId: 'chat_1',
          senderId: 'user_1',
          content: '',
          type: MessageType.text,
          timestamp: DateTime.now(),
          status: MessageStatus.sending,
          isFromCurrentUser: true,
        );

        await messagingService.sendMessage('chat_1', emptyMessage);

        // Should handle gracefully
        final messages = messagingService.getMessages('chat_1');
        expect(messages, isEmpty); // Empty messages should be rejected
      });
    });

    group('Persistence Tests', () {
      test('should save and load chat data', () async {
        await messagingService.initialize();
        
        final chatRoom = ChatRoom(
          id: 'chat_1',
          title: 'Test Chat',
          participants: [
            const ChatParticipant(id: 'user_1', name: 'User 1'),
            const ChatParticipant(id: 'user_2', name: 'User 2'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await messagingService.createChatRoom(chatRoom);

        // Save to cache
        await messagingService.saveToCache();

        // Create new instance and load
        final newMessagingService = MessagingService.instance;
        await newMessagingService.loadFromCache();

        expect(newMessagingService.chatRooms.length, equals(1));
        expect(newMessagingService.chatRooms.first.id, equals('chat_1'));
      });
    });
  });
}