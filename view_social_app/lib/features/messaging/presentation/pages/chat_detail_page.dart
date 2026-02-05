import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/message_bubble.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/models/message_model.dart';

class ChatDetailPage extends StatefulWidget {
  final String conversationId;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final MessagingRemoteDataSource messagingDataSource;
  final String currentUserId;

  const ChatDetailPage({
    super.key,
    required this.conversationId,
    required this.name,
    required this.messagingDataSource,
    required this.currentUserId,
    this.avatarUrl,
    this.isOnline = false,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFab = false;
  bool _isLoading = true;
  List<MessageModel> _messages = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final messages = await widget.messagingDataSource.getMessages(
        widget.conversationId,
        limit: 50,
      );

      setState(() {
        _messages = messages.reversed.toList(); // Reverse to show oldest first
        _isLoading = false;
      });

      // Scroll to bottom after loading
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final showFab = _scrollController.offset > 100;
      if (showFab != _showFab) {
        setState(() {
          _showFab = showFab;
        });
      }
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final sentMessage = await widget.messagingDataSource.sendMessage(
        widget.conversationId,
        messageText,
        messageType: 'text',
      );

      setState(() {
        _messages.add(sentMessage);
      });

      // Scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: DesignTokens.animationNormal,
            curve: DesignTokens.curveEaseOut,
          );
        }
      });
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      // Restore message text
      _messageController.text = messageText;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM d, HH:mm').format(dateTime);
    }
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DesignTokens.radius3xl),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: DesignTokens.spaceMd),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF4B5563)
                      : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: DesignTokens.space2xl),
              _buildOptionTile(
                icon: Icons.payment,
                title: 'Send Payment',
                subtitle: 'Quick money transfer',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment feature coming soon'),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.attach_file,
                title: 'Send File',
                subtitle: 'Share documents and media',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File sharing coming soon')),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.location_on,
                title: 'Share Location',
                subtitle: 'Send your current location',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Location sharing coming soon'),
                    ),
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.auto_awesome,
                title: 'AI Assistant',
                subtitle: 'Get AI-powered suggestions',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI features coming soon')),
                  );
                },
              ),
              const SizedBox(height: DesignTokens.spaceLg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        ),
        child: Icon(icon, color: theme.colorScheme.primary),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(
                    0xFF6A0DAD,
                  ).withValues(alpha: 0.1),
                  child: widget.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            widget.avatarUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 24,
                                color: theme.colorScheme.primary,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1A1A1A)
                              : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: DesignTokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isOnline ? 'Online' : 'Offline',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.isOnline
                          ? const Color(0xFF10B981)
                          : (isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280)),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Voice call coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video call coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: const Color(0xFFEF4444),
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        Text(
                          'Failed to load messages',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        ElevatedButton(
                          onPressed: _loadMessages,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark
                              ? const Color(0xFF4B5563)
                              : const Color(0xFFD1D5DB),
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        Text(
                          'No messages yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(
                          'Start the conversation!',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.spaceLg,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isSent = message.sender?.id == widget.currentUserId;

                      return MessageBubble(
                        message: message.content ?? '',
                        time: _formatTime(message.createdAt),
                        isSent: isSent,
                        isRead: message.isRead,
                      );
                    },
                  ),
          ),
          // Input area
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceMd),
                child: Row(
                  children: [
                    // Voice input button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A0DAD), Color(0xFFA500E0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusLg,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.mic, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Voice input coming soon'),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceMd),
                    // Text input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(
                            DesignTokens.radius2xl,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Write now...',
                            hintStyle: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceLg,
                              vertical: DesignTokens.spaceMd,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceMd),
                    // Send button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6A0DAD), Color(0xFFA500E0)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          DesignTokens.radiusLg,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedScale(
        scale: _showFab ? 1.0 : 0.0,
        duration: DesignTokens.animationNormal,
        curve: DesignTokens.curveEaseOut,
        child: FloatingActionButton(
          onPressed: _showOptionsMenu,
          backgroundColor: theme.colorScheme.primary,
          child: const Icon(Icons.auto_awesome, color: Colors.white),
        ),
      ),
    );
  }
}
