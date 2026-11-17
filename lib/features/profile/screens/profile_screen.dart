import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/responsive_form_container.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../feed/models/post_model.dart';
import '../../feed/repositories/follow_repository.dart';
import '../../feed/screens/post_details_screen.dart';
import '../../feed/screens/student_list_screen.dart';
import '../controllers/profile_controller.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _profileController;
  final FollowRepository _followRepository = FollowRepository();
  final FeedController _feedController = FeedController();
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController();

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _profileController.loadProfile(currentUser.uid);
    }
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _confirmLogout() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(80, 40),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      await _logout();
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (error) {
      if (!mounted) return;

      setState(() => _isLoggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your profile.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.primaryColor),
            tooltip: 'Edit Profile',
            onPressed: _isLoggingOut
                ? null
                : () async {
                    final result = await Navigator.pushNamed(
                      context,
                      '/edit-profile',
                    );

                    if (result == true && mounted) {
                      _profileController.loadProfile(currentUser.uid);
                    }
                  },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            tooltip: 'Logout',
            onPressed: _isLoggingOut ? null : _confirmLogout,
          ),
        ],
      ),
      body: _isLoggingOut
          ? const Center(child: CircularProgressIndicator())
          : AnimatedBuilder(
              animation: _profileController,
              builder: (context, child) {
                switch (_profileController.status) {
                  case ProfileStatus.initial:
                  case ProfileStatus.loading:
                    return const Center(child: CircularProgressIndicator());

                  case ProfileStatus.error:
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _profileController.errorMessage ??
                              'Something went wrong.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );

                  case ProfileStatus.success:
                    final UserProfile profile = _profileController.profile!;
                    return _buildProfileContent(profile, theme);
                }
              },
            ),
    );
  }

  Widget _buildProfileContent(UserProfile profile, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return ResponsiveFormContainer(
      maxWidth: 580,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // 1. Header Card (Profile Picture, Name, Email, Role)
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppTheme.lavenderGradient,
              ),
              child: Column(
                children: [
                  // Centered Profile Picture with Purple Border Ring
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 42,
                      backgroundColor: AppTheme.secondaryColor,
                      backgroundImage:
                          profile.profileImageUrl != null &&
                              profile.profileImageUrl!.isNotEmpty
                          ? NetworkImage(profile.profileImageUrl!)
                          : null,
                      child:
                          profile.profileImageUrl == null ||
                              profile.profileImageUrl!.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 44,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name with Verified Checkmark Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.check_circle_rounded,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Academic Subtitle (e.g. Degree · Year X · Faculty)
                  if ([
                    profile.degree,
                    profile.academicYear != null
                        ? 'Year ${profile.academicYear}'
                        : null,
                    profile.faculty,
                  ].any((element) => element?.isNotEmpty == true))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        [
                          if (profile.degree?.isNotEmpty == true)
                            profile.degree,
                          if (profile.academicYear != null)
                            'Year ${profile.academicYear}',
                          if (profile.faculty?.isNotEmpty == true)
                            profile.faculty,
                        ].join(' · '),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),

                  // User Email
                  Text(
                    profile.email,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : const Color(0xFF1F2937),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Real Followers / Following Counters
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0C7C3AED),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentListScreen(
                                  initialFilter: 'Followers',
                                  targetUserId: profile.uid,
                                ),
                              ),
                            );
                          },
                          child: StreamBuilder<int>(
                            stream: _followRepository.getFollowersCount(
                              profile.uid,
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
                                  targetUserId: profile.uid,
                                ),
                              ),
                            );
                          },
                          child: StreamBuilder<int>(
                            stream: _followRepository.getFollowingCount(
                              profile.uid,
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
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 2. "About You" White Rounded Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'About You',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3730A3)
                              : AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'PROFILE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bio Box
                  _buildInfoBox(
                    label: 'BIO',
                    value: profile.bio?.isNotEmpty == true
                        ? profile.bio!
                        : 'Not added',
                    icon: Icons.notes_rounded,
                    theme: theme,
                  ),

                  const SizedBox(height: 8),

                  // Skills Section
                  Text(
                    'SKILLS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (profile.skills.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.skills
                          .map(
                            (skill) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                skill,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF231F4C)
                            : const Color(0xFFF8F6FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3730A3)
                              : const Color(0xFFE8E3FA),
                        ),
                      ),
                      child: Text(
                        'Not added',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Interests Section
                  Text(
                    'INTERESTS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (profile.interests.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.interests
                          .map(
                            (interest) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF3730A3)
                                    : AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF4C1D95)
                                      : const Color(0xFFDDD6FE),
                                ),
                              ),
                              child: Text(
                                interest,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF231F4C)
                            : const Color(0xFFF8F6FE),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF3730A3)
                              : const Color(0xFFE8E3FA),
                        ),
                      ),
                      child: Text(
                        'Not added',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.grey.shade500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. "Academic Information" White Rounded Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // University Box
                  _buildInfoBox(
                    label: 'UNIVERSITY',
                    value: profile.university?.isNotEmpty == true
                        ? profile.university!
                        : 'Not added',
                    icon: Icons.account_balance_outlined,
                    theme: theme,
                  ),

                  // Faculty Box
                  _buildInfoBox(
                    label: 'FACULTY',
                    value: profile.faculty?.isNotEmpty == true
                        ? profile.faculty!
                        : 'Not added',
                    icon: Icons.domain_outlined,
                    theme: theme,
                  ),

                  // Degree / Programme Box
                  _buildInfoBox(
                    label: 'DEGREE / PROGRAMME',
                    value: profile.degree?.isNotEmpty == true
                        ? profile.degree!
                        : 'Not added',
                    icon: Icons.school_outlined,
                    theme: theme,
                  ),

                  // Department Box
                  _buildInfoBox(
                    label: 'DEPARTMENT',
                    value: profile.department?.isNotEmpty == true
                        ? profile.department!
                        : 'Not added',
                    icon: Icons.business_outlined,
                    theme: theme,
                  ),

                  // Academic Year Box
                  _buildInfoBox(
                    label: 'ACADEMIC YEAR',
                    value: profile.academicYear != null
                        ? 'Year ${profile.academicYear}'
                        : 'Not added',
                    icon: Icons.calendar_today_outlined,
                    theme: theme,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 4. "My Authored Posts" Stream Section (Requirement 3)
          _buildMyPostsSection(profile.uid, theme),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMyPostsSection(String userId, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'My Authored Posts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        StreamBuilder<List<PostModel>>(
          stream: _feedController.postsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final allPosts = snapshot.data ?? [];
            final myPosts = allPosts
                .where((p) => p.authorId == userId)
                .toList();

            if (myPosts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    'No posts published yet.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }

            return Column(
              children: myPosts.map((post) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C7C3AED),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        post.createdAt.toLocal().toString().split('.')[0],
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailsScreen(post: post),
                        ),
                      );
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatColumn(String number, String label) {
    return Column(
      children: [
        Text(
          number,
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 2.0),
        Text(
          label,
          style: TextStyle(fontSize: 11.0, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    final boxBgColor = isDark
        ? const Color(0xFF231F4C)
        : const Color(0xFFF8F6FE);

    final borderColor = isDark
        ? const Color(0xFF3730A3)
        : const Color(0xFFE8E3FA);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: boxBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x803730A3) : AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
