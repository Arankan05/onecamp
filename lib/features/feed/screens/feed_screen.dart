import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/feed_controller.dart';
import '../models/post_model.dart';
import 'create_post_screen.dart';
import 'comment_screen.dart';
import 'edit_post_screen.dart';
import 'post_details_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final FeedController _controller;

  bool _showFollowing = false;

  @override
  void initState() {
    super.initState();
    _controller = FeedController();
  }

  // Open Post Details screen
  void _openPostDetails(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PostDetailsScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),

      appBar: AppBar(
        title: const Text(
          'OneCamp',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Students',
            onPressed: () {
              Navigator.pushNamed(context, '/students');
            },
          ),
        ],
      ),

      body: Column(
        children: [
          // All Posts / Following selector
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('All Posts')),
                    selected: !_showFollowing,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _showFollowing = false;
                        });
                      }
                    },
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('Following')),
                    selected: _showFollowing,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _showFollowing = true;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          // Selected feed
          Expanded(child: _buildPostsFeed()),
        ],
      ),
    );
  }

  // Build All Posts or Following feed
  Widget _buildPostsFeed() {
    final user = FirebaseAuth.instance.currentUser;

    if (_showFollowing && user == null) {
      return const Center(child: Text('Please log in to view followed posts.'));
    }

    final postsStream = _showFollowing
        ? _controller.getFollowedPosts(user!.uid)
        : _controller.postsStream;

    return StreamBuilder<List<PostModel>>(
      stream: postsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint('FEED ERROR: ${snapshot.error}');

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Feed Error:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.dynamic_feed, size: 60, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  _showFollowing
                      ? 'No posts from followed students'
                      : 'No posts yet',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _showFollowing
                      ? 'Follow students to see their posts here!'
                      : 'Be the first to share something!',
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return _buildPostCard(posts[index]);
          },
        );
      },
    );
  }

  // Build individual post card
  Widget _buildPostCard(PostModel post) {
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openPostDetails(post),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Post header
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      'Student • ${post.authorId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Post options
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),

                    onSelected: (value) async {
                      if (value == 'copy') {
                        await Clipboard.setData(
                          ClipboardData(text: post.content),
                        );

                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Post text copied')),
                        );
                      }

                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditPostScreen(post: post),
                          ),
                        );
                      }

                      if (value == 'delete') {
                        try {
                          await _controller.deletePost(post.id);

                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Post deleted successfully'),
                            ),
                          );
                        } catch (e) {
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Unable to delete post: $e'),
                            ),
                          );
                        }
                      }
                    },

                    itemBuilder: (context) => [
                      // Copy option for every user
                      const PopupMenuItem<String>(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy),
                            SizedBox(width: 8),
                            Text('Copy Post Text'),
                          ],
                        ),
                      ),

                      // Edit option for post owner only
                      if (user?.uid == post.authorId)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit Post'),
                            ],
                          ),
                        ),

                      // Delete option for post owner only
                      if (user?.uid == post.authorId)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete Post'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Post content
              if (post.content.isNotEmpty) Text(post.content),

              // Post image
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),

                Image.network(
                  post.imageUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Unable to load image');
                  },
                ),
              ],

              const SizedBox(height: 12),

              // Post date
              Text(
                post.createdAt.toLocal().toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const Divider(),

              // Like count and Like button
              StreamBuilder<int>(
                stream: _controller.getLikeCount(post.id),
                builder: (context, countSnapshot) {
                  final likeCount = countSnapshot.data ?? 0;

                  return StreamBuilder<bool>(
                    stream: user == null
                        ? null
                        : _controller.isPostLikedByUser(
                            postId: post.id,
                            userId: user.uid,
                          ),
                    builder: (context, likedSnapshot) {
                      final isLiked = likedSnapshot.data ?? false;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          // Like button
                          TextButton.icon(
                            onPressed: user == null
                                ? null
                                : () async {
                                    try {
                                      await _controller.toggleLike(
                                        postId: post.id,
                                        userId: user.uid,
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;

                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Unable to like post: $e',
                                              ),
                                            ),
                                          );
                                    }
                                  },
                            icon: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : null,
                            ),
                            label: Text('Like ($likeCount)'),
                          ),

                          // Comment button
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommentScreen(postId: post.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.comment_outlined),
                            label: const Text('Comment'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 8),

              // View details indicator
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tap post to view details',
                      style: TextStyle(color: Colors.deepPurple, fontSize: 12),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Colors.deepPurple,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
