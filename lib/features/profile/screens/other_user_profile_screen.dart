import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../../../routes/app_routes.dart';
import '../../chat/repositories/chat_repository.dart';
import '../../chat/screens/call_screen.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../feed/controllers/follow_controller.dart';
import '../../feed/models/post_model.dart';
import '../../feed/screens/post_details_screen.dart';
import '../../feed/screens/student_list_screen.dart';
import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final FollowController _followController = FollowController();
  final FeedController _feedController = FeedController();
  final ChatRepository _chatRepository = ChatRepository();

  UserProfile? _userProfile;
  bool _isLoading = true;
  bool _isFollowPending = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileRepository.getUserProfile(widget.userId);
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleFollowToggle(
    String currentUserId, {
    required bool isFollowing,
  }) async {
    if (currentUserId == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot follow yourself.')),
      );
      return;
    }

    if (_isFollowPending) return;

    if (isFollowing) {
      final bool? confirmUnfollow = await showDialog<bool>(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: Text('Unfollow ${_userProfile?.name ?? 'Student'}?'),
          content: const Text(
            'Their posts will no longer appear in your Following feed.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Unfollow'),
            ),
          ],
        ),
      );

      if (confirmUnfollow != true) return;
    }

    setState(() => _isFollowPending = true);

    try {
      if (isFollowing) {
        await _followController.unfollowUser(
          currentUserId: currentUserId,
          targetUserId: widget.userId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unfollowed ${_userProfile?.name ?? 'student'}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        await _followController.followUser(
          currentUserId: currentUserId,
          targetUserId: widget.userId,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Now following ${_userProfile?.name ?? 'student'}! 🎉',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Follow action failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFollowPending = false);
      }
    }
  }

  Future<void> _startMessage() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final chatId = await _chatRepository.createDirectChat(
        currentUserId: currentUser.uid,
        otherUserId: widget.userId,
      );

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        AppRoutes.chatRoom,
        arguments: {
          'chatId': chatId,
          'title': _userProfile?.name ?? 'Student',
          'isGroup': false,
          'avatarUrl': _userProfile?.profileImageUrl,
          'participantIds': [currentUser.uid, widget.userId],
          'otherUserId': widget.userId,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start conversation: $e')),
      );
    }
  }

  Future<void> _startVoiceCall() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final chatId = await _chatRepository.createDirectChat(
        currentUserId: currentUser.uid,
        otherUserId: widget.userId,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(
            targetId: widget.userId,
            targetName: _userProfile?.name ?? 'Student',
            chatId: chatId,
            isVideo: false,
            isIncoming: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not start call: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser =
            authSnapshot.data ?? FirebaseAuth.instance.currentUser;
        final currentUid = currentUser?.uid;
        final isSelf =
            currentUid != null &&
            currentUid.isNotEmpty &&
            currentUid == widget.userId;

        if (_isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBackground,
            appBar: AppBar(
              title: const Text('Student Profile'),
              backgroundColor: AppTheme.primaryBackground,
              elevation: 0,
              leading: const OneCampBackButton(),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final name = _userProfile?.name ?? 'Student Profile';
        final avatarUrl = _userProfile?.profileImageUrl;
        final university = _userProfile?.university?.isNotEmpty == true
            ? _userProfile!.university!
            : 'OneCamp Verified Student';
        final bio = _userProfile?.bio?.isNotEmpty == true
            ? _userProfile!.bio!
            : 'No bio added yet.';

        return Scaffold(
          backgroundColor: AppTheme.primaryBackground,
          appBar: AppBar(
            title: Text(name),
            backgroundColor: AppTheme.primaryBackground,
            elevation: 0,
            leading: const OneCampBackButton(),
          ),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero Profile Card Container
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x127C3AED),
                              blurRadius: 16.0,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Avatar with Purple Border Ring
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2.5,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 46,
                                backgroundColor: AppTheme.secondaryColor,
                                backgroundImage:
                                    avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                                child: avatarUrl == null || avatarUrl.isEmpty
                                    ? const Icon(
                                        Icons.person_rounded,
                                        size: 48,
                                        color: AppTheme.primaryColor,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 22.0,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(width: 6.0),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 20.0,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              university,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16.0),

                            // Followers / Following Stats Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentListScreen(
                                          initialFilter: 'Followers',
                                          targetUserId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: StreamBuilder<int>(
                                    stream: _followController.getFollowersCount(
                                      widget.userId,
                                    ),
                                    builder: (context, snapshot) {
                                      return _buildStatColumn(
                                        '${snapshot.data ?? 0}',
                                        'Followers',
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.grey.shade200,
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StudentListScreen(
                                          initialFilter: 'Following',
                                          targetUserId: widget.userId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: StreamBuilder<int>(
                                    stream: _followController.getFollowingCount(
                                      widget.userId,
                                    ),
                                    builder: (context, snapshot) {
                                      return _buildStatColumn(
                                        '${snapshot.data ?? 0}',
                                        'Following',
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18.0),

                            // PROMINENT FOLLOW BUTTON & ACTION BAR
                            if (isSelf)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Your Own Profile',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            else if (currentUid != null)
                              Column(
                                children: [
                                  // Prominent Full-Width Follow Button
                                  StreamBuilder<bool>(
                                    stream: _followController.isFollowing(
                                      currentUserId: currentUid,
                                      targetUserId: widget.userId,
                                    ),
                                    builder: (context, followSnapshot) {
                                      final isFollowing =
                                          followSnapshot.data ?? false;
                                      return _buildFollowButton(
                                        currentUid,
                                        isFollowing,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  // Separate Chat & Call Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _startMessage,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.primaryColor,
                                            side: const BorderSide(
                                              color: AppTheme.primaryColor,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.chat_bubble_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Message',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: _startVoiceCall,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                AppTheme.primaryColor,
                                            side: const BorderSide(
                                              color: AppTheme.primaryColor,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.call_rounded,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Call',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // Bio Card
                      Container(
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About Student',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 6.0),
                            Text(
                              bio,
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.grey.shade700,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      const Text(
                        'Posts by Student',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                    ],
                  ),
                ),
              ),

              // User's Posts Feed Stream
              StreamBuilder<List<PostModel>>(
                stream: _feedController.postsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final allPosts = snapshot.data ?? [];
                  final userPosts = allPosts
                      .where((p) => p.authorId == widget.userId)
                      .toList();

                  if (userPosts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No posts published yet.',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = userPosts[index];
                        return _buildUserPostCard(post);
                      }, childCount: userPosts.length),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFollowButton(String currentUserId, bool isFollowing) {
    if (_isFollowPending) {
      return Container(
        height: 48,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.secondaryColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      );
    }

    if (isFollowing) {
      return ElevatedButton.icon(
        onPressed: () => _handleFollowToggle(currentUserId, isFollowing: true),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.secondaryColor,
          foregroundColor: const Color(0xFF1F2937),
          elevation: 0,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.check_rounded, size: 20, color: Colors.green),
        label: const Text(
          'Following',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _handleFollowToggle(currentUserId, isFollowing: false),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      icon: const Icon(Icons.person_add_rounded, size: 20, color: Colors.white),
      label: const Text(
        '+ Follow',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildUserPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C7C3AED),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14.0),
        title: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            post.createdAt.toLocal().toString().split('.')[0],
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PostDetailsScreen(post: post)),
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: TextStyle(fontSize: 11.0, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
