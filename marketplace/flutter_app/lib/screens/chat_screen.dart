import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/config/app_constants.dart';
import '../models/message.dart';
import '../services/messaging_service.dart';
import '../widgets/glassmorphic_container.dart';
import '../widgets/loading_states.dart';

/// Individual chat screen for conversations
class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  late StreamSubscription<Message> _messageSubscription;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _messageSubscription.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final messagingService = MessagingService.instance;
    
    // Load messages for this chat
    await messagingService.loadMessages(widget.chatRoom.id);
    
    // Mark messages as read
    await messagingService.markMessagesAsRead(widget.chatRoom.id);
    
    // Listen to new messages
    _messageSubscription = messagingService.getMessageStream(widget.chatRoom.id)
        .listen(_handleNewMessage);
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _handleNewMessage(Message message) {
    // Auto-scroll to bottom when new message arrives
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
    
    // Mark as read if chat is visible
    if (mounted) {
      MessagingService.instance.markMessagesAsRead(widget.chatRoom.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherParticipant = widget.chatRoom.otherParticipant;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              backgroundImage: otherParticipant?.avatarUrl != null
                  ? NetworkImage(otherParticipant!.avatarUrl!)
                  : null,
              child: otherParticipant?.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  : null,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chatRoom.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
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
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startVoiceCall,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showChatOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat type indicator
          if (widget.chatRoom.isProductChat || widget.chatRoom.isOrderChat)
            _buildChatTypeIndicator(),
          
          // Messages list
          Expanded(
            child: _buildMessagesList(),
          ),
          
          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatTypeIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.chatRoom.isProductChat ? Icons.shopping_cart : Icons.receipt,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.spacingS),
          Text(
            widget.chatRoom.isProductChat 
                ? 'Product Inquiry Chat'
                : 'Order Support Chat',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Consumer<MessagingService>(
      builder: (context, messagingService, child) {
        final messages = messagingService.getMessages(widget.chatRoom.id);
        
        if (messages.isEmpty) {
          return _buildEmptyMessages();
        }
        
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppConstants.spacingM),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isFirstInGroup = index == 0 || 
                messages[index - 1].senderId != message.senderId ||
                message.timestamp.difference(messages[index - 1].timestamp).inMinutes > 5;
            final isLastInGroup = index == messages.length - 1 ||
                messages[index + 1].senderId != message.senderId ||
                messages[index + 1].timestamp.difference(message.timestamp).inMinutes > 5;
            
            return Padding(
              padding: EdgeInsets.only(
                bottom: isLastInGroup ? AppConstants.spacingM : 2,
              ),
              child: ChatBubbleWidget(
                message: message,
                isFirstInGroup: isFirstInGroup,
                isLastInGroup: isLastInGroup,
                onReply: _replyToMessage,
                onEdit: _editMessage,
                onDelete: _deleteMessage,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyMessages() {
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
            'Start the conversation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(
            'Send a message to begin chatting',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _messageFocusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingM,
                  vertical: AppConstants.spacingS,
                ),
              ),
              maxLines: 5,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              onChanged: _onTyping,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: AppConstants.spacingS),
          GestureDetector(
            onTap: _sendMessage,
            onLongPress: _sendVoiceMessage,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.spacingM),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _messageController.text.trim().isEmpty ? Icons.mic : Icons.send,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onTyping(String text) {
    if (!_isTyping && text.isNotEmpty) {
      _isTyping = true;
      MessagingService.instance.startTyping(widget.chatRoom.id);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        MessagingService.instance.stopTyping(widget.chatRoom.id);
      }
    });
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final message = Message.text(
      content: content,
      chatId: widget.chatRoom.id,
      senderId: 'current_user',
      receiverId: widget.chatRoom.otherParticipant?.id,
    );

    _messageController.clear();
    
    // Stop typing indicator
    if (_isTyping) {
      _isTyping = false;
      MessagingService.instance.stopTyping(widget.chatRoom.id);
    }

    final success = await MessagingService.instance.sendMessage(message);
    
    if (success) {
      _scrollToBottom();
    } else {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _replyToMessage(Message message) {
    // Implement reply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reply feature coming soon!')),
    );
  }

  void _editMessage(Message message) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit feature coming soon!')),
    );
  }

  void _deleteMessage(Message message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await MessagingService.instance.deleteMessage(
        message.id,
        widget.chatRoom.id,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message deleted')),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Send Attachment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.spacingL),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Photo',
                  onTap: _sendPhoto,
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: _takePhoto,
                ),
                _buildAttachmentOption(
                  icon: Icons.attach_file,
                  label: 'File',
                  onTap: _sendFile,
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  onTap: _sendLocation,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.spacingM),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.spacingS),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  void _sendPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Photo sharing coming soon!')),
    );
  }

  void _takePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera feature coming soon!')),
    );
  }

  void _sendFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('File sharing coming soon!')),
    );
  }

  void _sendLocation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Location sharing coming soon!')),
    );
  }

  void _sendVoiceMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice messages coming soon!')),
    );
  }

  void _startVideoCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video calls coming soon!')),
    );
  }

  void _startVoiceCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice calls coming soon!')),
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Chat Info'),
              onTap: _showChatInfo,
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Messages'),
              onTap: _searchMessages,
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block User'),
              onTap: _blockUser,
            ),
            ListTile(
              leading: const Icon(Icons.report),
              title: const Text('Report Chat'),
              onTap: _reportChat,
            ),
          ],
        ),
      ),
    );
  }

  void _showChatInfo() {
    Navigator.pop(context);
    // Show chat info screen
  }

  void _searchMessages() {
    Navigator.pop(context);
    // Show message search
  }

  void _blockUser() {
    Navigator.pop(context);
    // Block user functionality
  }

  void _reportChat() {
    Navigator.pop(context);
    // Report chat functionality
  }
}

