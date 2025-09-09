import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../core/config/app_constants.dart';
import '../models/message.dart';
import '../widgets/glassmorphic_container.dart';

/// Chat bubble widget for displaying messages with various types and styles
class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool showAvatar;
  final bool showTimestamp;
  final bool showStatus;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onReply;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;
  final Widget? customAvatar;
  final double maxWidth;

  const ChatBubble({
    super.key,
    required this.message,
    this.isFirstInGroup = false,
    this.isLastInGroup = false,
    this.showAvatar = false,
    this.showTimestamp = true,
    this.showStatus = true,
    this.onTap,
    this.onLongPress,
    this.onReply,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
    this.customAvatar,
    this.maxWidth = 280.0,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemMessage(context);
    }

    return Container(
      margin: EdgeInsets.only(
        bottom: isLastInGroup ? AppConstants.spacingM : 2,
        left: AppConstants.spacingS,
        right: AppConstants.spacingS,
      ),
      child: Row(
        mainAxisAlignment: message.isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar for other users
          if (!message.isFromCurrentUser && showAvatar && isLastInGroup)
            _buildAvatar(context)
          else if (!message.isFromCurrentUser && showAvatar)
            const SizedBox(width: 32),
          
          if (!message.isFromCurrentUser)
            const SizedBox(width: AppConstants.spacingS),
          
          // Message bubble
          Flexible(
            child: GestureDetector(
              onTap: onTap,
              onLongPress: onLongPress ?? () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: isSelected ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ) : null,
                padding: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
                child: _buildMessageBubble(context),
              ),
            ),
          ),
          
          if (message.isFromCurrentUser) ...[
            const SizedBox(width: AppConstants.spacingS),
            if (showStatus && isLastInGroup)
              _buildStatusIndicator(context)
            else if (showStatus)
              const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppConstants.spacingS),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingM,
            vertical: AppConstants.spacingS,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (customAvatar != null) return customAvatar!;

    return CircleAvatar(
      radius: 16,
      backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
      child: Icon(
        Icons.person,
        size: 16,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      padding: _getMessagePadding(),
      decoration: BoxDecoration(
        gradient: message.isFromCurrentUser
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: message.isFromCurrentUser
            ? null
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: _getBubbleBorderRadius(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isReply) _buildReplyIndicator(context),
          _buildMessageContent(context),
          if (showTimestamp && isLastInGroup) _buildMessageFooter(context),
        ],
      ),
    );
  }

  EdgeInsets _getMessagePadding() {
    switch (message.type) {
      case MessageType.image:
        return const EdgeInsets.all(4);
      case MessageType.product:
      case MessageType.order:
        return const EdgeInsets.all(AppConstants.spacingM);
      default:
        return const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingM,
          vertical: AppConstants.spacingS,
        );
    }
  }

  BorderRadius _getBubbleBorderRadius() {
    const baseRadius = 18.0;
    const tightRadius = 4.0;

    return BorderRadius.only(
      topLeft: Radius.circular(
        !message.isFromCurrentUser && isFirstInGroup ? tightRadius : baseRadius,
      ),
      topRight: Radius.circular(
        message.isFromCurrentUser && isFirstInGroup ? tightRadius : baseRadius,
      ),
      bottomLeft: const Radius.circular(baseRadius),
      bottomRight: const Radius.circular(baseRadius),
    );
  }

  Widget _buildReplyIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: message.isFromCurrentUser
                ? Colors.white
                : Theme.of(context).colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Text(
        'Replying to a message',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
          color: message.isFromCurrentUser
              ? Colors.white70
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.product:
        return _buildProductMessage(context);
      case MessageType.order:
        return _buildOrderMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.location:
        return _buildLocationMessage(context);
      case MessageType.typing:
        return _buildTypingIndicator(context);
      default:
        return _buildTextMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return SelectableText(
      message.content,
      style: TextStyle(
        color: message.isFromCurrentUser
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 15,
        height: 1.3,
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 200,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: message.attachments.isNotEmpty
                ? Image.network(
                    message.attachments.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 48)),
                    ),
                  )
                : const Center(child: Icon(Icons.image, size: 48)),
          ),
        ),
        if (message.content.isNotEmpty) ...[
          const SizedBox(height: AppConstants.spacingS),
          Text(
            message.content,
            style: TextStyle(
              color: message.isFromCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProductMessage(BuildContext context) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.shopping_cart),
                ),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: message.isFromCurrentUser
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (message.metadata?['price'] != null)
                        Text(
                          '\$${message.metadata!['price']}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: message.isFromCurrentUser
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: message.isFromCurrentUser
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: message.isFromCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
              child: const Text('View Product'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderMessage(BuildContext context) {
    return GlassmorphicContainer.card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: AppConstants.spacingM),
                Expanded(
                  child: Text(
                    'Order ${message.metadata?['order_id'] ?? 'N/A'}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: message.isFromCurrentUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.spacingS),
            Text(message.content),
            const SizedBox(height: AppConstants.spacingM),
            ElevatedButton(
              onPressed: () {},
              child: const Text('View Order'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppConstants.spacingS),
        Expanded(
          child: Text(
            message.content.isNotEmpty ? message.content : 'File attachment',
            style: TextStyle(
              color: message.isFromCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Icon(Icons.download, size: 16),
      ],
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(child: Icon(Icons.map, size: 48)),
        ),
        const SizedBox(height: AppConstants.spacingS),
        Text(message.content.isNotEmpty ? message.content : 'Shared location'),
      ],
    );
  }

  Widget _buildTypingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
      )),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTimestamp(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: message.isFromCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          if (message.isFromCurrentUser && showStatus) ...[
            const SizedBox(width: 4),
            Icon(
              _getStatusIcon(),
              size: 12,
              color: message.getStatusColor(context).withOpacity(0.8),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    return Icon(
      _getStatusIcon(),
      size: 16,
      color: message.getStatusColor(context),
    );
  }

  IconData _getStatusIcon() {
    switch (message.status) {
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
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppConstants.spacingM),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppConstants.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            if (message.isFromCurrentUser) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  onEdit?.call();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete?.call();
                },
              ),
            ],
            const SizedBox(height: AppConstants.spacingM),
          ],
        ),
      ),
    );
  }
}

/// Typing indicator widget
class TypingIndicator extends StatefulWidget {
  final String userName;
  final Color? color;

  const TypingIndicator({
    super.key,
    required this.userName,
    this.color,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingM,
        vertical: AppConstants.spacingS,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.person,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingM,
              vertical: AppConstants.spacingS,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.userName} is typing',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: AppConstants.spacingS),
                Row(
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final opacity = (0.5 + 0.5 * 
                            ((1 + math.sin(_controller.value * 2 * math.pi + index * 0.5)) / 2));
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: (widget.color ?? Theme.of(context).colorScheme.primary)
                                .withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}