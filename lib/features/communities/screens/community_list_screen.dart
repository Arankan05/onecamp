import 'package:flutter/material.dart';

import '../controllers/community_controller.dart';
import '../models/community.dart';

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
      body: StreamBuilder<List<Community>>(
        stream: _controller.communities,
        builder: (context, snapshot) {
          // 1. Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Error
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

          // 3. Empty
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

          // 4. List
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
                    // Details screen comes in the next step.
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