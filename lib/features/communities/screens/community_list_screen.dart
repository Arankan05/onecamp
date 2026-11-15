import 'package:flutter/material.dart';

import '../controllers/community_controller.dart';
import '../models/community.dart';
import 'community_details_screen.dart';
import 'create_community_screen.dart';

class CommunityListScreen extends StatefulWidget {
  const CommunityListScreen({super.key});

  @override
  State<CommunityListScreen> createState() => _CommunityListScreenState();
}

class _CommunityListScreenState extends State<CommunityListScreen> {
  final CommunityController _controller = CommunityController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create community',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CreateCommunityScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Community>>(
        stream: _controller.communities,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load communities. Please try again.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final communities = snapshot.data ?? [];
          if (communities.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No communities yet.\nBe the first to create one!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: communities.length,
            itemBuilder: (context, index) {
              final community = communities[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      community.name.isNotEmpty
                          ? community.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(community.name),
                  subtitle: Text(
                    community.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Chip(label: Text(community.category)),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            CommunityDetailsScreen(communityId: community.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}