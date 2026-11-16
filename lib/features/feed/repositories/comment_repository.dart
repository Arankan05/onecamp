
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/comment_model.dart';

class CommentRepository {
  final FirebaseFirestore _firestore;

  CommentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return CommentModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Add a new comment
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Comment cannot be empty.');
    }

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'authorId': authorId,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing comment
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Comment cannot be empty.');
    }

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .update({
      'content': content.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
  }
}
