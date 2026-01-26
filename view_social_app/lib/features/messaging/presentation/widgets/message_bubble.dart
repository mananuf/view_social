import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../core/theme/responsive.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isFromCurrentUser;
  final bool showAvatar;
  
  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    this.showAvatar = true,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && showAvatar) ...[
            _buildAvatar(theme),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: Column(
                crossAxisAlignment: isFromCurrentUser 
                    ? CrossAxisAlignment.end 
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(context, theme),
                  const SizedBox(height: 2),
                  _buildMessageInfo(context, theme),
                ],
              ),
            ),
          ),
          
          if (isFromCurrentUser && showAvatar) ...[
            const SizedBox(width: 8),
            _buildAvatar(theme),
          ],
        ],
      ),
    );
  }
  
  Widget _buildAvatar(ThemeData theme) {
    if (!showAvatar || isFromCurrentUser) {
      return const SizedBox(width: 32);
    }
    
    return CircleAvatar(
      radius: 16,
      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
      backgroundImage: message.sender?.avatarUrl != null
          ? CachedNetworkImageProvider(message.sender!.avatarUrl!)
          : null,
      child: message.sender?.avatarUrl == null
          ? Text(
              message.sender?.displayName?.substring(0, 1).toUpperCase() ??
                  message.sender?.username.substring(0, 1).toUpperCase() ??
                  'U',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            )
          : null,
    );
  }
  
  Widget _buildMessageContent(BuildContext context, ThemeData theme) {
    switch (message.messageType) {
      case MessageType.text:
        return _buildTextMessage(context, theme);
      case MessageType.image:
        return _buildImageMessage(context, theme);
      case MessageType.video:
        return _buildVideoMessage(context, theme);
      case MessageType.voice:
        return _buildVoiceMessage(context, theme);
      case MessageType.payment:
        return _buildPaymentMessage(context, theme);
      case MessageType.system:
        return _buildSystemMessage(context, theme);
    }
  }
  
  Widget _buildTextMessage(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isFromCurrentUser 
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: isFromCurrentUser 
              ? const Radius.circular(4) 
              : const Radius.circular(18),
          bottomLeft: !isFromCurrentUser 
              ? const Radius.circular(4) 
              : const Radius.circular(18),
        ),
        border: !isFromCurrentUser ? Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ) : null,
      ),
      child: Text(
        message.content ?? '',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isFromCurrentUser 
              ? Colors.white 
              : theme.colorScheme.onSurface,
          fontSize: Responsive.getFontSize(context, 16),
        ),
      ),
    );
  }
  
  Widget _buildImageMessage(BuildContext context, ThemeData theme) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: message.mediaUrl != null
            ? CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.error),
                ),
              )
            : const Center(
                child: Icon(Icons.image, size: 48),
              ),
      ),
    );
  }
  
  Widget _buildVideoMessage(BuildContext context, ThemeData theme) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (message.mediaUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(25),
            ),
            child: const Icon(
              Icons.play_arrow,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildVoiceMessage(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isFromCurrentUser 
            ? theme.colorScheme.primary
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: !isFromCurrentUser ? Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.play_arrow,
            color: isFromCurrentUser 
                ? Colors.white 
                : theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: (isFromCurrentUser ? Colors.white : theme.colorScheme.primary)
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 2,
                color: isFromCurrentUser 
                    ? Colors.white 
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '0:15',
            style: TextStyle(
              color: isFromCurrentUser 
                  ? Colors.white 
                  : theme.colorScheme.onSurface,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentMessage(BuildContext context, ThemeData theme) {
    final paymentData = message.paymentData!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.payment,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isFromCurrentUser ? 'Payment Sent' : 'Payment Received',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₦${paymentData.amount.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPaymentStatusColor(paymentData.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              paymentData.status.toUpperCase(),
              style: TextStyle(
                color: _getPaymentStatusColor(paymentData.status),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSystemMessage(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.content ?? '',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.6),
          fontSize: Responsive.getFontSize(context, 12),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildMessageInfo(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTime(message.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            fontSize: Responsive.getFontSize(context, 11),
          ),
        ),
        
        if (isFromCurrentUser) ...[
          const SizedBox(width: 4),
          Icon(
            message.isRead ? Icons.done_all : Icons.done,
            size: 14,
            color: message.isRead 
                ? theme.colorScheme.primary 
                : theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ],
      ],
    );
  }
  
  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (messageDate == today) {
      // Today - show time
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}