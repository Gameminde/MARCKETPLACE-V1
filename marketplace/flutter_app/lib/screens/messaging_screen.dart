import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';
import '../widgets/custom_app_bar.dart';
import 'chat_screen.dart';

/// Main messaging screen showing chat list
class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeMessaging();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMessaging() async {
    await MessagingService.instance.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchBar,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showOptionsMenu,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.chat)),
            Tab(text: 'Unread', icon: Icon(Icons.mark_chat_unread)),
            Tab(text: 'Archived', icon: Icon(Icons.archive)),
          ],
        ),
      ),
      body: Consumer<MessagingService>(
        builder: (context, messagingService, child) {
          if (!messagingService.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }

          if (messagingService.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: AppConstants.spacingM),
                  Text(
                    messagingService.errorMessage!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.spacingL),
                  ElevatedButton(
                    onPressed: _initializeMessaging,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildChatList(messagingService.chatRooms),
              _buildChatList(messagingService.chatRooms.where((chat) => chat.hasUnreadMessages).toList()),
              _buildChatList(messagingService.chatRooms.where((chat) => 
                chat.metadata?['archived'] == true).toList()),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewChatOptions,
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildChatList(List<ChatRoom> chatRooms) {
    if (chatRooms.isEmpty) {
      return _buildEmptyState();
    }

    // Filter by search query
    final filteredChats = _searchQuery.isEmpty
        ? chatRooms
        : chatRooms.where((chat) =>
            chat.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            chat.lastMessage?.content.toLowerCase().contains(_searchQuery.toLowerCase()) == true
          ).toList();

    return RefreshIndicator(
      onRefresh: _refreshChats,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.spacingM),
            child: _buildChatItem(chat),
          );
        },
      ),
    );
  }

  Widget _buildChatItem(ChatRoom chat) {
    final otherParticipant = chat.otherParticipant;
    
    return GlassmorphicContainer.card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppConstants.spacingM),
        leading: _buildAvatar(otherParticipant),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.hasUnreadMessages)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingS,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${chat.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (chat.lastMessage != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (chat.lastMessage!.isFromCurrentUser) ...[
                    Icon(
                      _getStatusIcon(chat.lastMessage!.status),
                      size: 14,
                      color: chat.lastMessage!.getStatusColor(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      _getMessagePreview(chat.lastMessage!),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: chat.hasUnreadMessages ? FontWeight.w600 : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (otherParticipant != null)
                  Text(
                    otherParticipant.statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: otherParticipant.isOnline 
                          ? Colors.green 
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                if (chat.lastMessage != null)
                  Text(
                    _formatTimestamp(chat.lastMessage!.timestamp),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            
            // Chat type indicators
            if (chat.isProductChat || chat.isOrderChat) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    chat.isProductChat ? Icons.shopping_cart : Icons.receipt,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    chat.isProductChat ? 'Product Inquiry' : 'Order Chat',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        onTap: () => _openChat(chat),
        onLongPress: () => _showChatOptions(chat),
      ),
    );
  }

  Widget _buildAvatar(ChatParticipant? participant) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          backgroundImage: participant?.avatarUrl != null
              ? NetworkImage(participant!.avatarUrl!)
              : null,
          child: participant?.avatarUrl == null
              ? Icon(
                  Icons.person,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                )
              : null,
        ),
        if (participant?.isOnline == true)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: AppConstants.spacingM),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Start a conversation by messaging a seller',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.spacingL),
          ElevatedButton.icon(
            onPressed: _showNewChatOptions,
            icon: const Icon(Icons.chat),
            label: const Text('Start Chatting'),
          ),
        ],
      ),
    );
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case MessageType.text:
        return message.content;
      case MessageType.image:
        return '📷 Photo${message.content.isNotEmpty ? ': ${message.content}' : ''}';
      case MessageType.file:
        return '📄 File${message.content.isNotEmpty ? ': ${message.content}' : ''}';
      case MessageType.product:
        return '🛍️ Product: ${message.content}';
      case MessageType.order:
        return '📦 Order: ${message.content}';
      case MessageType.location:
        return '📍 Location';
      case MessageType.system:
        return message.content;
      case MessageType.typing:
        return 'typing...';
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.schedule;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openChat(ChatRoom chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chat),
      ),
    );
  }

  Future<void> _refreshChats() async {
    // In a real app, this would refresh from API
    await Future.delayed(const Duration(seconds: 1));
  }

  void _showSearchBar() {
    showSearch(
      context: context,
      delegate: ChatSearchDelegate(),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_chat_read),
              title: const Text('Mark all as read'),
              onTap: _markAllAsRead,
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive all'),
              onTap: _archiveAll,
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Chat settings'),
              onTap: _openChatSettings,
            ),
          ],
        ),
      ),
    );
  }

  void _showChatOptions(ChatRoom chat) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              chat.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ListTile(
              leading: Icon(
                chat.hasUnreadMessages ? Icons.mark_chat_read : Icons.mark_chat_unread,
              ),
              title: Text(
                chat.hasUnreadMessages ? 'Mark as read' : 'Mark as unread',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleReadStatus(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive chat'),
              onTap: () {
                Navigator.pop(context);
                _archiveChat(chat);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete chat', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteChat(chat);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Start a new chat',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Message a seller'),
              subtitle: const Text('Find and message product sellers'),
              onTap: () {
                Navigator.pop(context);
                _showSellerSearch();
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text('Contact support'),
              subtitle: const Text('Get help from customer service'),
              onTap: () {
                Navigator.pop(context);
                _contactSupport();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead() {
    Navigator.pop(context);
    final messagingService = MessagingService.instance;
    for (final chat in messagingService.chatRooms) {
      if (chat.hasUnreadMessages) {
        messagingService.markMessagesAsRead(chat.id);
      }
    }
  }

  void _archiveAll() {
    Navigator.pop(context);
    final messagingService = MessagingService.instance;
    for (final chat in messagingService.chatRooms) {
      messagingService.archiveChat(chat.id);
    }
  }

  void _openChatSettings() {
    Navigator.pop(context);
    // Navigate to chat settings screen
  }

  void _toggleReadStatus(ChatRoom chat) {
    final messagingService = MessagingService.instance;
    if (chat.hasUnreadMessages) {
      messagingService.markMessagesAsRead(chat.id);
    }
    // Note: "Mark as unread" would require additional implementation
  }

  void _archiveChat(ChatRoom chat) {
    MessagingService.instance.archiveChat(chat.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Chat archived')),
    );
  }

  void _deleteChat(ChatRoom chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Chat'),
        content: const Text('Are you sure you want to delete this chat? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              MessagingService.instance.deleteChat(chat.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chat deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSellerSearch() {
    // Navigate to seller search/browse screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seller search coming soon!')),
    );
  }

  void _contactSupport() async {
    final messagingService = MessagingService.instance;
    // Create or find support chat
    final supportChat = ChatRoom(
      id: 'support_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Customer Support',
      participants: [
        const ChatParticipant(
          id: 'current_user',
          name: 'You',
        ),
        const ChatParticipant(
          id: 'support_agent',
          name: 'Support Agent',
          role: 'admin',
          isOnline: true,
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      type: ChatRoomType.support,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: supportChat),
      ),
    );
  }
}

/// Search delegate for chat search functionality
class ChatSearchDelegate extends SearchDelegate<ChatRoom?> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return _buildRecentChats(context);
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final messagingService = MessagingService.instance;
    
    return FutureBuilder<List<Message>>(
      future: messagingService.searchMessages(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final messages = snapshot.data ?? [];
        
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: AppConstants.spacingM),
                Text(
                  'No messages found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Try searching with different keywords',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final chat = messagingService.getChatRoom(message.chatId);
            
            return ListTile(
              title: Text(chat?.title ?? 'Unknown Chat'),
              subtitle: Text(
                message.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _formatTimestamp(message.timestamp),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              onTap: () {
                if (chat != null) {
                  close(context, chat);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chatRoom: chat),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRecentChats(BuildContext context) {
    final messagingService = MessagingService.instance;
    final recentChats = messagingService.chatRooms.take(5).toList();

    return ListView.builder(
      itemCount: recentChats.length,
      itemBuilder: (context, index) {
        final chat = recentChats[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(chat.title),
          subtitle: Text(chat.lastMessage?.content ?? ''),
          onTap: () {
            query = chat.title;
            showResults(context);
          },
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
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