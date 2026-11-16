import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:onecamp/features/events/models/user_position.dart';
import 'package:onecamp/features/events/services/location_service.dart';

/// Test double simulating platform GPS responses.
class FakeLocationPlatform implements LocationPlatform {
  bool serviceEnabled = true;
  LocationPermission currentPermission = LocationPermission.whileInUse;
  LocationPermission requestPermissionResult = LocationPermission.whileInUse;
  Position? positionResult;
  Duration? simulatedDelay;
  bool shouldThrow = false;
  String errorMessage = 'Native error';

  @override
  Future<bool> isLocationServiceEnabled() async {
    if (shouldThrow) throw Exception(errorMessage);
    return serviceEnabled;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    if (shouldThrow) throw Exception(errorMessage);
    return currentPermission;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    if (shouldThrow) throw Exception(errorMessage);
    currentPermission = requestPermissionResult;
    return requestPermissionResult;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) async {
    if (shouldThrow) throw Exception(errorMessage);
    if (simulatedDelay != null) {
      await Future.delayed(simulatedDelay!);
    }
    if (positionResult != null) return positionResult!;
    return Position(
      latitude: 6.9271,
      longitude: 79.8612,
      timestamp: DateTime(2026, 11, 15, 12, 0),
      accuracy: 5.0,
      altitude: 10.0,
      altitudeAccuracy: 1.0,
      heading: 0.0,
      headingAccuracy: 1.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  @override
  Future<bool> openAppSettings() async => true;

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    // Equirectangular distance approximation for test double
    final dx = (endLatitude - startLatitude) * 111000;
    final dy = (endLongitude - startLongitude) * 111000;
    return math.sqrt(dx * dx + dy * dy);
  }
}

void main() {
  group('LocationService Tests', () {
    late FakeLocationPlatform fakePlatform;
    late LocationService locationService;

    setUp(() {
      fakePlatform = FakeLocationPlatform();
      locationService = LocationService(platform: fakePlatform);
    });

    test('isLocationServiceEnabled reports status accurately', () async {
      fakePlatform.serviceEnabled = true;
      expect(await locationService.isLocationServiceEnabled(), isTrue);

      fakePlatform.serviceEnabled = false;
      expect(await locationService.isLocationServiceEnabled(), isFalse);
    });

    test('checkPermission maps platform permissions to normalized enum', () async {
      fakePlatform.currentPermission = LocationPermission.whileInUse;
      expect(await locationService.checkPermission(),
          equals(LocationPermissionStatus.granted));

      fakePlatform.currentPermission = LocationPermission.always;
      expect(await locationService.checkPermission(),
          equals(LocationPermissionStatus.granted));

      fakePlatform.currentPermission = LocationPermission.denied;
      expect(await locationService.checkPermission(),
          equals(LocationPermissionStatus.denied));

      fakePlatform.currentPermission = LocationPermission.deniedForever;
      expect(await locationService.checkPermission(),
          equals(LocationPermissionStatus.deniedForever));
    });

    test('getCurrentPosition succeeds when permission and service are enabled', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.currentPermission = LocationPermission.whileInUse;

      final pos = await locationService.getCurrentPosition();

      expect(pos.latitude, equals(6.9271));
      expect(pos.longitude, equals(79.8612));
      expect(pos.accuracy, equals(5.0));
    });

    test('getCurrentPosition throws LocationServiceDisabledException when service is off', () async {
      fakePlatform.serviceEnabled = false;

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<LocationServiceDisabledException>()),
      );
    });

    test('getCurrentPosition requests permission when denied, throws if denied again', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.currentPermission = LocationPermission.denied;
      fakePlatform.requestPermissionResult = LocationPermission.denied;

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
    });

    test('getCurrentPosition succeeds if user grants permission upon request', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.currentPermission = LocationPermission.denied;
      fakePlatform.requestPermissionResult = LocationPermission.whileInUse;

      final pos = await locationService.getCurrentPosition();
      expect(pos.latitude, equals(6.9271));
    });

    test('getCurrentPosition throws LocationPermissionPermanentlyDeniedException', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.currentPermission = LocationPermission.deniedForever;

      expect(
        () => locationService.getCurrentPosition(),
        throwsA(isA<LocationPermissionPermanentlyDeniedException>()),
      );
    });

    test('getCurrentPosition throws LocationTimeoutException on timeout', () async {
      fakePlatform.serviceEnabled = true;
      fakePlatform.currentPermission = LocationPermission.whileInUse;
      fakePlatform.simulatedDelay = const Duration(milliseconds: 200);

      expect(
        () => locationService.getCurrentPosition(
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<LocationTimeoutException>()),
      );
    });

    test('getMapsUrl generates valid Google Maps query URL', () {
      final url = locationService.getMapsUrl(6.9271, 79.8612);
      expect(url, equals('https://www.google.com/maps/search/?api=1&query=6.9271,79.8612'));
    });

    test('calculateDistance returns geodesic distance', () {
      final distance = locationService.calculateDistance(6.9271, 79.8612, 6.9281, 79.8612);
      expect(distance, greaterThan(0));
      expect(distance, closeTo(111.0, 1.0));
    });
  });

  group('UserPosition Model Tests', () {
    test('UserPosition serialization and string conversion', () {
      final now = DateTime(2026, 11, 15, 12, 0);
      final pos = UserPosition(
        latitude: 6.927079,
        longitude: 79.861244,
        accuracy: 10.5,
        altitude: 25.0,
        speed: 1.2,
        timestamp: now,
      );

      final map = pos.toMap();
      expect(map['latitude'], equals(6.927079));
      expect(map['longitude'], equals(79.861244));
      expect(map['accuracy'], equals(10.5));

      final restored = UserPosition.fromMap(map);
      expect(restored.latitude, equals(6.927079));
      expect(restored.longitude, equals(79.861244));
      expect(pos.toCoordinatesString(decimals: 4), equals('6.9271, 79.8612'));
    });
  });
}
