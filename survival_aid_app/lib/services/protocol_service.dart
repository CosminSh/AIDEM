import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/protocol.dart';

class ProtocolService {
  Map<String, ProtocolNode> _nodes = {};
  Map<String, String> _knowledgeBase = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadProtocol() async {
    if (_isLoaded) return;

    try {
      // Load protocol tree
      final String jsonString = await rootBundle.loadString('assets/data/protocol.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic> nodesJson = jsonData['nodes'];

      _nodes = nodesJson.map((key, value) => MapEntry(
            key,
            ProtocolNode.fromJson(value as Map<String, dynamic>),
          ));

      // Load knowledge base
      final String kbString = await rootBundle.loadString('assets/data/knowledge_base.json');
      final Map<String, dynamic> kbData = json.decode(kbString);
      _knowledgeBase = kbData.map((k, v) => MapEntry(k, v.toString()));

      _isLoaded = true;
    } catch (e) {
      print('Error loading protocol: $e');
      rethrow;
    }
  }

  ProtocolNode? getNode(String id) => _nodes[id];

  ProtocolNode get startNode => _nodes['start']!;

  /// Returns relevant documentation for the current protocol node.
  /// Walks up related nodes to gather context (e.g. bleeding_protocol
  /// also returns injury_assessment context).
  String getDocumentationForNode(String nodeId) {
    final buffer = StringBuffer();

    // Primary match
    if (_knowledgeBase.containsKey(nodeId)) {
      buffer.writeln(_knowledgeBase[nodeId]);
    }

    // Related protocol context
    final related = _relatedNodes[nodeId] ?? [];
    for (final relId in related) {
      if (_knowledgeBase.containsKey(relId)) {
        buffer.writeln();
        buffer.writeln(_knowledgeBase[relId]);
      }
    }

    return buffer.toString().trim();
  }

  /// Maps each node to related nodes whose documentation is also relevant.
  static const Map<String, List<String>> _relatedNodes = {
    'bleeding_protocol': ['injury_assessment'],
    'apply_tourniquet': ['bleeding_protocol'],
    'pressure_dressing': ['bleeding_protocol'],
    'lost_protocol': ['signaling_protocol', 'shelter_protocol'],
    'signaling_protocol': ['lost_protocol', 'signal_ground_to_air'],
    'anaphylaxis_protocol': ['triage_selection'],
    'snake_bite_protocol': ['triage_selection'],
    'heat_stroke': ['heat_protocol'],
    'hypothermia_protocol': ['shelter_protocol'],
    'concussion_protocol': ['spinal_protocol'],
    'rescue_call': ['signaling_protocol'],
  };
}
