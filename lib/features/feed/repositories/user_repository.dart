import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../profile/models/user_profile.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get all registered students
  Stream<List<UserProfile>> getUsers() {
    return _firestore.collection(AppConstants.usersCollection).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final uid = doc.id;
        return UserProfile(
          uid: data['uid'] as String? ?? uid,
          name: data['name'] as String? ?? 'Unknown Student',
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
      }).toList();
    });
  }

  // Get a specific student
  Future<UserProfile?> getUserById(String userId) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();

    if (!doc.exists) {
      return null;
    }

    final data = doc.data()!;
    return UserProfile(
      uid: data['uid'] as String? ?? userId,
      name: data['name'] as String? ?? 'Unknown Student',
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
}
