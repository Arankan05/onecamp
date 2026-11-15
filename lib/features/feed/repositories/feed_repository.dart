
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/post_model.dart';

class FeedRepository {
  final FirebaseFirestore _firestore;

  FeedRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String _cloudinaryCloudName =
  String.fromEnvironment('CLOUDINARY_CLOUD_NAME');

  static const String _cloudinaryUploadPreset =
  String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');

  // Get all posts, newest first
  Stream<List<PostModel>> getPosts() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PostModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get posts from users the current student follows
  Stream<List<PostModel>> getFollowedPosts(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots()
        .asyncExpand((followingSnapshot) {
      final followedUserIds =
      followingSnapshot.docs.map((doc) => doc.id).toList();

      if (followedUserIds.isEmpty) {
        return Stream.value(<PostModel>[]);
      }

      return _firestore
          .collection('posts')
          .where('authorId', whereIn: followedUserIds)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return PostModel.fromMap(doc.id, doc.data());
        }).toList();
      });
    });
  }

  // Upload post image to Cloudinary
  Future<String> uploadPostImage({
    required File image,
    required String authorId,
  }) async {
    if (_cloudinaryCloudName.isEmpty ||
        _cloudinaryUploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary configuration is missing. '
            'Run the app with the required dart-define values.',
      );
    }

    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/'
          '$_cloudinaryCloudName/image/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _cloudinaryUploadPreset
      ..fields['folder'] = 'feed'
      ..fields['public_id'] =
          '${authorId}_${DateTime.now().millisecondsSinceEpoch}'
      ..files.add(
        await http.MultipartFile.fromPath('file', image.path),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Cloudinary upload failed: ${response.body}',
      );
    }

    final responseData =
    jsonDecode(response.body) as Map<String, dynamic>;

    final secureUrl = responseData['secure_url'] as String?;

    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return an image URL.');
    }

    return secureUrl;
  }

  // Create a new post
  Future<void> createPost({
    required String authorId,
    required String content,
    String? imageUrl,
  }) async {
    if (content.trim().isEmpty &&
        (imageUrl == null || imageUrl.trim().isEmpty)) {
      throw ArgumentError('A post must contain text or an image.');
    }

    await _firestore.collection('posts').add({
      'authorId': authorId,
      'content': content.trim(),
      'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete your own post
  Future<void> deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  // Update your own post
  Future<void> updatePost({
    required String postId,
    required String content,
  }) async {
    if (content.trim().isEmpty) {
      throw ArgumentError('Post content cannot be empty.');
    }

    await _firestore.collection('posts').doc(postId).update({
      'content': content.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Check whether a user liked a post
  Stream<bool> isPostLikedByUser({
    required String postId,
    required String userId,
  }) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  // Get total number of likes
  Stream<int> getLikeCount(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Like or unlike a post
  Future<void> toggleLike({
    required String postId,
    required String userId,
  }) async {
    final likeRef = _firestore
        .collection('posts')
        .doc(postId)
        .collection('likes')
        .doc(userId);

    final likeSnapshot = await likeRef.get();

    if (likeSnapshot.exists) {
      await likeRef.delete();
    } else {
      await likeRef.set({
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }
}
