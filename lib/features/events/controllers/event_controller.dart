import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/cloudinary_upload_service.dart';
import '../models/event_model.dart';
import '../models/user_position.dart';
import '../repositories/event_repository.dart';
import '../services/location_service.dart';

/// State management controller for creating, editing, and managing events,
/// with integrated device GPS location retrieval via [LocationService].
class EventController extends ChangeNotifier {
  final EventRepository _eventRepository;
  final LocationService _locationService;

  EventController({
    EventRepository? eventRepository,
    LocationService? locationService,
  })  : _eventRepository = eventRepository ?? EventRepository(),
        _locationService = locationService ?? LocationService();

  // ---------- Form Fields ----------
  String _title = '';
  String _description = '';
  String _category = 'General';
  DateTime _dateTime = DateTime.now().add(const Duration(days: 1));
  String _locationName = '';
  double? _latitude;
  double? _longitude;
  String? _imageUrl;

  // ---------- Edit State Tracking ----------
  String? _editingEventId;
  String? _organizerId;
  String? _organizerName;
  int _attendeeCount = 0;
  DateTime? _createdAt;

  // ---------- Asynchronous Status State ----------
  bool _isLoadingLocation = false;
  bool _isUploadingImage = false;
  bool _isSaving = false;
  String? _locationErrorMessage;
  String? _saveErrorMessage;
  UserPosition? _lastRetrievedPosition;

  final CloudinaryUploadService _cloudinaryService = CloudinaryUploadService(
    uploadPreset: 'onecamp_event_images',
  );

  // ---------- Getters ----------
  String get title => _title;
  String get description => _description;
  String get category => _category;
  DateTime get dateTime => _dateTime;
  String get locationName => _locationName;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  String? get imageUrl => _imageUrl;
  bool get isUploadingImage => _isUploadingImage;

  String? get editingEventId => _editingEventId;
  String? get organizerId => _organizerId;
  String? get organizerName => _organizerName;
  int get attendeeCount => _attendeeCount;
  DateTime? get createdAt => _createdAt;
  bool get isEditing => _editingEventId != null;

  bool get isLoadingLocation => _isLoadingLocation;
  bool get isSaving => _isSaving;
  String? get locationErrorMessage => _locationErrorMessage;
  String? get saveErrorMessage => _saveErrorMessage;
  UserPosition? get lastRetrievedPosition => _lastRetrievedPosition;

  /// Whether the current form state has both latitude and longitude.
  bool get hasCoordinates => _latitude != null && _longitude != null;

  /// Human-readable formatted coordinate string e.g. "6.9271, 79.8612" or null.
  String? get coordinatesDisplay => hasCoordinates
      ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
      : null;

  /// External Google Maps query URL for the current coordinates, or null if absent.
  String? get mapsUrl => hasCoordinates
      ? _locationService.getMapsUrl(_latitude!, _longitude!)
      : null;

  /// Generates external Google Maps query URL for any given event.
  String? getMapsUrlForEvent(EventModel event) {
    if (!event.hasCoordinates) return null;
    return _locationService.getMapsUrl(event.latitude!, event.longitude!);
  }

  // ---------- Form Mutation Methods ----------

  void setTitle(String value) {
    _title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    _description = value;
    notifyListeners();
  }

  void setCategory(String value) {
    _category = value;
    notifyListeners();
  }

  void setDateTime(DateTime value) {
    _dateTime = value;
    notifyListeners();
  }

  /// Updates the venue name manually.
  ///
  /// Retains independent editing so the user can enter or modify a
  /// human-readable venue name without requiring reverse geocoding.
  void setLocationName(String value) {
    _locationName = value;
    notifyListeners();
  }

