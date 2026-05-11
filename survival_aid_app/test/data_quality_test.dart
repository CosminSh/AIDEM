import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Protocol data quality', () {
    final protocolFile = File('assets/data/protocol.json');

    test('every protocol node has a source citation', () {
      final protocol =
          jsonDecode(protocolFile.readAsStringSync()) as Map<String, dynamic>;
      final nodes = protocol['nodes'] as Map<String, dynamic>;

      final missingSources = <String>[];
      for (final entry in nodes.entries) {
        final node = entry.value as Map<String, dynamic>;
        final source = node['source']?.toString().trim() ?? '';
        if (source.isEmpty) {
          missingSources.add(entry.key);
        }
      }

      expect(missingSources, isEmpty);
    });

    test('all branch targets resolve to existing nodes or terminal end', () {
      final protocol =
          jsonDecode(protocolFile.readAsStringSync()) as Map<String, dynamic>;
      final nodes = protocol['nodes'] as Map<String, dynamic>;
      final nodeIds = nodes.keys.toSet();
      final missingTargets = <String>[];

      for (final entry in nodes.entries) {
        final node = entry.value as Map<String, dynamic>;
        final branches = node['branches'] as List<dynamic>? ?? [];
        for (final branch in branches) {
          final target = (branch as Map<String, dynamic>)['target'] as String;
          if (target != 'end' && !nodeIds.contains(target)) {
            missingTargets.add('${entry.key} -> $target');
          }
        }
      }

      expect(missingTargets, isEmpty);
    });
  });

  group('Emergency number data quality', () {
    test('database contains expected entries for at least 10 countries', () {
      final numbers =
          jsonDecode(
                File('assets/data/emergency_numbers.json').readAsStringSync(),
              )
              as Map<String, dynamic>;

      const expectedCountries = [
        'United States',
        'Canada',
        'United Kingdom',
        'Romania',
        'France',
        'Germany',
        'Spain',
        'Italy',
        'Japan',
        'Australia',
      ];

      for (final country in expectedCountries) {
        expect(
          numbers[country]?.toString().trim(),
          isNot(isEmpty),
          reason: '$country should have an emergency number entry',
        );
      }
    });
  });
}
