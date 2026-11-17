import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore;

  NotificationService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Send persistent in-app notification to target user.
  Future<void> sendNotification({
    required String recipientUserId,
    required String actorId,
    required String type, // 'follow', 'like', 'comment', 'event', 'chat'
    required String title,
    required String body,
    String? targetId,
  }) async {
    // Avoid self-notification
    if (recipientUserId.isEmpty || recipientUserId == actorId) return;

    try {
      // Fetch actor profile for display name & avatar
      final actorDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(actorId)
          .get();

      String actorName = 'Campus Peer';
      String? actorAvatarUrl;

      if (actorDoc.exists && actorDoc.data() != null) {
        final data = actorDoc.data()!;
        actorName =
            data['name'] as String? ??
            data['displayName'] as String? ??
            'Campus Peer';
        actorAvatarUrl =
            data['profileImageUrl'] as String? ?? data['photoUrl'] as String?;
      }

      // De-duplicate recent identical unread notifications
      final query = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: recipientUserId)
          .where('actorId', isEqualTo: actorId)
          .where('type', isEqualTo: type)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty && targetId != null) {
        final existingDoc = query.docs.first;
        if (existingDoc.data()['targetId'] == targetId) {
          // Update timestamp of existing unread notification
          await existingDoc.reference.update({
            'createdAt': FieldValue.serverTimestamp(),
            'body': body,
          });
          return;
        }
      }

      // Add new notification document
      await _firestore.collection(AppConstants.notificationsCollection).add({
        'userId': recipientUserId,
        'actorId': actorId,
        'actorName': actorName,
        'actorAvatarUrl': actorAvatarUrl,
        'type': type,
        'title': title,
        'body': body,
        'targetId': targetId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Ignore background notification write failures safely
    }
  }

  /// Stream notifications for logged-in user.
  Stream<List<NotificationModel>> getUserNotificationsStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => NotificationModel.fromDocument(doc))
              .toList();

          // Client-side sort by createdAt descending
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Stream unread notification count.
  Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (_) {}
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (_) {}
  }
}
