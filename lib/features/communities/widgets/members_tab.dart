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
          return const Center(
            child: Text(
              'Could not load members.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 15),
            ),
          );
        }

        final members = snapshot.data ?? [];
        if (members.isEmpty) {
          return const Center(
            child: Text(
              'No members yet.',
              style: TextStyle(color: Color(0xFF4B5563), fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isCreator = member.role == CommunityConstants.roleCreator;
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFDDD6FE),
                  child: const Icon(Icons.person, color: Color(0xFF7C3AED)),
                ),
                title: Text(
                  'Member ${_shortId(member.userId)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                subtitle: isCreator
                    ? const Text(
                        'Creator',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
