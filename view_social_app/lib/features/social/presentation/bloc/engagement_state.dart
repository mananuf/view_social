import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final String? replyToId;
  final int likeCount;
  final DateTime createdAt;

  const Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.replyToId,
    required this.likeCount,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      postId: json['post_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      replyToId: json['reply_to_id'] as String?,
      likeCount: json['like_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        postId,
        userId,
        content,
        replyToId,
        likeCount,
        createdAt,
      ];
}

abstract class EngagementState extends Equatable {
  const EngagementState();

  @override
  List<Object?> get props => [];
}

class EngagementInitial extends EngagementState {
  const EngagementInitial();
}

class EngagementLoading extends EngagementState {
  const EngagementLoading();
}

class LikeToggleSuccess extends EngagementState {
  final String postId;
  final bool isLiked;
  final int newLikeCount;

  const LikeToggleSuccess({
    required this.postId,
    required this.isLiked,
    required this.newLikeCount,
  });

  @override
  List<Object> get props => [postId, isLiked, newLikeCount];
}

class CommentAddedSuccess extends EngagementState {
  final Comment comment;

  const CommentAddedSuccess(this.comment);

  @override
  List<Object> get props => [comment];
}

class CommentsLoaded extends EngagementState {
  final List<Comment> comments;

  const CommentsLoaded(this.comments);

  @override
  List<Object> get props => [comments];
}

class EngagementError extends EngagementState {
  final String message;

  const EngagementError(this.message);

  @override
  List<Object> get props => [message];
}
