import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Protocol data quality', () {
    final protocolFile = File('assets/data/protocol.json');

    test('protocol file does not contain duplicate node ids', () {
      final protocolText = protocolFile.readAsStringSync();
      final nodeIdPattern = RegExp(r'^    "([^"]+)": \{', multiLine: true);
      final seen = <String>{};
      final duplicateIds = <String>[];

      for (final match in nodeIdPattern.allMatches(protocolText)) {
        final nodeId = match.group(1)!;
        if (!seen.add(nodeId)) {
          duplicateIds.add(nodeId);
        }
      }

      expect(duplicateIds, isEmpty);
    });

    test('protocol has broad emergency coverage', () {
      final protocol =
          jsonDecode(protocolFile.readAsStringSync()) as Map<String, dynamic>;
      final nodes = protocol['nodes'] as Map<String, dynamic>;

      expect(nodes.length, greaterThanOrEqualTo(150));
    });

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

    test('branch labels are unique within each protocol node', () {
      final protocol =
          jsonDecode(protocolFile.readAsStringSync()) as Map<String, dynamic>;
      final nodes = protocol['nodes'] as Map<String, dynamic>;
      final duplicateLabels = <String>[];

      for (final entry in nodes.entries) {
        final node = entry.value as Map<String, dynamic>;
        final branches = node['branches'] as List<dynamic>? ?? [];
        final seen = <String>{};
        for (final branch in branches) {
          final label = ((branch as Map<String, dynamic>)['label'] as String)
              .trim();
          if (!seen.add(label)) {
            duplicateLabels.add('${entry.key}: $label');
          }
        }
      }

      expect(duplicateLabels, isEmpty);
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

    test('expanded resilience and health protocols have knowledge entries', () {
      final protocol =
          jsonDecode(protocolFile.readAsStringSync()) as Map<String, dynamic>;
      final nodes = protocol['nodes'] as Map<String, dynamic>;
      final knowledge =
          jsonDecode(File('assets/data/knowledge_base.json').readAsStringSync())
              as Map<String, dynamic>;

      const expectedProtocolIds = [
        'stroke_protocol',
        'stroke_fast_check',
        'asthma_breathing_protocol',
        'asthma_inhaler_steps',
        'opioid_overdose_protocol',
        'naloxone_steps',
        'pregnancy_labor_protocol',
        'imminent_birth_steps',
        'newborn_immediate_care',
        'mental_health_crisis_protocol',
        'mental_health_stabilize',
        'mass_casualty_triage',
        'power_outage_protocol',
        'power_medical_device_plan',
        'gas_co_triage',
        'carbon_monoxide_protocol',
        'gas_leak_protocol',
        'chemical_spill_protocol',
        'infectious_disease_protocol',
        'infection_control_steps',
      ];

      for (final id in expectedProtocolIds) {
        expect(nodes.containsKey(id), isTrue, reason: '$id node missing');
        expect(
          knowledge[id]?.toString().trim(),
          isNot(isEmpty),
          reason: '$id knowledge entry missing',
        );
      }
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
