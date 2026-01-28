import 'package:equatable/equatable.dart';
import '../../../../shared/models/post_model.dart';

abstract class PostCreationState extends Equatable {
  const PostCreationState();

  @override
  List<Object?> get props => [];
}

class PostCreationInitial extends PostCreationState {
  const PostCreationInitial();
}

class PostCreationLoading extends PostCreationState {
  const PostCreationLoading();
}

class PostCreationSuccess extends PostCreationState {
  final PostModel post;

  const PostCreationSuccess(this.post);

  @override
  List<Object> get props => [post];
}

class PostCreationError extends PostCreationState {
  final String message;

  const PostCreationError(this.message);

  @override
  List<Object> get props => [message];
}
