import 'package:flutter/material.dart';

import '../controllers/community_controller.dart';
import '../models/community.dart';
import '../widgets/members_tab.dart';

class CommunityDetailsScreen extends StatefulWidget {
  const CommunityDetailsScreen({super.key, required this.communityId});

  final String communityId;

  @override
  State<CommunityDetailsScreen> createState() =>
      _CommunityDetailsScreenState();
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
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('Could not load this community.'),
            ),
          );
        }

        final community = snapshot.data;
        if (community == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This community no longer exists.')),
          );
        }

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(community.name),
              bottom: const TabBar(
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
                      const Center(child: Text('Posts coming next')),
                      const Center(child: Text('Announcements coming next')),
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
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(community.description),
          const SizedBox(height: 8),
          Chip(label: Text(community.category)),
          const SizedBox(height: 8),
          StreamBuilder<bool>(
            stream: _controller.watchIsMember(widget.communityId),
            builder: (context, memberSnapshot) {
              final isMember = memberSnapshot.data ?? false;
              return ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  if (_controller.isLoading) {
                    return const CircularProgressIndicator();
                  }
                  return isMember
                      ? OutlinedButton(
                          onPressed: () => _toggleMembership(true),
                          child: const Text('Leave'),
                        )
                      : ElevatedButton(
                          onPressed: () => _toggleMembership(false),
                          child: const Text('Join'),
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