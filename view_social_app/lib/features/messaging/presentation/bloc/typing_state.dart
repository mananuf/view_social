import 'package:equatable/equatable.dart';

abstract class TypingState extends Equatable {
  const TypingState();

  @override
  List<Object?> get props => [];
}

class TypingInitial extends TypingState {
  const TypingInitial();
}

class TypingIndicatorState extends TypingState {
  final Map<String, Set<String>> typingUsers; // conversationId -> Set of userIds

  const TypingIndicatorState(this.typingUsers);

  @override
  List<Object> get props => [typingUsers];

  bool isUserTyping(String conversationId, String userId) {
    return typingUsers[conversationId]?.contains(userId) ?? false;
  }

  Set<String> getTypingUsers(String conversationId) {
    return typingUsers[conversationId] ?? {};
  }

  TypingIndicatorState copyWith({
    Map<String, Set<String>>? typingUsers,
  }) {
    return TypingIndicatorState(
      typingUsers ?? this.typingUsers,
    );
  }
}
