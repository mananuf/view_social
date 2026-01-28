import 'package:equatable/equatable.dart';
import '../../../../shared/models/message_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatOpened extends ChatEvent {
  final String conversationId;

  const ChatOpened(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class ChatMessagesLoadRequested extends ChatEvent {
  final String conversationId;
  final String? beforeId;

  const ChatMessagesLoadRequested({
    required this.conversationId,
    this.beforeId,
  });

  @override
  List<Object?> get props => [conversationId, beforeId];
}

class ChatMessageSent extends ChatEvent {
  final String conversationId;
  final String content;
  final MessageType messageType;
  final String? mediaUrl;
  final String? replyToId;

  const ChatMessageSent({
    required this.conversationId,
    required this.content,
    required this.messageType,
    this.mediaUrl,
    this.replyToId,
  });

  @override
  List<Object?> get props => [
        conversationId,
        content,
        messageType,
        mediaUrl,
        replyToId,
      ];
}

class ChatMessageReceived extends ChatEvent {
  final MessageModel message;

  const ChatMessageReceived(this.message);

  @override
  List<Object> get props => [message];
}

class ChatMessageRead extends ChatEvent {
  final String messageId;

  const ChatMessageRead(this.messageId);

  @override
  List<Object> get props => [messageId];
}

class ChatClosed extends ChatEvent {
  const ChatClosed();
}
