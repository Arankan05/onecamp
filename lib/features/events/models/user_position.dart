class UserPosition {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final DateTime timestamp;

  const UserPosition({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
  });

  /// Factory constructor to parse coordinates from Map or Firestore data.
  factory UserPosition.fromMap(Map<String, dynamic> map) {
    return UserPosition(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Converts the position into a Map suitable for storage or transmission.
  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (altitude != null) 'altitude': altitude,
      if (speed != null) 'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convenience helper to return formatted coordinates string e.g. "6.9271, 79.8612".
  String toCoordinatesString({int decimals = 4}) {
    return '${latitude.toStringAsFixed(decimals)}, ${longitude.toStringAsFixed(decimals)}';
  }

  /// Creates a copy with specified fields replaced.
  UserPosition copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    DateTime? timestamp,
  }) {
    return UserPosition(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'UserPosition(lat: $latitude, lng: $longitude, accuracy: ${accuracy}m, time: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPosition &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(latitude, longitude, timestamp);
}
