
import 'package:flutter/material.dart';

import '../controllers/feed_controller.dart';
import '../models/post_model.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({
    super.key,
    required this.post,
  });

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _contentController =
  TextEditingController();

  late final FeedController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _controller = FeedController();

    // Display the existing post text
    _contentController.text = widget.post.content;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updatePost() async {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post content cannot be empty'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _controller.updatePost(
        postId: widget.post.id,
        content: content,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post updated successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update post: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Post'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'What is happening?',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePost,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Update Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
