import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String messageId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileExtension;
  final int? durationSeconds;
  final String messageType; // 'text', 'image', 'document', 'audio', 'voice'
  final DateTime? sentAt;
  final List<String> readBy;
  final String? replyToMessageId;
  final String? replyToSenderName;
  final String? replyToText;
  final bool isForwarded;
  final String? forwardedFrom;
  final bool isDeleted;
  final List<String> hiddenFor;
  final String status; // 'sent', 'pending', 'failed'

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.fileExtension,
    this.durationSeconds,
    this.messageType = 'text',
    this.sentAt,
    this.readBy = const [],
    this.replyToMessageId,
    this.replyToSenderName,
    this.replyToText,
    this.isForwarded = false,
    this.forwardedFrom,
    this.isDeleted = false,
    this.hiddenFor = const [],
    this.status = 'sent',
  });

  bool get isText => messageType == 'text';
  bool get isImage =>
      messageType == 'image' || (imageUrl != null && imageUrl!.isNotEmpty);
  bool get isDocument => messageType == 'document';
  bool get isAudio => messageType == 'audio';
  bool get isVoice => messageType == 'voice';

  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  String? get effectiveMediaUrl => mediaUrl ?? imageUrl;

  MessageModel copyWith({
    String? messageId,
    String? senderId,
    String? text,
    String? imageUrl,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    String? fileExtension,
    int? durationSeconds,
    String? messageType,
    DateTime? sentAt,
    List<String>? readBy,
    String? replyToMessageId,
    String? replyToSenderName,
    String? replyToText,
    bool? isForwarded,
    String? forwardedFrom,
    bool? isDeleted,
    List<String>? hiddenFor,
    String? status,
  }) {
    return MessageModel(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileExtension: fileExtension ?? this.fileExtension,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      messageType: messageType ?? this.messageType,
      sentAt: sentAt ?? this.sentAt,
      readBy: readBy ?? this.readBy,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToSenderName: replyToSenderName ?? this.replyToSenderName,
      replyToText: replyToText ?? this.replyToText,
      isForwarded: isForwarded ?? this.isForwarded,
      forwardedFrom: forwardedFrom ?? this.forwardedFrom,
      isDeleted: isDeleted ?? this.isDeleted,
      hiddenFor: hiddenFor ?? this.hiddenFor,
      status: status ?? this.status,
    );
  }

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
      mediaUrl: map['mediaUrl'] as String?,
      fileName: map['fileName'] as String?,
      fileSize: map['fileSize'] as int?,
      fileExtension: map['fileExtension'] as String?,
      durationSeconds: map['durationSeconds'] as int?,
      messageType: map['messageType'] as String? ?? 'text',
      sentAt: parseDateTime(map['sentAt']),
      readBy:
          (map['readBy'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      replyToMessageId: map['replyToMessageId'] as String?,
      replyToSenderName: map['replyToSenderName'] as String?,
      replyToText: map['replyToText'] as String?,
      isForwarded: map['isForwarded'] as bool? ?? false,
      forwardedFrom: map['forwardedFrom'] as String?,
      isDeleted: map['isDeleted'] as bool? ?? false,
      hiddenFor:
          (map['hiddenFor'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: map['status'] as String? ?? 'sent',
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
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
      if (fileName != null) 'fileName': fileName,
      if (fileSize != null) 'fileSize': fileSize,
      if (fileExtension != null) 'fileExtension': fileExtension,
      if (durationSeconds != null) 'durationSeconds': durationSeconds,
      'messageType': messageType,
      'sentAt': sentAt != null
          ? Timestamp.fromDate(sentAt!)
          : FieldValue.serverTimestamp(),
      'readBy': readBy,
      if (replyToMessageId != null) 'replyToMessageId': replyToMessageId,
      if (replyToSenderName != null) 'replyToSenderName': replyToSenderName,
      if (replyToText != null) 'replyToText': replyToText,
      if (isForwarded) 'isForwarded': true,
      if (forwardedFrom != null) 'forwardedFrom': forwardedFrom,
      'isDeleted': isDeleted,
      'hiddenFor': hiddenFor,
      'status': status,
    };
  }
}
