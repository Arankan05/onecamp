import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/widgets/onecamp_back_button.dart';
import '../controllers/feed_controller.dart';
import '../models/post_model.dart';
import '../repositories/user_repository.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/screens/other_user_profile_screen.dart';
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
  final UserRepository _userRepository = UserRepository();

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

  Widget _buildCreatePostComposerCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C7952B8),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: lightLavender,
                  child: const Icon(Icons.person, color: primaryPurple),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "What's on your mind? Share with campus...",
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: primaryPurple,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.photo_library_rounded,
                      color: Colors.green,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Photo',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 16, color: borderLavender),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreatePostScreen(),
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Camera',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLavender,

      // Create Post button
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add, size: 24),
        label: const Text(
          'Create Post',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
      ),

      // AppBar
      appBar: AppBar(
        elevation: 0,
        backgroundColor: backgroundLavender,
        surfaceTintColor: Colors.transparent,
        leading: Navigator.canPop(context) ? const OneCampBackButton() : null,
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
          // Create Post Prominent Composer Box
          _buildCreatePostComposerCard(),

          // All Posts / Following selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    size: 60,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _showFollowing
                        ? 'No posts from followed students'
                        : 'No posts yet',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _showFollowing
                        ? 'Follow students to see their posts here!'
                        : 'Be the first to share something!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
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
              // Post header with real author profile lookup
              FutureBuilder<UserProfile?>(
                future: _userRepository.getUserById(post.authorId),
                builder: (context, authorSnapshot) {
                  final author = authorSnapshot.data;
                  final authorName = author?.name ?? 'Campus Student';
                  final avatarUrl = author?.profileImageUrl;

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OtherUserProfileScreen(userId: post.authorId),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: lightLavender,
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? const Icon(Icons.person, color: primaryPurple)
                              : null,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtherUserProfileScreen(
                                  userId: post.authorId,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authorName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Post options popup menu
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
                                builder: (context) =>
                                    EditPostScreen(post: post),
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
                                Icon(Icons.copy),
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
                                  Icon(Icons.edit),
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
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete Post'),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Post content
              if (post.content.isNotEmpty)
                Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: darkText,
                    height: 1.4,
                  ),
                ),

              // Post image
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Unable to load image');
                    },
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Post date
              Text(
                post.createdAt.toLocal().toString().split('.')[0],
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
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
                      style: TextStyle(color: primaryPurple, fontSize: 12),
                    ),
                    SizedBox(width: 4),
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
