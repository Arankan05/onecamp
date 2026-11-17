import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String actorId;
  final String actorName;
  final String? actorAvatarUrl;
  final String type; // 'follow', 'like', 'comment', 'event', 'chat'
  final String title;
  final String body;
  final String? targetId;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.actorId,
    required this.actorName,
    this.actorAvatarUrl,
    required this.type,
    required this.title,
    required this.body,
    this.targetId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? 'Student',
      actorAvatarUrl: data['actorAvatarUrl'] as String?,
      type: data['type'] as String? ?? 'general',
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      targetId: data['targetId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'actorId': actorId,
      'actorName': actorName,
      'actorAvatarUrl': actorAvatarUrl,
      'type': type,
      'title': title,
      'body': body,
      'targetId': targetId,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
