import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_provider.dart';
import '../services/protocol_service.dart';
import '../services/gps_service.dart';
import '../services/emergency_number_service.dart';
import '../services/session_log_service.dart';
import '../services/llm_service.dart';

// --- Services ---

final protocolServiceProvider = Provider<ProtocolService>((ref) {
  return ProtocolService();
});

final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService();
});

final emergencyNumberServiceProvider = Provider<EmergencyNumberService>((ref) {
  return EmergencyNumberService();
});

final sessionLogServiceProvider = Provider<SessionLogService>((ref) {
  final service = SessionLogService();
  service.initDb();
  return service;
});

final llmServiceProvider = Provider<LlmService>((ref) {
  final service = LlmService();
  service.init();
  return service;
});

// --- State Management ---

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(() {
  return SessionNotifier();
});

// --- Streams & Futures ---

final gpsStreamProvider = StreamProvider<GpsCoordinates>((ref) {
  final gpsService = ref.watch(gpsServiceProvider);
  return gpsService.positionStream;
});

final countryProvider = FutureProvider<String>((ref) async {
  // In a real app, this would use reverse geocoding on the GPS coordinates
  // For offline capabilities, a local bounding-box database could be used
  // Stubbing to a default country for now.
  return 'US';
});

final emergencyNumberProvider = FutureProvider<String>((ref) async {
  final country = await ref.watch(countryProvider.future);
  final emergencyService = ref.watch(emergencyNumberServiceProvider);
  return emergencyService.getNumberForCountry(country);
});
