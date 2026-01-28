import 'package:equatable/equatable.dart';
import '../../../../shared/models/user_model.dart';

class ConversationModel extends Equatable {
  final String id;
  final List<UserModel> participants;
  final String? groupName;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.participants,
    this.groupName,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participants: (json['participants'] as List)
          .map((p) => UserModel.fromJson(p))
          .toList(),
      groupName: json['group_name'] as String?,
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCount: json['unread_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  ConversationModel copyWith({
    String? id,
    List<UserModel>? participants,
    String? groupName,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int? unreadCount,
    DateTime? createdAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participants: participants ?? this.participants,
      groupName: groupName ?? this.groupName,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        participants,
        groupName,
        lastMessageContent,
        lastMessageAt,
        unreadCount,
        createdAt,
      ];
}

abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {
  const ConversationInitial();
}

class ConversationLoading extends ConversationState {
  const ConversationLoading();
}

class ConversationsLoaded extends ConversationState {
  final List<ConversationModel> conversations;

  const ConversationsLoaded(this.conversations);

  @override
  List<Object> get props => [conversations];

  ConversationsLoaded copyWith({
    List<ConversationModel>? conversations,
  }) {
    return ConversationsLoaded(
      conversations ?? this.conversations,
    );
  }
}

class ConversationCreated extends ConversationState {
  final ConversationModel conversation;

  const ConversationCreated(this.conversation);

  @override
  List<Object> get props => [conversation];
}

class ConversationError extends ConversationState {
  final String message;

  const ConversationError(this.message);

  @override
  List<Object> get props => [message];
}
