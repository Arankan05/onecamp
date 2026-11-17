import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../models/community.dart';
import '../models/community_member.dart';
import '../models/community_post.dart';
import '../repositories/community_repository.dart';

class CommunityController extends ChangeNotifier {
  CommunityController({CommunityRepository? repository})
    : _repository = repository ?? CommunityRepository();

  final CommunityRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// The logged-in user's ID (null if nobody is logged in).
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // Streams the screens listen to
  Stream<List<Community>> get communities => _repository.watchCommunities();
  Stream<Community?> watchCommunity(String id) =>
      _repository.watchCommunity(id);
  Stream<List<CommunityMember>> watchMembers(String id) =>
      _repository.watchMembers(id);
  Stream<List<CommunityPost>> watchPosts(String id) =>
      _repository.watchPosts(id);
  Stream<List<Announcement>> watchAnnouncements(String id) =>
      _repository.watchAnnouncements(id);

  Stream<bool> watchIsMember(String communityId) {
    final uid = currentUserId;
    if (uid == null) return Stream.value(false);
    return _repository.watchIsMember(communityId, uid);
  }

  /// Runs an action, handling loading and errors in one place.
  Future<bool> _run(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on FirebaseException catch (e) {
      _errorMessage = e.code == 'permission-denied'
          ? 'You do not have permission to do that.'
          : 'Something went wrong. Please try again.';
      return false;
    } catch (_) {
      _errorMessage = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCommunity({
    required String name,
    required String description,
    required String category,
  }) {
    final uid = currentUserId;
    if (uid == null) {
      _errorMessage = 'Please log in first.';
      notifyListeners();
      return Future.value(false);
    }
    return _run(
      () => _repository.createCommunity(
        name: name,
        description: description,
        category: category,
        userId: uid,
      ),
    );
  }

  Future<bool> join(String communityId) {
    final uid = currentUserId;
    if (uid == null) return Future.value(false);
    return _run(() => _repository.joinCommunity(communityId, uid));
  }

  Future<bool> leave(String communityId) {
    final uid = currentUserId;
    if (uid == null) return Future.value(false);
    return _run(() => _repository.leaveCommunity(communityId, uid));
  }

  Future<bool> addPost(String communityId, String text) {
    final uid = currentUserId;
    if (uid == null) return Future.value(false);
    return _run(
      () => _repository.addPost(
        communityId: communityId,
        authorId: uid,
        text: text,
      ),
    );
  }

  Future<bool> addAnnouncement(String communityId, String title, String body) {
    return _run(
      () => _repository.addAnnouncement(
        communityId: communityId,
        title: title,
        body: body,
      ),
    );
  }
}
