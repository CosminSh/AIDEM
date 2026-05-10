import 'package:flutter_test/flutter_test.dart';
import 'package:aidem_app/services/context_compaction_service.dart';
import 'package:aidem_app/services/conversation_guard_service.dart';

void main() {
  group('ConversationGuard', () {
    test('detects extraction JSON that should never be shown in chat', () {
      expect(
        ConversationGuard.looksLikeExtractionJson(
          '{"summary":"Cut reported","incident_type":"cut"}',
        ),
        isTrue,
      );
    });

    test('detects repeated last questions', () {
      expect(
        ConversationGuard.repeatsLastQuestion(
          previousAiMessage:
              'Keep pressure on it. Is the bleeding still heavy?',
          response: 'Keep applying pressure. Is the bleeding still heavy?',
        ),
        isTrue,
      );
    });

    test('detects paraphrased repeated bleeding checks', () {
      expect(
        ConversationGuard.repeatsLastQuestion(
          previousAiMessage:
              'Keep firm pressure on the cut with a clean cloth for a few minutes. Tell me if the bleeding is soaking through the cloth or not slowing down.',
          response:
              'Keep firm pressure on the cut with a clean cloth. Is the wound still soaking through the cloth or not slowing down?',
        ),
        isTrue,
      );
    });

    test('cut fallback moves forward when bleeding is not heavy', () {
      final ctx = SituationContext.empty().copyWith(
        incidentType: 'cut',
        injuryType: 'finger cut',
        answeredFacts: [
          'Cut is on a finger.',
          'Cut is bleeding.',
          'Bleeding is not heavy.',
        ],
      );

      final response = ConversationGuard.fallbackResponseForContext(
        ctx,
      ).toLowerCase();

      expect(response, contains('not sound like heavy bleeding'));
      expect(response, contains('gentle pressure'));
      expect(response, contains('when it stops'));
      expect(response, contains('deep'));
      expect(response, contains('gaping'));
      expect(response, contains('dirty'));
      expect(response, contains('numb'));
    });

    test('cut fallback asks wound-detail check after bleeding stops', () {
      final ctx = SituationContext.empty().copyWith(
        incidentType: 'cut',
        injuryType: 'finger cut',
        answeredFacts: ['Cut is on a finger.', 'Bleeding has stopped.'],
      );

      final response = ConversationGuard.fallbackResponseForContext(
        ctx,
      ).toLowerCase();

      expect(response, contains('bleeding has stopped'));
      expect(response, contains('rinse'));
      expect(response, contains('clean'));
      expect(response, contains('bandage'));
      expect(response, contains('deep'));
      expect(response, contains('gaping'));
      expect(response, contains('numb'));
    });

    test('injury fallback asks for movement details and suggests photo', () {
      final ctx = SituationContext.empty().copyWith(
        incidentType: 'injury',
        injuryType: 'ankle injury',
        answeredFacts: ['Swelling is present.', 'Movement is possible.'],
      );

      final response = ConversationGuard.fallbackResponseForContext(
        ctx,
      ).toLowerCase();

      expect(response, contains('cold pack'));
      expect(response, contains('photo'));
      expect(response, contains('put weight'));
      expect(response, contains('sharp pain'));
    });

    test('allergic fallback prioritizes epinephrine and emergency help', () {
      final ctx = SituationContext.empty().copyWith(
        incidentType: 'allergic reaction',
        answeredFacts: ['Allergic reaction warning sign reported.'],
      );

      final response = ConversationGuard.fallbackResponseForContext(
        ctx,
      ).toLowerCase();

      expect(response, contains('epinephrine'));
      expect(response, contains('emergency'));
      expect(response, contains('epipen'));
    });

    test('poisoning fallback asks substance amount and timing', () {
      final ctx = SituationContext.empty().copyWith(
        incidentType: 'poisoning',
        answeredFacts: ['Chemical exposure reported.'],
      );

      final response = ConversationGuard.fallbackResponseForContext(
        ctx,
      ).toLowerCase();

      expect(response, contains('do not make'));
      expect(response, contains('substance'));
      expect(response, contains('how much'));
      expect(response, contains('when'));
    });
  });
}
