import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/community/create_post_screen.dart';
import 'package:plant_care_app/pages/community/comments_bottom_sheet.dart';
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
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _loadPosts();
  }

  Future<void> _getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        currentUserId = user.id;
      });
    }
  }

  Future<void> _loadPosts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await supabase
          .from('community_interactions')
          .select()
          .order('created_at', ascending: false);

      print('Fetched posts: ${response.length}');

      final List<Post> posts = [];

      for (final post in response) {
        String? imageUrl1 = post['image_path'];

        String imageUrl =
            "https://xbohbkzamxgocrpyzydf.supabase.co/storage/v1/object/public/community-images/${imageUrl1}";

        // Fetch the actual username from user_details table
        String userName = 'Anonymous';
        if (post['user_id'] != null) {
          try {
            final userDetailsResponse =
                await supabase
                    .from('user_details')
                    .select('user_name')
                    .eq('id', post['user_id'])
                    .maybeSingle();

            if (userDetailsResponse != null &&
                userDetailsResponse['user_name'] != null) {
              userName = userDetailsResponse['user_name'];
            } else {
              // Fallback to previous format if user_details entry not found
              userName =
                  'User ${post['user_id']?.toString().substring(0, 8) ?? 'Anonymous'}';
            }
          } catch (error) {
            print('Error fetching user details: $error');
            // Fallback to previous format on error
            userName =
                'User ${post['user_id']?.toString().substring(0, 8) ?? 'Anonymous'}';
          }
        }

        // Check if the post has been liked by the current user
        bool isLiked = false;
        if (currentUserId != null) {
          final likeResponse = await supabase
              .from('post_likes')
              .select()
              .eq('post_id', post['community_id'])
              .eq('user_id', currentUserId!);

          isLiked = likeResponse.length > 0;
        }

        // Get the number of likes for this post
        final int numOfLikes = post['num_of_likes'] ?? 0;

        final postData = {
          ...post,
          'user_name': userName,
          'user_profile_image': null,
          'image_path': imageUrl,
          'is_liked': isLiked,
          'likes': numOfLikes,
        };

        posts.add(Post.fromMap(postData));
      }

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading posts: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load posts: $error';
      });
    }
  }

  Future<void> _toggleLike(Post post) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to like posts')),
      );
      return;
    }

    // Create a copy of the current like state and count before toggling
    final bool wasLiked = post.isLiked;
    final int previousLikeCount = post.likes;

    // Compute new values
    final bool newLikeStatus = !wasLiked;
    final int newLikeCount =
        wasLiked ? previousLikeCount - 1 : previousLikeCount + 1;

    try {
      // First update local state for immediate feedback
      setState(() {
        // Create a new Post with updated values instead of modifying the existing one
        int postIndex = _posts.indexWhere((p) => p.id == post.id);
        if (postIndex != -1) {
          final updatedPost = Post(
            id: post.id,
            createdAt: post.createdAt,
            userId: post.userId,
            userName: post.userName,
            userProfileImage: post.userProfileImage,
            imageUrl: post.imageUrl,
            description: post.description,
            location: post.location,
            interactionType: post.interactionType,
            likes: newLikeCount,
            comments: post.comments,
            isLiked: newLikeStatus,
          );
          _posts[postIndex] = updatedPost;
        }
      });

      // Then update in database
      if (newLikeStatus) {
        // User is liking the post
        await supabase.from('post_likes').insert({
          'post_id': post.id,
          'user_id': currentUserId,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // User is unliking the post
        await supabase.from('post_likes').delete().match({
          'post_id': post.id,
          'user_id': currentUserId!,
        });
      }

      // Update the like count in the post
      await supabase
          .from('community_interactions')
          .update({'num_of_likes': newLikeCount})
          .eq('community_id', post.id);
    } catch (error) {
      // Revert the local state changes if the database operation failed
      setState(() {
        int postIndex = _posts.indexWhere((p) => p.id == post.id);
        if (postIndex != -1) {
          final revertedPost = Post(
            id: post.id,
            createdAt: post.createdAt,
            userId: post.userId,
            userName: post.userName,
            userProfileImage: post.userProfileImage,
            imageUrl: post.imageUrl,
            description: post.description,
            location: post.location,
            interactionType: post.interactionType,
            likes: previousLikeCount,
            comments: post.comments,
            isLiked: wasLiked,
          );
          _posts[postIndex] = revertedPost;
        }
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update like: $error')));
    }
  }

  Future<void> _refreshPostCommentCount(String postId) async {
    try {
      // Get updated comment count from database
      final response =
          await supabase
              .from('community_interactions')
              .select('num_of_comments')
              .eq('community_id', postId)
              .single();

      if (response != null && response['num_of_comments'] != null) {
        // Update only the specific post
        setState(() {
          int postIndex = _posts.indexWhere((p) => p.id == postId);
          if (postIndex != -1) {
            final updatedPost = Post(
              id: _posts[postIndex].id,
              createdAt: _posts[postIndex].createdAt,
              userId: _posts[postIndex].userId,
              userName: _posts[postIndex].userName,
              userProfileImage: _posts[postIndex].userProfileImage,
              imageUrl: _posts[postIndex].imageUrl,
              description: _posts[postIndex].description,
              location: _posts[postIndex].location,
              interactionType: _posts[postIndex].interactionType,
              likes: _posts[postIndex].likes,
              comments: response['num_of_comments'],
              isLiked: _posts[postIndex].isLiked,
            );
            _posts[postIndex] = updatedPost;
          }
        });
      }
    } catch (error) {
      print('Error refreshing comment count: $error');
    }
  }

  void _showComments(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(post: post),
    ).then((_) {
      // Refresh the post's comment count when the bottom sheet is closed
      _refreshPostCommentCount(post.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _posts.isEmpty
              ? const Center(child: Text('No posts yet. Be the first to post!'))
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
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                      loadingProgress.expectedTotalBytes != null
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
                                  InkWell(
                                    onTap: () => _toggleLike(post),
                                    child: Row(
                                      children: [
                                        Icon(
                                          post.isLiked
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color:
                                              post.isLiked ? Colors.red : null,
                                        ),
                                        const SizedBox(width: 4),
                                        Text('${post.likes}'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  InkWell(
                                    onTap: () => _showComments(post),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.chat_bubble_outline),
                                        const SizedBox(width: 4),
                                        Text('${post.comments}'),
                                      ],
                                    ),
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
          ).then((_) => _loadPosts());
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
