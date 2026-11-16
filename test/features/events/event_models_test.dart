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
      expect(map['attendeeCount'], equals(15));
      expect(map['attendeeIds'], isA<List>());

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

    test('copyWith updates specified fields while preserving others', () {
      final now = DateTime(2026, 11, 15, 10, 0);
      final event = EventModel(
        id: 'evt_1',
        title: 'Original Title',
        description: 'Original Description',
        category: 'Sports',
        dateTime: now,
        locationName: 'Gym',
        latitude: 6.9271,
        longitude: 79.8612,
        organizerId: 'org_1',
        organizerName: 'Sports Club',
        attendeeCount: 10,
        createdAt: now,
      );

      final updated = event.copyWith(
        title: 'Updated Title',
        attendeeCount: 25,
      );

      expect(updated.title, equals('Updated Title'));
      expect(updated.attendeeCount, equals(25));
      expect(updated.id, equals('evt_1'));
      expect(updated.description, equals('Original Description'));
      expect(updated.organizerId, equals('org_1'));
      // Coordinates are preserved when omitted
      expect(updated.latitude, equals(6.9271));
      expect(updated.longitude, equals(79.8612));
      expect(updated.hasCoordinates, isTrue);
      expect(updated.coordinatesDisplay, equals('6.9271, 79.8612'));
    });

    test('copyWith explicitly clears coordinates when clearCoordinates is true', () {
      final now = DateTime(2026, 11, 15, 10, 0);
      final event = EventModel(
        id: 'evt_with_coords',
        title: 'Outdoor Meetup',
        description: 'Meet at the fountain',
        category: 'Social',
        dateTime: now,
        locationName: 'Campus Fountain',
        latitude: 6.9271,
        longitude: 79.8612,
        organizerId: 'org_1',
        organizerName: 'Social Club',
        createdAt: now,
      );

      expect(event.hasCoordinates, isTrue);

      final cleared = event.copyWith(clearCoordinates: true);

      expect(cleared.latitude, isNull);
      expect(cleared.longitude, isNull);
      expect(cleared.hasCoordinates, isFalse);
      expect(cleared.coordinatesDisplay, isNull);
      expect(cleared.locationName, equals('Campus Fountain')); // venue name remains intact!
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

      final restored =
          EventAttendeeModel.fromMap('usr_user_1', map, eventId: 'evt_123');

      expect(restored.id, equals('usr_user_1'));
      expect(restored.userId, equals('usr_user_1'));
      expect(restored.eventId, equals('evt_123'));
      expect(restored.userName, equals('John Doe'));
    });

    test('EventAttendeeModel copyWith correctly replaces attributes', () {
      final now = DateTime(2026, 11, 15, 12, 00);
      final attendee = EventAttendeeModel(
        id: 'usr_2',
        eventId: 'evt_1',
        userId: 'usr_2',
        userName: 'Jane',
        registeredAt: now,
      );

      final copied = attendee.copyWith(userName: 'Jane Smith');
      expect(copied.userName, equals('Jane Smith'));
      expect(copied.userId, equals('usr_2'));
    });
  });
}
