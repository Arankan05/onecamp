import 'package:flutter/material.dart';

import '../community_constants.dart';
import '../controllers/community_controller.dart';
import '../models/community_member.dart';

class MembersTab extends StatelessWidget {
  const MembersTab({
    super.key,
    required this.controller,
    required this.communityId,
  });

  final CommunityController controller;
  final String communityId;

  String _shortId(String id) => id.length > 6 ? id.substring(0, 6) : id;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CommunityMember>>(
      stream: controller.watchMembers(communityId),
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
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text('Member ${_shortId(member.userId)}'),
              subtitle: isCreator ? const Text('Creator') : null,
            );
          },
        );
      },
    );
  }
}