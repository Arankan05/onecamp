import 'package:flutter/material.dart';

import '../../profile/models/user_profile.dart';
import '../community_constants.dart';
import '../controllers/community_controller.dart';
import '../controllers/user_lookup.dart';
import '../models/community_member.dart';

class MembersTab extends StatefulWidget {
  const MembersTab({
    super.key,
    required this.controller,
    required this.communityId,
  });

  final CommunityController controller;
  final String communityId;

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> {
  final UserLookup _lookup = UserLookup();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityMember>>(
      stream: widget.controller.watchMembers(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Could not load members.'));
        }

        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return const Center(child: Text('No members yet.'));
        }

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isCreator = member.role == CommunityConstants.roleCreator;

            return FutureBuilder<UserProfile?>(
              future: _lookup.getUser(member.userId),
              builder: (context, userSnapshot) {
                final user = userSnapshot.data;
                final name = (user != null && user.name.isNotEmpty)
                    ? user.name
                    : 'Member ${shortId(member.userId)}';
                final imageUrl = user?.profileImageUrl;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                        ? NetworkImage(imageUrl)
                        : null,
                    child: (imageUrl != null && imageUrl.isNotEmpty)
                        ? null
                        : const Icon(Icons.person),
                  ),
                  title: Text(name),
                  subtitle: isCreator ? const Text('Creator') : null,
                );
              },
            );
          },
        );
      },
    );
  }
}