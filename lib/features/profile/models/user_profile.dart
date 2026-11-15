
class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String role;
  final String? profileImageUrl;
  final String? bio;
  final String? department;
  final int? academicYear;

  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.bio,
    this.department,
    this.academicYear,
  });
}
