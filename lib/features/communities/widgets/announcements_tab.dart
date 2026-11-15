import 'package:flutter/material.dart';

import '../controllers/community_controller.dart';
import '../models/announcement.dart';

class AnnouncementsTab extends StatelessWidget {
  const AnnouncementsTab({
    super.key,
    required this.controller,
    required this.communityId,
    required this.isCreator,
  });

  final CommunityController controller;
  final String communityId;
  final bool isCreator;

  Future<void> _showAddDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('New announcement'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 3) return 'At least 3 characters';
                    return null;
                  },
                ),
                TextFormField(
                  controller: bodyController,
                  maxLength: 500,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Message'),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.length < 5) return 'At least 5 characters';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Post'),
            ),
          ],
        );
      },
    );

    if (shouldSave != true) {
      titleController.dispose();
      bodyController.dispose();
      return;
    }

    final success = await controller.addAnnouncement(
      communityId,
      titleController.text,
      bodyController.text,
    );
    titleController.dispose();
    bodyController.dispose();

    if (!context.mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Something went wrong.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: isCreator
          ? FloatingActionButton(
              tooltip: 'Add announcement',
              onPressed: () => _showAddDialog(context),
              child: const Icon(Icons.campaign),
            )
          : null,
      body: StreamBuilder<List<Announcement>>(
        stream: controller.watchAnnouncements(communityId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load announcements.'));
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No announcements yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.campaign),
                  title: Text(item.title),
                  subtitle: Text(item.body),
                ),
              );
            },
          );
        },
      ),
    );
  }
}