  /// Explicitly sets coordinates.
  void setCoordinates(double? lat, double? lng) {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  /// Explicitly clears GPS coordinates while keeping the venue name intact.
  void clearCoordinates() {
    _latitude = null;
    _longitude = null;
    _lastRetrievedPosition = null;
    notifyListeners();
  }

  /// Clears any active location error banner.
  void clearLocationError() {
    _locationErrorMessage = null;
    notifyListeners();
  }

  /// Clears any active save error banner.
  void clearSaveError() {
    _saveErrorMessage = null;
    notifyListeners();
  }

  // ---------- Form Initialization ----------

  /// Initializes the controller for editing an existing event.
  ///
  /// Accurately preserves existing coordinates, venue name, and metadata
  /// so that editing other fields does not accidentally erase coordinates.
  void initForEdit(EventModel event) {
    _editingEventId = event.id;
    _title = event.title;
    _description = event.description;
    _category = event.category;
    _dateTime = event.dateTime;
    _locationName = event.locationName;
    _latitude = event.latitude;
    _longitude = event.longitude;
    _imageUrl = event.imageUrl;
    _organizerId = event.organizerId;
    _organizerName = event.organizerName;
    _attendeeCount = event.attendeeCount;
    _createdAt = event.createdAt;
    _locationErrorMessage = null;
    _saveErrorMessage = null;
    _isLoadingLocation = false;
    _isSaving = false;
    _lastRetrievedPosition = null;
    notifyListeners();
  }

  /// Initializes the controller for creating a new event.
  void initForCreate({String? organizerId, String? organizerName}) {
    _editingEventId = null;
    _title = '';
    _description = '';
    _category = 'General';
    _dateTime = DateTime.now().add(const Duration(days: 1));
    _locationName = '';
    _latitude = null;
    _longitude = null;
    _imageUrl = null;
    _organizerId = organizerId;
    _organizerName = organizerName;
    _attendeeCount = 0;
    _createdAt = null;
    _locationErrorMessage = null;
    _saveErrorMessage = null;
    _isLoadingLocation = false;
    _isSaving = false;
    _lastRetrievedPosition = null;
    notifyListeners();
  }

  // ---------- Location Integration ----------

  /// Retrieves current device GPS coordinates via [LocationService].
  ///
  /// Expected behavior:
  /// 1. Sets [isLoadingLocation] to true and clears previous error.
  /// 2. Checks if location services are enabled on the device.
  /// 3. Requests location permission if required.
  /// 4. Handles denied and permanently denied permissions gracefully.
  /// 5. Populates [_latitude] and [_longitude].
  /// 6. Does NOT overwrite [_locationName] (retains manual venue name).
  /// 7. Exposes descriptive, actionable error messages on failure.
  Future<bool> useCurrentLocation({
    Duration timeout = const Duration(seconds: 15),
  }) async {
    _isLoadingLocation = true;
    _locationErrorMessage = null;
    notifyListeners();

    try {
      final position =
          await _locationService.getCurrentPosition(timeout: timeout);
      _latitude = position.latitude;
      _longitude = position.longitude;
      _lastRetrievedPosition = position;
      _locationErrorMessage = null;
      return true;
    } on LocationServiceDisabledException {
      _locationErrorMessage =
          'Location services are disabled on this device. Please enable GPS in your device settings.';
      return false;
    } on LocationPermissionDeniedException {
      _locationErrorMessage =
          'Location permission was denied. Please grant location access to use your current location.';
      return false;
    } on LocationPermissionPermanentlyDeniedException {
      _locationErrorMessage =
          'Location permission is permanently denied. Please enable location permissions in App Settings.';
      return false;
    } on LocationTimeoutException {
      _locationErrorMessage =
          'Location request timed out. Please check GPS reception and try again.';
      return false;
    } on LocationException catch (e) {
      _locationErrorMessage = e.message;
      return false;
    } catch (e) {
      _locationErrorMessage = 'Failed to retrieve location: $e';
      return false;
    } finally {
      _isLoadingLocation = false;
      notifyListeners();
    }
  }

  /// Opens system app settings for manually granting permanently denied permissions.
  Future<bool> openAppSettings() => _locationService.openAppSettings();

  /// Opens device location settings for enabling GPS hardware.
  Future<bool> openLocationSettings() =>
      _locationService.openLocationSettings();

  // ---------- Image Upload Operations (Cloudinary) ----------

  /// Pick an image from camera or gallery and upload to Cloudinary.
  Future<void> pickAndUploadImage(ImageSource source) async {
    _isUploadingImage = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      final xFile = await _cloudinaryService.pickImage(source);
      if (xFile != null) {
        final url = await _cloudinaryService.uploadImage(xFile);
        _imageUrl = url;
      }
    } catch (e) {
      _saveErrorMessage = 'Image upload error: $e';
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Remove attached event banner image.
  void removeImage() {
    _imageUrl = null;
    notifyListeners();
  }

  // ---------- Persistence Operations ----------

  /// Saves the current form state to Cloud Firestore via [EventRepository].
  ///
  /// - If [isEditing], updates the existing event while preserving attendee count,
  ///   original organizer ID, and createdAt. Coordinates are preserved unless
  ///   explicitly modified or cleared.
  /// - If creating, creates a new event document.
  Future<String?> saveEvent({
    String? fallbackOrganizerId,
    String? fallbackOrganizerName,
  }) async {
    _isSaving = true;
    _saveErrorMessage = null;
    notifyListeners();

    try {
      if (_title.trim().isEmpty) {
        throw ArgumentError('Event title cannot be empty.');
      }
      if (_locationName.trim().isEmpty) {
        throw ArgumentError('Venue or location name cannot be empty.');
      }

      final orgId = _organizerId ??
          fallbackOrganizerId ??
          _eventRepository.currentUserId ??
          '';
      final orgName = _organizerName ?? fallbackOrganizerName ?? 'Organizer';

      if (orgId.isEmpty) {
        throw StateError('User must be signed in to save an event.');
      }

      if (isEditing) {
        final existingEvent =
            await _eventRepository.getEvent(_editingEventId!);
        if (existingEvent == null) {
          throw StateError(
              'Cannot update event: Event with ID $_editingEventId does not exist.');
        }

        final shouldClearCoordinates =
            (_latitude == null && _longitude == null);

        final updatedEvent = existingEvent.copyWith(
          title: _title.trim(),
          description: _description.trim(),
          category: _category,
          dateTime: _dateTime,
          locationName: _locationName.trim(),
          latitude: _latitude,
          longitude: _longitude,
          clearCoordinates: shouldClearCoordinates,
          imageUrl: _imageUrl,
        );

        await _eventRepository.updateEvent(updatedEvent);
        return _editingEventId;
      } else {
        final newEvent = EventModel(
          id: '',
          title: _title.trim(),
          description: _description.trim(),
          category: _category,
          dateTime: _dateTime,
          locationName: _locationName.trim(),
          latitude: _latitude,
          longitude: _longitude,
          organizerId: orgId,
          organizerName: orgName,
          imageUrl: _imageUrl,
          attendeeCount: 0,
          createdAt: DateTime.now(),
        );

        final docId = await _eventRepository.createEvent(newEvent);
        return docId;
      }
    } catch (e) {
      _saveErrorMessage = e.toString();
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
