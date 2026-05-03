import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/protocol.dart';

class PersistedSession {
  final List<ChatMessage> chatHistory;
  final String? currentNodeId;
  final bool isEmergencyActive;
  final bool isPracticeMode;
  final String situationSummary;

  PersistedSession({
    required this.chatHistory,
    this.currentNodeId,
    required this.isEmergencyActive,
    required this.isPracticeMode,
    required this.situationSummary,
  });

  Map<String, dynamic> toJson() => {
        'chat_history': chatHistory.map((m) => m.toJson()).toList(),
        'current_node_id': currentNodeId,
        'is_emergency_active': isEmergencyActive,
        'is_practice_mode': isPracticeMode,
        'situation_summary': situationSummary,
      };

  factory PersistedSession.fromJson(Map<String, dynamic> json) => PersistedSession(
        chatHistory: (json['chat_history'] as List<dynamic>)
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList(),
        currentNodeId: json['current_node_id'] as String?,
        isEmergencyActive: json['is_emergency_active'] as bool,
        isPracticeMode: json['is_practice_mode'] as bool,
        situationSummary: json['situation_summary'] as String,
      );
}

class SessionPersistenceService {
  static const String _filename = 'active_session.json';

  Future<void> saveSession(PersistedSession session) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_filename');
      await file.writeAsString(jsonEncode(session.toJson()));
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  Future<PersistedSession?> loadSession() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_filename');
      if (await file.exists()) {
        final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        return PersistedSession.fromJson(json);
      }
    } catch (e) {
      print('Error loading session: $e');
    }
    return null;
  }

  Future<void> clearSession() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_filename');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error clearing session: $e');
    }
  }
}
