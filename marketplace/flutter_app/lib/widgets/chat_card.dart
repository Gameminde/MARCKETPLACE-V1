import 'package:flutter/material.dart';
import '../models/message.dart';
import '../core/config/app_constants.dart';

/// Chat card widget for displaying chat conversations or individual messages
class ChatCard extends StatelessWidget {
  final ChatRoom? chatRoom;
  final Message? message;
  final VoidCallback? onTap;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isCurrentUser;

  const ChatCard({
    Key? key,
    this.chatRoom,
    this.message,
    this.onTap,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.isCurrentUser = false,
  }) : super(key: key);

  /// Factory constructor for chat room list item
  factory ChatCard.chatRoom({
    required ChatRoom chatRoom,
    VoidCallback? onTap,
  }) {
    return ChatCard(
      chatRoom: chatRoom,
      onTap: onTap,
      showAvatar: true,
      showTimestamp: true,
    );
  }

  /// Factory constructor for individual message
  factory ChatCard.message({
    required Message message,
    bool isCurrentUser = false,
    VoidCallback? onTap,
  }) {
    return ChatCard(
      message: message,
      onTap: onTap,
      isCurrentUser: isCurrentUser,
      showAvatar: !isCurrentUser,
      showTimestamp: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (chatRoom != null) {
      return _buildChatRoomCard(context);
    } else if (message != null) {
      return _buildMessageCard(context);
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildChatRoomCard(BuildContext context) {
    final room = chatRoom!;
    final otherParticipant = room.otherParticipant;
    
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingS,
        vertical: 2,
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              // Avatar
              _buildAvatar(
                context,
                otherParticipant?.avatarUrl,
                otherParticipant?.name ?? room.title,
                isOnline: otherParticipant?.isOnline ?? false,
              ),
              const SizedBox(width: AppConstants.spacingM),
              
              // Chat content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Chat title and timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            room.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: room.hasUnreadMessages 
                                  ? FontWeight.bold 
                                  : FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (showTimestamp && room.lastMessage != null)
                          Text(
                            _formatTimestamp(room.lastMessage!.timestamp),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Last message and unread count
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            room.lastMessage?.content ?? 'No messages yet',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: room.hasUnreadMessages
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: room.hasUnreadMessages 
                                  ? FontWeight.w500 
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (room.hasUnreadMessages) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              room.unreadCount > 99 ? '99+' : room.unreadCount.toString(),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    // Chat type indicator
                    if (room.isProductChat || room.isOrderChat) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            room.isProductChat ? Icons.shopping_bag : Icons.receipt,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            room.isProductChat ? 'Product Chat' : 'Order Chat',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(BuildContext context) {
    final msg = message!;
    
    return Container(
      margin: EdgeInsets.only(
        left: isCurrentUser ? 48 : 8,
        right: isCurrentUser ? 8 : 48,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users
          if (!isCurrentUser && showAvatar) ...[
            _buildAvatar(context, null, 'User', size: 32),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message content
                  _buildMessageContent(context, msg),
                  
                  // Timestamp and status
                  if (showTimestamp) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTimestamp(msg.timestamp),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isCurrentUser
                                ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                                : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 4),
                          Icon(
                            _getStatusIcon(msg.status),
                            size: 12,
                            color: msg.getStatusColor(context),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(
    BuildContext context,
    String? avatarUrl,
    String name, {
    bool isOnline = false,
    double size = 48,
  }) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageContent(BuildContext context, Message msg) {
    switch (msg.type) {
      case MessageType.text:
        return Text(
          msg.content,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: isCurrentUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (msg.attachments.isNotEmpty)
              Container(
                height: 150,
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    msg.attachments.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.image_not_supported),
                      );
                    },
                  ),
                ),
              ),
            if (msg.content.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                msg.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      
      case MessageType.system:
        return Text(
          msg.content,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontStyle: FontStyle.italic,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        );
      
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              msg.typeIcon,
              size: 16,
              color: isCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              msg.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
    }
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icons.access_time;
      case MessageStatus.sent:
        return Icons.check;
      case MessageStatus.delivered:
        return Icons.done_all;
      case MessageStatus.read:
        return Icons.done_all;
      case MessageStatus.failed:
        return Icons.error_outline;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}