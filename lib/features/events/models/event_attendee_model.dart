import 'package:cloud_firestore/cloud_firestore.dart';

class EventAttendeeModel {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String? userEmail;
  final DateTime registeredAt;

  const EventAttendeeModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.registeredAt,
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

  /// Factory constructor to convert Firestore document data into an [EventAttendeeModel].
  /// The document ID in Firestore is the attendee's user UID as guarded by security rules.
  factory EventAttendeeModel.fromMap(
    String id,
    Map<String, dynamic> map, {
    String eventId = '',
  }) {
    return EventAttendeeModel(
      id: id,
      eventId: map['eventId'] as String? ?? eventId,
      userId: map['userId'] as String? ?? id,
      userName: map['userName'] as String? ?? '',
      userEmail: map['userEmail'] as String?,
      registeredAt: _parseDateTime(map['registeredAt']),
    );
  }

  /// Factory constructor to create an [EventAttendeeModel] directly from a [DocumentSnapshot].
  factory EventAttendeeModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    String eventId = '',
  }) {
    final data = doc.data() ?? {};
    return EventAttendeeModel.fromMap(doc.id, data, eventId: eventId);
  }

  /// Converts the [EventAttendeeModel] instance into a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'registeredAt': Timestamp.fromDate(registeredAt),
      if (eventId.isNotEmpty) 'eventId': eventId,
    };
  }

  /// Creates a copy of this [EventAttendeeModel] with specified fields replaced.
  EventAttendeeModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userEmail,
    DateTime? registeredAt,
  }) {
    return EventAttendeeModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  @override
  String toString() {
    return 'EventAttendeeModel(id: $id, eventId: $eventId, userId: $userId, userName: $userName, registeredAt: $registeredAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventAttendeeModel &&
        other.id == id &&
        other.eventId == eventId;
  }

  @override
  int get hashCode => Object.hash(id, eventId);
}
