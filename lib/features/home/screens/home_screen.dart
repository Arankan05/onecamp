import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../communities/screens/create_community_screen.dart';
import '../../feed/models/post_model.dart';
import '../../feed/repositories/feed_repository.dart';
import '../../feed/repositories/follow_repository.dart';
import '../../feed/repositories/user_repository.dart';
import '../../feed/screens/comment_screen.dart';
import '../../feed/screens/create_post_screen.dart';
import '../../feed/screens/edit_post_screen.dart';
import '../../feed/screens/feed_screen.dart';
import '../../feed/screens/post_details_screen.dart';
import '../../feed/screens/student_list_screen.dart';
import '../../marketplace/screens/marketplace_browse_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../notifications/services/notification_service.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/screens/other_user_profile_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int index)? onNavigateToTab;

  const HomeScreen({super.key, this.onNavigateToTab});

  User? _getCurrentUser() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _getCurrentUser();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        titleSpacing: 16.0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school_rounded,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'OneCamp',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            StreamBuilder<int>(
              stream: NotificationService().getUnreadCountStream(user.uid),
              builder: (context, snapshot) {
                final unreadCount = snapshot.data ?? 0;

                return IconButton(
                  icon: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0C7C3AED),
                              blurRadius: 6.0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: AppTheme.primaryColor,
                          size: 20.0,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          const SizedBox(width: 8.0),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Welcome section
            _buildWelcomeCard(context, user, theme),
            const SizedBox(height: 16),

            // 2. Create Post composer
            _buildCreatePostComposerCard(context, user),
            const SizedBox(height: 20),

            // 3. Campus Social Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Campus Social Feed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FeedScreen()),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCampusFeedSection(context, user),
            const SizedBox(height: 24),

            // 4. Discover Students Section (NEW REQUIRED SECTION)
            _buildDiscoverStudentsHeader(context),
            const SizedBox(height: 10),
            _buildDiscoverStudentsSection(context, user),
            const SizedBox(height: 24),

            // 5. Upcoming Events & Campus Updates
            const Text(
              'Campus Activity Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            _buildCampusOverviewCard(context),
            const SizedBox(height: 24),

            // 6. Compact Campus Directory
            const Text(
              'Campus Directory',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            _buildModuleGrid(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverStudentsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discover Students',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Connect with students across your campus',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentListScreen()),
            );
          },
          child: const Text(
            'View All',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverStudentsSection(
    BuildContext context,
    User? currentUser,
  ) {
    final userRepository = UserRepository();
    final followRepository = FollowRepository();

    return StreamBuilder<List<UserProfile>>(
      stream: userRepository.getUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 210,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allUsers = snapshot.data ?? [];
        final otherStudents = allUsers
            .where((s) => currentUser == null || s.uid != currentUser.uid)
            .toList();

        if (otherStudents.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                'No other students found yet.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 215,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: otherStudents.length,
            itemBuilder: (context, index) {
              final student = otherStudents[index];
              return _buildStudentCard(
                context,
                student,
                currentUser,
                followRepository,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentCard(
    BuildContext context,
    UserProfile student,
    User? currentUser,
    FollowRepository followRepository,
  ) {
    final university = student.university?.isNotEmpty == true
        ? student.university!
        : (student.faculty?.isNotEmpty == true
              ? student.faculty!
              : 'Verified Student');

    final academicBadge = student.academicYear != null
        ? 'Year ${student.academicYear}'
        : (student.degree?.isNotEmpty == true ? student.degree! : 'OneCamp');

    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C7C3AED),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtherUserProfileScreen(userId: student.uid),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor, width: 2),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.secondaryColor,
                  backgroundImage:
                      student.profileImageUrl != null &&
                          student.profileImageUrl!.isNotEmpty
                      ? NetworkImage(student.profileImageUrl!)
                      : null,
                  child:
                      student.profileImageUrl == null ||
                          student.profileImageUrl!.isEmpty
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryColor,
                          size: 28,
                        )
                      : null,
                ),
              ),

              // Name & Details
              Column(
                children: [
                  Text(
                    student.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    university,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    academicBadge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),

              // Follow / Following Action Button
              if (currentUser != null && currentUser.uid != student.uid)
                StreamBuilder<bool>(
                  stream: followRepository.isFollowing(
                    currentUserId: currentUser.uid,
                    targetUserId: student.uid,
                  ),
                  builder: (context, followSnapshot) {
                    final isFollowing = followSnapshot.data ?? false;

                    return SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            if (isFollowing) {
                              await followRepository.unfollowUser(
                                currentUserId: currentUser.uid,
                                targetUserId: student.uid,
                              );
                            } else {
                              await followRepository.followUser(
                                currentUserId: currentUser.uid,
                                targetUserId: student.uid,
                              );
                            }
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Action failed: $e')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? AppTheme.secondaryColor
                              : AppTheme.primaryColor,
                          foregroundColor: isFollowing
                              ? const Color(0xFF1F2937)
                              : Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          isFollowing ? 'Following' : '+ Follow',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFollowing
                                ? const Color(0xFF1F2937)
                                : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampusFeedSection(BuildContext context, User? currentUser) {
    final feedRepository = FeedRepository();
    final userRepository = UserRepository();

    return StreamBuilder<List<PostModel>>(
      stream: feedRepository.getPosts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.dynamic_feed_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                const Text(
                  'No campus posts published yet.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Be the first student to share news or updates!',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Show top 3 recent posts on Home screen feed
        final displayPosts = posts.take(3).toList();

        return Column(
          children: displayPosts.map((post) {
            return _buildHomePostCard(
              context,
              post,
              currentUser,
              feedRepository,
              userRepository,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHomePostCard(
    BuildContext context,
    PostModel post,
    User? currentUser,
    FeedRepository feedRepository,
    UserRepository userRepository,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C7C3AED),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author Profile Header
              FutureBuilder<UserProfile?>(
                future: userRepository.getUserById(post.authorId),
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
                          backgroundColor: AppTheme.secondaryColor,
                          backgroundImage:
                              avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                )
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
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              Text(
                                post.createdAt.toLocal().toString().split(
                                  '.',
                                )[0],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (currentUser?.uid == post.authorId)
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey,
                          ),
                          onSelected: (val) async {
                            if (val == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditPostScreen(post: post),
                                ),
                              );
                            } else if (val == 'delete') {
                              await feedRepository.deletePost(post.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit Post'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'Delete Post',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 12),

              // Post Text
              if (post.content.isNotEmpty)
                Text(
                  post.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    height: 1.4,
                  ),
                ),

              // Post Image Attachment
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    post.imageUrl!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(),
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),

              // Like & Comment Actions Bar
              StreamBuilder<int>(
                stream: feedRepository.getLikeCount(post.id),
                builder: (context, likeCountSnapshot) {
                  final likeCount = likeCountSnapshot.data ?? 0;

                  return StreamBuilder<bool>(
                    stream: currentUser == null
                        ? null
                        : feedRepository.isPostLikedByUser(
                            postId: post.id,
                            userId: currentUser.uid,
                          ),
                    builder: (context, isLikedSnapshot) {
                      final isLiked = isLikedSnapshot.data ?? false;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          TextButton.icon(
                            onPressed: currentUser == null
                                ? null
                                : () => feedRepository.toggleLike(
                                    postId: post.id,
                                    userId: currentUser.uid,
                                  ),
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isLiked ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                            label: Text(
                              'Like ($likeCount)',
                              style: TextStyle(
                                color: isLiked
                                    ? Colors.red
                                    : Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CommentScreen(postId: post.id),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline_rounded,
                              color: Colors.grey,
                              size: 20,
                            ),
                            label: Text(
                              'Comment',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreatePostComposerCard(BuildContext context, User? user) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C7C3AED),
            blurRadius: 10.0,
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
                MaterialPageRoute(builder: (_) => const CreatePostScreen()),
              );
            },
            borderRadius: BorderRadius.circular(16.0),
            child: Row(
              children: [
                if (user != null)
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection(AppConstants.usersCollection)
                        .doc(user.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String? photoUrl;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data();
                        photoUrl =
                            data?['profileImageUrl'] as String? ??
                            data?['photoUrl'] as String? ??
                            user.photoURL;
                      } else {
                        photoUrl = user.photoURL;
                      }

                      return Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 1.5,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20.0,
                          backgroundColor: AppTheme.secondaryColor,
                          backgroundImage:
                              photoUrl != null && photoUrl.isNotEmpty
                              ? NetworkImage(photoUrl)
                              : null,
                          child: photoUrl == null || photoUrl.isEmpty
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                        ),
                      );
                    },
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20.0,
                      backgroundColor: AppTheme.secondaryColor,
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    "What's on your mind? Share with campus...",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.photo_library_rounded,
                      color: Colors.green,
                      size: 20.0,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'Photo',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.blue,
                      size: 20.0,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'Camera',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 16, color: Colors.grey.shade300),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePostScreen()),
                  );
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.edit_note_rounded,
                      color: AppTheme.primaryColor,
                      size: 20.0,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'Write',
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
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

  Widget _buildDefaultWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryLightColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x267C3AED),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to OneCamp! 👋',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Your university hub for messaging, student communities, and campus life.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, User? user, ThemeData theme) {
    if (user == null) {
      return _buildDefaultWelcomeCard(context);
    }

    try {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          String displayName =
              user.displayName ?? user.email?.split('@').first ?? 'Student';
          String role = 'Student';

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data();
            if (data != null) {
              displayName = data['name'] as String? ?? displayName;
              role = (data['role'] as String? ?? 'student').toUpperCase();
            }
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, Colors.deepPurple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x267C3AED),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Welcome back,\n$displayName! 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connect with peers, collaborate in communities, and chat in real-time.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          );
        },
      );
    } catch (_) {
      return _buildDefaultWelcomeCard(context);
    }
  }

  Widget _buildCampusOverviewCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: AppTheme.primaryColor,
                ),
              ),
              title: const Text(
                'Campus Announcements',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              subtitle: const Text(
                'Stay updated with university activities and events.',
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Want to start a new club or group?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const CreateCommunityScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleGrid(BuildContext context) {
    final modules = [
      _ModuleItem(
        'Events & Schedule',
        'University calendar',
        Icons.event_rounded,
        Colors.red,
        () {
          if (onNavigateToTab != null) onNavigateToTab!(1);
        },
      ),
      _ModuleItem(
        'Marketplace',
        'Buy & sell textbooks',
        Icons.storefront_rounded,
        Colors.teal,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketplaceBrowseScreen()),
          );
        },
      ),
      _ModuleItem(
        'Campus Feed',
        'Social posts & news',
        Icons.dynamic_feed_rounded,
        Colors.orange,
        () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedScreen()),
          );
        },
      ),
      _ModuleItem(
        'Student Profile',
        'Academic bio & skills',
        Icons.person_rounded,
        Colors.purple,
        () {
          if (onNavigateToTab != null) onNavigateToTab!(4);
        },
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: modules.length,
      itemBuilder: (context, index) {
        final item = modules[index];
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.icon, color: item.color, size: 26),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModuleItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ModuleItem(this.title, this.subtitle, this.icon, this.color, this.onTap);
}
