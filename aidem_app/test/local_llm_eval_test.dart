import 'dart:io';

import 'package:aidem_app/providers/global_providers.dart';
import 'package:aidem_app/services/context_compaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final runLocalLlm = Platform.environment['AIDEM_RUN_LOCAL_LLM_EVAL'] == '1';

  test(
    'local Gemma handles mixed radiation exposure with app prompt context',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final llm = container.read(llmServiceProvider.notifier);
      final ready = await llm.init();
      if (!ready) {
        markTestSkipped(
          'Local Gemma model is not installed in this test environment.',
        );
        return;
      }

      final context = ContextCompactionService();
      await context.init(null);
      const userMessage =
          'I touched fine glowing dust from an old radiology department, now my finger has blisters and I am throwing up.';
      context.noteUserMessage(userMessage);

      final response = StringBuffer();
      await for (final token in llm.generateResponseStream(
        userMessage: userMessage,
        situationContext: context.getPromptContext(
          currentUserMessage: userMessage,
        ),
        knowledgeBase:
            'Radiation contamination: move away, avoid spreading dust, remove contaminated outer clothing if safe, bag it, wash exposed skin gently with soap and water, call emergency services or hazmat/poison control.',
        recentHistory: const [],
      )) {
        response.write(token);
      }

      final lower = response.toString().toLowerCase();
      expect(lower, contains('move away'));
      expect(lower, anyOf(contains('hazmat'), contains('emergency')));
      expect(lower, contains('wash'));
      expect(lower, isNot(contains('stop throwing up')));
    },
    skip: runLocalLlm
        ? false
        : 'Set AIDEM_RUN_LOCAL_LLM_EVAL=1 to run against the installed local Gemma model.',
  );
}
