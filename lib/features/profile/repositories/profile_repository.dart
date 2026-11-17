import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserProfile?> getUserProfile(String uid) async {
    final document = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();

    if (!document.exists) {
      return null;
    }

    final data = document.data()!;

    return UserProfile(
      uid: data['uid'] as String? ?? uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'student',
      profileImageUrl: data['profileImageUrl'] as String?,
      bio: data['bio'] as String?,
      university: data['university'] as String?,
      faculty: data['faculty'] as String?,
      degree: data['degree'] as String?,
      department: data['department'] as String?,
      academicYear: (data['academicYear'] as num?)?.toInt(),
      skills: List<String>.from(data['skills'] ?? []),
      interests: List<String>.from(data['interests'] ?? []),
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }

  Future<void> completeOnboarding({
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
    await _firestore.collection(AppConstants.usersCollection).doc(uid).set({
      'uid': uid,
      'role': 'student',
      'university': university.trim(),
      'faculty': faculty.trim(),
      'degree': degree.trim(),
      'department': department.trim(),
      'academicYear': academicYear,
      'bio': bio.trim(),
      'skills': skills,
      'interests': interests,
      'onboardingCompleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String bio,
    required String department,
    required int? academicYear,
    String? profileImageUrl,
    String? university,
    String? faculty,
    String? degree,
    List<String>? skills,
    List<String>? interests,
  }) async {
    final Map<String, dynamic> updates = {
      'name': name.trim(),
      'bio': bio.trim(),
      'department': department.trim(),
      'academicYear': academicYear,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (profileImageUrl != null) {
      updates['profileImageUrl'] = profileImageUrl;
    }

    if (university != null) {
      updates['university'] = university.trim();
    }

    if (faculty != null) {
      updates['faculty'] = faculty.trim();
    }

    if (degree != null) {
      updates['degree'] = degree.trim();
    }

    if (skills != null) {
      updates['skills'] = skills;
    }

    if (interests != null) {
      updates['interests'] = interests;
    }

    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(updates);
  }
}
