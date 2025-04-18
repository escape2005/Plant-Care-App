import 'package:flutter/material.dart';
import 'package:plant_care_app/pages/community/create_post_screen.dart';
import 'package:plant_care_app/pages/community/comments_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
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

  // Helper method to download image from URL and save locally
  Future<File?> _downloadAndSaveImage(String imageUrl) async {
    try {
      // Get temporary directory to store the image
      final directory = await getTemporaryDirectory();

      // Generate a unique file name using timestamp
      final fileName =
          'plant_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      // Download the file
      final response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Save the image to the file system
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      } else {
        print('Failed to download image: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error downloading image: $e');
      return null;
    }
  }

  // Share post with image and text
  Future<void> _sharePost(Post post) async {
    try {
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing to share post...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Create share text
      final String shareText =
          '${post.description}\n\nShared from Plantify App by ${post.userName}';

      // Download and save the image
      final File? imageFile = await _downloadAndSaveImage(post.imageUrl);

      if (imageFile != null) {
        // Get the position for share sheet (important for iOS)
        final box = context.findRenderObject() as RenderBox?;

        // Share the image and text
        final result = await Share.shareXFiles(
          [XFile(imageFile.path)],
          text: shareText,
          subject: 'Check out this plant post!',
          sharePositionOrigin:
              box != null ? box.localToGlobal(Offset.zero) & box.size : null,
        );

        // Optional: Handle share result
        if (result.status == ShareResultStatus.success) {
          print('Post shared successfully');
        } else if (result.status == ShareResultStatus.dismissed) {
          print('Share was dismissed');
        }
      } else {
        // Fallback to sharing just the text if image download fails
        await Share.share(
          '${shareText}\n\n(Image could not be shared)',
          subject: 'Check out this plant post!',
        );
      }
    } catch (e) {
      print('Error sharing post: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.green),
              )
              : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : _posts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No posts yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Be the first to share with the community!',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadPosts,
                color: Colors.green,
                child: ListView.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User info bar with modern design
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 12),
                                    // User avatar with border
                                    Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.green.shade300,
                                                Colors.green.shade500,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Hero(
                                            tag: 'profile-${post.id}',
                                            child: CircleAvatar(
                                              radius: 20,
                                              backgroundColor: Colors.white,
                                              backgroundImage:
                                                  post.userProfileImage != null
                                                      ? NetworkImage(
                                                        post.userProfileImage!,
                                                      )
                                                      : const AssetImage(
                                                            'assets/images/account_circle.png',
                                                          )
                                                          as ImageProvider,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 12),

                                    // User info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                post.userName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                            ],
                                          ),
                                          Text(
                                            post.timeAgo,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Location badge if available
                                    if (post.location != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              color: Colors.green[700],
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              post.location!,
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                  ],
                                ),
                              ),
                            ),

                            // Post image with hero animation
                            Hero(
                              tag: 'post-image-${post.id}',
                              child: Container(
                                height: 300,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F5F5),
                                ),
                                child: Image.network(
                                  post.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (
                                    context,
                                    child,
                                    loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.green,
                                            ),
                                        value:
                                            loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            size: 50,
                                            color: Colors.grey[400],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Image not available',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Post description with nice typography
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                post.description,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),

                            // Divider before interaction buttons
                            const Divider(height: 1),

                            // Post interaction buttons
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // Like button
                                  InkWell(
                                    onTap: () => _toggleLike(post),
                                    borderRadius: BorderRadius.circular(30),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 12.0,
                                      ),
                                      child: Row(
                                        children: [
                                          AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            transitionBuilder: (
                                              Widget child,
                                              Animation<double> animation,
                                            ) {
                                              return ScaleTransition(
                                                scale: animation,
                                                child: child,
                                              );
                                            },
                                            child: Icon(
                                              post.isLiked
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              key: ValueKey<bool>(post.isLiked),
                                              color:
                                                  post.isLiked
                                                      ? Colors.red
                                                      : Colors.grey[700],
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.likes}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  post.isLiked
                                                      ? Colors.red
                                                      : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Comment button
                                  InkWell(
                                    onTap: () => _showComments(post),
                                    borderRadius: BorderRadius.circular(30),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 12.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            color: Colors.grey[700],
                                            size: 22,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${post.comments}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Share button
                                  InkWell(
                                    onTap: () => _sharePost(post),
                                    borderRadius: BorderRadius.circular(30),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                        horizontal: 12.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.share_outlined,
                                            color: Colors.grey[700],
                                            size: 22,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Share',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
          ).then((_) => _loadPosts());
        },
        backgroundColor: Colors.green,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: Colors.white,
        ),
      ),
    );
  }
}
