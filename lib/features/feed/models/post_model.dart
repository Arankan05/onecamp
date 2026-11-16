
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  const PostModel({
    required this.id,
    required this.authorId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  // Convert Firestore data into a PostModel object
  factory PostModel.fromMap(
      String id,
      Map<String, dynamic> data,
      ) {
    return PostModel(
      id: id,
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert PostModel into Firestore data
  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'content': content,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
