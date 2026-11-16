
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? profileImageUrl;
  final String? bio;
  final String? university;
  final String? faculty;
  final String? degree;
  final String? department;
  final int? academicYear;
  final List<String> skills;
  final List<String> interests;
  final bool onboardingCompleted;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.bio,
    this.university,
    this.faculty,
    this.degree,
    this.department,
    this.academicYear,
    this.skills = const [],
    this.interests = const [],
    this.onboardingCompleted = false,
  });
}
