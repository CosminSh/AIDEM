import 'package:flutter_test/flutter_test.dart';
import 'package:aidem_app/models/protocol.dart';
import 'package:aidem_app/services/context_compaction_service.dart';

void main() {
  group('ContextCompactionService flow memory', () {
    test(
      'burn observations become answered facts, not completed care steps',
      () async {
        final service = ContextCompactionService();
        await service.init(null);

        service.noteUserMessage('i burned my finger while cooking');
        service.noteUserMessage(
          'i think it is first degree',
          previousAiMessage:
              'Assess the burn severity: Is it first, second, or third degree?',
        );
        service.noteUserMessage(
          "it's red, no blisters",
          previousAiMessage:
              'Check for blanching. If the skin turns white or charred, it is third degree.',
        );

        final ctx = service.context;
        final facts = ctx.answeredFacts.join(' ').toLowerCase();
        final steps = ctx.completedSteps.join(' ').toLowerCase();

        expect(ctx.incidentType, 'burn');
        expect(ctx.injuryType, 'finger burn');
        expect(facts, contains('no blisters'));
        expect(facts, contains('red'));
        expect(steps, isNot(contains('assess')));
        expect(steps, isNot(contains('blanching')));

        final prompt = service.getPromptContext(
          currentUserMessage: "it's red, no blisters",
        );
        expect(prompt, contains('KNOWN FACTS / ANSWERED ALREADY'));
        expect(prompt.toLowerCase(), contains('no blisters'));
      },
    );

    test(
      'asking what comes next does not mark previous burn advice done',
      () async {
        final service = ContextCompactionService();
        await service.init(null);

        await service.addExchange(
          userMessage: ChatMessage(
            text: "i burned my finger and it's red, no blisters",
            author: MessageAuthor.user,
            timestamp: DateTime.now(),
          ),
          aiResponse: ChatMessage(
            text:
                'Apply cool, running water to the burn for 10-20 minutes. Cover loosely with a clean, dry dressing.',
            author: MessageAuthor.ai,
            timestamp: DateTime.now(),
          ),
        );
        await service.addExchange(
          userMessage: ChatMessage(
            text: 'and after that?',
            author: MessageAuthor.user,
            timestamp: DateTime.now(),
          ),
          aiResponse: ChatMessage(
            text: 'Check for blistering.',
            author: MessageAuthor.ai,
            timestamp: DateTime.now(),
          ),
        );

        final steps = service.context.completedSteps.join(' ').toLowerCase();
        expect(steps, isNot(contains('cooled the burn')));
        expect(steps, isNot(contains('covered the burn')));
      },
    );

    test(
      'confirmed cooling and dressing are remembered as completed care',
      () async {
        final service = ContextCompactionService();
        await service.init(null);

        service.noteUserMessage('i burned my finger');
        service.noteUserMessage(
          'yes, i cooled it under running water for 15 minutes and covered it',
          previousAiMessage:
              'Apply cool, running water to the burn for 10-20 minutes. Cover loosely with a clean, dry dressing.',
        );

        final steps = service.context.completedSteps.join(' ').toLowerCase();
        expect(steps, contains('cooled the burn'));
        expect(steps, contains('covered the burn'));
      },
    );

    test('either-or pain answers are remembered as facts', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage('i burned my finger while cooking');
      service.noteUserMessage(
        'dull pain',
        previousAiMessage: 'Does the pain feel sharp or dull?',
      );

      final facts = service.context.answeredFacts.join(' ').toLowerCase();
      final steps = service.context.completedSteps.join(' ').toLowerCase();

      expect(facts, contains('dull pain'));
      expect(steps, isNot(contains('dull pain')));
    });

    test('finger cut bleeding answers advance context', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage('i cut my finger while cooking');
      service.noteUserMessage(
        "it's bleeding",
        previousAiMessage:
            'Stop what you are doing and look at the cut. Tell me what you see and if there is any bleeding.',
      );
      service.noteUserMessage(
        'No',
        previousAiMessage:
            'Apply direct, firm pressure to the cut with a clean cloth. Keep pressure on it for a few minutes. Is the bleeding still heavy?',
      );
      service.noteUserMessage(
        'the bleeding almost stopped',
        previousAiMessage:
            'Cover the cut with a clean cloth and keep gentle pressure on it. Does the bleeding start to slow down again?',
      );
      service.noteUserMessage(
        "it's not bleeding anymore. what now?",
        previousAiMessage:
            'Cover the cut with a clean cloth and keep gentle pressure on it. Does the bleeding start to slow down again?',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();

      expect(ctx.incidentType, 'cut');
      expect(ctx.injuryType, 'finger cut');
      expect(ctx.summary.toLowerCase(), contains('bleeding has stopped'));
      expect(ctx.urgencyLevel, 'minor');
      expect(facts, contains('cut is bleeding'));
      expect(facts, contains('bleeding is not heavy'));
      expect(facts, contains('bleeding is almost stopped'));
      expect(facts, contains('bleeding has stopped'));
    });

    test('minor bleeding language is remembered instead of re-asked', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage('i cut my finger while cooking');
      service.noteUserMessage(
        "it's not bleeding that bad",
        previousAiMessage:
            'Apply direct pressure to the cut with a clean cloth and keep it firm for a few minutes. Is the bleeding still heavy?',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();
      final prompt = service.getPromptContext(
        lastAiMessage:
            'Apply direct pressure to the cut with a clean cloth and keep it firm for a few minutes. Is the bleeding still heavy?',
        currentUserMessage: "it's not bleeding that bad",
      );

      expect(ctx.incidentType, 'cut');
      expect(ctx.urgencyLevel, 'minor');
      expect(facts, contains('bleeding is not heavy'));
      expect(prompt.toLowerCase(), contains('do not ask again'));
      expect(prompt.toLowerCase(), contains('bleeding is not heavy'));
    });

    test('fall injury answers become reusable facts', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage('i fell and twisted my ankle');
      service.noteUserMessage(
        'it is swollen but i can move it',
        previousAiMessage:
            'Look at the ankle. Is it swollen, crooked, numb, or hard to move?',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();
      final prompt = service.getPromptContext(
        currentUserMessage: 'it is swollen but i can move it',
      );

      expect(ctx.incidentType, 'injury');
      expect(ctx.injuryType, 'ankle injury');
      expect(facts, contains('swelling is present'));
      expect(facts, contains('movement is possible'));
      expect(prompt.toLowerCase(), contains('swelling is present'));
      expect(prompt.toLowerCase(), contains('movement is possible'));
    });

    test('allergic reaction warning signs are promoted', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage('a bee stung me and now i have a rash');
      service.noteUserMessage(
        'my lips are swelling',
        previousAiMessage:
            'Watch for trouble breathing or swelling of the lips, tongue, face, or throat.',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();

      expect(ctx.incidentType, 'allergic reaction');
      expect(ctx.urgencyLevel, 'critical');
      expect(facts, contains('rash'));
      expect(facts, contains('allergic reaction warning sign'));
    });

    test('poisoning details are remembered without marking care done', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage('my kid swallowed cleaner');
      service.noteUserMessage(
        'he is vomiting but awake',
        previousAiMessage:
            'Do not make him vomit. Tell me what substance it was, how much, and when it happened.',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();
      final steps = ctx.completedSteps.join(' ').toLowerCase();

      expect(ctx.incidentType, 'poisoning');
      expect(facts, contains('chemical exposure'));
      expect(facts, contains('vomiting or nausea'));
      expect(steps, isNot(contains('vomit')));
    });

    test('hand cut transcript details prevent repeated bleeding checks', () async {
      final service = ContextCompactionService();
      await service.init(null);

      service.noteUserMessage('i cut my hand while cooking');
      service.noteUserMessage(
        'its on the side of my finder, 1 cm long, somehow deesp, bleeds fairly bad',
        previousAiMessage:
            'Tell me what you can see about the cut, and how much blood is coming out.',
      );
      service.noteUserMessage(
        'bright red',
        previousAiMessage:
            'Apply firm, direct pressure to the wound with a clean cloth to try and slow the bleeding. Is the blood bright red or dark red?',
      );
      service.noteUserMessage(
        'steady flow',
        previousAiMessage:
            'Keep applying firm, direct pressure to the wound with a clean cloth. Is the bleeding still spurting or is it just a steady flow?',
      );
      service.noteUserMessage(
        'is slowing',
        previousAiMessage:
            'Keep firm pressure on the cut with a clean cloth for a few minutes. Tell me if the bleeding is soaking through the cloth or not slowing down.',
      );
      service.noteUserMessage(
        'the bleeding seems to stop',
        previousAiMessage:
            'Keep firm pressure on the cut with a clean cloth. Is the bleeding soaking through the cloth or not slowing down?',
      );

      final ctx = service.context;
      final facts = ctx.answeredFacts.join(' ').toLowerCase();

      expect(ctx.incidentType, 'cut');
      expect(ctx.injuryType, 'finger cut');
      expect(ctx.urgencyLevel, 'minor');
      expect(facts, contains('cut is on a finger'));
      expect(facts, contains('1 cm'));
      expect(facts, contains('deep'));
      expect(facts, contains('fairly heavy'));
      expect(facts, contains('bright red'));
      expect(facts, contains('steady flow'));
      expect(facts, contains('bleeding is almost stopped'));
      expect(facts, contains('bleeding has stopped'));
    });
  });
}
