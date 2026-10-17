// lib/data/model/post.dart
// Backend-neutral post model

import 'package:halalgram/data/model/user_profile.dart';

class Post {
  const Post({
    required this.id,
    required this.userId,
    required this.imagePath,
    required this.caption,
    required this.location,
    required this.createdAt,
    required this.author,
  });

  final String id;
  final String userId;
  final String imagePath;
  final String caption;
  final String location;
  final DateTime createdAt;
  final UserProfile author;

  factory Post.fromSupabase({
    required Map<String, dynamic> postMap,
    required Map<String, dynamic> authorMap,
  }) {
    return Post(
      id: postMap['id'] as String,
      userId: postMap['user_id'] as String,
      imagePath: postMap['image_path'] as String,
      caption: postMap['caption'] as String? ?? '',
      location: postMap['location'] as String? ?? '',
      createdAt: DateTime.parse(postMap['created_at'] as String),
      author: UserProfile.fromSupabase(authorMap),
    );
  }

  String? get imageUrl {
    // This will be resolved by the UI layer using SupabasePostsService
    return imagePath;
  }
}

/// Pagination cursor for keyset pagination
class PostCursor {
  const PostCursor({
    required this.createdAt,
    required this.id,
  });

  final DateTime createdAt;
  final String id;

  factory PostCursor.fromPost(Post post) {
    return PostCursor(createdAt: post.createdAt, id: post.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'id': id,
    };
  }

  factory PostCursor.fromMap(Map<String, dynamic> map) {
    return PostCursor(
      createdAt: DateTime.parse(map['createdAt'] as String),
      id: map['id'] as String,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PostCursor &&
          runtimeType == other.runtimeType &&
          createdAt == other.createdAt &&
          id == other.id;

  @override
  int get hashCode => createdAt.hashCode ^ id.hashCode;
}

/// Paginated result for posts
class PostPage {
  const PostPage({
    required this.posts,
    required this.hasMore,
    required this.nextCursor,
  });

  final List<Post> posts;
  final bool hasMore;
  final PostCursor? nextCursor;
}
