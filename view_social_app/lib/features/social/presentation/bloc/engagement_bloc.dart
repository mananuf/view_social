import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import 'engagement_event.dart';
import 'engagement_state.dart';

class EngagementBloc extends Bloc<EngagementEvent, EngagementState> {
  final ApiClient apiClient;

  EngagementBloc({required this.apiClient}) : super(const EngagementInitial()) {
    on<PostLikeToggled>(_onPostLikeToggled);
    on<CommentAdded>(_onCommentAdded);
    on<CommentsLoadRequested>(_onCommentsLoadRequested);
  }

  Future<void> _onPostLikeToggled(
    PostLikeToggled event,
    Emitter<EngagementState> emit,
  ) async {
    try {
      final response = await apiClient.dio.post('/posts/${event.postId}/like');

      final isLiked = response.data['is_liked'] as bool;
      final newLikeCount = response.data['like_count'] as int;

      emit(LikeToggleSuccess(
        postId: event.postId,
        isLiked: isLiked,
        newLikeCount: newLikeCount,
      ));
    } catch (e) {
      emit(EngagementError(_getErrorMessage(e)));
    }
  }

  Future<void> _onCommentAdded(
    CommentAdded event,
    Emitter<EngagementState> emit,
  ) async {
    emit(const EngagementLoading());
    try {
      final response =
          await apiClient.dio.post('/posts/${event.postId}/comments', data: {
        'content': event.content,
        if (event.replyToId != null) 'reply_to_id': event.replyToId,
      });

      final comment = Comment.fromJson(response.data);
      emit(CommentAddedSuccess(comment));
    } catch (e) {
      emit(EngagementError(_getErrorMessage(e)));
    }
  }

  Future<void> _onCommentsLoadRequested(
    CommentsLoadRequested event,
    Emitter<EngagementState> emit,
  ) async {
    emit(const EngagementLoading());
    try {
      final response =
          await apiClient.dio.get('/posts/${event.postId}/comments');

      final comments = (response.data['comments'] as List)
          .map((json) => Comment.fromJson(json))
          .toList();

      emit(CommentsLoaded(comments));
    } catch (e) {
      emit(EngagementError(_getErrorMessage(e)));
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Operation failed. Please try again.';
  }
}
