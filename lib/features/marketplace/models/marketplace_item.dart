import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';

/// Represents a marketplace item listing in OneCamp.
class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> imageUrls;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final String? sellerPhotoUrl;
  final String status;
  final String? location;
  final List<String> searchKeywords;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MarketplaceItem({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageUrls,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    this.sellerPhotoUrl,
    this.status = AppConstants.statusAvailable,
    this.location,
    required this.searchKeywords,
    this.createdAt,
    this.updatedAt,
  });

  /// Convenience getter to check if item is currently available for purchase.
  bool get isAvailable => status == AppConstants.statusAvailable;

  /// Convenience getter to check if item has been marked as sold.
  bool get isSold => status == AppConstants.statusSold;

  /// Generates normalized lowercase token keywords from title, description, and category.
  static List<String> generateKeywords(
    String title,
    String description,
    String category,
  ) {
    final combined = '$title $description $category'.toLowerCase();
    final clean = combined.replaceAll(RegExp(r'[^\w\s]'), ' ');
    final words = clean
        .split(RegExp(r'\s+'))
        .where((word) => word.trim().length > 1)
        .toSet();
    return words.toList();
  }

  /// Creates a [MarketplaceItem] from a Firestore [DocumentSnapshot].
  factory MarketplaceItem.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MarketplaceItem.fromMap(data, id: doc.id);
  }

  /// Creates a [MarketplaceItem] from a key-value Map and document ID.
  factory MarketplaceItem.fromMap(
    Map<String, dynamic> map, {
    required String id,
  }) {
    return MarketplaceItem(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] as String? ?? 'Other',
      condition: map['condition'] as String? ?? 'Good',
      imageUrls:
          (map['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sellerId: map['sellerId'] as String? ?? '',
      sellerName: map['sellerName'] as String? ?? '',
      sellerEmail: map['sellerEmail'] as String? ?? '',
      sellerPhotoUrl: map['sellerPhotoUrl'] as String?,
      status: map['status'] as String? ?? AppConstants.statusAvailable,
      location: map['location'] as String?,
      searchKeywords:
          (map['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Converts the item instance to a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerEmail': sellerEmail,
      'sellerPhotoUrl': sellerPhotoUrl,
      'status': status,
      'location': location,
      'searchKeywords': searchKeywords,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of this [MarketplaceItem] with updated fields.
  MarketplaceItem copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    String? condition,
    List<String>? imageUrls,
    String? sellerId,
    String? sellerName,
    String? sellerEmail,
    String? sellerPhotoUrl,
    String? status,
    String? location,
    List<String>? searchKeywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketplaceItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      condition: condition ?? this.condition,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerEmail: sellerEmail ?? this.sellerEmail,
      sellerPhotoUrl: sellerPhotoUrl ?? this.sellerPhotoUrl,
      status: status ?? this.status,
      location: location ?? this.location,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
