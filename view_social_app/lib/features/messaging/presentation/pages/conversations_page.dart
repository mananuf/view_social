import 'package:flutter/material.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../core/theme/responsive.dart';
import '../widgets/conversation_tile.dart';
import 'chat_page.dart';

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final List<ConversationModel> _conversations = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadConversations();
  }
  
  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual API call with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      final conversations = _generateMockConversations();
      
      setState(() {
        _conversations.clear();
        _conversations.addAll(conversations);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load conversations: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _onRefresh() async {
    await _loadConversations();
  }
  
  List<ConversationModel> _generateMockConversations() {
    return List.generate(15, (index) {
      final user = UserModel(
        id: 'user_$index',
        username: 'user$index',
        email: 'user$index@example.com',
        displayName: 'User $index',
        avatarUrl: null,
        isVerified: index % 5 == 0,
        followerCount: index * 100,
        followingCount: index * 50,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      );
      
      final lastMessage = MessageModel(
        id: 'msg_$index',
        conversationId: 'conv_$index',
        senderId: index % 2 == 0 ? 'current_user' : user.id,
        sender: index % 2 == 0 ? null : user,
        messageType: _getRandomMessageType(index),
        content: _getRandomMessageContent(index),
        paymentData: index % 10 == 0 ? PaymentData(
          transactionId: 'tx_$index',
          amount: (index + 1) * 100.0,
          currency: 'NGN',
          status: 'completed',
        ) : null,
        replyToId: null,
        replyToMessage: null,
        isRead: index % 3 != 0,
        createdAt: DateTime.now().subtract(Duration(minutes: index * 15)),
      );
      
      return ConversationModel(
        id: 'conv_$index',
        participants: [user],
        lastMessage: lastMessage,
        unreadCount: index % 3 == 0 ? index % 5 : 0,
        isGroup: false,
        createdAt: DateTime.now().subtract(Duration(days: index)),
      );
    });
  }
  
  MessageType _getRandomMessageType(int index) {
    final types = [MessageType.text, MessageType.image, MessageType.payment];
    return types[index % types.length];
  }
  
  String _getRandomMessageContent(int index) {
    final contents = [
      'Hey! How are you doing?',
      'Thanks for the help earlier 😊',
      'Are we still on for tomorrow?',
      'Just sent you the payment',
      'Check out this cool photo!',
      'Let\'s catch up soon',
      'Happy birthday! 🎉',
      'Good morning!',
      'See you later',
      'Thanks!',
    ];
    
    return contents[index % contents.length];
  }
  
  void _navigateToChat(ConversationModel conversation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversation: conversation,
        ),
      ),
    );
  }
  
  void _startNewConversation() {
    // TODO: Navigate to user selection page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New conversation feature coming soon!'),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _startNewConversation,
          ),
        ],
      ),
      body: _isLoading && _conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _conversations.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.isMobile(context) ? 0 : 16,
                    ),
                    itemCount: _conversations.length,
                    itemBuilder: (context, index) {
                      return ConversationTile(
                        conversation: _conversations[index],
                        onTap: () => _navigateToChat(_conversations[index]),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startNewConversation,
        child: const Icon(Icons.chat),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: Responsive.getPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with someone!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Conversation Model for UI
class ConversationModel {
  final String id;
  final List<UserModel> participants;
  final MessageModel? lastMessage;
  final int unreadCount;
  final bool isGroup;
  final DateTime createdAt;
  
  ConversationModel({
    required this.id,
    required this.participants,
    this.lastMessage,
    required this.unreadCount,
    required this.isGroup,
    required this.createdAt,
  });
}