import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum PostContentType { text, image, video, mixed }
enum PostVisibility { public, followers, private }

class MediaAttachment extends Equatable {
  final String url;
  final String type; // 'image' or 'video'
  final String? thumbnailUrl;
  
  const MediaAttachment({
    required this.url,
    required this.type,
    this.thumbnailUrl,
  });
  
  factory MediaAttachment.fromJson(Map<String, dynamic> json) {
    return MediaAttachment(
      url: json['url'] as String,
      type: json['type'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type,
      'thumbnail_url': thumbnailUrl,
    };
  }
  
  @override
  List<Object?> get props => [url, type, thumbnailUrl];
}

class PostModel extends Equatable {
  final String id;
  final String userId;
  final UserModel? user;
  final PostContentType contentType;
  final String? textContent;
  final List<MediaAttachment> mediaUrls;
  final bool isReel;
  final PostVisibility visibility;
  final int likeCount;
  final int commentCount;
  final int reshareCount;
  final bool isLiked;
  final DateTime createdAt;
  
  const PostModel({
    required this.id,
    required this.userId,
    this.user,
    required this.contentType,
    this.textContent,
    required this.mediaUrls,
    required this.isReel,
    required this.visibility,
    required this.likeCount,
    required this.commentCount,
    required this.reshareCount,
    required this.isLiked,
    required this.createdAt,
  });
  
  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      contentType: PostContentType.values.firstWhere(
        (e) => e.name == json['content_type'],
        orElse: () => PostContentType.text,
      ),
      textContent: json['text_content'] as String?,
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => MediaAttachment.fromJson(e))
              .toList() ??
          [],
      isReel: json['is_reel'] as bool,
      visibility: PostVisibility.values.firstWhere(
        (e) => e.name == json['visibility'],
        orElse: () => PostVisibility.public,
      ),
      likeCount: json['like_count'] as int,
      commentCount: json['comment_count'] as int,
      reshareCount: json['reshare_count'] as int,
      isLiked: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user': user?.toJson(),
      'content_type': contentType.name,
      'text_content': textContent,
      'media_urls': mediaUrls.map((e) => e.toJson()).toList(),
      'is_reel': isReel,
      'visibility': visibility.name,
      'like_count': likeCount,
      'comment_count': commentCount,
      'reshare_count': reshareCount,
      'is_liked': isLiked,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  PostModel copyWith({
    String? id,
    String? userId,
    UserModel? user,
    PostContentType? contentType,
    String? textContent,
    List<MediaAttachment>? mediaUrls,
    bool? isReel,
    PostVisibility? visibility,
    int? likeCount,
    int? commentCount,
    int? reshareCount,
    bool? isLiked,
    DateTime? createdAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      contentType: contentType ?? this.contentType,
      textContent: textContent ?? this.textContent,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      isReel: isReel ?? this.isReel,
      visibility: visibility ?? this.visibility,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      reshareCount: reshareCount ?? this.reshareCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        userId,
        user,
        contentType,
        textContent,
        mediaUrls,
        isReel,
        visibility,
        likeCount,
        commentCount,
        reshareCount,
        isLiked,
        createdAt,
      ];
}