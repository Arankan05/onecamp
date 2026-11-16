import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../community_constants.dart';
import '../models/announcement.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_post.dart';

class CommunityRepository {
  CommunityRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // ---------- Collection helpers ----------

  CollectionReference<Map<String, dynamic>> get _communities =>
      _firestore.collection(AppConstants.communitiesCollection);

  CollectionReference<Map<String, dynamic>> _members(String communityId) =>
      _communities
          .doc(communityId)
          .collection(CommunityConstants.membersCollection);

  CollectionReference<Map<String, dynamic>> _posts(String communityId) =>
      _communities
          .doc(communityId)
          .collection(CommunityConstants.postsCollection);

  CollectionReference<Map<String, dynamic>> _announcements(
          String communityId) =>
      _communities
          .doc(communityId)
          .collection(CommunityConstants.announcementsCollection);

  // ---------- Communities ----------

  /// Live list of all communities, newest first.
  Stream<List<Community>> watchCommunities() {
    return _communities
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Community.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Live data for one community.
  Stream<Community?> watchCommunity(String communityId) {
    return _communities.doc(communityId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return Community.fromMap(doc.id, data);
    });
  }

  /// Create a community and add the creator as its first member.
  Future<String> createCommunity({
    required String name,
    required String description,
    required String category,
    required String userId,
  }) async {
    final docRef = _communities.doc();
    final community = Community(
      id: docRef.id,
      name: name.trim(),
      description: description.trim(),
      category: category,
      createdBy: userId,
      createdAt: DateTime.now(),
    );

    await docRef.set(community.toMap());

    await _members(docRef.id).doc(userId).set({
      'role': CommunityConstants.roleCreator,
      'joinedAt': Timestamp.now(),
    });

    return docRef.id;
  }

  // ---------- Join / Leave ----------

  /// Join = create your own member document (ID = your UID).
  Future<void> joinCommunity(String communityId, String userId) {
    return _members(communityId).doc(userId).set({
      'role': CommunityConstants.roleMember,
      'joinedAt': Timestamp.now(),
    });
  }

  /// Leave = delete your own member document.
  Future<void> leaveCommunity(String communityId, String userId) {
    return _members(communityId).doc(userId).delete();
  }

  /// Live true/false: is this user a member?
  Stream<bool> watchIsMember(String communityId, String userId) {
    return _members(communityId)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  // ---------- Members ----------

  Stream<List<CommunityMember>> watchMembers(String communityId) {
    return _members(communityId)
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityMember.fromMap(doc.id, doc.data()))
            .toList());
  }

  // ---------- Posts (discussions) ----------

  Stream<List<CommunityPost>> watchPosts(String communityId) {
    return _posts(communityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommunityPost.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addPost({
    required String communityId,
    required String authorId,
    required String text,
  }) {
    final post = CommunityPost(
      id: '',
      authorId: authorId,
      text: text.trim(),
      createdAt: DateTime.now(),
    );
    return _posts(communityId).add(post.toMap());
  }

  // ---------- Announcements ----------

  Stream<List<Announcement>> watchAnnouncements(String communityId) {
    return _announcements(communityId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Announcement.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Only the community creator is allowed by the security rules.
  Future<void> addAnnouncement({
    required String communityId,
    required String title,
    required String body,
  }) {
    final announcement = Announcement(
      id: '',
      title: title.trim(),
      body: body.trim(),
      createdAt: DateTime.now(),
    );
    return _announcements(communityId).add(announcement.toMap());
  }
}