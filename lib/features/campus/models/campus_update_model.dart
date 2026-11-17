import 'package:cloud_firestore/cloud_firestore.dart';

class CampusUpdateModel {
  final String id;
  final String title;
  final String body;
  final String category;
  final String authorId;
  final String authorName;
  final String? imageUrl;
  final bool isUrgent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CampusUpdateModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.authorId,
    required this.authorName,
    this.imageUrl,
    this.isUrgent = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Helper to safely parse dates from Firestore Timestamp, DateTime, int, or String.
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is DateTime) {
      return value;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  /// Factory constructor to convert Firestore document data into a [CampusUpdateModel].
  factory CampusUpdateModel.fromMap(String id, Map<String, dynamic> map) {
    return CampusUpdateModel(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      authorId: map['authorId'] as String? ?? '',
      authorName: map['authorName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      isUrgent: map['isUrgent'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: map['updatedAt'] != null
          ? _parseDateTime(map['updatedAt'])
          : null,
    );
  }

  /// Factory constructor to create a [CampusUpdateModel] directly from a [DocumentSnapshot].
  factory CampusUpdateModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return CampusUpdateModel.fromMap(doc.id, data);
  }

  /// Converts the [CampusUpdateModel] instance into a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'imageUrl': imageUrl,
      'isUrgent': isUrgent,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }

  /// Creates a copy of this [CampusUpdateModel] with specified fields replaced.
  CampusUpdateModel copyWith({
    String? id,
    String? title,
    String? body,
    String? category,
    String? authorId,
    String? authorName,
    String? imageUrl,
    bool? isUrgent,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CampusUpdateModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      imageUrl: imageUrl ?? this.imageUrl,
      isUrgent: isUrgent ?? this.isUrgent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CampusUpdateModel(id: $id, title: $title, category: $category, authorName: $authorName, isUrgent: $isUrgent, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CampusUpdateModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
