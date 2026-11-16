import '../../profile/models/user_profile.dart';
import '../repositories/user_repository.dart';
import '../repositories/follow_repository.dart';

class FollowController {
  final UserRepository _userRepository;
  final FollowRepository _followRepository;

  FollowController({
    UserRepository? userRepository,
    FollowRepository? followRepository,
  })  : _userRepository = userRepository ?? UserRepository(),
        _followRepository = followRepository ?? FollowRepository();

  // Get all students
  Stream<List<UserProfile>> getUsers() {
    return _userRepository.getUsers();
  }

  // Follow a student
  Future<void> followUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _followRepository.followUser(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }

  // Unfollow a student
  Future<void> unfollowUser({
    required String currentUserId,
    required String targetUserId,
  }) async {
    await _followRepository.unfollowUser(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }

  // Check following status
  Stream<bool> isFollowing({
    required String currentUserId,
    required String targetUserId,
  }) {
    return _followRepository.isFollowing(
      currentUserId: currentUserId,
      targetUserId: targetUserId,
    );
  }

  // Get following count
  Stream<int> getFollowingCount(String userId) {
    return _followRepository.getFollowingCount(userId);
  }

  Stream<int> getFollowersCount(String userId) {
    return _followRepository.getFollowersCount(userId);
  }
}
