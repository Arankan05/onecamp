import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../../../routes/app_routes.dart';
import '../../events/repositories/event_repository.dart';
import '../../feed/repositories/feed_repository.dart';
import '../../feed/screens/post_details_screen.dart';
import '../../profile/screens/other_user_profile_screen.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final FeedRepository _feedRepository = FeedRepository();
  final EventRepository _eventRepository = EventRepository();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.primaryBackground,
        appBar: AppBar(
          title: const Text('Notifications'),
          backgroundColor: AppTheme.primaryBackground,
          elevation: 0,
          leading: const OneCampBackButton(),
        ),
        body: const Center(child: Text('Please log in to view notifications.')),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: const OneCampBackButton(),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead(user.uid);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications marked as read'),
                ),
              );
            },
            child: const Text(
              'Mark all read',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getUserNotificationsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Could not load notifications.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'No notifications yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Follow students, like posts, and join events to see updates here.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            physics: const BouncingScrollPhysics(),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final item = notifications[index];
              return _buildNotificationTile(context, item);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel item) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case 'follow':
        icon = Icons.person_add_rounded;
        iconColor = AppTheme.primaryColor;
        break;
      case 'like':
        icon = Icons.favorite_rounded;
        iconColor = Colors.red;
        break;
      case 'comment':
        icon = Icons.chat_bubble_rounded;
        iconColor = Colors.blue;
        break;
      case 'event':
        icon = Icons.event_rounded;
        iconColor = Colors.orange;
        break;
      case 'chat':
        icon = Icons.forum_rounded;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.notifications_rounded;
        iconColor = AppTheme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: item.isRead
            ? Colors.white
            : AppTheme.secondaryColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: item.isRead
              ? Colors.grey.shade200
              : AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.secondaryColor,
              backgroundImage:
                  item.actorAvatarUrl != null && item.actorAvatarUrl!.isNotEmpty
                  ? NetworkImage(item.actorAvatarUrl!)
                  : null,
              child: item.actorAvatarUrl == null || item.actorAvatarUrl!.isEmpty
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryColor,
                      size: 22,
                    )
                  : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 12, color: iconColor),
              ),
            ),
          ],
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: item.isRead ? FontWeight.bold : FontWeight.w900,
            fontSize: 14,
            color: const Color(0xFF1F2937),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.body,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              item.createdAt.toLocal().toString().split('.')[0],
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: !item.isRead
            ? Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () async {
          await _notificationService.markAsRead(item.id);

          if (!context.mounted) return;

          if (item.type == 'follow') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtherUserProfileScreen(userId: item.actorId),
              ),
            );
          } else if (item.type == 'like' || item.type == 'comment') {
            if (item.targetId != null) {
              final post = await _feedRepository.getPostById(item.targetId!);
              if (!context.mounted) return;
              if (post != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailsScreen(post: post),
                  ),
                );
              }
            }
          } else if (item.type == 'event') {
            if (item.targetId != null) {
              final event = await _eventRepository.getEvent(item.targetId!);
              if (!context.mounted) return;
              if (event != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.eventDetails,
                  arguments: event,
                );
              }
            }
          } else if (item.type == 'chat') {
            Navigator.pushNamed(context, AppRoutes.chatList);
          }
        },
      ),
    );
  }
}
