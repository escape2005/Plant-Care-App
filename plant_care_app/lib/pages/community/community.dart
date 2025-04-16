import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/community/create_post_screen.dart';
import '../../models/post.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<Post> _posts = [
    Post(
      userId: 'user123',
      userName: 'Omkar',
      location: 'Dombivli',
      imagePath: 'path/to/monstera_image.jpg', // Changed from imageUrl to imagePath
      description: 'My monstera is thriving! Any tips for propagation?', // Changed from caption to description
      createdAt: DateTime.now().subtract(const Duration(hours: 2)), // Required field
      likes: 24,
      comments: 8,
      userProfileImage: 'assets/images/plant.jpg',
    ),
    // Add more sample posts here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundImage: post.userProfileImage != null
                        ? AssetImage(post.userProfileImage!)
                        : const AssetImage('assets/images/default_profile.jpg'),
                  ),
                  title: Text(
                    post.userName ?? 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(post.timeAgo),
                  trailing: post.location != null ? Text(
                    post.location!,
                    style: TextStyle(color: Colors.grey[600]),
                  ) : null,
                ),
                Image.network(
                  post.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 300,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text('Failed to load image'),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.description, style: const TextStyle(fontSize: 16)), // Changed from caption to description
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.thumb_up_outlined),
                              const SizedBox(width: 4),
                              Text('${post.likes}'),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              const Icon(Icons.comment_outlined),
                              const SizedBox(width: 4),
                              Text('${post.comments}'),
                            ],
                          ),
                          const SizedBox(width: 24),
                          const Icon(Icons.share_outlined),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.add_photo_alternate_outlined),
      ),
    );
  }
}