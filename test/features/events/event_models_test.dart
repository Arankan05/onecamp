import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/features/events/models/event_attendee_model.dart';
import 'package:onecamp/features/events/models/event_model.dart';

void main() {
  group('EventModel Tests', () {
    test('Serializes toMap and deserializes fromMap accurately', () {
      final now = DateTime(2026, 11, 15, 10, 30);
      final event = EventModel(
        id: 'evt_123',
        title: 'Tech Hackathon',
        description: '24-hour campus hackathon',
        category: 'Academic',
        dateTime: now,
        locationName: 'Hall B',
        latitude: 6.9271,
        longitude: 79.8612,
        organizerId: 'org_999',
        organizerName: 'Computing Society',
        imageUrl: 'https://example.com/banner.png',
        attendeeCount: 15,
        createdAt: now,
      );

      final map = event.toMap();

      expect(map['title'], equals('Tech Hackathon'));
      expect(map['organizerId'], equals('org_999'));
      expect(map['dateTime'], isA<Timestamp>());
      expect((map['dateTime'] as Timestamp).toDate(), equals(now));
      expect(map['latitude'], equals(6.9271));
      expect(map['longitude'], equals(79.8612));

      final restored = EventModel.fromMap('evt_123', map);

      expect(restored.id, equals('evt_123'));
      expect(restored.title, equals('Tech Hackathon'));
      expect(restored.organizerId, equals('org_999'));
      expect(restored.latitude, equals(6.9271));
      expect(restored.attendeeCount, equals(15));
    });

    test('Handles missing optional and nullable fields gracefully', () {
      final minimalMap = <String, dynamic>{
        'title': 'Study Session',
        'organizerId': 'org_100',
        'dateTime': Timestamp.now(),
      };

      final event = EventModel.fromMap('evt_min', minimalMap);

      expect(event.id, equals('evt_min'));
      expect(event.title, equals('Study Session'));
      expect(event.category, equals('General'));
      expect(event.locationName, equals(''));
      expect(event.latitude, isNull);
      expect(event.longitude, isNull);
      expect(event.imageUrl, isNull);
      expect(event.attendeeCount, equals(0));
    });
  });

  group('EventAttendeeModel Tests', () {
    test('Attendee document matches user UID and serializes correctly', () {
      final now = DateTime(2026, 11, 15, 11, 00);
      final attendee = EventAttendeeModel(
        id: 'usr_user_1',
        eventId: 'evt_123',
        userId: 'usr_user_1',
        userName: 'John Doe',
        userEmail: 'john@campus.edu',
        registeredAt: now,
      );

      final map = attendee.toMap();

      expect(map['userId'], equals('usr_user_1'));
      expect(map['userName'], equals('John Doe'));
      expect(map['registeredAt'], isA<Timestamp>());

      final restored = EventAttendeeModel.fromMap('usr_user_1', map, eventId: 'evt_123');

      expect(restored.id, equals('usr_user_1'));
      expect(restored.userId, equals('usr_user_1'));
      expect(restored.eventId, equals('evt_123'));
      expect(restored.userName, equals('John Doe'));
    });
  });
}

