// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:onecamp/features/events/controllers/event_controller.dart';
import 'package:onecamp/features/events/models/event_model.dart';
import 'package:onecamp/features/events/services/location_service.dart';
import 'package:onecamp/features/events/widgets/event_location_input.dart';
import 'package:onecamp/features/events/widgets/event_map_action.dart';

import 'event_controller_test.dart';

void main() {
  group('EventLocationInput Widget Tests', () {
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
      controller.initForCreate();
    });

    testWidgets('Renders venue input and Use Current Location button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => EventLocationInput(controller: controller),
            ),
          ),
        ),
      );

      expect(find.text('Venue / Location Name *'), findsOneWidget);
      expect(find.byKey(const Key('use_current_location_button')), findsOneWidget);
      expect(find.byKey(const Key('coordinates_badge')), findsNothing);
      expect(find.byKey(const Key('location_error_banner')), findsNothing);
    });

    testWidgets('Tapping Use Current Location populates coordinates badge and preserves venue name', (tester) async {
      final textController = TextEditingController(text: 'Science Hall 1');
      controller.setLocationName('Science Hall 1');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => EventLocationInput(
                controller: controller,
                locationTextController: textController,
              ),
            ),
          ),
        ),
      );

      // Verify venue name is present
      expect(find.text('Science Hall 1'), findsOneWidget);

      // Tap Use Current Location
      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      // Verify coordinates badge is now visible
      expect(find.byKey(const Key('coordinates_badge')), findsOneWidget);
      expect(find.textContaining('6.9271, 79.8612'), findsOneWidget);

      // Verify venue name remains intact
      expect(controller.locationName, equals('Science Hall 1'));
      expect(find.text('Science Hall 1'), findsOneWidget);
    });

    testWidgets('Tapping Clear Coordinates icon clears coordinates badge', (tester) async {
      controller.setCoordinates(6.9271, 79.8612);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => EventLocationInput(controller: controller),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('coordinates_badge')), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byKey(const Key('clear_coordinates_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('coordinates_badge')), findsNothing);
      expect(controller.hasCoordinates, isFalse);
    });

    testWidgets('Displays error banner when location retrieval fails', (tester) async {
      fakePlatform.serviceEnabled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => EventLocationInput(controller: controller),
            ),
          ),
        ),
      );

      // Tap Use Current Location
      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('location_error_banner')), findsOneWidget);
      expect(find.textContaining('disabled on this device'), findsOneWidget);
    });

    testWidgets('Displays settings link when permission is permanently denied', (tester) async {
      fakePlatform.currentPermission = LocationPermission.deniedForever;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListenableBuilder(
              listenable: controller,
              builder: (context, child) => EventLocationInput(controller: controller),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('use_current_location_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('location_error_banner')), findsOneWidget);
      expect(find.text('Open App Settings'), findsOneWidget);
    });
  });

  group('EventMapAction Widget Tests', () {
    late FakeLocationPlatform fakePlatform;
    late LocationService locationService;

    setUp(() {
      fakePlatform = FakeLocationPlatform();
      locationService = LocationService(platform: fakePlatform);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
    });

    testWidgets('Renders nothing (SizedBox.shrink) when event has no coordinates', (tester) async {
      final eventWithoutCoords = EventModel(
        id: 'evt_no_coords',
        title: 'Virtual Meetup',
        description: 'Online webinar',
        category: 'Academic',
        dateTime: DateTime.now(),
        locationName: 'Online',
        organizerId: 'org_1',
        organizerName: 'Organizer',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventMapAction(
              event: eventWithoutCoords,
              locationService: locationService,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('open_in_maps_button')), findsNothing);
      expect(find.text('Open in Maps'), findsNothing);
    });

    testWidgets('Renders Open in Maps button and coordinates when event has valid coordinates', (tester) async {
      final eventWithCoords = EventModel(
        id: 'evt_coords',
        title: 'Campus Hackathon',
        description: 'Main Hall',
        category: 'Academic',
        dateTime: DateTime.now(),
        locationName: 'Innovation Hub',
        latitude: 6.9271,
        longitude: 79.8612,
        organizerId: 'org_1',
        organizerName: 'Organizer',
        createdAt: DateTime.now(),
      );

      String? launchedUrl;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventMapAction(
              event: eventWithCoords,
              locationService: locationService,
              onOpenMaps: (url) {
                launchedUrl = url;
              },
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('open_in_maps_button')), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);
      expect(find.text('Innovation Hub'), findsOneWidget);
      expect(find.textContaining('6.9271, 79.8612'), findsOneWidget);

      // Tap button and verify URL passed to callback
      await tester.tap(find.byKey(const Key('open_in_maps_button')));
      await tester.pumpAndSettle();

      expect(
        launchedUrl,
        equals('https://www.google.com/maps/search/?api=1&query=6.9271,79.8612'),
      );
    });

    testWidgets('Direct urlLauncher launches external map URL directly', (tester) async {
      final eventWithCoords = EventModel(
        id: 'evt_coords_2',
        title: 'Sports Day',
        description: 'Stadium',
        category: 'Sports',
        dateTime: DateTime.now(),
        locationName: 'University Stadium',
        latitude: 6.9000,
        longitude: 79.8500,
        organizerId: 'org_1',
        organizerName: 'Sports Lead',
        createdAt: DateTime.now(),
      );

      String? launchedUrl;
      bool launcherInvoked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventMapAction(
              event: eventWithCoords,
              locationService: locationService,
              urlLauncher: (url) async {
                launcherInvoked = true;
                launchedUrl = url;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_in_maps_button')));
      await tester.pumpAndSettle();

      expect(launcherInvoked, isTrue);
      expect(launchedUrl, equals('https://www.google.com/maps/search/?api=1&query=6.9,79.85'));
      // No fallback snackbar should appear on success
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('Direct urlLauncher failure triggers fallback message', (tester) async {
      final eventWithCoords = EventModel(
        id: 'evt_coords_3',
        title: 'Outdoor Meet',
        description: 'Park',
        category: 'Social',
        dateTime: DateTime.now(),
        locationName: 'Campus Park',
        latitude: 6.9100,
        longitude: 79.8600,
        organizerId: 'org_1',
        organizerName: 'Social Lead',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventMapAction(
              event: eventWithCoords,
              locationService: locationService,
              urlLauncher: (url) async => false, // simulates launcher failure
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_in_maps_button')));
      await tester.pumpAndSettle();

      // Fallback snackbar must be displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Could not open map app directly'), findsOneWidget);
    });

    testWidgets('Direct urlLauncher exception triggers fallback message without crash', (tester) async {
      final eventWithCoords = EventModel(
        id: 'evt_coords_4',
        title: 'Outdoor Meet 2',
        description: 'Park',
        category: 'Social',
        dateTime: DateTime.now(),
        locationName: 'Campus Park',
        latitude: 6.9100,
        longitude: 79.8600,
        organizerId: 'org_1',
        organizerName: 'Social Lead',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventMapAction(
              event: eventWithCoords,
              locationService: locationService,
              urlLauncher: (url) async => throw Exception('Native platform failure'),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_in_maps_button')));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Could not open map app directly'), findsOneWidget);
    });
  });
}
