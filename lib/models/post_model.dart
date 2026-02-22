// ============================================================
//  Post Model – Community / Parents Park – MaaCare
// ============================================================

class PostModel {
  final String id;
  final String userId;
  final String content;
  int likes;
  final int weekTag;
  final bool anonymous;
  final String? authorName;
  final DateTime createdAt;
  final List<ReplyModel> replies;
  final String? imageUrl;
  final String? videoUrl;
  bool isLikedByMe;

  PostModel({
    required this.id,
    required this.userId,
    required this.content,
    this.likes = 0,
    this.weekTag = 0,
    this.anonymous = true,
    this.authorName,
    required this.createdAt,
    this.replies = const [],
    this.imageUrl,
    this.videoUrl,
    this.isLikedByMe = false,
  });

  String get displayName =>
      anonymous ? 'Mama 🌸' : (authorName ?? 'Mama 🌸');

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      likes: (map['likes'] as int?) ?? 0,
      weekTag: (map['week_tag'] as int?) ?? 0,
      anonymous: (map['anonymous'] as bool?) ?? true,
      authorName: map['author_name'] as String?,
      imageUrl: map['image_url'] as String?,
      videoUrl: map['video_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'content': content,
      'week_tag': weekTag,
      'anonymous': anonymous,
      'author_name': authorName,
      if (imageUrl != null) 'image_url': imageUrl,
      if (videoUrl != null) 'video_url': videoUrl,
    };
  }
}

class ReplyModel {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final bool anonymous;
  final DateTime createdAt;

  const ReplyModel({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    this.anonymous = true,
    required this.createdAt,
  });

  factory ReplyModel.fromMap(Map<String, dynamic> map) {
    return ReplyModel(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      anonymous: (map['anonymous'] as bool?) ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
