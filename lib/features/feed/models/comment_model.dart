import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorId;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(String id, Map<String, dynamic> data) {
    return CommentModel(
      id: id,
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
