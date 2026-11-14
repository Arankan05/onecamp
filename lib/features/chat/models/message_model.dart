import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String messageType; // 'text' or 'image'
  final DateTime? sentAt;
  final List<String> readBy;
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToText;
  final bool isDeleted;
  final List<String> hiddenFor;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.messageType = 'text',
    this.sentAt,
    this.readBy = const [],
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToText,
    this.isDeleted = false,
    this.hiddenFor = const [],
  });

  bool get isImage => messageType == 'image' || (imageUrl != null && imageUrl!.isNotEmpty);

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
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

    return MessageModel(
      messageId: documentId,
      senderId: map['senderId'] as String? ?? '',
      text: map['text'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      messageType: map['messageType'] as String? ?? 'text',
      sentAt: parseDateTime(map['sentAt']),
      readBy: (map['readBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      replyToMessageId: map['replyToMessageId'] as String?,
      replyToSenderName: map['replyToSenderName'] as String?,
      replyToText: map['replyToText'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      hiddenFor: (map['hiddenFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MessageModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'messageType': messageType,
      'sentAt': sentAt != null
          ? Timestamp.fromDate(sentAt!)
          : FieldValue.serverTimestamp(),
      'readBy': readBy,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
      'isDeleted': isDeleted,
      'hiddenFor': hiddenFor,
    };
  }
}
