import 'package:flutter_test/flutter_test.dart';
import 'package:survival_aid_app/services/llm_service.dart';

void main() {
  group('AdaptiveMock Response Quality Tests', () {
    test('Bleeding without bandage gives improvisation advice', () {
      final response = AdaptiveMock.respond(
        userMessage: "I have a wound but no bandage",
        situationContext: "bleeding",
        historyCount: 0,
      );

      expect(response.toLowerCase(), anyOf(contains('improvise'), contains('shirt'), contains('cloth')));
    });

    test('No signal gives elevation and SMS advice', () {
      final response = AdaptiveMock.respond(
        userMessage: "I have no signal here",
        situationContext: "",
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(contains('signal'), contains('higher'), contains('sms'), contains('text')));
    });

    test('Unconscious triggers breathing/CPR instructions', () {
      final response = AdaptiveMock.respond(
        userMessage: "He is unconscious and not waking up",
        situationContext: "",
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(contains('breathing'), contains('cpr'), contains('compressions')));
    });

    test('Alone scenario gives stay put advice', () {
      final response = AdaptiveMock.respond(
        userMessage: "I am alone in the forest",
        situationContext: "",
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(contains('alone'), contains('stay'), contains('control'), contains('visible')));
    });

    test('No parroting - does not repeat user message', () {
      final response = AdaptiveMock.respond(
        userMessage: "my son fell",
        situationContext: "child fell on knee",
        historyCount: 2,
      );

      final lower = response.toLowerCase();
      expect(lower, isNot(contains('my son fell')));
      expect(lower, isNot(contains('child fell')));
    });

    test('No headers or bullet points in response', () {
      final response = AdaptiveMock.respond(
        userMessage: "bleeding",
        situationContext: "",
        historyCount: 0,
      );

      expect(response, isNot(contains(':')));
      expect(response, isNot(contains('-')));
      expect(response, isNot(contains('*')));
    });

    test('Lost scenario after history gives STAY PUT rule', () {
      final response = AdaptiveMock.respond(
        userMessage: "I am lost in the forest",
        situationContext: "",
        historyCount: 3,
      );

      final lower = response.toLowerCase();
      expect(lower, contains('stay'));
    });

    test('No water for wound gives alternative cleaning advice', () {
      final response = AdaptiveMock.respond(
        userMessage: "I have a cut but no water",
        situationContext: "wound",
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(contains('liquid'), contains('sports drink'), contains('urine'), contains('flush')));
    });

    test('No tourniquet for bleed gives field tourniquet instructions', () {
      final response = AdaptiveMock.respond(
        userMessage: "bleeding heavily, no tourniquet",
        situationContext: "bleed",
        historyCount: 0,
      );

      final lower = response.toLowerCase();
      expect(lower, anyOf(contains('tourniquet'), contains('stick'), contains('twist'), contains('strip')));
    });
  });

  group('Response Context Awareness', () {
    test('Lost message with 0 history gives generic advice', () {
      final response = AdaptiveMock.respond(
        userMessage: "I am lost",
        situationContext: "",
        historyCount: 0,
      );

      expect(response.toLowerCase(), isNot(contains('stay where you are')));
    });

    test('Lost message after 3+ exchanges gives STAY PUT rule', () {
      final response = AdaptiveMock.respond(
        userMessage: "I am lost in the forest",
        situationContext: "",
        historyCount: 5,
      );

      final lower = response.toLowerCase();
      expect(lower, contains('stay'));
    });
  });
}