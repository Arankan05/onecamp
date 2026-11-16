import '../../profile/models/user_profile.dart';
import '../../profile/repositories/profile_repository.dart';

/// Looks up a user's name and picture using Member 1's ProfileRepository.
/// Remembers results so the same person is never fetched twice.
class UserLookup {
  UserLookup({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;
  final Map<String, Future<UserProfile?>> _cache = {};

  Future<UserProfile?> getUser(String uid) {
    return _cache.putIfAbsent(uid, () async {
      try {
        return await _repository.getUserProfile(uid);
      } catch (_) {
        return null;
      }
    });
  }
}

String shortId(String id) => id.length > 6 ? id.substring(0, 6) : id;