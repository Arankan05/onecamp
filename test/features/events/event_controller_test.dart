import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:onecamp/features/events/controllers/event_controller.dart';
import 'package:onecamp/features/events/models/event_attendee_model.dart';
import 'package:onecamp/features/events/models/event_model.dart';
import 'package:onecamp/features/events/repositories/event_repository.dart';
import 'package:onecamp/features/events/services/location_service.dart';

/// In-memory fake implementation of EventRepository for controller testing.
class FakeEventRepository implements EventRepository {
  final Map<String, EventModel> events = {};
  String? fakeUserId;

  FakeEventRepository({this.fakeUserId = 'org_test_123'});

  @override
  String? get currentUserId => fakeUserId;

  @override
  Future<String> createEvent(EventModel event) async {
    final id = 'evt_${events.length + 1}';
    final saved = event.copyWith(id: id);
    events[id] = saved;
    return id;
  }

  @override
  Future<EventModel?> getEvent(String eventId) async {
    return events[eventId];
  }

  @override
  Future<void> updateEvent(EventModel event) async {
    if (!events.containsKey(event.id)) {
      throw StateError('Event with ID ${event.id} does not exist.');
    }
    events[event.id] = event;
  }

  @override
  Future<void> deleteEvent(String eventId) async {
    events.remove(eventId);
  }

  @override
  Stream<List<EventModel>> watchEvents() =>
      Stream.value(events.values.toList());

  @override
  Stream<List<EventModel>> watchUpcomingEvents() =>
      Stream.value(events.values.toList());

  @override
  Stream<List<EventModel>> watchEventsByCategory(String category) =>
      Stream.value(events.values.where((e) => e.category == category).toList());

  @override
  Stream<List<EventModel>> watchMyEvents(String organizerId) =>
      Stream.value(events.values.where((e) => e.organizerId == organizerId).toList());

  @override
  Stream<List<EventModel>> watchAttendingEvents(String userId) =>
      Stream.value(events.values.where((e) => e.attendeeIds.contains(userId)).toList());

  @override
  Future<void> registerAttendance(
      String eventId, EventAttendeeModel attendee) async {}

  @override
  Future<void> cancelAttendance(String eventId, String userId) async {}

  @override
  Stream<bool> watchIsAttending(String eventId, String userId) =>
      Stream.value(false);

  @override
  Stream<List<EventAttendeeModel>> watchAttendees(String eventId) =>
      Stream.value([]);

  @override
  Stream<int> watchAttendeeCount(String eventId) => Stream.value(0);
}

/// Fake LocationPlatform for simulating GPS hardware states and responses.
class FakeLocationPlatform implements LocationPlatform {
  bool serviceEnabled = true;
  LocationPermission currentPermission = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Position? positionResult;
  Duration? simulatedDelay;
  bool shouldThrow = false;
  String errorMessage = 'Native platform error';

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (shouldThrow) throw Exception(errorMessage);
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    if (shouldThrow) throw Exception(errorMessage);
    return currentPermission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    if (shouldThrow) throw Exception(errorMessage);
    currentPermission = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    if (shouldThrow) throw Exception(errorMessage);
    if (simulatedDelay != null) {
      await Future.delayed(simulatedDelay!);
    }
    if (positionResult != null) return positionResult!;
    return Position(
      latitude: 6.9271,
      longitude: 79.8612,
      timestamp: DateTime(2026, 11, 15, 12, 0),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final dx = (endLatitude - startLatitude) * 111000;
    final dy = (endLongitude - startLongitude) * 111000;
    return math.sqrt(dx * dx + dy * dy);
  }
}

