import 'package:flutter/material.dart';

import '../../profile/models/user_profile.dart';
import '../controllers/community_controller.dart';
import '../controllers/user_lookup.dart';
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
  final UserLookup _lookup = UserLookup();

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
                return const Center(child: Text('Could not load posts.'));
              }
              final posts = snapshot.data ?? [];
              if (posts.isEmpty) {
                return const Center(
                  child: Text('No posts yet.\nStart the discussion!',
                      textAlign: TextAlign.center),
                );
              }
              return ListView.builder(
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: FutureBuilder<UserProfile?>(
                      future: _lookup.getUser(post.authorId),
                      builder: (context, userSnapshot) {
                        final user = userSnapshot.data;
                        final name = (user != null && user.name.isNotEmpty)
                            ? user.name
                            : 'Member ${shortId(post.authorId)}';
                        final imageUrl = user?.profileImageUrl;
                        final hasImage =
                            imageUrl != null && imageUrl.isNotEmpty;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                hasImage ? NetworkImage(imageUrl) : null,
                            child: hasImage ? null : const Icon(Icons.person),
                          ),
                          title: Text(post.text),
                          subtitle: Text(name),
                        );
                      },
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
                child: Text('Join this community to post.'),
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
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _send,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}