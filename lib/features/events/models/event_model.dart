import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime dateTime;
  final String locationName;
  final double? latitude;
  final double? longitude;
  final String organizerId;
  final String organizerName;
  final String? imageUrl;
  final int attendeeCount;
  final DateTime createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.dateTime,
    required this.locationName,
    this.latitude,
    this.longitude,
    required this.organizerId,
    required this.organizerName,
    this.imageUrl,
    this.attendeeCount = 0,
    required this.createdAt,
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

  /// Factory constructor to convert Firestore document data into an [EventModel].
  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      dateTime: _parseDateTime(map['dateTime']),
      locationName: map['locationName'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      organizerId: map['organizerId'] as String? ?? '',
      organizerName: map['organizerName'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      attendeeCount: (map['attendeeCount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Factory constructor to create an [EventModel] directly from a [DocumentSnapshot].
  factory EventModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EventModel.fromMap(doc.id, data);
  }

  /// Converts the [EventModel] instance into a Firestore-compatible Map.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'dateTime': Timestamp.fromDate(dateTime),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'imageUrl': imageUrl,
      'attendeeCount': attendeeCount,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a copy of this [EventModel] with specified fields replaced.
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? dateTime,
    String? locationName,
    double? latitude,
    double? longitude,
    String? organizerId,
    String? organizerName,
    String? imageUrl,
    int? attendeeCount,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      locationName: locationName ?? this.locationName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      imageUrl: imageUrl ?? this.imageUrl,
      attendeeCount: attendeeCount ?? this.attendeeCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, category: $category, dateTime: $dateTime, locationName: $locationName, organizerName: $organizerName, attendeeCount: $attendeeCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EventModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

