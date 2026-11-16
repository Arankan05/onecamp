import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;

  const CommunityPost({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  factory CommunityPost.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'];
    return CommunityPost(
      id: id,
      authorId: map['authorId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}