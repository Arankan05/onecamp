import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../models/campus_update_model.dart';

class CampusRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CampusRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ---------- Firestore Collection References ----------

  CollectionReference<Map<String, dynamic>> get _updatesCollection =>
      _firestore.collection(AppConstants.campusUpdatesCollection);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  /// The currently authenticated user's UID (null if not signed in).
  String? get currentUserId => _auth.currentUser?.uid;

  // ---------- Permission & Role Handling ----------

  /// Retrieves the role for a given user from `users/{uid}`.
  ///
  /// Defaults to 'student' if document is absent or has no explicit role.
  Future<String?> getUserRole([String? userId]) async {
    final uid = userId ?? currentUserId;
    if (uid == null || uid.isEmpty) return null;

    final userDoc = await _usersCollection.doc(uid).get();
    if (!userDoc.exists || userDoc.data() == null) return 'student';
    return userDoc.data()?['role'] as String? ?? 'student';
  }

  /// Checks whether the user has permission to create, edit, or delete campus updates.
  ///
  /// Strictly checks against the project's established role strategy:
  /// Allowed roles: 'admin' or 'staff'. Students are read-only.
  Future<bool> canManageUpdates([String? userId]) async {
    final role = await getUserRole(userId);
    return role == 'admin' || role == 'staff';
  }

  /// Live stream watching whether the user has update management permissions.
  Stream<bool> watchCanManageUpdates([String? userId]) {
    final uid = userId ?? currentUserId;
    if (uid == null || uid.isEmpty) return Stream.value(false);

    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return false;
      final role = doc.data()?['role'] as String? ?? 'student';
      return role == 'admin' || role == 'staff';
    });
  }

  // ---------- Retrieval Operations ----------

  /// Live stream of all campus updates, ordered by publication date descending (newest first).
  Stream<List<CampusUpdateModel>> watchCampusUpdates() {
    return _updatesCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CampusUpdateModel.fromDocument(doc))
            .toList());
  }

  /// Fetches a single campus update by document ID.
  Future<CampusUpdateModel?> getCampusUpdate(String updateId) async {
    final doc = await _updatesCollection.doc(updateId).get();
    if (!doc.exists || doc.data() == null) return null;
    return CampusUpdateModel.fromDocument(doc);
  }

  /// Live stream of campus updates filtered by category (e.g. Announcements, Academic, Sports, Event Updates).
  Stream<List<CampusUpdateModel>> watchUpdatesByCategory(String category) {
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return watchCampusUpdates();
    }
    return _updatesCollection
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CampusUpdateModel.fromDocument(doc))
            .toList());
  }

  /// Live stream of urgent / pinned campus updates.
  Stream<List<CampusUpdateModel>> watchUrgentUpdates() {
    return _updatesCollection
        .where('isUrgent', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CampusUpdateModel.fromDocument(doc))
            .toList());
  }

  // ---------- Management Operations (Admin / Staff Only) ----------

  /// Creates a new campus update document.
  ///
  /// Enforces security rules:
  /// - Only 'admin' or 'staff' users may write (`allow write: if isAdmin();`).
  /// - Sets `createdAt` using a server timestamp.
  Future<String> createCampusUpdate(CampusUpdateModel update) async {
    final allowed = await canManageUpdates();
    if (!allowed) {
      throw StateError(
          'Permission denied: Only admin or staff accounts can create campus updates.');
    }

    final uid = currentUserId;
    final docRef = _updatesCollection.doc();
    final data = update.toMap();
    if (uid != null && uid.isNotEmpty) {
      data['authorId'] = uid;
    }
    data['createdAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
    return docRef.id;
  }

  /// Updates an existing campus update.
  ///
  /// Enforces security rules:
  /// - Only 'admin' or 'staff' users may modify campus updates.
  /// - Updates `updatedAt` with a server timestamp while preserving original `createdAt`.
  Future<void> updateCampusUpdate(CampusUpdateModel update) async {
    final allowed = await canManageUpdates();
    if (!allowed) {
      throw StateError(
          'Permission denied: Only admin or staff accounts can update campus updates.');
    }

    final existingDoc = await _updatesCollection.doc(update.id).get();
    if (!existingDoc.exists) {
      throw StateError(
          'Campus update with ID ${update.id} does not exist.');
    }

    final updateData = update.toMap();
    updateData.remove('createdAt');
    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await _updatesCollection.doc(update.id).update(updateData);
  }

  /// Deletes an existing campus update.
  ///
  /// Enforces security rules:
  /// - Only 'admin' or 'staff' users may delete campus updates.
  Future<void> deleteCampusUpdate(String updateId) async {
    final allowed = await canManageUpdates();
    if (!allowed) {
      throw StateError(
          'Permission denied: Only admin or staff accounts can delete campus updates.');
    }

    final existingDoc = await _updatesCollection.doc(updateId).get();
    if (!existingDoc.exists) {
      throw StateError(
          'Campus update with ID $updateId does not exist.');
    }

    await _updatesCollection.doc(updateId).delete();
  }
}

