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
      userName: 'Omkar',
      location: 'Dombivli',
      imageUrl: 'https://images.unsplash.com/photo-1682687220801-eef408f95d71',
      caption: 'My monstera is thriving! Any tips for propagation?',
      timeAgo: '2h ago',
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
                    backgroundImage: AssetImage(post.userProfileImage),
                  ),
                  title: Text(
                    post.userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(post.timeAgo),
                  trailing: Text(
                    post.location,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                Image.network(
                  post.imageUrl,
                  height: 300,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.caption, style: const TextStyle(fontSize: 16)),
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
