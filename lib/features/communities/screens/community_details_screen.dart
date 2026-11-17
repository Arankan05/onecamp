import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../controllers/community_controller.dart';
import '../models/community.dart';
import '../widgets/announcements_tab.dart';
import '../widgets/members_tab.dart';
import '../widgets/posts_tab.dart';

class CommunityDetailsScreen extends StatefulWidget {
  const CommunityDetailsScreen({super.key, required this.communityId});

  final String communityId;

  @override
  State<CommunityDetailsScreen> createState() => _CommunityDetailsScreenState();
}

class _CommunityDetailsScreenState extends State<CommunityDetailsScreen> {
  final CommunityController _controller = CommunityController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleMembership(bool isMember) async {
    final success = isMember
        ? await _controller.leave(widget.communityId)
        : await _controller.join(widget.communityId);

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Something went wrong.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Community?>(
      stream: _controller.watchCommunity(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryBackground,
              elevation: 0,
              leading: const OneCampBackButton(),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryBackground,
              elevation: 0,
              leading: const OneCampBackButton(),
            ),
            body: const Center(child: Text('Could not load this community.')),
          );
        }

        final community = snapshot.data;
        if (community == null) {
          return Scaffold(
            backgroundColor: AppTheme.primaryBackground,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryBackground,
              elevation: 0,
              leading: const OneCampBackButton(),
            ),
            body: const Center(child: Text('This community no longer exists.')),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: AppTheme.primaryBackground,
            appBar: AppBar(
              title: Text(community.name),
              backgroundColor: AppTheme.primaryBackground,
              elevation: 0,
              leading: const OneCampBackButton(),
              bottom: const TabBar(
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: 'Posts'),
                  Tab(text: 'Announcements'),
                  Tab(text: 'Members'),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildHeader(community),
                Expanded(
                  child: TabBarView(
                    children: [
                      PostsTab(
                        controller: _controller,
                        communityId: widget.communityId,
                      ),
                      AnnouncementsTab(
                        controller: _controller,
                        communityId: widget.communityId,
                        isCreator:
                            community.createdBy == _controller.currentUserId,
                      ),
                      MembersTab(
                        controller: _controller,
                        communityId: widget.communityId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Community community) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.secondaryColor,
                child: Text(
                  community.name.isNotEmpty
                      ? community.name[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        community.category,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            community.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<bool>(
            stream: _controller.watchIsMember(widget.communityId),
            builder: (context, memberSnapshot) {
              final isMember = memberSnapshot.data ?? false;
              return ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return SizedBox(
                    width: double.infinity,
                    child: isMember
                        ? OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey.shade800,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text(
                              'Joined Community',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _toggleMembership(true),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            icon: const Icon(Icons.group_add_rounded, size: 18),
                            label: const Text(
                              'Join Community',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _toggleMembership(false),
                          ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
