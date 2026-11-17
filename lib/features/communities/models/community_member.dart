import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityMember {
  final String userId;
  final String role;
  final DateTime joinedAt;

  const CommunityMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  /// The document ID in Firestore is the user's UID.
  factory CommunityMember.fromMap(String userId, Map<String, dynamic> map) {
    final timestamp = map['joinedAt'];
    return CommunityMember(
      userId: userId,
      role: map['role'] as String? ?? 'member',
      joinedAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'role': role, 'joinedAt': Timestamp.fromDate(joinedAt)};
  }
}
