import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../models/campus_update_model.dart';
import '../repositories/campus_repository.dart';

/// UI Screen displaying official campus announcements and news updates.
class CampusUpdatesScreen extends StatefulWidget {
  final CampusRepository? repository;

  const CampusUpdatesScreen({super.key, this.repository});

  @override
  State<CampusUpdatesScreen> createState() => _CampusUpdatesScreenState();
}

class _CampusUpdatesScreenState extends State<CampusUpdatesScreen> {
  late final CampusRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CampusRepository();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Campus Updates'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: const OneCampBackButton(),
      ),
      body: StreamBuilder<List<CampusUpdateModel>>(
        stream: _repository.watchCampusUpdates(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error loading campus updates: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final updates = snapshot.data ?? [];
          if (updates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.campaign_outlined,
                    size: 64,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No official campus updates posted yet.',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: updates.length,
            itemBuilder: (context, index) {
              final update = updates[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (update.isUrgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'URGENT',
                                style: TextStyle(
                                  color: Colors.red.shade900,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          Chip(
                            label: Text(
                              update.category,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          const Spacer(),
                          Text(
                            update.createdAt.toString().split(' ')[0],
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        update.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        update.body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF374151),
                          height: 1.4,
                        ),
                      ),
                      if (update.authorName.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Posted by ${update.authorName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ],
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
