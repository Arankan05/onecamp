import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../../profile/models/user_profile.dart';
import '../../profile/screens/other_user_profile_screen.dart';
import '../controllers/follow_controller.dart';
import '../repositories/follow_repository.dart';

class StudentListScreen extends StatefulWidget {
  final String initialFilter;
  final String? targetUserId;

  const StudentListScreen({
    super.key,
    this.initialFilter = 'All',
    this.targetUserId,
  });

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final FollowController _controller = FollowController();
  final FollowRepository _followRepository = FollowRepository();
  final TextEditingController _searchController = TextEditingController();

  late String _selectedFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final activeUserId = widget.targetUserId ?? currentUser?.uid;

    if (currentUser == null || activeUserId == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        appBar: AppBar(title: const Text('Students')),
        body: const Center(child: Text('Please sign in to view students.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Students & Connections'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: const OneCampBackButton(),
      ),
      body: Column(
        children: [
          // Search Bar & Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                Container(
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
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search students by name or email...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Category Filter Chips
                Row(
                  children: [
                    _buildFilterChip('All Students', 'All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Following', 'Following'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Followers', 'Followers'),
                  ],
                ),
              ],
            ),
          ),

          // Student List Stream
          Expanded(
            child: StreamBuilder<List<UserProfile>>(
              stream: _controller.getUsers(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading students: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allStudents = snapshot.data ?? [];

                if (_selectedFilter == 'Following') {
                  return StreamBuilder<List<String>>(
                    stream: _followRepository.getFollowingUserIdsStream(
                      activeUserId,
                    ),
                    builder: (context, followingSnapshot) {
                      if (followingSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (followingSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading following list: ${followingSnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final followingIds = followingSnapshot.data ?? [];
                      final filtered = allStudents
                          .where((s) => followingIds.contains(s.uid))
                          .toList();
                      return _buildStudentListView(
                        context,
                        currentUser.uid,
                        filtered,
                      );
                    },
                  );
                } else if (_selectedFilter == 'Followers') {
                  return StreamBuilder<List<String>>(
                    stream: _followRepository.getFollowerUserIdsStream(
                      activeUserId,
                    ),
                    builder: (context, followersSnapshot) {
                      if (followersSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (followersSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading followers list: ${followersSnapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }

                      final followerIds = followersSnapshot.data ?? [];
                      final filtered = allStudents
                          .where((s) => followerIds.contains(s.uid))
                          .toList();
                      return _buildStudentListView(
                        context,
                        currentUser.uid,
                        filtered,
                      );
                    },
                  );
                }

                final otherStudents = allStudents
                    .where((s) => s.uid != currentUser.uid)
                    .toList();
                return _buildStudentListView(
                  context,
                  currentUser.uid,
                  otherStudents,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1F2937),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }

  Widget _buildStudentListView(
    BuildContext context,
    String currentUserId,
    List<UserProfile> students,
  ) {
    var filtered = students;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      filtered = filtered
          .where(
            (s) =>
                s.name.toLowerCase().contains(q) ||
                s.email.toLowerCase().contains(q) ||
                (s.university?.toLowerCase().contains(q) ?? false) ||
                (s.faculty?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    if (filtered.isEmpty) {
      String emptyMessage;
      if (_searchQuery.trim().isNotEmpty) {
        emptyMessage = 'No students match "$_searchQuery".';
      } else if (_selectedFilter == 'Following') {
        emptyMessage = 'Not following any students yet.';
      } else if (_selectedFilter == 'Followers') {
        emptyMessage = 'No followers yet.';
      } else {
        emptyMessage = 'No students found.';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final student = filtered[index];
        final isSelf = student.uid == currentUserId;

        final subtitleText = student.university?.isNotEmpty == true
            ? '${student.university} • ${student.email}'
            : student.email;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 22,
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
                    )
                  : null,
            ),
            title: Text(
              student.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1F2937),
              ),
            ),
            subtitle: Text(
              subtitleText,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: isSelf
                ? null
                : StreamBuilder<bool>(
                    stream: _controller.isFollowing(
                      currentUserId: currentUserId,
                      targetUserId: student.uid,
                    ),
                    builder: (context, followSnapshot) {
                      final isFollowing = followSnapshot.data ?? false;

                      return ElevatedButton(
                        onPressed: followSnapshot.hasError
                            ? null
                            : () async {
                                try {
                                  if (isFollowing) {
                                    await _controller.unfollowUser(
                                      currentUserId: currentUserId,
                                      targetUserId: student.uid,
                                    );
                                  } else {
                                    await _controller.followUser(
                                      currentUserId: currentUserId,
                                      targetUserId: student.uid,
                                    );
                                  }
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Action failed: $e'),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? Colors.grey.shade200
                              : AppTheme.primaryColor,
                          foregroundColor: isFollowing
                              ? const Color(0xFF1F2937)
                              : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(isFollowing ? 'Following' : 'Follow'),
                      );
                    },
                  ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtherUserProfileScreen(userId: student.uid),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
