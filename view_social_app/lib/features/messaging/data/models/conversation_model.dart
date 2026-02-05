import '../../../../shared/models/user_model.dart';
import 'message_model.dart';

class ConversationModel {
  final String id;
  final List<UserModel> participants;
  final bool isGroup;
  final String? groupName;
  final MessageModel? lastMessage;
  final int unreadCount;
  final DateTime createdAt;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.isGroup,
    this.groupName,
    this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      participants: (json['participants'] as List)
          .map((p) => UserModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      isGroup: json['is_group'] as bool,
      groupName: json['group_name'] as String?,
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participants': participants.map((p) => p.toJson()).toList(),
      'is_group': isGroup,
      'group_name': groupName,
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Get the other user in a direct conversation
  UserModel? getOtherUser(String currentUserId) {
    if (isGroup) return null;
    return participants.firstWhere(
      (p) => p.id != currentUserId,
      orElse: () => participants.first,
    );
  }

  // Get conversation display name
  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return groupName ?? 'Group Chat';
    }
    final otherUser = getOtherUser(currentUserId);
    return otherUser?.displayName ?? otherUser?.username ?? 'Unknown';
  }
}
