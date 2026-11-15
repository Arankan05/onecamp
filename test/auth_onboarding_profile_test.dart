import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/features/profile/models/user_profile.dart';
import 'package:onecamp/features/onboarding/controllers/onboarding_controller.dart';
import 'package:onecamp/routes/app_routes.dart';

void main() {
  group('UserProfile Model Mapping Tests', () {
    test('Maps complete Firestore data correctly', () {
      final data = {
        'uid': 'user123',
        'name': 'Jane Student',
        'email': 'jane@university.edu',
        'role': 'student',
        'profileImageUrl': 'https://cloudinary.com/pic.jpg',
        'bio': 'Computer Science Student',
        'university': 'State University',
        'faculty': 'Engineering',
        'degree': 'BSc Computer Science',
        'department': 'Software Engineering',
        'academicYear': 3,
        'skills': ['Flutter', 'Dart', 'Firebase'],
        'interests': ['AI', 'Mobile Dev'],
        'onboardingCompleted': true,
      };

      final profile = UserProfile(
        uid: data['uid'] as String,
        name: data['name'] as String,
        email: data['email'] as String,
        role: data['role'] as String,
        profileImageUrl: data['profileImageUrl'] as String?,
        bio: data['bio'] as String?,
        university: data['university'] as String?,
        faculty: data['faculty'] as String?,
        degree: data['degree'] as String?,
        department: data['department'] as String?,
        academicYear: (data['academicYear'] as num?)?.toInt(),
        skills: List<String>.from(data['skills'] as List),
        interests: List<String>.from(data['interests'] as List),
        onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
      );

      expect(profile.uid, equals('user123'));
      expect(profile.name, equals('Jane Student'));
      expect(profile.email, equals('jane@university.edu'));
      expect(profile.role, equals('student'));
      expect(profile.profileImageUrl, equals('https://cloudinary.com/pic.jpg'));
      expect(profile.university, equals('State University'));
      expect(profile.faculty, equals('Engineering'));
      expect(profile.degree, equals('BSc Computer Science'));
      expect(profile.department, equals('Software Engineering'));
      expect(profile.academicYear, equals(3));
      expect(profile.skills, equals(['Flutter', 'Dart', 'Firebase']));
      expect(profile.interests, equals(['AI', 'Mobile Dev']));
      expect(profile.onboardingCompleted, isTrue);
    });

    test('Handles missing or null optional Firestore fields safely', () {
      const profile = UserProfile(
        uid: 'user456',
        name: 'John Student',
        email: 'john@university.edu',
        role: 'student',
      );

      expect(profile.uid, equals('user456'));
      expect(profile.onboardingCompleted, isFalse);
      expect(profile.profileImageUrl, isNull);
      expect(profile.bio, isNull);
      expect(profile.university, isNull);
      expect(profile.faculty, isNull);
      expect(profile.degree, isNull);
      expect(profile.department, isNull);
      expect(profile.academicYear, isNull);
      expect(profile.skills, isEmpty);
      expect(profile.interests, isEmpty);
    });
  });

  group('Validation Logic Tests', () {
    bool isValidEmail(String email) {
      return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email.trim());
    }

    List<String> parseList(String text) {
      return text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList();
    }

    test('Email validation checks format correctly', () {
      expect(isValidEmail('student@university.edu'), isTrue);
      expect(isValidEmail('invalid-email'), isFalse);
      expect(isValidEmail(''), isFalse);
    });

    test('Comma-separated list parsing handles whitespace and duplicates', () {
      final parsed =
          parseList('  Flutter, Dart , Flutter , Mobile Development  ');
      expect(parsed, equals(['Flutter', 'Dart', 'Mobile Development']));
    });

    test('Comma-separated list parsing returns empty list for blank strings', () {
      expect(parseList('   '), isEmpty);
      expect(parseList(','), isEmpty);
    });
  });

  group('OnboardingController Tests', () {
    test('Initial status of OnboardingController is initial', () {
      final controller = OnboardingController();
      expect(controller.status, equals(OnboardingStatus.initial));
      expect(controller.errorMessage, isNull);
    });
  });

  group('AppRoutes Navigation Tests', () {
    test('Route path constants match expected named routes', () {
      expect(AppRoutes.initial, equals('/'));
      expect(AppRoutes.login, equals('/login'));
      expect(AppRoutes.register, equals('/register'));
      expect(AppRoutes.forgotPassword, equals('/forgot-password'));
      expect(AppRoutes.onboarding, equals('/onboarding'));
      expect(AppRoutes.profile, equals('/profile'));
      expect(AppRoutes.editProfile, equals('/edit-profile'));
    });
  });
}
