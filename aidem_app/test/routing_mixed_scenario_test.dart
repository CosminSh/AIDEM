import 'package:aidem_app/providers/session_provider.dart';
import 'package:aidem_app/services/context_compaction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mixed scenario protocol routing', () {
    const cases = [
      (
        name: 'radiology dust beats finger blisters and vomiting',
        message:
            'I touched glowing dust in an old radiology department, my finger has blisters and I am throwing up.',
        incident: 'radiation exposure',
        summary: '',
        promptContext:
            'HAZARDS: Possible radioactive or hazardous contamination.',
        expected: 'radiation_decontamination',
      ),
      (
        name: 'CO alarm beats chest pain routing',
        message:
            'The CO alarm is going off near a generator indoors and now we have headache and chest pain.',
        incident: 'Unknown',
        summary: '',
        promptContext: '',
        expected: 'carbon_monoxide_protocol',
      ),
      (
        name: 'gas leak beats asthma symptom routing',
        message: 'There is a hissing gas leak and my asthma is wheezing badly.',
        incident: 'Unknown',
        summary: '',
        promptContext: '',
        expected: 'gas_leak_protocol',
      ),
      (
        name: 'chemical spill beats ordinary burn routing',
        message:
            'A chemical spill splashed on my hand and it is burning with blisters.',
        incident: 'Unknown',
        summary: '',
        promptContext: '',
        expected: 'chemical_spill_protocol',
      ),
      (
        name: 'stroke signs beat fall routing',
        message: 'He fell and now his face is drooping and speech is slurred.',
        incident: 'fall',
        summary: '',
        promptContext: '',
        expected: 'stroke_protocol',
      ),
      (
        name: 'anaphylaxis beats generic sting routing',
        message:
            'A bee stung her and now her lips are swelling and she is wheezing.',
        incident: 'allergic reaction',
        summary: '',
        promptContext: '',
        expected: 'anaphylaxis_protocol',
      ),
      (
        name: 'snake bite reaches snake protocol',
        message: 'A snake bit my ankle and it is swelling.',
        incident: 'bite',
        summary: '',
        promptContext: '',
        expected: 'snake_bite_protocol',
      ),
      (
        name: 'drowning reaches CPR protocol',
        message: 'He was pulled from water after drowning and has no pulse.',
        incident: 'breathing problem',
        summary: '',
        promptContext: '',
        expected: 'drowning_cpr_protocol',
      ),
      (
        name: 'controlled mobile trail injury still routes to evacuation',
        message: 'My knee stopped bleeding and I can walk on the trail.',
        incident: 'injury',
        summary: '',
        promptContext:
            'Environment is a forest trail. Bleeding has stopped. Can stand or bear weight.',
        expected: 'evacuation_triage',
      ),
    ];

    for (final scenario in cases) {
      test(scenario.name, () {
        expect(
          routeProtocolNodeIdForSituation(
            currentNodeId: 'start',
            incident: scenario.incident,
            summary: scenario.summary,
            userMessage: scenario.message,
            promptContext: scenario.promptContext,
          ),
          scenario.expected,
        );
      });
    }

    test(
      'does not retarget mid-protocol unless evacuation is newly needed',
      () {
        expect(
          routeProtocolNodeIdForSituation(
            currentNodeId: 'burn_protocol',
            incident: 'burn',
            summary: '',
            userMessage: 'it is red and painful',
            promptContext: '',
          ),
          'burn_protocol',
        );
      },
    );
  });

  group('Mixed scenario context extraction', () {
    test('CO alarm with chest pain remains toxic gas exposure', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage(
        'the co alarm is going off by a generator indoors and we have headache and chest pain',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();

      expect(ctx.incidentType, 'carbon monoxide exposure');
      expect(ctx.urgencyLevel, 'critical');
      expect(ctx.hazards.toLowerCase(), contains('carbon monoxide'));
      expect(facts, contains('carbon monoxide'));
      expect(facts, contains('danger sign'));
    });

    test('chemical spill with burn symptoms remains hazmat exposure', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage(
        'a chemical spill splashed on my hand and my skin is burning with blisters',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();

      expect(ctx.incidentType, 'chemical exposure');
      expect(ctx.injuryType, 'chemical or hazmat exposure');
      expect(ctx.urgencyLevel, 'critical');
      expect(ctx.hazards.toLowerCase(), contains('chemical'));
      expect(facts, contains('skin or eye symptoms'));
    });

    test('gas leak with asthma symptoms remains gas leak', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage(
        'there is a hissing gas leak and my asthma is wheezing badly',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();

      expect(ctx.incidentType, 'gas leak');
      expect(ctx.urgencyLevel, 'critical');
      expect(ctx.hazards.toLowerCase(), contains('gas leak'));
      expect(facts, contains('breathing symptoms'));
    });
  });
}
