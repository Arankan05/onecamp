
import '../models/comment_model.dart';
import '../repositories/comment_repository.dart';

class CommentController {
  final CommentRepository _repository;

  CommentController({CommentRepository? repository})
      : _repository = repository ?? CommentRepository();

  // Get comments for a post
  Stream<List<CommentModel>> getComments(String postId) {
    return _repository.getComments(postId);
  }

  // Add a comment
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String content,
  }) async {
    await _repository.addComment(
      postId: postId,
      authorId: authorId,
      content: content,
    );
  }

  // Update a comment
  Future<void> updateComment({
    required String postId,
    required String commentId,
    required String content,
  }) async {
    await _repository.updateComment(
      postId: postId,
      commentId: commentId,
      content: content,
    );
  }

  // Delete a comment
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {
    await _repository.deleteComment(
      postId: postId,
      commentId: commentId,
    );
  }
}
