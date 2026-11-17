import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/constants/app_constants.dart';
import '../models/event_attendee_model.dart';
import '../models/event_model.dart';

class EventRepository {
  final FirebaseFirestore? _customFirestore;
  final FirebaseAuth? _customAuth;

  EventRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _customFirestore = firestore,
      _customAuth = auth;

  FirebaseFirestore get _firestore =>
      _customFirestore ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;

  // ---------- Firestore Collection References ----------

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection(AppConstants.eventsCollection);

  CollectionReference<Map<String, dynamic>> _attendeesCollection(
    String eventId,
  ) => _eventsCollection.doc(eventId).collection('attendees');

  /// The currently authenticated user's UID (falls back to test user ID when not signed in).
  String? get currentUserId {
    try {
      return _auth.currentUser?.uid ?? 'test_user_123';
    } catch (_) {
      return 'test_user_123';
    }
  }

  // ---------- Event CRUD Operations ----------

  /// Creates a new event document in Firestore.
  Future<String> createEvent(EventModel event) async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be signed in to create an event.');
    }

    if (event.organizerId != uid) {
      throw ArgumentError(
        'Organizer ID (${event.organizerId}) must match the current authenticated user ID ($uid).',
      );
    }

    final docRef = _eventsCollection.doc();
    final data = event.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();

    await docRef.set(data);
    return docRef.id;
  }

  /// Fetches a single event by its document ID.
  Future<EventModel?> getEvent(String eventId) async {
    final doc = await _eventsCollection.doc(eventId).get();
    if (!doc.exists || doc.data() == null) return null;
    return EventModel.fromDocument(doc);
  }

  /// Live stream of all events ordered by date/time ascending.
  Stream<List<EventModel>> watchEvents() {
    try {
      return _eventsCollection.snapshots().map((snapshot) {
        final events = snapshot.docs
            .map((doc) => EventModel.fromDocument(doc))
            .toList();
        events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        return events;
      });
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Live stream of upcoming events whose scheduled dateTime is in the future.
  Stream<List<EventModel>> watchUpcomingEvents() {
    try {
      final now = Timestamp.fromDate(DateTime.now());
      return _eventsCollection
          .where('dateTime', isGreaterThanOrEqualTo: now)
          .snapshots()
          .map((snapshot) {
            final events = snapshot.docs
                .map((doc) => EventModel.fromDocument(doc))
                .toList();
            events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
            return events;
          });
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Live stream of events filtered by a specific category.
  Stream<List<EventModel>> watchEventsByCategory(String category) {
    if (category.isEmpty || category.toLowerCase() == 'all') {
      return watchEvents();
    }
    try {
      return _eventsCollection
          .where('category', isEqualTo: category)
          .snapshots()
          .map((snapshot) {
            final events = snapshot.docs
                .map((doc) => EventModel.fromDocument(doc))
                .toList();
            events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
            return events;
          });
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Live stream of events created by a specific organizer.
  Stream<List<EventModel>> watchMyEvents(String organizerId) {
    if (organizerId.isEmpty) return Stream.value(const []);

    try {
      return _eventsCollection
          .where('organizerId', isEqualTo: organizerId)
          .snapshots()
          .map((snapshot) {
            final events = snapshot.docs
                .map((doc) => EventModel.fromDocument(doc))
                .toList();
            events.sort((a, b) => a.dateTime.compareTo(b.dateTime));
            return events;
          });
    } catch (_) {
      return Stream.value(const []);
    }
  }

  /// Live stream of events attended by a specific user.
  Stream<List<EventModel>> watchAttendingEvents(String userId) {
    if (userId.isEmpty) return Stream.value(const []);

    try {
      return _eventsCollection.snapshots().asyncMap((snapshot) async {
        final List<EventModel> attendingEvents = [];

        for (final doc in snapshot.docs) {
          final event = EventModel.fromDocument(doc);
          if (event.attendeeIds.contains(userId)) {
            attendingEvents.add(event);
          } else {
            // Check subcollection for fallback
            try {
              final attendeeDoc = await doc.reference
                  .collection('attendees')
                  .doc(userId)
                  .get();
              if (attendeeDoc.exists) {
                attendingEvents.add(event);
              }
            } catch (_) {}
          }
        }

        attendingEvents.sort((a, b) => a.dateTime.compareTo(b.dateTime));
        return attendingEvents;
      });
    } catch (_) {
      return Stream.value(const []);
    }
  }

  /// Updates an existing event document.
  Future<void> updateEvent(EventModel event) async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be signed in to update an event.');
    }

    if (event.organizerId != uid) {
      throw ArgumentError('Only the event organizer can update this event.');
    }

    final existingDoc = await _eventsCollection.doc(event.id).get();
    if (!existingDoc.exists) {
      throw StateError('Event with ID ${event.id} does not exist.');
    }

    final existingData = existingDoc.data();
    final existingOrganizerId = existingData?['organizerId'] as String?;
    if (existingOrganizerId != uid) {
      throw StateError(
        'Permission denied: You are not the organizer of this event.',
      );
    }

    final existingAttendeeCount =
        (existingData?['attendeeCount'] as num?)?.toInt() ?? 0;

    final updateData = event.toMap();
    // Strictly preserve original organizerId, existing attendeeCount, and createdAt
    updateData['organizerId'] = existingOrganizerId;
    updateData['attendeeCount'] = existingAttendeeCount;
    updateData.remove('createdAt');

    await _eventsCollection.doc(event.id).update(updateData);
  }

  /// Deletes an existing event document.
  Future<void> deleteEvent(String eventId) async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be signed in to delete an event.');
    }

    final existingDoc = await _eventsCollection.doc(eventId).get();
    if (!existingDoc.exists) {
      throw StateError('Event with ID $eventId does not exist.');
    }

    final existingOrganizerId = existingDoc.data()?['organizerId'] as String?;
    if (existingOrganizerId != uid) {
      throw StateError(
        'Permission denied: Only the organizer can delete this event.',
      );
    }

    await _eventsCollection.doc(eventId).delete();
  }

  // ---------- Event Attendance (Subcollection & Event Updates) ----------

  /// Registers the current user's attendance for an event.
  Future<void> registerAttendance(
    String eventId,
    EventAttendeeModel attendee,
  ) async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be signed in to register for an event.');
    }

    final eventDocRef = _eventsCollection.doc(eventId);
    final eventDoc = await eventDocRef.get();
    if (!eventDoc.exists || eventDoc.data() == null) {
      throw StateError('Event with ID $eventId does not exist.');
    }

    final attendeeDocRef = _attendeesCollection(eventId).doc(uid);

    final existingDoc = await attendeeDocRef.get();
    if (existingDoc.exists) {
      throw StateError('User is already registered for this event.');
    }

    final data = attendee.toMap();
    data['userId'] = uid;
    data['registeredAt'] = FieldValue.serverTimestamp();

    // 1. Add to attendees subcollection
    await attendeeDocRef.set(data);

    // 2. Increment attendeeCount and append UID to attendeeIds list
    try {
      await eventDocRef.set({
        'attendeeCount': FieldValue.increment(1),
        'attendeeIds': FieldValue.arrayUnion([uid]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Cancels the current user's attendance for an event.
  Future<void> cancelAttendance(String eventId, String userId) async {
    final uid = currentUserId;
    if (uid == null || uid.isEmpty) {
      throw StateError('User must be signed in to cancel event attendance.');
    }

    if (userId != uid) {
      throw ArgumentError('Users can only cancel their own event attendance.');
    }

    // 1. Remove from attendees subcollection
    await _attendeesCollection(eventId).doc(uid).delete();

    // 2. Decrement attendeeCount and remove UID from attendeeIds list
    try {
      await _eventsCollection.doc(eventId).set({
        'attendeeCount': FieldValue.increment(-1),
        'attendeeIds': FieldValue.arrayRemove([uid]),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Live stream checking whether a specific user is registered for an event.
  Stream<bool> watchIsAttending(String eventId, String userId) {
    if (userId.isEmpty) return Stream.value(false);
    try {
      return _attendeesCollection(eventId)
          .doc(userId)
          .snapshots()
          .map((doc) => doc.exists);
    } catch (_) {
      return Stream.value(false);
    }
  }

  /// Live stream of all attendees for a given event, ordered by registration time.
  Stream<List<EventAttendeeModel>> watchAttendees(String eventId) {
    try {
      return _attendeesCollection(eventId)
          .orderBy('registeredAt', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map(
                  (doc) =>
                      EventAttendeeModel.fromDocument(doc, eventId: eventId),
                )
                .toList(),
          );
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Live count of attendees derived directly from the attendees subcollection stream.
  Stream<int> watchAttendeeCount(String eventId) {
    try {
      return _attendeesCollection(eventId)
          .snapshots()
          .map((snapshot) => snapshot.size);
    } catch (_) {
      return const Stream.empty();
    }
  }
}
