import 'package:equatable/equatable.dart';

abstract class TypingEvent extends Equatable {
  const TypingEvent();

  @override
  List<Object?> get props => [];
}

class TypingStarted extends TypingEvent {
  final String conversationId;

  const TypingStarted(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class TypingStopped extends TypingEvent {
  final String conversationId;

  const TypingStopped(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class TypingIndicatorReceived extends TypingEvent {
  final String conversationId;
  final String userId;
  final bool isTyping;

  const TypingIndicatorReceived({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  @override
  List<Object> get props => [conversationId, userId, isTyping];
}
