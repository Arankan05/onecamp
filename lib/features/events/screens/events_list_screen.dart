import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/onecamp_back_button.dart';
import '../../../routes/app_routes.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';

enum EventViewFilter { all, myEvents, attending }

/// Screen displaying a real-time list of campus events styled to match the Messages master design.
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
    String? currentUid;
    try {
      currentUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {}
    currentUid ??= _repository.currentUserId;

    return Scaffold(
      backgroundColor: AppTheme.primaryBackground,
      appBar: AppBar(
        title: const Text('Campus Events'),
        backgroundColor: AppTheme.primaryBackground,
        elevation: 0,
        leading: Navigator.canPop(context) ? const OneCampBackButton() : null,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Top View Filter Tabs (All Events | My Events | Attending)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildSegmentTab('All Events', EventViewFilter.all),
                  _buildSegmentTab('My Events', EventViewFilter.myEvents),
                  _buildSegmentTab('Attending', EventViewFilter.attending),
                ],
              ),
            ),
          ),

          // 2. Category Filter Chips Horizontal Scroll
          SizedBox(
            height: 52,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  selectedColor: AppTheme.primaryColor,
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1F2937),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
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
                        Icon(
                          Icons.event_busy_rounded,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          emptyText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create New Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
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
                  physics: const BouncingScrollPhysics(),
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
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'New Event',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.createEvent);
        },
      ),
    );
  }

  Widget _buildSegmentTab(String label, EventViewFilter filter) {
    final isSelected = _viewFilter == filter;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
            ),
          ),
        ),
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
    final isOrganizer = currentUid != null && event.organizerId == currentUid;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
              Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: AppTheme.secondaryColor,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
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
                          event.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      if (isOrganizer) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 12,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'My Event',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      StreamBuilder<int>(
                        stream: repository.watchAttendeeCount(event.id),
                        initialData: event.attendeeCount > 0
                            ? event.attendeeCount
                            : event.attendeeIds.length,
                        builder: (context, countSnapshot) {
                          final count =
                              countSnapshot.data ??
                              (event.attendeeCount > 0
                                  ? event.attendeeCount
                                  : event.attendeeIds.length);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
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
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$count attending',
                                  style: const TextStyle(
                                    fontSize: 11,
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
                  const SizedBox(height: 10),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Organizer Name Badge
                  Row(
                    children: [
                      const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Organized by ${event.organizerName.isNotEmpty ? event.organizerName : 'Campus Student'}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
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
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.locationName,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Date Time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        event.dateTime.toString().split('.')[0],
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
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
