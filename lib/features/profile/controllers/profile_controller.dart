
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';
import '../repositories/profile_repository.dart';

enum ProfileStatus {
  initial,
  loading,
  success,
  error,
}

class ProfileController extends ChangeNotifier {
  final ProfileRepository _profileRepository;

  ProfileStatus _status = ProfileStatus.initial;
  UserProfile? _profile;
  String? _errorMessage;

  ProfileController({
    ProfileRepository? profileRepository,
  }) : _profileRepository =
      profileRepository ?? ProfileRepository();

  ProfileStatus get status => _status;
  UserProfile? get profile => _profile;
  String? get errorMessage => _errorMessage;

  Future<void> loadProfile(String uid) async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileRepository.getUserProfile(uid);

      if (_profile == null) {
        _status = ProfileStatus.error;
        _errorMessage = 'User profile not found.';
      } else {
        _status = ProfileStatus.success;
      }
    } catch (_) {
      _status = ProfileStatus.error;
      _errorMessage = 'Failed to load profile.';
    }

    notifyListeners();
  }


  Future<bool> updateProfile({
    required String uid,
    required String name,
    required String bio,
    required String department,
    required int? academicYear,
    String? profileImageUrl,
  }) async {
    _status = ProfileStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _profileRepository.updateUserProfile(
        uid: uid,
        name: name,
        bio: bio,
        department: department,
        academicYear: academicYear,
        profileImageUrl: profileImageUrl,
      );

      await loadProfile(uid);
      return _status == ProfileStatus.success;
    } catch (_) {
      _status = ProfileStatus.error;
      _errorMessage = 'Failed to update profile.';
      notifyListeners();
      return false;
    }
  }

}
