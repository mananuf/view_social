import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/websocket_client.dart';
import '../../../../shared/models/message_model.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiClient apiClient;
  final WebSocketClient webSocketClient;
  StreamSubscription? _wsSubscription;

  ChatBloc({
    required this.apiClient,
    required this.webSocketClient,
  }) : super(const ChatInitial()) {
    on<ChatOpened>(_onChatOpened);
    on<ChatMessagesLoadRequested>(_onChatMessagesLoadRequested);
    on<ChatMessageSent>(_onChatMessageSent);
    on<ChatMessageReceived>(_onChatMessageReceived);
    on<ChatMessageRead>(_onChatMessageRead);
    on<ChatClosed>(_onChatClosed);
  }

  Future<void> _onChatOpened(
    ChatOpened event,
    Emitter<ChatState> emit,
  ) async {
    emit(const ChatLoading());

    // Subscribe to WebSocket messages
    _wsSubscription = webSocketClient.messageStream.listen((data) {
      if (data['type'] == 'message_sent' &&
          data['conversation_id'] == event.conversationId) {
        final message = MessageModel.fromJson(data['message']);
        add(ChatMessageReceived(message));
      }
    });

    // Load initial messages
    add(ChatMessagesLoadRequested(conversationId: event.conversationId));
  }

  Future<void> _onChatMessagesLoadRequested(
    ChatMessagesLoadRequested event,
    Emitter<ChatState> emit,
  ) async {
    if (state is ChatLoaded && event.beforeId != null) {
      final currentState = state as ChatLoaded;
      emit(ChatLoadingMore(
        conversationId: currentState.conversationId,
        messages: currentState.messages,
      ));
    } else {
      emit(const ChatLoading());
    }

    try {
      final response = await apiClient.dio.get(
        '/conversations/${event.conversationId}/messages',
        queryParameters: {
          'limit': 50,
          if (event.beforeId != null) 'before_id': event.beforeId,
        },
      );

      final newMessages = (response.data['messages'] as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      List<MessageModel> allMessages;
      if (state is ChatLoaded || state is ChatLoadingMore) {
        final currentMessages = state is ChatLoaded
            ? (state as ChatLoaded).messages
            : (state as ChatLoadingMore).messages;
        allMessages = [...currentMessages, ...newMessages];
      } else {
        allMessages = newMessages;
      }

      final hasMore = newMessages.length >= 50;

      emit(ChatLoaded(
        conversationId: event.conversationId,
        messages: allMessages,
        hasMore: hasMore,
      ));
    } catch (e) {
      emit(ChatError(_getErrorMessage(e)));
    }
  }

  Future<void> _onChatMessageSent(
    ChatMessageSent event,
    Emitter<ChatState> emit,
  ) async {
    if (state is! ChatLoaded) return;

    final currentState = state as ChatLoaded;
    emit(ChatMessageSending(
      conversationId: currentState.conversationId,
      messages: currentState.messages,
    ));

    try {
      final response = await apiClient.dio.post(
        '/conversations/${event.conversationId}/messages',
        data: {
          'content': event.content,
          'message_type': event.messageType.name,
          if (event.mediaUrl != null) 'media_url': event.mediaUrl,
          if (event.replyToId != null) 'reply_to_id': event.replyToId,
        },
      );

      final message = MessageModel.fromJson(response.data);

      emit(ChatLoaded(
        conversationId: currentState.conversationId,
        messages: [message, ...currentState.messages],
        hasMore: currentState.hasMore,
      ));
    } catch (e) {
      emit(ChatError(_getErrorMessage(e)));
      // Restore previous state
      emit(currentState);
    }
  }

  void _onChatMessageReceived(
    ChatMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Check if message already exists
      final exists = currentState.messages.any((m) => m.id == event.message.id);
      if (exists) return;

      emit(currentState.copyWith(
        messages: [event.message, ...currentState.messages],
      ));

      // Mark message as read
      add(ChatMessageRead(event.message.id));
    }
  }

  Future<void> _onChatMessageRead(
    ChatMessageRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await apiClient.dio.post('/messages/${event.messageId}/read');
    } catch (e) {
      // Silently fail - read receipts are not critical
    }
  }

  void _onChatClosed(
    ChatClosed event,
    Emitter<ChatState> emit,
  ) {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    emit(const ChatInitial());
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to send message. Please try again.';
  }
}
