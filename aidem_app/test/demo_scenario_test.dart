import 'package:aidem_app/models/demo_scenario.dart';
import 'package:aidem_app/models/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Practice/demo scenarios', () {
    test('all curated scenarios are clearly labeled as demo mode', () {
      expect(demoScenarios, hasLength(greaterThanOrEqualTo(4)));

      for (final scenario in demoScenarios) {
        final messages = scenario.toChatMessages();

        expect(messages, isNotEmpty);
        expect(messages.first.author, MessageAuthor.ai);
        expect(messages.first.text, contains('[DEMO MODE]'));
        expect(
          messages.map((message) => message.text).join('\n').toLowerCase(),
          isNot(contains('real emergency active')),
        );
      }
    });

    test('demo scenarios do not require GPS before opening', () {
      for (final scenario in demoScenarios) {
        expect(scenario.situationSummary, isNot(contains('GPS:')));
        expect(scenario.tags, isNot(contains('Live GPS')));
      }
    });

    test('runner self-evacuation demo has a complete safe arc', () {
      final scenario = demoScenarios.firstWhere(
        (scenario) => scenario.id == 'runner_knee_self_evac',
      );
      final script = scenario.turns.map((turn) => turn.text).join('\n');

      expect(scenario.currentNodeId, 'evacuation_triage');
      expect(script, contains('no signal'));
      expect(script, contains('cleanest fabric'));
      expect(script, contains('Do not scrub'));
      expect(script, contains('A cautious self-evacuation is reasonable'));
      expect(script, contains('turn on battery saver'));
      expect(script, contains('clean the wound properly when you get home'));
    });
  });
}
