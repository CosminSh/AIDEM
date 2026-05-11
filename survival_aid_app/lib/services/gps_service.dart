import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsCoordinates {
  final double latitude;
  final double longitude;
  final double? altitude;
  final DateTime timestamp;

  GpsCoordinates({
    required this.latitude,
    required this.longitude,
    this.altitude,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'altitude': altitude,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GpsCoordinates.fromJson(Map<String, dynamic> json) => GpsCoordinates(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    altitude: (json['altitude'] as num?)?.toDouble(),
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  String toDms() {
    String latStr = _convert(latitude, true);
    String lonStr = _convert(longitude, false);
    return "$latStr, $lonStr";
  }

  String _convert(double decimal, bool isLat) {
    String direction = isLat
        ? (decimal >= 0 ? "N" : "S")
        : (decimal >= 0 ? "E" : "W");

    double absDecimal = decimal.abs();
    int degrees = absDecimal.floor();
    double minutesFloat = (absDecimal - degrees) * 60;
    int minutes = minutesFloat.floor();
    double seconds = (minutesFloat - minutes) * 60;
    return "$degrees°$minutes'${seconds.toStringAsFixed(1)}\"$direction";
  }
}

class GpsService {
  final StreamController<GpsCoordinates> _controller =
      StreamController<GpsCoordinates>.broadcast();

  Stream<GpsCoordinates> get positionStream => _controller.stream;

  GpsService() {
    _init();
  }

  Future<void> _init() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    // Start streaming positions
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      _controller.add(
        GpsCoordinates(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          timestamp: position.timestamp,
        ),
      );
    });
  }

  String toPhonetic(double coord) {
    return coord
        .toString()
        .replaceAll('.', ' point ')
        .split('')
        .join(' ')
        .replaceAll('  ', ' ');
  }

  Future<GpsCoordinates> getCurrentLocation() async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return GpsCoordinates(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      timestamp: position.timestamp,
    );
  }
}
