import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/marketplace_item.dart';

/// Repository for handling data access and Firestore operations for the Marketplace feature.
class MarketplaceRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MarketplaceRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _marketplaceRef =>
      _firestore.collection(AppConstants.marketplaceCollection);

  /// Helper getter to ensure user is authenticated before write operations.
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception(
        'User must be authenticated to perform marketplace operations.',
      );
    }
    return user.uid;
  }

  /// Creates a new marketplace listing in Firestore.
  /// Strictly sets [sellerId] from current authenticated user's UID.
  Future<String> createItem(MarketplaceItem item) async {
    final currentUid = _currentUserId;
    final docRef = _marketplaceRef.doc();

    final keywords = MarketplaceItem.generateKeywords(
      item.title,
      item.description,
      item.category,
    );

    final data = item.toMap();
    data['sellerId'] = currentUid;
    data['searchKeywords'] = keywords;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
    return docRef.id;
  }

  /// Updates an existing marketplace listing.
  /// Verifies ownership and guarantees [sellerId] cannot be altered.
  Future<void> updateItem(MarketplaceItem item) async {
    final currentUid = _currentUserId;
    final docRef = _marketplaceRef.doc(item.id);

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Marketplace listing does not exist.');
    }

    final existingData = snapshot.data();
    final existingSellerId = existingData?['sellerId'] as String?;

    if (existingSellerId != currentUid) {
      throw Exception(
        'Unauthorized: You can only edit your own marketplace listings.',
      );
    }

    final keywords = MarketplaceItem.generateKeywords(
      item.title,
      item.description,
      item.category,
    );

    final data = item.toMap();
    // Preserve existing sellerId and creation timestamp
    data['sellerId'] = existingSellerId;
    data['searchKeywords'] = keywords;
    data['createdAt'] =
        existingData?['createdAt'] ?? FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();

    await docRef.update(data);
  }

  /// Updates the status (e.g. available or sold) of a marketplace item.
  Future<void> updateItemStatus(String itemId, String newStatus) async {
    if (newStatus != AppConstants.statusAvailable &&
        newStatus != AppConstants.statusSold) {
      throw ArgumentError(
        'Invalid item status "$newStatus". Allowed statuses are "${AppConstants.statusAvailable}" and "${AppConstants.statusSold}".',
      );
    }

    final currentUid = _currentUserId;
    final docRef = _marketplaceRef.doc(itemId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Marketplace listing does not exist.');
    }

    final existingSellerId = snapshot.data()?['sellerId'] as String?;
    if (existingSellerId != currentUid) {
      throw Exception(
        'Unauthorized: You can only change status for your own listings.',
      );
    }

    await docRef.update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes a marketplace listing if current user is the seller.
  Future<void> deleteItem(String itemId) async {
    final currentUid = _currentUserId;
    final docRef = _marketplaceRef.doc(itemId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      throw Exception('Marketplace listing does not exist.');
    }

    final existingSellerId = snapshot.data()?['sellerId'] as String?;
    if (existingSellerId != currentUid) {
      throw Exception('Unauthorized: You can only delete your own listings.');
    }

    await docRef.delete();
  }

  /// Retrieves a single marketplace item by its document ID.
  Future<MarketplaceItem?> getItemById(String itemId) async {
    final snapshot = await _marketplaceRef.doc(itemId).get();
    if (!snapshot.exists) return null;
    return MarketplaceItem.fromDocument(snapshot);
  }

  /// Stream of available marketplace listings with optional category filtering.
  Stream<List<MarketplaceItem>> getAvailableItemsStream({String? category}) {
    return _marketplaceRef.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => MarketplaceItem.fromDocument(doc))
          .where((item) => item.isAvailable || item.status.isEmpty)
          .toList();

      if (category != null && category.isNotEmpty && category != 'All') {
        final filtered = items.where((i) => i.category == category).toList();
        filtered.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        return filtered;
      }

      items.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items;
    });
  }

  /// Stream of marketplace listings posted by a specific seller (or current user if omitted).
  Stream<List<MarketplaceItem>> getSellerItemsStream({String? sellerId}) {
    final targetUid = sellerId ?? _currentUserId;

    return _marketplaceRef.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => MarketplaceItem.fromDocument(doc))
          .where((item) => item.sellerId == targetUid)
          .toList();

      items.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return items;
    });
  }
}
