import 'package:cloud_firestore/cloud_firestore.dart';

class Community {
  final String id;
  final String name;
  final String description;
  final String category;
  final String createdBy;
  final DateTime createdAt;

  const Community({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.createdBy,
    required this.createdAt,
  });

  /// Turn a Firestore document into a Community object.
  factory Community.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'];
    return Community(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Other',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  /// Turn a Community object into data to save in Firestore.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
