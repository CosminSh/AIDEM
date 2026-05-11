import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/protocol.dart';
import 'gps_service.dart';

class PersistedSession {
  final String id;
  final List<ChatMessage> chatHistory;
  final String? currentNodeId;
  final bool isEmergencyActive;
  final bool isPracticeMode;
  final String situationSummary;
  final List<GpsCoordinates> locationHistory;
  final DateTime lastUpdated;

  PersistedSession({
    required this.id,
    required this.chatHistory,
    this.currentNodeId,
    required this.isEmergencyActive,
    required this.isPracticeMode,
    required this.situationSummary,
    this.locationHistory = const [],
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'chat_history': chatHistory.map((m) => m.toJson()).toList(),
    'current_node_id': currentNodeId,
    'is_emergency_active': isEmergencyActive,
    'is_practice_mode': isPracticeMode,
    'situation_summary': situationSummary,
    'location_history': locationHistory.map((fix) => fix.toJson()).toList(),
    'last_updated': lastUpdated.toIso8601String(),
  };

  factory PersistedSession.fromJson(Map<String, dynamic> json) =>
      PersistedSession(
        id: json['id'] as String,
        chatHistory: (json['chat_history'] as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentNodeId: json['current_node_id'] as String?,
        isEmergencyActive: json['is_emergency_active'] as bool,
        isPracticeMode: json['is_practice_mode'] as bool,
        situationSummary: json['situation_summary'] as String,
        locationHistory: (json['location_history'] as List<dynamic>? ?? [])
            .map((e) => GpsCoordinates.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastUpdated: DateTime.parse(
          json['last_updated'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
}

class SessionPersistenceService {
  static const String _sessionDir = 'sessions';

  Future<Directory> _getDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final sessionDir = Directory('${docsDir.path}/$_sessionDir');
    if (!await sessionDir.exists()) {
      await sessionDir.create(recursive: true);
    }
    return sessionDir;
  }

  Future<void> saveSession(PersistedSession session) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/session_${session.id}.json');
      await file.writeAsString(jsonEncode(session.toJson()));
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  Future<PersistedSession?> loadSession(String id) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/session_$id.json');
      if (await file.exists()) {
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return PersistedSession.fromJson(json);
      }
    } catch (e) {
      print('Error loading session: $e');
    }
    return null;
  }

  Future<List<PersistedSession>> getAllSessions() async {
    try {
      final dir = await _getDir();
      final files = dir.listSync().whereType<File>().where(
        (f) => f.path.endsWith('.json'),
      );
      final sessions = <PersistedSession>[];
      for (final file in files) {
        try {
          final json =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          sessions.add(PersistedSession.fromJson(json));
        } catch (_) {}
      }
      // Sort by last updated (newest first)
      sessions.sort((a, b) => b.lastUpdated.compareTo(a.lastUpdated));
      return sessions;
    } catch (e) {
      print('Error listing sessions: $e');
      return [];
    }
  }

  Future<void> deleteSession(String id) async {
    try {
      final dir = await _getDir();
      final file = File('${dir.path}/session_$id.json');
      if (await file.exists()) {
        await file.delete();
      }

      // Also delete the associated context if it exists
      final contextFile = File(
        '${(await getApplicationDocumentsDirectory()).path}/context_$id.json',
      );
      if (await contextFile.exists()) {
        await contextFile.delete();
      }
    } catch (e) {
      print('Error deleting session: $e');
    }
  }
}
