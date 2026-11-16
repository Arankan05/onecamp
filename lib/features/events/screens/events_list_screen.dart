import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';

enum EventViewFilter { all, myEvents, attending }

/// Screen displaying a real-time list of campus events with "My Events" tab & category filtering.
class EventsListScreen extends StatefulWidget {
  final EventRepository? eventRepository;

  const EventsListScreen({super.key, this.eventRepository});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  late final EventRepository _repository;
  EventViewFilter _viewFilter = EventViewFilter.all;
  String _selectedCategory = 'All';

  final List<String> _categories = const [
    'All',
    'General',
    'Academic',
    'Sports',
    'Cultural',
    'Workshop',
    'Social',
  ];

  @override
  void initState() {
    super.initState();
    _repository = widget.eventRepository ?? EventRepository();
  }

  Stream<List<EventModel>> get _eventsStream {
    try {
      String? currentUid;
      try {
        currentUid = FirebaseAuth.instance.currentUser?.uid;
      } catch (_) {}
      currentUid ??= _repository.currentUserId;

      switch (_viewFilter) {
        case EventViewFilter.myEvents:
          if (currentUid != null && currentUid.isNotEmpty) {
            return _repository.watchMyEvents(currentUid);
          }
          return _repository.watchEvents();
        case EventViewFilter.attending:
          if (currentUid != null && currentUid.isNotEmpty) {
            return _repository.watchAttendingEvents(currentUid);
          }
          return _repository.watchEvents();
        case EventViewFilter.all:
          return _repository.watchEvents();
      }
    } catch (_) {
      return const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    currentUid ??= _repository.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Top View Filter Tabs (All Events | My Events | Attending)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<EventViewFilter>(
              segments: const [
                ButtonSegment(
                  value: EventViewFilter.all,
                  label: Text('All Events'),
                  icon: Icon(Icons.event_note_outlined),
                ),
                ButtonSegment(
                  value: EventViewFilter.myEvents,
                  label: Text('My Events'),
                  icon: Icon(Icons.person_pin_outlined),
                ),
                ButtonSegment(
                  value: EventViewFilter.attending,
                  label: Text('Attending'),
                  icon: Icon(Icons.check_circle_outline),
                ),
              ],
              selected: {_viewFilter},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _viewFilter = newSelection.first;
                });
              },
            ),
          ),

          // 2. Category Filter Chips Horizontal Scroll
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    }
                  },
                );
              },
            ),
          ),

          // 3. Real-Time Stream List of Events
          Expanded(
            child: StreamBuilder<List<EventModel>>(
              stream: _eventsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading events: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final events = snapshot.data ?? [];
                final filteredEvents = _selectedCategory == 'All'
                    ? events
                    : events
                        .where((e) => e.category == _selectedCategory)
                        .toList();

                if (filteredEvents.isEmpty) {
                  String emptyText;
                  if (_viewFilter == EventViewFilter.myEvents) {
                    emptyText = 'You haven\'t created any events yet.';
                  } else if (_viewFilter == EventViewFilter.attending) {
                    emptyText = 'You aren\'t attending any events yet.';
                  } else if (_selectedCategory != 'All') {
                    emptyText = 'No events found in "$_selectedCategory".';
                  } else {
                    emptyText = 'No campus events created yet.';
                  }

                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          emptyText,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Create New Event'),
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.createEvent);
                          },
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return _EventCard(
                      event: event,
                      currentUid: currentUid,
                      repository: _repository,
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.eventDetails,
                          arguments: event,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Event'),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createEvent);
        },
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final EventModel event;
  final String? currentUid;
  final EventRepository repository;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    this.currentUid,
    required this.repository,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOrganizer = currentUid != null && event.organizerId == currentUid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              Image.network(
                event.imageUrl!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          event.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      if (isOrganizer) ...[
                        const SizedBox(width: 8),
                        Chip(
                          avatar: const Icon(Icons.star, size: 12, color: Colors.amber),
                          label: const Text('My Event',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.amber.shade50,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                      const Spacer(),
                      StreamBuilder<int>(
                        stream: repository.watchAttendeeCount(event.id),
                        initialData: event.attendeeCount > 0 ? event.attendeeCount : event.attendeeIds.length,
                        builder: (context, countSnapshot) {
                          final count = countSnapshot.data ??
                              (event.attendeeCount > 0
                                  ? event.attendeeCount
                                  : event.attendeeIds.length);
                          return Row(
                            children: [
                              const Icon(Icons.people_outline, size: 16),
                              const SizedBox(width: 4),
                              Text('$count', style: theme.textTheme.bodySmall),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Organizer Name Badge
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Organized by ${event.organizerName.isNotEmpty ? event.organizerName : 'Campus Admin'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.locationName,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.grey.shade700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Date Time
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        event.dateTime.toString().split('.')[0],
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
