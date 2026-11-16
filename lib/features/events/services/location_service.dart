import 'dart:async';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import '../models/user_position.dart';

/// Normalized location permission statuses.
enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  unableToDetermine,
}

/// Base exception for location operations.
class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => 'LocationException: $message';
}

/// Thrown when device location services (GPS hardware) are turned off.
class LocationServiceDisabledException extends LocationException {
  const LocationServiceDisabledException([
    super.message = 'Location services are disabled on this device.',
  ]);
}

/// Thrown when the user denies location permission.
class LocationPermissionDeniedException extends LocationException {
  const LocationPermissionDeniedException([
    super.message = 'Location permission was denied by the user.',
  ]);
}

/// Thrown when location permission is permanently denied (requires OS App Settings).
class LocationPermissionPermanentlyDeniedException extends LocationException {
  const LocationPermissionPermanentlyDeniedException([
    super.message =
        'Location permission is permanently denied. Please enable it in Settings.',
  ]);
}

/// Thrown when querying device GPS coordinates times out.
class LocationTimeoutException extends LocationException {
  const LocationTimeoutException([
    super.message = 'Timed out while retrieving location coordinates.',
  ]);
}

/// Abstract platform wrapper interface allowing complete unit testing without hardware GPS.
abstract class LocationPlatform {
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermission> checkPermission();
  Future<LocationPermission> requestPermission();
  Future<Position> getCurrentPosition({LocationSettings? locationSettings});
  Future<bool> openAppSettings();
  Future<bool> openLocationSettings();
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  );
}

/// Default implementation wrapping the official `Geolocator` plugin.
class GeolocatorPlatformWrapper implements LocationPlatform {
  const GeolocatorPlatformWrapper();

  @override
  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  @override
  Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  @override
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      Geolocator.getCurrentPosition(locationSettings: locationSettings);

  @override
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) =>
      Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
}

/// Reusable service handling device GPS coordinate retrieval and permission flows.
class LocationService {
  final LocationPlatform _platform;

  LocationService({LocationPlatform? platform})
      : _platform = platform ?? const GeolocatorPlatformWrapper();

  /// Checks whether hardware location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    try {
      return await _platform.isLocationServiceEnabled();
    } catch (e) {
      throw LocationException('Failed to check location service status: $e');
    }
  }

  /// Checks current location permission state.
  Future<LocationPermissionStatus> checkPermission() async {
    try {
      final permission = await _platform.checkPermission();
      return _mapPermission(permission);
    } catch (e) {
      throw LocationException('Failed to check location permission: $e');
    }
  }

  /// Prompts the user to grant location permissions.
  Future<LocationPermissionStatus> requestPermission() async {
    try {
      final permission = await _platform.requestPermission();
      return _mapPermission(permission);
    } catch (e) {
      throw LocationException('Failed to request location permission: $e');
    }
  }

  /// Retrieves the current device coordinates.
  ///
  /// Enforces complete lifecycle checks:
  /// 1. Verifies location services are turned on.
  /// 2. Verifies and prompts for permission if not yet granted.
  /// 3. Queries coordinates with a configurable timeout.
  Future<UserPosition> getCurrentPosition({
    Duration timeout = const Duration(seconds: 15),
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await checkPermission();
    if (permission == LocationPermissionStatus.denied ||
        permission == LocationPermissionStatus.unableToDetermine) {
      permission = await requestPermission();
      if (permission == LocationPermissionStatus.denied ||
          permission == LocationPermissionStatus.unableToDetermine) {
        throw const LocationPermissionDeniedException();
      }
    }

    if (permission == LocationPermissionStatus.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    try {
      final position = await _platform
          .getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: accuracy,
              timeLimit: timeout,
            ),
          )
          .timeout(timeout);

      return UserPosition(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        timestamp: position.timestamp,
      );
    } on TimeoutException {
      throw LocationTimeoutException(
          'Location request timed out after ${timeout.inSeconds} seconds.');
    } catch (e) {
      if (e is LocationException) rethrow;
      throw LocationException('Failed to retrieve location: $e');
    }
  }

  /// Launches system app settings for manually enabling permanently denied permissions.
  Future<bool> openAppSettings() => _platform.openAppSettings();

  /// Launches device location settings so the user can turn on GPS.
  Future<bool> openLocationSettings() => _platform.openLocationSettings();

  /// Formats an external Google Maps query URL for displaying coordinates in external map applications.
  String getMapsUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
  }

  /// Calculates geodesic distance in meters between two points (useful for campus geofences).
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return _platform.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.granted;
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.unableToDetermine;
    }
  }
}
