class Post {
  final String id;
  final DateTime createdAt;
  final String? userId;
  final String userName;
  final String? userProfileImage;
  final String imageUrl;
  final String description;
  final String? location;
  final String? interactionType;
  final int likes;
  final int comments;
  bool isLiked; // Added isLiked property

  Post({
    required this.id,
    required this.createdAt,
    this.userId,
    required this.userName,
    this.userProfileImage,
    required this.imageUrl,
    required this.description,
    this.location,
    this.interactionType,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false, // Default to not liked
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      id: map['community_id'],
      createdAt: DateTime.parse(map['created_at']),
      userId: map['user_id'],
      userName: map['user_name'] ?? 'Anonymous',
      userProfileImage: map['user_profile_image'],
      imageUrl: map['image_path'] ?? '',
      description: map['description'] ?? '',
      location: map['location'],
      interactionType: map['interaction_type'],
      likes: map['num_of_likes'] ?? 0,
      comments: map['num_of_comments'] ?? 0,
      isLiked: map['is_liked'] ?? false,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
