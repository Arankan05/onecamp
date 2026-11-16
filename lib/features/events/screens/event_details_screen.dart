// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/event_attendee_model.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';
import '../services/location_service.dart';
import '../widgets/event_map_action.dart';

/// Screen displaying the details of an individual event,
/// including organizer details, venue map action, and attendance RSVP control.
class EventDetailsScreen extends StatefulWidget {
  final EventModel event;
  final LocationService? locationService;
  final EventRepository? eventRepository;
  final Future<bool> Function(String url)? urlLauncher;
  final void Function(String url)? onOpenMaps;

  const EventDetailsScreen({
    super.key,
    required this.event,
    this.locationService,
    this.eventRepository,
    this.urlLauncher,
    this.onOpenMaps,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late final EventRepository _repository;
  bool _isProcessingAttendance = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.eventRepository ?? EventRepository();
  }

  Future<void> _toggleAttendance(bool isCurrentlyAttending) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? _repository.currentUserId;

    if (uid == null || uid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to attend events.')),
      );
      return;
    }

    setState(() => _isProcessingAttendance = true);

    try {
      if (isCurrentlyAttending) {
        await _repository.cancelAttendance(widget.event.id, uid);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Attendance cancelled.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        final attendee = EventAttendeeModel(
          id: uid,
          eventId: widget.event.id,
          userId: uid,
          userName: user?.displayName ?? user?.email?.split('@')[0] ?? 'Student',
          userEmail: user?.email,
          registeredAt: DateTime.now(),
        );

        await _repository.registerAttendance(widget.event.id, attendee);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registered! You are attending this event. 🎉'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating attendance: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingAttendance = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final currentUid = user?.uid ?? _repository.currentUserId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.title.isNotEmpty ? widget.event.title : 'Event Details'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Banner Image if available
          if (widget.event.imageUrl != null && widget.event.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.event.imageUrl!,
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

          // Category & Live Attendee Count Badges
          Row(
            children: [
              Chip(
                label: Text(widget.event.category),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              const Spacer(),
              StreamBuilder<int>(
                stream: _repository.watchAttendeeCount(widget.event.id),
                initialData: widget.event.attendeeCount,
                builder: (context, countSnapshot) {
                  final count = countSnapshot.data ?? widget.event.attendeeCount;
                  return Row(
                    children: [
                      const Icon(Icons.people_outline, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '$count attending',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            widget.event.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Date & Time
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month, color: Colors.blue),
            ),
            title: Text(widget.event.dateTime.toString().split('.')[0]),
            subtitle: const Text('Event Date & Time'),
          ),

          // Organizer Info
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.person, color: Colors.teal),
            ),
            title: Text(
              widget.event.organizerName.isNotEmpty
                  ? widget.event.organizerName
                  : 'Campus Organizer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Organized by'),
          ),

          const Divider(height: 24),

          // Attendance RSVP Action Button
          StreamBuilder<bool>(
            stream: _repository.watchIsAttending(widget.event.id, currentUid),
            initialData: widget.event.isUserAttending(currentUid),
            builder: (context, attendanceSnapshot) {
              final isAttending = attendanceSnapshot.data ?? false;

              return SizedBox(
                width: double.infinity,
                child: isAttending
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.green, width: 2),
                          foregroundColor: Colors.green,
                        ),
                        icon: _isProcessingAttendance
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle, color: Colors.green),
                        label: Text(
                          _isProcessingAttendance
                              ? 'Updating...'
                              : 'Attending (Tap to Cancel)',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isProcessingAttendance
                            ? null
                            : () => _toggleAttendance(true),
                      )
                    : FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _isProcessingAttendance
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.event_available),
                        label: Text(
                          _isProcessingAttendance
                              ? 'Registering...'
                              : 'Attend Event',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isProcessingAttendance
                            ? null
                            : () => _toggleAttendance(false),
                      ),
              );
            },
          ),

          const Divider(height: 28),

          // Description
          Text(
            'About this Event',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.event.description.isNotEmpty
                ? widget.event.description
                : 'No description provided.',
            style: theme.textTheme.bodyMedium,
          ),

          const Divider(height: 28),

          // Location Section
          Text(
            'Location & Venue',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.event.locationName.isNotEmpty
                ? widget.event.locationName
                : 'Venue to be announced',
            style: theme.textTheme.bodyLarge,
          ),

          // Map Action (Only rendered if coordinates are present!)
          EventMapAction(
            event: widget.event,
            locationService: widget.locationService,
            urlLauncher: widget.urlLauncher,
            onOpenMaps: widget.onOpenMaps,
          ),
        ],
      ),
    );
  }
}
