// ignore_for_file: deprecated_member_use

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
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
          userName:
              user?.displayName ?? user?.email?.split('@')[0] ?? 'Student',
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
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    currentUid ??= _repository.currentUserId ?? '';

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: Text(
          widget.event.title.isNotEmpty ? widget.event.title : 'Event Details',
        ),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: const OneCampBackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        children: [
          // Banner Image if available
          if (widget.event.imageUrl != null &&
              widget.event.imageUrl!.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                widget.event.imageUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: AppTheme.secondaryColor,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Hero Event Information Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C7C3AED),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.event.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<int>(
                      stream: _repository.watchAttendeeCount(widget.event.id),
                      initialData: widget.event.attendeeCount,
                      builder: (context, countSnapshot) {
                        final count =
                            countSnapshot.data ?? widget.event.attendeeCount;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBackground,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.people_alt_rounded,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$count attending',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Title
                Text(
                  widget.event.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 16),

                // Date & Time
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.dateTime.toString().split('.')[0],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Event Date & Time',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Organizer Info
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.event.organizerName.isNotEmpty
                              ? widget.event.organizerName
                              : 'Campus Organizer',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Organized by',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Attendance RSVP Action Button
                StreamBuilder<bool>(
                  stream: _repository.watchIsAttending(
                    widget.event.id,
                    currentUid,
                  ),
                  initialData: widget.event.isUserAttending(currentUid),
                  builder: (context, attendanceSnapshot) {
                    final isAttending = attendanceSnapshot.data ?? false;

                    return SizedBox(
                      width: double.infinity,
                      child: isAttending
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: const BorderSide(
                                  color: Colors.green,
                                  width: 2,
                                ),
                                foregroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              icon: _isProcessingAttendance
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.green,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                    ),
                              label: Text(
                                _isProcessingAttendance
                                    ? 'Updating...'
                                    : 'Attending (Tap to Cancel)',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _isProcessingAttendance
                                  ? null
                                  : () => _toggleAttendance(true),
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
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
                                  : const Icon(Icons.event_available_rounded),
                              label: Text(
                                _isProcessingAttendance
                                    ? 'Registering...'
                                    : 'Attend Event',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: _isProcessingAttendance
                                  ? null
                                  : () => _toggleAttendance(false),
                            ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Description Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About this Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.event.description.isNotEmpty
                      ? widget.event.description
                      : 'No description provided.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Location Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location & Venue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.event.locationName.isNotEmpty
                            ? widget.event.locationName
                            : 'Venue to be announced',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                  ],
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
          ),
        ],
      ),
    );
  }
}
