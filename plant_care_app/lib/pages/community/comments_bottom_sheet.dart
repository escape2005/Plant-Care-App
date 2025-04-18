import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/comment.dart';
import '../../models/post.dart';

class CommentsBottomSheet extends StatefulWidget {
  final Post post;

  const CommentsBottomSheet({Key? key, required this.post}) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final supabase = Supabase.instance.client;
  bool _isComposing = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<Comment> _comments = [];
  String? currentUserId;
  String? currentUserName;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchComments();
  }

  Future<void> _getCurrentUser() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      currentUserId = user.id;

      // Get current user's name
      try {
        final response =
            await supabase
                .from('user_details')
                .select('user_name')
                .eq('id', user.id)
                .single();

        if (response != null && response['user_name'] != null) {
          currentUserName = response['user_name'];
        }
      } catch (e) {
        print('Error fetching user name: $e');
      }
    }
  }

  Future<void> _fetchComments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch comments from post_comments table for this specific post
      final response = await supabase
          .from('post_comments')
          .select('*, user_details:user_id(user_name)')
          .eq('post_id', widget.post.id)
          .order('created_at', ascending: true);

      final List<Comment> comments = [];

      for (final item in response) {
        // Get the user name from the joined user_details
        String userName = 'Anonymous';
        if (item['user_details'] != null &&
            item['user_details']['user_name'] != null) {
          userName = item['user_details']['user_name'];
        }

        final commentData = {
          'id': item['comment_id'],
          'post_id': item['post_id'],
          'user_id': item['user_id'],
          'user_name': userName,
          'text': item['comment'],
          'created_at': item['created_at'],
        };

        comments.add(Comment.fromMap(commentData));
      }

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (error) {
      print('Error fetching comments: $error');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load comments: $error';
      });
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in to comment')));
      return;
    }

    _commentController.clear();
    setState(() {
      _isComposing = false;
    });

    try {
      // Save the comment to post_comments table
      final newComment = {
        'post_id': widget.post.id,
        'user_id': currentUserId,
        'comment': text.trim(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('post_comments').insert(newComment);

      // Update comment count in community_interactions table
      await supabase
          .from('community_interactions')
          .update({'num_of_comments': widget.post.comments + 1})
          .eq('community_id', widget.post.id);

      // Refresh the comments list
      _fetchComments();

      // Update the UI to show the new comment immediately for better UX
      if (mounted && currentUserName != null) {
        setState(() {
          _comments.add(
            Comment(
              id: 'temp-id-${DateTime.now().millisecondsSinceEpoch}',
              postId: widget.post.id,
              userId: currentUserId!,
              userName: currentUserName!,
              text: text.trim(),
              createdAt: DateTime.now(),
            ),
          );
        });
      }
    } catch (error) {
      print('Error saving comment: $error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save comment: $error')));
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with drag handle and title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  height: 4,
                  width: 40,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Comments (${_comments.length})',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      color: Colors.grey[700],
                      iconSize: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text(_errorMessage!))
                    : _comments.isEmpty
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No comments yet. Be the first to comment!',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      reverse: false,
                      itemCount: _comments.length,
                      itemBuilder: (_, int index) {
                        final comment = _comments[index];
                        return _buildCommentItem(comment);
                      },
                    ),
          ),

          // Comment input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.0,
                right: 8.0,
                top: 8.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  // Avatar
                  const CircleAvatar(
                    backgroundImage: AssetImage(
                      'assets/images/account_circle.png',
                    ),
                    radius: 18,
                  ),
                  const SizedBox(width: 10),

                  // Text field
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      focusNode: _focusNode,
                      onChanged: (text) {
                        setState(() {
                          _isComposing = text.trim().isNotEmpty;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 10.0,
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),

                  // Send button
                  Container(
                    margin: const EdgeInsets.only(left: 4.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.send_rounded,
                        color: _isComposing ? Colors.green : Colors.grey[400],
                      ),
                      onPressed:
                          _isComposing
                              ? () => _handleSubmitted(_commentController.text)
                              : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User avatar
          CircleAvatar(
            backgroundImage:
                comment.userProfileImage != null
                    ? NetworkImage(comment.userProfileImage!) as ImageProvider
                    : const AssetImage('assets/images/account_circle.png'),
            radius: 18,
          ),
          const SizedBox(width: 10),

          // Comment content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and time
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      comment.timeAgo,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),

                // Comment text
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    comment.text,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
