
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Get all registered students
  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Get a specific student
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return UserModel.fromMap(doc.id, doc.data()!);
  }
}
