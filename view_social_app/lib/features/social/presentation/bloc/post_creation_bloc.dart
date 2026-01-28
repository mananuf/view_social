import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/post_model.dart';
import 'post_creation_event.dart';
import 'post_creation_state.dart';

class PostCreationBloc extends Bloc<PostCreationEvent, PostCreationState> {
  final ApiClient apiClient;

  PostCreationBloc({required this.apiClient})
      : super(const PostCreationInitial()) {
    on<PostCreateRequested>(_onPostCreateRequested);
    on<PostCreationReset>(_onPostCreationReset);
  }

  Future<void> _onPostCreateRequested(
    PostCreateRequested event,
    Emitter<PostCreationState> emit,
  ) async {
    emit(const PostCreationLoading());
    try {
      final response = await apiClient.dio.post('/posts', data: {
        if (event.textContent != null) 'text_content': event.textContent,
        'media_urls': event.mediaUrls,
        'content_type': event.contentType.name,
        'is_reel': event.isReel,
        'visibility': event.visibility.name,
      });

      final post = PostModel.fromJson(response.data);
      emit(PostCreationSuccess(post));
    } catch (e) {
      emit(PostCreationError(_getErrorMessage(e)));
    }
  }

  void _onPostCreationReset(
    PostCreationReset event,
    Emitter<PostCreationState> emit,
  ) {
    emit(const PostCreationInitial());
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('DioException')) {
      return 'Network error. Please check your connection.';
    }
    return 'Failed to create post. Please try again.';
  }
}
