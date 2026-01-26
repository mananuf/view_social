import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../shared/models/message_model.dart';
import '../../../../core/theme/responsive.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../pages/conversations_page.dart';

class ChatPage extends StatefulWidget {
  final ConversationModel conversation;
  
  const ChatPage({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;
  bool _otherUserTyping = false;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _simulateTypingIndicator();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Implement actual API call with BLoC
      await Future.delayed(const Duration(seconds: 1));
      
      final messages = _generateMockMessages();
      
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  List<MessageModel> _generateMockMessages() {
    final otherUser = widget.conversation.participants.first;
    
    return List.generate(20, (index) {
      final isFromCurrentUser = index % 3 != 0;
      
      return MessageModel(
        id: 'msg_${widget.conversation.id}_$index',
        conversationId: widget.conversation.id,
        senderId: isFromCurrentUser ? 'current_user' : otherUser.id,
        sender: isFromCurrentUser ? null : otherUser,
        messageType: _getRandomMessageType(index),
        content: _getRandomMessageContent(index, isFromCurrentUser),
        paymentData: index == 5 ? PaymentData(
          transactionId: 'tx_$index',
          amount: 5000.0,
          currency: 'NGN',
          status: 'completed',
        ) : null,
        replyToId: null,
        replyToMessage: null,
        isRead: true,
        createdAt: DateTime.now().subtract(Duration(hours: 20 - index)),
      );
    }).reversed.toList();
  }
  
  MessageType _getRandomMessageType(int index) {
    if (index == 5) return MessageType.payment;
    if (index % 7 == 0) return MessageType.image;
    return MessageType.text;
  }
  
  String _getRandomMessageContent(int index, bool isFromCurrentUser) {
    final currentUserMessages = [
      'Hey! How are you?',
      'Thanks for your help',
      'Are we still meeting tomorrow?',
      'Let me know when you\'re free',
      'That sounds great!',
      'I\'ll send the payment now',
      'Perfect, thanks!',
      'See you soon',
      'Have a great day!',
      'Talk to you later',
    ];
    
    final otherUserMessages = [
      'Hi there! I\'m doing well, thanks',
      'No problem at all!',
      'Yes, definitely. Same time?',
      'I\'m free this afternoon',
      'Awesome, looking forward to it',
      'Payment received, thank you!',
      'You\'re welcome!',
      'See you then',
      'You too!',
      'Bye for now',
    ];
    
    final messages = isFromCurrentUser ? currentUserMessages : otherUserMessages;
    return messages[index % messages.length];
  }
  
  void _simulateTypingIndicator() {
    // Simulate other user typing occasionally
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _otherUserTyping = true;
        });
        
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _otherUserTyping = false;
            });
          }
        });
      }
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _sendMessage(String content, {MessageType type = MessageType.text}) async {
    if (content.trim().isEmpty && type == MessageType.text) return;
    
    final newMessage = MessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: 'current_user',
      sender: null,
      messageType: type,
      content: content,
      paymentData: null,
      replyToId: null,
      replyToMessage: null,
      isRead: false,
      createdAt: DateTime.now(),
    );
    
    setState(() {
      _messages.add(newMessage);
    });
    
    _messageController.clear();
    _scrollToBottom();
    
    // TODO: Implement actual message sending with BLoC
    try {
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      
      // Update message as sent
      setState(() {
        final index = _messages.indexWhere((m) => m.id == newMessage.id);
        if (index != -1) {
          _messages[index] = newMessage.copyWith(
            id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
            isRead: true,
          );
        }
      });
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _sendImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _sendMessage('Photo', type: MessageType.image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _sendPayment() async {
    // TODO: Navigate to payment screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment feature coming soon!'),
      ),
    );
  }
  
  void _onTypingChanged(bool isTyping) {
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      
      // TODO: Send typing indicator via WebSocket
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherUser = widget.conversation.participants.first;
    
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Text(
                otherUser.displayName?.substring(0, 1).toUpperCase() ??
                    otherUser.username.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    otherUser.displayName ?? otherUser.username,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: Responsive.getFontSize(context, 16),
                    ),
                  ),
                  Text(
                    _otherUserTyping ? 'typing...' : 'online',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: Responsive.getFontSize(context, 12),
                      color: _otherUserTyping 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.6),
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
            onPressed: () {
              // TODO: Start video call
            },
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Start voice call
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Show chat options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.isMobile(context) ? 8 : 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length + (_otherUserTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        // Typing indicator
                        return const TypingIndicator();
                      }
                      
                      final message = _messages[index];
                      final isFromCurrentUser = message.senderId == 'current_user';
                      
                      return MessageBubble(
                        message: message,
                        isFromCurrentUser: isFromCurrentUser,
                        showAvatar: !isFromCurrentUser,
                      );
                    },
                  ),
          ),
          
          // Chat Input
          ChatInput(
            controller: _messageController,
            onSendMessage: (content) => _sendMessage(content),
            onSendImage: _sendImage,
            onSendPayment: _sendPayment,
            onTypingChanged: _onTypingChanged,
          ),
        ],
      ),
    );
  }
}