import 'package:equatable/equatable.dart';

abstract class EngagementEvent extends Equatable {
  const EngagementEvent();

  @override
  List<Object?> get props => [];
}

class PostLikeToggled extends EngagementEvent {
  final String postId;

  const PostLikeToggled(this.postId);

  @override
  List<Object> get props => [postId];
}

class CommentAdded extends EngagementEvent {
  final String postId;
  final String content;
  final String? replyToId;

  const CommentAdded({
    required this.postId,
    required this.content,
    this.replyToId,
  });

  @override
  List<Object?> get props => [postId, content, replyToId];
}

class CommentsLoadRequested extends EngagementEvent {
  final String postId;

  const CommentsLoadRequested(this.postId);

  @override
  List<Object> get props => [postId];
}
