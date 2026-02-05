import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../shared/widgets/search_bar_widget.dart';
import '../../data/datasources/messaging_remote_datasource.dart';
import '../../data/models/conversation_model.dart';
import '../widgets/chat_tile.dart';
import 'chat_detail_page.dart';
import 'user_search_page.dart';

class ChatsPage extends StatefulWidget {
  final MessagingRemoteDataSource messagingDataSource;
  final String currentUserId;

  const ChatsPage({
    super.key,
    required this.messagingDataSource,
    required this.currentUserId,
  });

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filteredConversations = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterConversations);
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final conversations = await widget.messagingDataSource.getConversations();
      setState(() {
        _conversations = conversations;
        _filteredConversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterConversations() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = List.from(_conversations);
      } else {
        _filteredConversations = _conversations.where((conv) {
          final displayName = conv
              .getDisplayName(widget.currentUserId)
              .toLowerCase();
          final lastMessage = conv.lastMessage?.content?.toLowerCase() ?? '';
          return displayName.contains(query) || lastMessage.contains(query);
        }).toList();
      }
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
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
        title: Text(
          'Messages',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.primary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: SearchBarWidget(
              hintText: 'Search chats...',
              controller: _searchController,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.space2xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: DesignTokens.spaceLg),
                          Text(
                            'Failed to load chats',
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
                            onPressed: _loadConversations,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _filteredConversations.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spaceLg),
                        Text(
                          _searchController.text.isEmpty
                              ? 'No chats yet'
                              : 'No chats found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280),
                          ),
                        ),
                        if (_searchController.text.isEmpty) ...[
                          const SizedBox(height: DesignTokens.spaceSm),
                          Text(
                            'Tap the + button to start a new chat',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadConversations,
                    child: ListView.builder(
                      itemCount: _filteredConversations.length,
                      itemBuilder: (context, index) {
                        final conversation = _filteredConversations[index];
                        final displayName = conversation.getDisplayName(
                          widget.currentUserId,
                        );
                        final lastMessage =
                            conversation.lastMessage?.content ??
                            'No messages yet';
                        final time = conversation.lastMessage != null
                            ? _formatTime(conversation.lastMessage!.createdAt)
                            : _formatTime(conversation.createdAt);

                        return ChatTile(
                          name: displayName,
                          lastMessage: lastMessage,
                          time: time,
                          unreadCount: conversation.unreadCount,
                          hasStatus: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailPage(
                                  conversationId: conversation.id,
                                  name: displayName,
                                  messagingDataSource:
                                      widget.messagingDataSource,
                                  currentUserId: widget.currentUserId,
                                  isOnline: false,
                                ),
                              ),
                            ).then((_) => _loadConversations());
                          },
                          onLongPress: () {},
                          onDelete: () {},
                          onArchive: () {},
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserSearchPage(
                messagingDataSource: widget.messagingDataSource,
                currentUserId: widget.currentUserId,
              ),
            ),
          ).then((_) => _loadConversations());
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
