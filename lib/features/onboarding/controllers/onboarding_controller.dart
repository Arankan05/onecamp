import 'package:flutter/foundation.dart';

import '../../profile/repositories/profile_repository.dart';

enum OnboardingStatus {
  initial,
  loading,
  success,
  error,
}

class OnboardingController extends ChangeNotifier {
  final ProfileRepository? profileRepository;

  OnboardingStatus _status = OnboardingStatus.initial;
  String? _errorMessage;

  OnboardingController({
    this.profileRepository,
  });

  ProfileRepository get _repository =>
      profileRepository ?? ProfileRepository();

  OnboardingStatus get status => _status;
  String? get errorMessage => _errorMessage;

  Future<bool> completeOnboarding({
    required String uid,
    required String university,
    required String faculty,
    required String degree,
    required String department,
    required int academicYear,
    required String bio,
    required List<String> skills,
    required List<String> interests,
  }) async {
    _status = OnboardingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.completeOnboarding(
        uid: uid,
        university: university,
        faculty: faculty,
        degree: degree,
        department: department,
        academicYear: academicYear,
        bio: bio,
        skills: skills,
        interests: interests,
      );

      _status = OnboardingStatus.success;
      notifyListeners();
      return true;
    } catch (_) {
      _status = OnboardingStatus.error;
      _errorMessage =
          'Failed to complete onboarding. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