void main() {
  group('EventController Location Integration Tests', () {
    late FakeEventRepository fakeRepo;
    late FakeLocationPlatform fakePlatform;
    late LocationService locationService;
    late EventController controller;

    setUp(() {
      fakeRepo = FakeEventRepository();
      fakePlatform = FakeLocationPlatform();
      locationService = LocationService(platform: fakePlatform);
      controller = EventController(
        eventRepository: fakeRepo,
        locationService: locationService,
      );
    });

    test('Initial state has no coordinates and default form values', () {
      controller.initForCreate();
      expect(controller.latitude, isNull);
      expect(controller.longitude, isNull);
      expect(controller.hasCoordinates, isFalse);
      expect(controller.coordinatesDisplay, isNull);
      expect(controller.mapsUrl, isNull);
      expect(controller.isLoadingLocation, isFalse);
      expect(controller.locationErrorMessage, isNull);
    });

    test('Successful GPS retrieval populates coordinates while preserving manual venue name', () async {
      controller.initForCreate();
      controller.setLocationName('Faculty Complex Auditorium');

      final success = await controller.useCurrentLocation();

      expect(success, isTrue);
      expect(controller.isLoadingLocation, isFalse);
      expect(controller.latitude, equals(6.9271));
      expect(controller.longitude, equals(79.8612));
      expect(controller.hasCoordinates, isTrue);
      expect(controller.coordinatesDisplay, equals('6.9271, 79.8612'));
      expect(controller.locationErrorMessage, isNull);
      // Venue name entered by organizer must be preserved!
      expect(controller.locationName, equals('Faculty Complex Auditorium'));
    });

    test('Handles disabled location services gracefully with user-friendly error', () async {
      controller.initForCreate();
      fakePlatform.serviceEnabled = false;

      final success = await controller.useCurrentLocation();

      expect(success, isFalse);
      expect(controller.isLoadingLocation, isFalse);
      expect(controller.hasCoordinates, isFalse);
      expect(controller.locationErrorMessage, contains('disabled on this device'));
    });

    test('Handles permission denial gracefully with user-friendly error', () async {
      controller.initForCreate();
      fakePlatform.currentPermission = LocationPermission.denied;
      fakePlatform.requestPermissionResult = LocationPermission.denied;

      final success = await controller.useCurrentLocation();

      expect(success, isFalse);
      expect(controller.isLoadingLocation, isFalse);
      expect(controller.hasCoordinates, isFalse);
      expect(controller.locationErrorMessage, contains('permission was denied'));
    });

    test('Handles permanently denied permission with instructions for Settings', () async {
      controller.initForCreate();
      fakePlatform.currentPermission = LocationPermission.deniedForever;

      final success = await controller.useCurrentLocation();

      expect(success, isFalse);
      expect(controller.isLoadingLocation, isFalse);
      expect(controller.hasCoordinates, isFalse);
      expect(controller.locationErrorMessage, contains('permanently denied'));
      expect(controller.locationErrorMessage, contains('Settings'));
    });

    test('Handles GPS retrieval timeout gracefully', () async {
      controller.initForCreate();
      fakePlatform.simulatedDelay = const Duration(milliseconds: 200);

      final success = await controller.useCurrentLocation(
        timeout: const Duration(milliseconds: 50),
      );

      expect(success, isFalse);
      expect(controller.isLoadingLocation, isFalse);
      expect(controller.hasCoordinates, isFalse);
      expect(controller.locationErrorMessage, contains('timed out'));
    });

    test('Manual venue name editing does not affect coordinates', () {
      controller.initForCreate();
      controller.setCoordinates(6.9000, 79.8500);
      expect(controller.hasCoordinates, isTrue);

      controller.setLocationName('Student Union Center');
      expect(controller.locationName, equals('Student Union Center'));
      expect(controller.latitude, equals(6.9000));
      expect(controller.longitude, equals(79.8500));
    });

    test('Clearing coordinates explicitly resets latitude and longitude but preserves venue name', () {
      controller.initForCreate();
      controller.setLocationName('Main Library');
      controller.setCoordinates(6.9271, 79.8612);

      expect(controller.hasCoordinates, isTrue);

      controller.clearCoordinates();

      expect(controller.latitude, isNull);
      expect(controller.longitude, isNull);
      expect(controller.hasCoordinates, isFalse);
      expect(controller.coordinatesDisplay, isNull);
      expect(controller.mapsUrl, isNull);
      expect(controller.locationName, equals('Main Library'));
    });

    test('Preserving coordinates during event editing when organizer does not change them', () async {
      final existingEvent = EventModel(
        id: 'evt_edit_1',
        title: 'Tech Meetup',
        description: 'Monthly meet',
        category: 'Academic',
        dateTime: DateTime(2026, 12, 1, 10, 0),
        locationName: 'Engineering Lab 2',
        latitude: 6.9271,
        longitude: 79.8612,
        organizerId: 'org_test_123',
        organizerName: 'Tech Lead',
        attendeeCount: 12,
        createdAt: DateTime(2026, 11, 1, 10, 0),
      );
      fakeRepo.events['evt_edit_1'] = existingEvent;

      controller.initForEdit(existingEvent);

      expect(controller.isEditing, isTrue);
      expect(controller.latitude, equals(6.9271));
      expect(controller.longitude, equals(79.8612));
      expect(controller.hasCoordinates, isTrue);

      // Organizer only changes title and description, leaving location untouched
      controller.setTitle('Tech Meetup 2.0');
      controller.setDescription('Updated schedule');

      final savedId = await controller.saveEvent();

      expect(savedId, equals('evt_edit_1'));
      final updated = fakeRepo.events['evt_edit_1']!;
      expect(updated.title, equals('Tech Meetup 2.0'));
      expect(updated.description, equals('Updated schedule'));
      // Coordinates must be accurately preserved!
      expect(updated.latitude, equals(6.9271));
      expect(updated.longitude, equals(79.8612));
      expect(updated.hasCoordinates, isTrue);
      expect(updated.locationName, equals('Engineering Lab 2'));
    });

    test('Editing event and explicitly clearing coordinates saves null coordinates', () async {
      final existingEvent = EventModel(
        id: 'evt_edit_2',
        title: 'Online Webinar',
        description: 'Moved online',
        category: 'Academic',
        dateTime: DateTime(2026, 12, 1, 10, 0),
        locationName: 'Zoom link to follow',
        latitude: 6.9271,
        longitude: 79.8612,
        organizerId: 'org_test_123',
        organizerName: 'Tech Lead',
        createdAt: DateTime(2026, 11, 1, 10, 0),
      );
      fakeRepo.events['evt_edit_2'] = existingEvent;

      controller.initForEdit(existingEvent);
      expect(controller.hasCoordinates, isTrue);

      // Organizer clears coordinates explicitly
      controller.clearCoordinates();
      expect(controller.hasCoordinates, isFalse);

      final savedId = await controller.saveEvent();
      expect(savedId, equals('evt_edit_2'));

      final updated = fakeRepo.events['evt_edit_2']!;
      expect(updated.latitude, isNull);
      expect(updated.longitude, isNull);
      expect(updated.hasCoordinates, isFalse);
      expect(updated.locationName, equals('Zoom link to follow'));
    });

    test('Maps URL generation produces valid query URL for coordinates', () {
      controller.initForCreate();
      expect(controller.mapsUrl, isNull);

      controller.setCoordinates(6.9271, 79.8612);
      expect(
        controller.mapsUrl,
        equals('https://www.google.com/maps/search/?api=1&query=6.9271,79.8612'),
      );

      final eventWithCoords = EventModel(
        id: 'e1',
        title: 'Event With GPS',
        description: '',
        category: 'Sports',
        dateTime: DateTime.now(),
        locationName: 'Sports Ground',
        latitude: 6.9123,
        longitude: 79.8456,
        organizerId: 'org1',
        organizerName: 'Club',
        createdAt: DateTime.now(),
      );
      expect(
        controller.getMapsUrlForEvent(eventWithCoords),
        equals('https://www.google.com/maps/search/?api=1&query=6.9123,79.8456'),
      );

      final eventWithoutCoords = EventModel(
        id: 'e2',
        title: 'Online Event',
        description: '',
        category: 'General',
        dateTime: DateTime.now(),
        locationName: 'Online',
        organizerId: 'org1',
        organizerName: 'Club',
        createdAt: DateTime.now(),
      );
      expect(controller.getMapsUrlForEvent(eventWithoutCoords), isNull);
    });
  });
}

