
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../models/user_profile.dart';

class ProfileRepository {
  final FirebaseFirestore _firestore;

  ProfileRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get user profile
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
      uid: data['uid'] as String,
      name: data['name'] as String,
      email: data['email'] as String,
      role: data['role'] as String,
      profileImageUrl: data['profileImageUrl'] as String?,
      bio: data['bio'] as String?,
      department: data['department'] as String?,
      academicYear: (data['academicYear'] as num?)?.toInt(),
    );
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String bio,
    required String department,
    required int? academicYear,
    String? profileImageUrl,
  }) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update({
      'name': name.trim(),
      'bio': bio.trim(),
      'department': department.trim(),
      'academicYear': academicYear,
      'profileImageUrl': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
