import 'package:equatable/equatable.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class ConversationsLoadRequested extends ConversationEvent {
  const ConversationsLoadRequested();
}

class ConversationCreateRequested extends ConversationEvent {
  final List<String> participantIds;
  final String? groupName;

  const ConversationCreateRequested({
    required this.participantIds,
    this.groupName,
  });

  @override
  List<Object?> get props => [participantIds, groupName];
}

class ConversationUpdated extends ConversationEvent {
  final String conversationId;
  final Map<String, dynamic> updates;

  const ConversationUpdated({
    required this.conversationId,
    required this.updates,
  });

  @override
  List<Object> get props => [conversationId, updates];
}
