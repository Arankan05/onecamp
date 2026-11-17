import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory Announcement.fromMap(String id, Map<String, dynamic> map) {
    final timestamp = map['createdAt'];
    return Announcement(
      id: id,
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
