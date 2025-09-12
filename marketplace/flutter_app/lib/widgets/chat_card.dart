import 'package:flutter/material.dart';

import '../core/config/app_constants.dart';
import '../models/message.dart';
import '../widgets/glassmorphic_container.dart';

/// Chat card widget to display chat conversation information
class ChatCard extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback? onTap;

  const ChatCard({
    super.key,
    required this.chatRoom,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final otherParticipant = chatRoom.otherParticipant;
    
    return GestureDetector(
      onTap: onTap,
      child: GlassmorphicContainer.card(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingM),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                backgroundImage: otherParticipant?.avatarUrl != null
                    ? NetworkImage(otherParticipant!.avatarUrl!)
                    : null,
                child: otherParticipant?.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              const SizedBox(width: AppConstants.spacingM),
              
              // Chat info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chatRoom.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (otherParticipant != null)
                      Text(
                        otherParticipant.statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: otherParticipant.isOnline 
                              ? Colors.green 
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              
              // Unread count or timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (chatRoom.lastMessage != null)
                    Text(
                      _formatTimestamp(chatRoom.lastMessage!.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (chatRoom.hasUnreadMessages)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        chatRoom.unreadCount.toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}