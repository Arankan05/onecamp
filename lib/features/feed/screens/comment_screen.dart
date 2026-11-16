
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/comment_controller.dart';
import '../models/comment_model.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({
    super.key,
    required this.postId,
  });

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CommentController _controller = CommentController();
  final TextEditingController _commentController =
  TextEditingController();

  bool _isSending = false;
  bool _isEditing = false;
  String? _editingCommentId;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // Add a new comment
  Future<void> _sendComment() async {
    final content = _commentController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (content.isEmpty || user == null || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _controller.addComment(
        postId: widget.postId,
        authorId: user.uid,
        content: content,
      );

      if (!mounted) return;

      _commentController.clear();

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
      _commentController.text = comment.content;
    });
  }

  // Cancel editing
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingCommentId = null;
      _commentController.clear();
    });
  }

  // Save edited comment
  Future<void> _updateComment() async {
    final content = _commentController.text.trim();

    if (content.isEmpty ||
        _editingCommentId == null ||
        _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await _controller.updateComment(
        postId: widget.postId,
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

  // Delete your own comment
  Future<void> _deleteComment(String commentId) async {
    try {
      await _controller.deleteComment(
        postId: widget.postId,
        commentId: commentId,
      );

      if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
      ),

      body: Column(
        children: [
          // Comments list
          Expanded(
            child: StreamBuilder<List<CommentModel>>(
              stream: _controller.getComments(widget.postId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading comments:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return const Center(
                    child: Text(
                      'No comments yet.\nBe the first to comment!',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
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
                            fontSize: 13,
                          ),
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 6),

                            Text(comment.content),

                            const SizedBox(height: 5),

                            Text(
                              comment.createdAt
                                  .toLocal()
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        // Edit and Delete buttons
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
                                _deleteComment(comment.id);
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
            ),
          ),

          // Comment input area
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Editing indicator
                  if (_isEditing)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
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
                            onPressed: _isSending
                                ? null
                                : _cancelEditing,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText: _isEditing
                                ? 'Edit your comment...'
                                : 'Write a comment...',
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(25),
                            ),
                            contentPadding:
                            const EdgeInsets.symmetric(
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
                            : (_isEditing
                            ? _updateComment
                            : _sendComment),
                        icon: _isSending
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : Icon(
                          _isEditing
                              ? Icons.check
                              : Icons.send,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
