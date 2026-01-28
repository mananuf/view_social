import 'package:equatable/equatable.dart';
import '../../../../shared/models/message_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final String conversationId;
  final List<MessageModel> messages;
  final bool hasMore;

  const ChatLoaded({
    required this.conversationId,
    required this.messages,
    required this.hasMore,
  });

  @override
  List<Object> get props => [conversationId, messages, hasMore];

  ChatLoaded copyWith({
    String? conversationId,
    List<MessageModel>? messages,
    bool? hasMore,
  }) {
    return ChatLoaded(
      conversationId: conversationId ?? this.conversationId,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ChatLoadingMore extends ChatState {
  final String conversationId;
  final List<MessageModel> messages;

  const ChatLoadingMore({
    required this.conversationId,
    required this.messages,
  });

  @override
  List<Object> get props => [conversationId, messages];
}

class ChatMessageSending extends ChatState {
  final String conversationId;
  final List<MessageModel> messages;

  const ChatMessageSending({
    required this.conversationId,
    required this.messages,
  });

  @override
  List<Object> get props => [conversationId, messages];
}

class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
