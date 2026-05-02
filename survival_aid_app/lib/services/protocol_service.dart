import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/protocol.dart';

class ProtocolService {
  Map<String, ProtocolNode> _nodes = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the protocol from the JSON asset.
  Future<void> loadProtocol() async {
    if (_isLoaded) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/data/protocol.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final Map<String, dynamic> nodesJson = jsonData['nodes'];

      _nodes = nodesJson.map((key, value) => MapEntry(
            key,
            ProtocolNode.fromJson(value as Map<String, dynamic>),
          ));

      _isLoaded = true;
    } catch (e) {
      print('Error loading protocol: $e');
      rethrow;
    }
  }

  /// Gets a specific node by its ID.
  ProtocolNode? getNode(String id) {
    return _nodes[id];
  }

  /// Gets the starting node.
  ProtocolNode get startNode => _nodes['start']!;
}
