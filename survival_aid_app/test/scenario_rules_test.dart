import 'package:flutter_test/flutter_test.dart';
import 'package:aidem_app/services/llm_service.dart';

void main() {
  group('Emergency Scenario Detection', () {
    test('Tier 1: Spinal injury keywords trigger critical response', () {
      final response = AdaptiveMock.respond(
        userMessage: 'my friend fell on his mtb and hit his back, lower back hurts',
        situationContext: '',
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(
        contains('don'),
        contains('stay still'),
        contains('call'),
        contains('911'),
        contains('112'),
      ));
    });

    test('Tier 1: Unconscious triggers emergency protocol', () {
      final response = AdaptiveMock.respond(
        userMessage: 'He is unconscious and not breathing',
        situationContext: '',
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(
        contains('cpr'),
        contains('breathing'),
        contains('call'),
        contains('911'),
        contains('112'),
      ));
    });

    test('Tier 3: Minor wound gets self-management advice', () {
      final response = AdaptiveMock.respond(
        userMessage: 'my son fell and scraped his knee, it bleeds a bit',
        situationContext: '',
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(
        contains('clean'),
        contains('water'),
        contains('bandage'),
        contains('elevate'),
      ));
    });

    test('Tier 2: Fracture suspicion gives immobilization advice', () {
      final response = AdaptiveMock.respond(
        userMessage: 'I think my wrist is broken after the fall',
        situationContext: '',
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(
        contains('splint'),
        contains('immobilize'),
        contains('support'),
        contains('ice'),
        contains('elevate'),
      ));
    });
  });

  group('Response Format Rules', () {
    test('No robotic labels in responses', () {
      final scenarios = ['bleeding', 'no signal', 'unconscious', 'lost'];

      for (final scenario in scenarios) {
        final response = AdaptiveMock.respond(
          userMessage: scenario,
          situationContext: '',
          historyCount: 0,
        );

        expect(response, isNot(contains('Location')));
        expect(response, isNot(contains('Status')));
        expect(response, isNot(contains('Priority')));
        expect(response, isNot(contains('Tier')));
      }
    });

    test('Responses are natural prose without bullet points', () {
      final response = AdaptiveMock.respond(
        userMessage: 'no bandage for my cut',
        situationContext: 'wound',
        historyCount: 0,
      );

      expect(response, isNot(contains(':')));
      expect(response, isNot(contains('-')));
      expect(response, isNot(contains('*')));
      expect(response, isNot(contains(' 1')));
      expect(response, isNot(contains(' 2')));
      expect(response, isNot(contains(' 3')));
    });
  });

  group('Information Gathering Behavior', () {
    test('First message gets context-gathering response when not critical', () {
      final response = AdaptiveMock.respond(
        userMessage: 'I was hiking and got a scratch',
        situationContext: '',
        historyCount: 0,
      );

      expect(response.toLowerCase(), isNot(contains('911')));
      expect(response.toLowerCase(), isNot(contains('call')));
    });

    test('Age context in message does not get parroted back', () {
      final response = AdaptiveMock.respond(
        userMessage: 'my 4 year old son fell and hurt his knee',
        situationContext: 'child injury',
        historyCount: 2,
      );

      final lower = response.toLowerCase();
      expect(lower, isNot(contains('4 year old')));
      expect(lower, isNot(contains('four year old')));
      expect(lower, isNot(contains('son fell')));
    });
  });
}