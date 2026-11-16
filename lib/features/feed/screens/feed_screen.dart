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

  static const Color primaryPurple = Color(0xFF7952B8);
  static const Color lightLavender = Color(0xFFEDE4F8);
  static const Color backgroundLavender = Color(0xFFF7F2FC);
  static const Color darkText = Color(0xFF302344);
  static const Color borderLavender = Color(0xFFE9DDF8);

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
      backgroundColor: backgroundLavender,

      // Create Post button
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        child: const Icon(Icons.add, size: 30),
      ),

      // AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundLavender,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'OneCamp',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: primaryPurple,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.people_alt_outlined,
              color: primaryPurple,
              size: 27,
            ),
            tooltip: 'Students',
            onPressed: () {
              Navigator.pushNamed(context, '/students');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Column(
        children: [
          // All Posts / Following selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: lightLavender,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFollowing = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showFollowing
                              ? primaryPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'All Posts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: !_showFollowing
                                ? Colors.white
                                : primaryPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showFollowing = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showFollowing
                              ? primaryPurple
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Following',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _showFollowing
                                ? Colors.white
                                : primaryPurple,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          return const Center(
            child: CircularProgressIndicator(color: primaryPurple),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.dynamic_feed_outlined,
                    size: 65,
                    color: primaryPurple,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _showFollowing
                        ? 'No posts from followed students'
                        : 'No posts yet',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _showFollowing
                        ? 'Follow students to see their posts here!'
                        : 'Be the first to share something!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 90),
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
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 2,
      shadowColor: primaryPurple..withValues(alpha: 0.12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: borderLavender, width: 1),
      ),
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
                  const CircleAvatar(
                    radius: 23,
                    backgroundColor: lightLavender,
                    child: Icon(Icons.person, color: primaryPurple, size: 26),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      'Student • ${post.authorId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: darkText,
                      ),
                    ),
                  ),

                  // Post options
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: primaryPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                      const PopupMenuItem<String>(
                        value: 'copy',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 19),
                            SizedBox(width: 8),
                            Text('Copy Post Text'),
                          ],
                        ),
                      ),

                      if (user?.uid == post.authorId)
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 19),
                              SizedBox(width: 8),
                              Text('Edit Post'),
                            ],
                          ),
                        ),

                      if (user?.uid == post.authorId)
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 19),
                              SizedBox(width: 8),
                              Text('Delete Post'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Post content
              if (post.content.isNotEmpty)
                Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: darkText,
                  ),
                ),

              // Post image
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: backgroundLavender,
                        alignment: Alignment.center,
                        child: const Text(
                          'Unable to load image',
                          style: TextStyle(color: primaryPurple),
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Post date
              Text(
                post.createdAt.toLocal().toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 12),

              const Divider(color: borderLavender, height: 1),

              const SizedBox(height: 8),

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
                            style: TextButton.styleFrom(
                              foregroundColor: isLiked
                                  ? Colors.pink
                                  : primaryPurple,
                            ),
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
                            ),
                            label: Text('Like ($likeCount)'),
                          ),

                          // Comment button
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: primaryPurple,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommentScreen(postId: post.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline),
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
                      style: TextStyle(color: primaryPurple, fontSize: 12),
                    ),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_forward, size: 14, color: primaryPurple),
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
