import 'package:flutter/material.dart';

import '../controllers/community_controller.dart';
import '../models/community_post.dart';

class PostsTab extends StatefulWidget {
  const PostsTab({
    super.key,
    required this.controller,
    required this.communityId,
  });

  final CommunityController controller;
  final String communityId;

  @override
  State<PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<PostsTab> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    if (text.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post is too long (max 500).')),
      );
      return;
    }

    final success = await widget.controller.addPost(widget.communityId, text);
    if (!mounted) return;

    if (success) {
      _textController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.controller.errorMessage ?? 'Something went wrong.',
          ),
        ),
      );
    }
  }

  String _shortId(String id) => id.length > 6 ? id.substring(0, 6) : id;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<CommunityPost>>(
            stream: widget.controller.watchPosts(widget.communityId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Could not load posts.',
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 15,
                    ),
                  ),
                );
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Center(
                  child: Text(
                    'No posts yet.\nStart the discussion!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    elevation: 1.5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        post.text,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                      subtitle: Text(
                        'Member ${_shortId(post.authorId)}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        StreamBuilder<bool>(
          stream: widget.controller.watchIsMember(widget.communityId),
          builder: (context, snapshot) {
            final isMember = snapshot.data ?? false;
            if (!isMember) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Join this community to post.',
                  style: TextStyle(
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Write a post...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.send), onPressed: _send),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
