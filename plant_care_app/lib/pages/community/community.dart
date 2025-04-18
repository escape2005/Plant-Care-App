import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/community/create_post_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/post.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final supabase = Supabase.instance.client;
  List<Post> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch posts from community_interactions table
      final response = await supabase
          .from('community_interactions')
          .select('*')
          .order('created_at', ascending: false);

      final List<Post> posts = [];

      for (final post in response) {
        // Create proper image URL from storage path
        String? imageUrl1 = post['image_path'];

        String? imageUrl =
            "https://xbohbkzamxgocrpyzydf.supabase.co/storage/v1/object/public/community-images/${imageUrl1}";

        // Just use the user_id as the username as requested
        String userName =
            'User ${post['user_id']?.toString().substring(0, 8) ?? 'Anonymous'}';

        final postData = {
          ...post,
          'user_name': userName,
          'user_profile_image':
              null, // No profile image since we're simplifying
          'image_path': imageUrl ?? '',
        };

        posts.add(Post.fromMap(postData));
      }

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load posts: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _posts.isEmpty
                ? const Center(
                  child: Text('No posts yet. Be the first to post!'),
                )
                : ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                                  post.userProfileImage != null
                                      ? NetworkImage(post.userProfileImage!)
                                      : const AssetImage(
                                            'assets/images/account_circle.png',
                                          )
                                          as ImageProvider,
                            ),
                            title: Text(
                              post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(post.timeAgo),
                            trailing:
                                post.location != null
                                    ? Text(
                                      post.location!,
                                      style: TextStyle(color: Colors.grey[600]),
                                    )
                                    : null,
                          ),
                          Image.network(
                            post.imageUrl,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return SizedBox(
                                height: 300,
                                child: Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  post.description,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.favorite_border),
                                        const SizedBox(width: 4),
                                        Text('${post.likes}'),
                                      ],
                                    ),
                                    const SizedBox(width: 24),
                                    Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          ).then(
            (_) => _loadPosts(),
          ); // Reload posts after returning from CreatePostScreen
        },
        backgroundColor: Colors.green,
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}
