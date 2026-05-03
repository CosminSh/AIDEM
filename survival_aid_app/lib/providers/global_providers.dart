import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_provider.dart';
import '../services/protocol_service.dart';
import '../services/gps_service.dart';
import '../services/emergency_number_service.dart';
import '../services/session_log_service.dart';
import '../services/llm_service.dart';
import '../services/context_compaction_service.dart';
import '../services/model_setup_service.dart';
import '../services/session_persistence_service.dart';

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
  return LlmService();
});

final contextCompactionServiceProvider = Provider<ContextCompactionService>((ref) {
  return ContextCompactionService();
});

final modelSetupServiceProvider = NotifierProvider<ModelSetupService, ModelSetupState>(() {
  return ModelSetupService();
});

final sessionPersistenceServiceProvider = Provider<SessionPersistenceService>((ref) {
  return SessionPersistenceService();
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
  return 'US';
});

final emergencyNumberProvider = FutureProvider<String>((ref) async {
  final country = await ref.watch(countryProvider.future);
  final emergencyService = ref.watch(emergencyNumberServiceProvider);
  return emergencyService.getNumberForCountry(country);
});
