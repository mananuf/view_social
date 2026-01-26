import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../core/theme/responsive.dart';
import '../pages/conversations_page.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;
  
  const ConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherUser = conversation.participants.first;
    
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(
        horizontal: Responsive.isMobile(context) ? 16 : 20,
        vertical: 8,
      ),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
            backgroundImage: otherUser.avatarUrl != null
                ? CachedNetworkImageProvider(otherUser.avatarUrl!)
                : null,
            child: otherUser.avatarUrl == null
                ? Text(
                    otherUser.displayName?.substring(0, 1).toUpperCase() ??
                        otherUser.username.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : null,
          ),
          
          // Online indicator (mock)
          if (conversation.id.hashCode % 3 == 0)
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUser.displayName ?? otherUser.username,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: conversation.unreadCount > 0 
                    ? FontWeight.w600 
                    : FontWeight.w500,
                fontSize: Responsive.getFontSize(context, 16),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (otherUser.isVerified)
            Icon(
              Icons.verified,
              size: 16,
              color: theme.colorScheme.primary,
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: _buildLastMessagePreview(context, theme),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(conversation.lastMessage?.createdAt ?? conversation.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: conversation.unreadCount > 0
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                  fontSize: Responsive.getFontSize(context, 12),
                  fontWeight: conversation.unreadCount > 0 
                      ? FontWeight.w600 
                      : FontWeight.normal,
                ),
              ),
              if (conversation.unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    conversation.unreadCount > 99 
                        ? '99+' 
                        : conversation.unreadCount.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.getFontSize(context, 10),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildLastMessagePreview(BuildContext context, ThemeData theme) {
    final lastMessage = conversation.lastMessage;
    
    if (lastMessage == null) {
      return Text(
        'No messages yet',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: Responsive.getFontSize(context, 14),
        ),
      );
    }
    
    String prefix = '';
    String content = '';
    IconData? icon;
    
    // Add "You: " prefix if current user sent the message
    if (lastMessage.senderId == 'current_user') {
      prefix = 'You: ';
    }
    
    switch (lastMessage.messageType) {
      case MessageType.text:
        content = lastMessage.content ?? '';
        break;
      case MessageType.image:
        content = 'Photo';
        icon = Icons.image;
        break;
      case MessageType.video:
        content = 'Video';
        icon = Icons.videocam;
        break;
      case MessageType.voice:
        content = 'Voice message';
        icon = Icons.mic;
        break;
      case MessageType.payment:
        final amount = lastMessage.paymentData?.amount ?? 0;
        content = 'Payment: ₦${amount.toStringAsFixed(0)}';
        icon = Icons.payment;
        break;
      case MessageType.system:
        content = lastMessage.content ?? 'System message';
        break;
    }
    
    return Row(
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            '$prefix$content',
            style: theme.textTheme.bodySmall?.copyWith(
              color: conversation.unreadCount > 0
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontSize: Responsive.getFontSize(context, 14),
              fontWeight: conversation.unreadCount > 0 
                  ? FontWeight.w500 
                  : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Read status indicator for sent messages
        if (lastMessage.senderId == 'current_user') ...[
          const SizedBox(width: 4),
          Icon(
            lastMessage.isRead ? Icons.done_all : Icons.done,
            size: 16,
            color: lastMessage.isRead 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ],
      ],
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}