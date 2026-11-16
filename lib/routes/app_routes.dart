// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../features/events/models/event_model.dart';
import '../features/events/screens/create_event_screen.dart';
import '../features/events/screens/event_details_screen.dart';

class AppRoutes {
  static const String initial = '/';

  // Events Feature Routes
  static const String createEvent = '/events/create';
  static const String eventDetails = '/events/details';

  static Map<String, WidgetBuilder> get routes {
    return {
      // Static routes can be registered here if needed
    };
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case initial:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const CreateEventScreen(),
        );

      case createEvent:
        // Accept optional EventModel argument for edit mode safely
        final args = settings.arguments;
        final eventToEdit = args is EventModel ? args : null;
        return MaterialPageRoute<String?>(
          settings: settings,
          builder: (_) => CreateEventScreen(eventToEdit: eventToEdit),
        );

      case eventDetails:
        // Require a valid EventModel argument safely
        final args = settings.arguments;
        if (args is! EventModel) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Invalid Event')),
              body: Center(
                child: Text(
                  args == null
                      ? 'Error: Missing event details argument.'
                      : 'Error: Invalid event details argument type (${args.runtimeType}).',
                ),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => EventDetailsScreen(event: args),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
