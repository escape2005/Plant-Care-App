import 'package:supabase_flutter/supabase_flutter.dart';

class Post {
  final String userId;
  final String? userName;
  final String? location;
  final String imagePath;
  final String description;
  final DateTime createdAt;
  final int likes;
  final int comments;
  final String? userProfileImage;

  Post({
    required this.userId,
    this.userName,
    this.location,
    required this.imagePath,
    required this.description,
    required this.createdAt,
    this.likes = 0,
    this.comments = 0,
    this.userProfileImage,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      userId: map['user_id'] ?? '',
      userName: map['user_name'] ?? 'Anonymous',
      location: map['location'],
      imagePath: map['image_path'] ?? '',
      description: map['description'] ?? '',
      createdAt:
          map['created_at'] != null
              ? DateTime.parse(map['created_at'])
              : DateTime.now(),
      likes: map['likes'] ?? 0,
      comments: map['comments'] ?? 0,
      userProfileImage: map['user_profile_image'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'location': location,
      'image_path': imagePath,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'likes': likes,
      'comments': comments,
      'user_profile_image': userProfileImage,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  String get imageUrl {
    final supabase = Supabase.instance.client;
    return supabase.storage.from('community-images').getPublicUrl(imagePath);
  }
  
  // Alias for description, to fix the "caption" error
  String get caption => description;
}