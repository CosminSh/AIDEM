import 'gps_service.dart';

class RescueScriptService {
  final GpsService _gpsService = GpsService();

  /// Generates a full script for the user to read to emergency services.
  String generateScript({
    required GpsCoordinates coords,
    required String emergencyNumber,
  }) {
    final latPhonetic = _gpsService.toPhonetic(coords.latitude);
    final lonPhonetic = _gpsService.toPhonetic(coords.longitude);
    final dms = coords.toDms();

    return '''
EMERGENCY SCRIPT:
"I have an emergency and require assistance. 
My current location is:
LATITUDE: $latPhonetic
LONGITUDE: $lonPhonetic

(In Degrees/Minutes/Seconds: $dms)

I am calling from a remote area. Please send help to these coordinates."
''';
  }

  /// Generates a simplified script for quick reporting.
  String generateQuickScript(GpsCoordinates coords) {
    return "Emergency: Lat ${_gpsService.toPhonetic(coords.latitude)}, Lon ${_gpsService.toPhonetic(coords.longitude)}";
  }
}