/// Chat bubble widget for individual messages
class ChatBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final Function(Message) onReply;
  final Function(Message) onEdit;
  final Function(Message) onDelete;

  const ChatBubbleWidget({
    super.key,
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.onReply,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _buildSystemMessage(context);
    }

    return Row(
      mainAxisAlignment: message.isFromCurrentUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!message.isFromCurrentUser && isLastInGroup)
          CircleAvatar(
            radius: 12,
            backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
            child: Icon(
              Icons.person,
              size: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          )
        else if (!message.isFromCurrentUser)
          const SizedBox(width: 24),
        
        const SizedBox(width: AppConstants.spacingS),
        
        Flexible(
          child: GestureDetector(
            onLongPress: () => _showMessageOptions(context),
            child: Container(
              margin: EdgeInsets.only(
                top: isFirstInGroup ? AppConstants.spacingS : 2,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingM,
                vertical: AppConstants.spacingS,
              ),
              decoration: BoxDecoration(
                color: message.isFromCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(
                    !message.isFromCurrentUser && isFirstInGroup ? 4 : 18,
                  ),
                  topRight: Radius.circular(
                    message.isFromCurrentUser && isFirstInGroup ? 4 : 18,
                  ),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reply indicator
                  if (message.isReply) _buildReplyIndicator(context),
                  
                  // Message content
                  _buildMessageContent(context),
                  
                  // Message footer
                  if (isLastInGroup) _buildMessageFooter(context),
                ],
              ),
            ),
          ),
        ),
        
        if (message.isFromCurrentUser) ...[
          const SizedBox(width: AppConstants.spacingS),
          if (isLastInGroup)
            Icon(
              _getStatusIcon(),
              size: 12,
              color: message.getStatusColor(context),
            )
          else
            const SizedBox(width: 12),
        ],
      ],
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
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
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

  Widget _buildReplyIndicator(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingS),
      padding: const EdgeInsets.all(AppConstants.spacingS),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Replying to message',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromCurrentUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      
      case MessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 48),
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
      
      case MessageType.product:
        return _buildProductMessage(context);
      
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              message.typeIcon,
              size: 16,
              color: message.isFromCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppConstants.spacingS),
            Text(
              message.content,
              style: TextStyle(
                color: message.isFromCurrentUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildProductMessage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingM),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (message.metadata?['price'] != null)
                      Text(
                        '\$${message.metadata!['price']}',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingS),
          ElevatedButton(
            onPressed: () {
              // Navigate to product details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
            child: const Text('View Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        _formatTimestamp(message.timestamp),
        style: TextStyle(
          fontSize: 10,
          color: message.isFromCurrentUser
              ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
        ),
      ),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppConstants.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                onReply(message);
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
                  onEdit(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  onDelete(message);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}