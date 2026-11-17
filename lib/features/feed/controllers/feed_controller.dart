import 'dart:io';

import '../models/post_model.dart';
import '../repositories/feed_repository.dart';

class FeedController {
  final FeedRepository _repository;

  FeedController({FeedRepository? repository})
    : _repository = repository ?? FeedRepository();

  // Get all posts
  Stream<List<PostModel>> get postsStream {
    return _repository.getPosts();
  }

  // Get posts from followed users
  Stream<List<PostModel>> getFollowedPosts(String userId) {
    return _repository.getFollowedPosts(userId);
  }

  // Create a new post
  Future<void> createPost({
    required String authorId,
    required String content,
    String? imageUrl,
  }) async {
    await _repository.createPost(
      authorId: authorId,
      content: content,
      imageUrl: imageUrl,
    );
  }

  // Upload post image
  Future<String> uploadPostImage({
    required File image,
    required String authorId,
  }) async {
    return await _repository.uploadPostImage(image: image, authorId: authorId);
  }

  // Delete your own post
  Future<void> deletePost(String postId) async {
    await _repository.deletePost(postId);
  }

  // Update your own post
  Future<void> updatePost({
    required String postId,
    required String content,
  }) async {
    await _repository.updatePost(postId: postId, content: content);
  }

  // Check whether a user liked a post
  Stream<bool> isPostLikedByUser({
    required String postId,
    required String userId,
  }) {
    return _repository.isPostLikedByUser(postId: postId, userId: userId);
  }

  // Get total number of likes
  Stream<int> getLikeCount(String postId) {
    return _repository.getLikeCount(postId);
  }

  // Like or unlike a post
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    await _repository.toggleLike(postId: postId, userId: userId);
  }
}
