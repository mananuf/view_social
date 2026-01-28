import 'package:equatable/equatable.dart';
import '../../../../shared/models/post_model.dart';

abstract class PostCreationEvent extends Equatable {
  const PostCreationEvent();

  @override
  List<Object?> get props => [];
}

class PostCreateRequested extends PostCreationEvent {
  final String? textContent;
  final List<String> mediaUrls;
  final PostContentType contentType;
  final bool isReel;
  final PostVisibility visibility;

  const PostCreateRequested({
    this.textContent,
    required this.mediaUrls,
    required this.contentType,
    required this.isReel,
    required this.visibility,
  });

  @override
  List<Object?> get props => [
        textContent,
        mediaUrls,
        contentType,
        isReel,
        visibility,
      ];
}

class PostCreationReset extends PostCreationEvent {
  const PostCreationReset();
}
