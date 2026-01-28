import 'package:equatable/equatable.dart';
import '../../../../shared/models/post_model.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  final List<PostModel> posts;
  final bool hasMore;
  final int currentPage;

  const FeedLoaded({
    required this.posts,
    required this.hasMore,
    required this.currentPage,
  });

  @override
  List<Object> get props => [posts, hasMore, currentPage];

  FeedLoaded copyWith({
    List<PostModel>? posts,
    bool? hasMore,
    int? currentPage,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

class FeedLoadingMore extends FeedState {
  final List<PostModel> posts;
  final int currentPage;

  const FeedLoadingMore({
    required this.posts,
    required this.currentPage,
  });

  @override
  List<Object> get props => [posts, currentPage];
}

class FeedError extends FeedState {
  final String message;

  const FeedError(this.message);

  @override
  List<Object> get props => [message];
}
