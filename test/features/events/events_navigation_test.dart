// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onecamp/features/events/models/event_model.dart';
import 'package:onecamp/features/events/screens/create_event_screen.dart';
import 'package:onecamp/features/events/screens/event_details_screen.dart';
import 'package:onecamp/routes/app_routes.dart';

void main() {
  group('Events Navigation & Routing Tests', () {
    testWidgets('AppRoutes.createEvent with no arguments opens CreateEventScreen in create mode',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.initial,
        ),
      );

      // Verify initial route
      expect(find.text('OneCamp Initializing...'), findsOneWidget);

      // Navigate to /events/create
      final navState = tester.state<NavigatorState>(find.byType(Navigator));
      navState.pushNamed(AppRoutes.createEvent);
      await tester.pumpAndSettle();

      expect(find.byType(CreateEventScreen), findsOneWidget);
      expect(find.text('Create Event'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Venue / Location Name *'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Venue / Location Name *'), findsOneWidget);
    });

    testWidgets('AppRoutes.createEvent with EventModel opens CreateEventScreen in edit mode',
        (tester) async {
      final sampleEvent = EventModel(
        id: 'evt_edit_nav',
        title: 'Robotics Workshop',
        description: 'Hands-on Arduino session',
        category: 'Workshop',
        dateTime: DateTime(2026, 12, 10, 14, 0),
        locationName: 'Robotics Lab 1',
        latitude: 6.9271,
        longitude: 79.8612,
        organizerId: 'org_1',
        organizerName: 'Robotics Society',
        createdAt: DateTime(2026, 11, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.initial,
        ),
      );

      final navState = tester.state<NavigatorState>(find.byType(Navigator));
      navState.pushNamed(AppRoutes.createEvent, arguments: sampleEvent);
      await tester.pumpAndSettle();

      expect(find.byType(CreateEventScreen), findsOneWidget);
      expect(find.text('Edit Event'), findsOneWidget);
      expect(find.text('Robotics Workshop'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Robotics Lab 1'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Robotics Lab 1'), findsOneWidget);
      expect(find.textContaining('6.9271, 79.8612'), findsOneWidget);
    });

    testWidgets('AppRoutes.eventDetails with valid EventModel opens EventDetailsScreen',
        (tester) async {
      final sampleEvent = EventModel(
        id: 'evt_details_nav',
        title: 'Campus Cricket Derby',
        description: 'Annual match',
        category: 'Sports',
        dateTime: DateTime(2026, 12, 15, 9, 0),
        locationName: 'University Oval',
        latitude: 6.9000,
        longitude: 79.8500,
        organizerId: 'org_2',
        organizerName: 'Cricket Club',
        attendeeCount: 45,
        createdAt: DateTime(2026, 11, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.initial,
        ),
      );

      final navState = tester.state<NavigatorState>(find.byType(Navigator));
      navState.pushNamed(AppRoutes.eventDetails, arguments: sampleEvent);
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailsScreen), findsOneWidget);
      expect(find.text('Campus Cricket Derby'), findsWidgets);
      expect(find.text('University Oval'), findsWidgets);
      expect(find.text('Open in Maps'), findsOneWidget);
    });

    testWidgets('AppRoutes.eventDetails with missing argument safely shows error screen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.initial,
        ),
      );

      final navState = tester.state<NavigatorState>(find.byType(Navigator));
      navState.pushNamed(AppRoutes.eventDetails); // No arguments passed
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailsScreen), findsNothing);
      expect(find.text('Invalid Event'), findsOneWidget);
      expect(find.text('Error: Missing event details argument.'), findsOneWidget);
    });

    testWidgets('AppRoutes.eventDetails with wrong argument type safely shows error screen',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: AppRoutes.onGenerateRoute,
          initialRoute: AppRoutes.createEvent,
        ),
      );

      final navState = tester.state<NavigatorState>(find.byType(Navigator));
      navState.pushNamed(AppRoutes.eventDetails, arguments: 'invalid_string_argument');
      await tester.pumpAndSettle();

      expect(find.byType(EventDetailsScreen), findsNothing);
      expect(find.text('Invalid Event'), findsOneWidget);
      expect(find.textContaining('Error: Invalid event details argument type'), findsOneWidget);
    });
  });
}
