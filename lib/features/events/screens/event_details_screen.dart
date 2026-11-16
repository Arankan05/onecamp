// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../models/event_model.dart';
import '../services/location_service.dart';
import '../widgets/event_map_action.dart';

/// Screen displaying the details of an individual event.
///
/// Location Features:
/// - Displays venue name and human-readable coordinates.
/// - Renders [EventMapAction] ("Open in Maps") ONLY when the event has valid GPS coordinates.
/// - Does not display map action when coordinates are missing.
class EventDetailsScreen extends StatelessWidget {
  final EventModel event;
  final LocationService? locationService;
  final Future<bool> Function(String url)? urlLauncher;
  final void Function(String url)? onOpenMaps;

  const EventDetailsScreen({
    super.key,
    required this.event,
    this.locationService,
    this.urlLauncher,
    this.onOpenMaps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(event.title.isNotEmpty ? event.title : 'Event Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Banner Image if available
          if (event.imageUrl != null && event.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                event.imageUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Category & Attendee Count Badges
          Row(
            children: [
              Chip(
                label: Text(event.category),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${event.attendeeCount} attending',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            event.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Date & Time
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_month, color: Colors.blue),
            title: Text(event.dateTime.toString().split('.')[0]),
            subtitle: const Text('Event Date & Time'),
          ),

          // Organizer
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.person_outline, color: Colors.teal),
            title: Text(event.organizerName),
            subtitle: const Text('Organized by'),
          ),

          const Divider(height: 24),

          // Description
          Text(
            'About this Event',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.description.isNotEmpty
                ? event.description
                : 'No description provided.',
            style: theme.textTheme.bodyMedium,
          ),

          const Divider(height: 24),

          // Location Section
          Text(
            'Location & Venue',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.locationName.isNotEmpty
                ? event.locationName
                : 'Venue to be announced',
            style: theme.textTheme.bodyLarge,
          ),

          // Map Action (Only rendered if coordinates are present!)
          EventMapAction(
            event: event,
            locationService: locationService,
            urlLauncher: urlLauncher,
            onOpenMaps: onOpenMaps,
          ),
        ],
      ),
    );
  }
}
