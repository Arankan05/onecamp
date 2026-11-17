import 'package:cloud_firestore/cloud_firestore.dart';

import '../../notifications/services/notification_service.dart';

class FollowRepository {
  final FirebaseFirestore _firestore;
  final NotificationService _notificationService = NotificationService();

  FollowRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Follow another student
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    if (currentUserId == targetUserId) {
      throw ArgumentError('You cannot follow yourself.');
    }

    final batch = _firestore.batch();

    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    final followersRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    batch.set(followingRef, {
      'userId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    batch.set(followersRef, {
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // Trigger persistent in-app notification
    await _notificationService.sendNotification(
      recipientUserId: targetUserId,
      actorId: currentUserId,
      type: 'follow',
      title: 'New Follower',
      body: 'A campus student started following your profile.',
      targetId: currentUserId,
    );
  }

  // Unfollow a student
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    final batch = _firestore.batch();

    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    final followersRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    batch.delete(followingRef);
    batch.delete(followersRef);

    await batch.commit();
  }

  // Check following status
  Stream<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Get following count
  Stream<int> getFollowingCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get followers count
  Stream<int> getFollowersCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Get list of followed user IDs
  Stream<List<String>> getFollowingUserIdsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .map((snapshot) {
          final Set<String> ids = {};
          for (final doc in snapshot.docs) {
            ids.add(doc.id);
            final data = doc.data();
            final uidVal = data['userId'] as String?;
            if (uidVal != null && uidVal.isNotEmpty) {
              ids.add(uidVal);
            }
          }
          return ids.toList();
        });
  }

  // Get list of follower user IDs
  Stream<List<String>> getFollowerUserIdsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots()
        .map((snapshot) {
          final Set<String> ids = {};
          for (final doc in snapshot.docs) {
            ids.add(doc.id);
            final data = doc.data();
            final uidVal = data['userId'] as String?;
            if (uidVal != null && uidVal.isNotEmpty) {
              ids.add(uidVal);
            }
          }
          return ids.toList();
        });
  }
}
