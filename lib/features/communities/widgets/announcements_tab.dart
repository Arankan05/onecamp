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
          title: const Text(
            'New announcement',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    maxLength: 80,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Announcement headline...',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 3) return 'At least 3 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: bodyController,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Write announcement details...',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 5) return 'At least 5 characters';
                      return null;
                    },
                  ),
                ],
              ),
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
            return const Center(
              child: Text(
                'Could not load announcements.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'No announcements yet.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.campaign_rounded,
                    color: Color(0xFF7C3AED),
                    size: 28,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    item.body,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
