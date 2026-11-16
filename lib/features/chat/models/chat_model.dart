import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String chatId;
  final String type; // 'direct' or 'group'
  final List<String> participantIds;
  final String? groupName;
  final String? groupImage;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final List<String> mutedBy;
  final List<String> pinnedBy;
  final List<String> hiddenFor;

  ChatModel({
    required this.chatId,
    required this.type,
    required this.participantIds,
    this.groupName,
    this.groupImage,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
    this.mutedBy = const [],
    this.pinnedBy = const [],
    this.hiddenFor = const [],
  });

  bool get isGroup => type == 'group';

  bool isMutedFor(String userId) => mutedBy.contains(userId);
  bool isPinnedFor(String userId) => pinnedBy.contains(userId);
  bool isHiddenFor(String userId) => hiddenFor.contains(userId);

  String getOtherUserId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  String getDisplayName(String currentUserId) {
    if (isGroup) {
      return groupName?.isNotEmpty == true ? groupName! : 'Group Chat';
    }
    return 'Student';
  }

  factory ChatModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return ChatModel(
      chatId: documentId,
      type: map['type'] as String? ?? 'direct',
      participantIds: (map['participantIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      groupName: map['groupName'] as String?,
      groupImage: map['groupImage'] as String?,
      lastMessage: map['lastMessage'] as String?,
      lastMessageAt: parseDateTime(map['lastMessageAt']),
      createdAt: parseDateTime(map['createdAt']),
      mutedBy: (map['mutedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      pinnedBy: (map['pinnedBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hiddenFor: (map['hiddenFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory ChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'participantIds': participantIds,
      if (groupName != null) 'groupName': groupName,
      if (groupImage != null) 'groupImage': groupImage,
      'lastMessage': lastMessage ?? '',
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'mutedBy': mutedBy,
      'pinnedBy': pinnedBy,
      'hiddenFor': hiddenFor,
    };
  }
}
