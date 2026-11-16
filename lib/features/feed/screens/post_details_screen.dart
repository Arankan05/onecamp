
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/feed_controller.dart';
import '../controllers/comment_controller.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class PostDetailsScreen extends StatefulWidget {
  final PostModel post;

  const PostDetailsScreen({
    super.key,
    required this.post,
  });

  @override
  State<PostDetailsScreen> createState() =>
      _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  final FeedController _feedController = FeedController();
  final CommentController _commentController = CommentController();

  final TextEditingController _textController =
  TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _commentsKey = GlobalKey();

  bool _isSending = false;
  bool _isEditing = false;
  String? _editingCommentId;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Scroll to comments section
  Future<void> _scrollToComments() async {
    final targetContext = _commentsKey.currentContext;

    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.0,
    );
  }

  // Add a new comment
  Future<void> _sendComment() async {
    final content = _textController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (content.isEmpty || user == null || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _commentController.addComment(
        postId: widget.post.id,
        authorId: user.uid,
        content: content,
      );

      if (!mounted) return;

      _textController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment added successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to send comment: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // Start editing a comment
  void _startEditing(CommentModel comment) {
    setState(() {
      _isEditing = true;
      _editingCommentId = comment.id;
      _textController.text = comment.content;
    });
  }

  // Cancel editing
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingCommentId = null;
      _textController.clear();
    });
  }

  // Update an existing comment
  Future<void> _updateComment() async {
    final content = _textController.text.trim();

    if (content.isEmpty ||
        _editingCommentId == null ||
        _isSending) {
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    debugPrint('========== COMMENT DEBUG ==========');
    debugPrint('CURRENT USER UID: ${currentUser?.uid}');
    debugPrint('EDITING COMMENT ID: $_editingCommentId');
    debugPrint('POST ID: ${widget.post.id}');
    debugPrint('===================================');

    setState(() {
      _isSending = true;
    });

    try {
      await _commentController.updateComment(
        postId: widget.post.id,
        commentId: _editingCommentId!,
        content: content,
      );

      if (!mounted) return;

      _cancelEditing();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment updated successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update comment: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // Delete a comment
  Future<void> _deleteComment(String commentId) async {
    try {
      await _commentController.deleteComment(
        postId: widget.post.id,
        commentId: commentId,
      );

      if (!mounted) return;

      if (_editingCommentId == commentId) {
        _cancelEditing();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Comment deleted successfully'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete comment: $e'),
        ),
      );
    }
  }

  // Confirm before deleting a comment
  Future<void> _confirmDeleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete comment?'),
          content: const Text(
            'Are you sure you want to delete this comment?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      await _deleteComment(commentId);
    }
  }

  // Like or unlike the post
  Future<void> _toggleLike(String userId) async {
    try {
      await _feedController.toggleLike(
        postId: widget.post.id,
        userId: userId,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update like: $e'),
        ),
      );
    }
  }

  // Build post details
  Widget _buildPost() {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Student',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.post.authorId,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Text(
              widget.post.content,
              style: const TextStyle(fontSize: 16),
            ),

            if (widget.post.imageUrl != null &&
                widget.post.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  widget.post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Unable to load image');
                  },
                ),
              ),
            ],

            const SizedBox(height: 12),

            Text(
              widget.post.createdAt.toLocal().toString(),
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),

            const Divider(height: 24),

            Row(
              children: [
                if (user != null)
                  StreamBuilder<bool>(
                    stream: _feedController.isPostLikedByUser(
                      postId: widget.post.id,
                      userId: user.uid,
                    ),
                    builder: (context, snapshot) {
                      final isLiked = snapshot.data ?? false;

                      return IconButton(
                        onPressed: () => _toggleLike(user.uid),
                        icon: Icon(
                          isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                      );
                    },
                  ),

                StreamBuilder<int>(
                  stream: _feedController.getLikeCount(
                    widget.post.id,
                  ),
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data ?? 0} Likes',
                    );
                  },
                ),

                const SizedBox(width: 16),

                // Clickable Comments button
                TextButton.icon(
                  onPressed: _scrollToComments,
                  icon: const Icon(
                    Icons.comment_outlined,
                    color: Colors.deepPurple,
                  ),
                  label: const Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Build comments list
  Widget _buildComments() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<List<CommentModel>>(
      stream: _commentController.getComments(widget.post.id),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading comments: ${snapshot.error}',
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final comments = snapshot.data ?? [];

        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No comments yet.\nBe the first to comment!',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: comments.length,
          itemBuilder: (context, index) {
            final comment = comments[index];

            final isMyComment =
                comment.authorId == currentUser?.uid;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),

                title: Text(
                  'Student • ${comment.authorId}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(comment.content),
                    const SizedBox(height: 5),
                    Text(
                      comment.createdAt.toLocal().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),

                trailing: isMyComment
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit comment',
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () {
                        _startEditing(comment);
                      },
                    ),
                    IconButton(
                      tooltip: 'Delete comment',
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        _confirmDeleteComment(comment.id);
                      },
                    ),
                  ],
                )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  // Comment input area
  Widget _buildCommentInput() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isEditing)
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Editing your comment',
                      style: TextStyle(
                        color: Colors.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _isSending ? null : _cancelEditing,
                    child: const Text('Cancel'),
                  ),
                ],
              ),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _isEditing
                          ? 'Edit your comment...'
                          : 'Write a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                IconButton(
                  onPressed: _isSending
                      ? null
                      : (_isEditing ? _updateComment : _sendComment),
                  icon: _isSending
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Icon(
                    _isEditing ? Icons.check : Icons.send,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPost(),

                  Padding(
                    key: _commentsKey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  _buildComments(),
                ],
              ),
            ),
          ),

          _buildCommentInput(),
        ],
      ),
    );
  }
}
