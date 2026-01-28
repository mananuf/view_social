import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/post_model.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final ApiClient apiClient;

  FeedBloc({required this.apiClient}) : super(const FeedInitial()) {
    on<FeedLoadRequested>(_onFeedLoadRequested);
    on<FeedRefreshRequested>(_onFeedRefreshRequested);
    on<FeedLoadMoreRequested>(_onFeedLoadMoreRequested);
  }

  Future<void> _onFeedLoadRequested(
    FeedLoadRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(const FeedLoading());
    try {
      final response = await apiClient.dio.get('/posts/feed', queryParameters: {
        'limit': AppConstants.defaultPageSize,
        'offset': 0,
      });

      final posts = (response.data['posts'] as List)
          .map((json) => PostModel.fromJson(json))
          .toList();

      final hasMore = posts.length >= AppConstants.defaultPageSize;

      emit(FeedLoaded(
        posts: posts,
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(FeedError(_getErrorMessage(e)));
    }
  }

  Future<void> _onFeedRefreshRequested(
    FeedRefreshRequested event,
    Emitter<FeedState> emit,
  ) async {
    try {
      final response = await apiClient.dio.get('/posts/feed', queryParameters: {
        'limit': AppConstants.defaultPageSize,
        'offset': 0,
      });

      final posts = (response.data['posts'] as List)
          .map((json) => PostModel.fromJson(json))
          .toList();

      final hasMore = posts.length >= AppConstants.defaultPageSize;

      emit(FeedLoaded(
        posts: posts,
        hasMore: hasMore,
        currentPage: 1,
      ));
    } catch (e) {
      emit(FeedError(_getErrorMessage(e)));
    }
  }

  Future<void> _onFeedLoadMoreRequested(
    FeedLoadMoreRequested event,
    Emitter<FeedState> emit,
  ) async {
    if (state is! FeedLoaded) return;

    final currentState = state as FeedLoaded;
    if (!currentState.hasMore) return;

    emit(FeedLoadingMore(
      posts: currentState.posts,
      currentPage: currentState.currentPage,
    ));

    try {
      final offset = currentState.currentPage * AppConstants.defaultPageSize;
      final response = await apiClient.dio.get('/posts/feed', queryParameters: {
        'limit': AppConstants.defaultPageSize,
        'offset': offset,
      });

      final newPosts = (response.data['posts'] as List)
          .map((json) => PostModel.fromJson(json))
          .toList();

      final allPosts = [...currentState.posts, ...newPosts];
      final hasMore = newPosts.length >= AppConstants.defaultPageSize;

      emit(FeedLoaded(
        posts: allPosts,
        hasMore: hasMore,
        currentPage: currentState.currentPage + 1,
      ));
    } catch (e) {
      emit(currentState);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to load feed. Please try again.';
  }
}
