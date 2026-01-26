import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? displayName;
  final String? bio;
  final String? avatarUrl;
  final bool isVerified;
  final int followerCount;
  final int followingCount;
  final DateTime createdAt;
  
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.phoneNumber,
    this.displayName,
    this.bio,
    this.avatarUrl,
    required this.isVerified,
    required this.followerCount,
    required this.followingCount,
    required this.createdAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      displayName: json['display_name'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      isVerified: json['is_verified'] as bool,
      followerCount: json['follower_count'] as int,
      followingCount: json['following_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'phone_number': phoneNumber,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'is_verified': isVerified,
      'follower_count': followerCount,
      'following_count': followingCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? phoneNumber,
    String? displayName,
    String? bio,
    String? avatarUrl,
    bool? isVerified,
    int? followerCount,
    int? followingCount,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        username,
        email,
        phoneNumber,
        displayName,
        bio,
        avatarUrl,
        isVerified,
        followerCount,
        followingCount,
        createdAt,
      ];
}