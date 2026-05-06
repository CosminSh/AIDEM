import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:aidem_app/main.dart' as app;
import 'package:aidem_app/providers/global_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> runConversation(WidgetTester tester, List<String> messages) async {
    for (var msg in messages) {
      debugPrint('USER: $msg');
      final inputFinder = find.byKey(const ValueKey('chat_input'));
      await tester.enterText(inputFinder, msg);
      await tester.tap(find.byKey(const ValueKey('send_button')));
      await tester.pump();

      // Wait for AI to finish typing
      int timeout = 0;
      bool isTyping = true;
      while (isTyping && timeout < 120) { // 60 seconds max (0.5s * 120)
        await tester.pump(const Duration(milliseconds: 500));
        try {
          final context = tester.element(inputFinder);
          final container = ProviderScope.containerOf(context);
          isTyping = container.read(sessionProvider).isLlmTyping;
        } catch (e) {
          isTyping = false; // input might be gone if we navigated
        }
        timeout++;
      }

      final context = tester.element(inputFinder);
      final state = ProviderScope.containerOf(context).read(sessionProvider);
      if (state.chatHistory.isNotEmpty) {
        debugPrint('AI: ${state.chatHistory.last.text}');
      }
      debugPrint('---');
    }
  }

  group('Simulation Scenarios', () {
    testWidgets('Run All Scenarios', (tester) async {
      debugPrint('TEST START: RUNNING APP...');
      try {
        app.main();
      } catch (e) {
        debugPrint('CRITICAL ERROR: app.main() failed: $e');
        return;
      }
      
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 1. Handle Onboarding/Disclaimer
      debugPrint('HANDLING ONBOARDING...');
      final acceptBtn = find.byKey(const ValueKey('accept_disclaimer'));
      if (acceptBtn.evaluate().isNotEmpty) {
        await tester.tap(acceptBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // 2. Handle Model Setup if it appears
      debugPrint('CHECKING FOR MODEL SETUP...');
      final skipBtn = find.byKey(const ValueKey('skip_model_setup'));
      if (skipBtn.evaluate().isNotEmpty) {
        debugPrint('Model setup appeared, skipping...');
        await tester.tap(skipBtn);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      debugPrint('WAITING FOR PROTOCOL/MODEL TO LOAD ON HOME...');
      int loadTimeout = 0;
      while (loadTimeout < 60) {
        await tester.pump(const Duration(seconds: 1));
        
        final startBtn = find.byKey(const ValueKey('start_emergency'));
        if (startBtn.evaluate().isNotEmpty) {
          debugPrint('SUCCESS: Emergency button found after $loadTimeout seconds.');
          break;
        }
        
        if (loadTimeout % 5 == 0) {
          debugPrint('Still waiting for Home Screen... ($loadTimeout seconds)');
        }
        loadTimeout++;
      }

      final startBtn = find.byKey(const ValueKey('start_emergency'));
      if (startBtn.evaluate().isEmpty) {
        debugPrint('ERROR: Emergency button never appeared. Printing widget tree:');
        debugPrint(tester.allWidgets.map((w) => w.toString()).join('\n'));
        return;
      }
      
      await tester.tap(startBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await runConversation(tester, [
        "my son fell and hit his knee while we are walking in the forest",
        "i have phone signal. we are probably like 1 km away from the parking lot",
        "it bleeds a bit and he is crying, doesn;t look broken.",
        "he is fine overall, just his knee hurts. he is 4 years old. can i carry him?",
      ]);

      debugPrint('RETURNING TO HOME...');
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      debugPrint('STARTING SCENARIO 02: SPINAL INJURY');
      await tester.tap(find.byKey(const ValueKey('start_emergency')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await runConversation(tester, [
        "my friend fell on him mtb and im afraid he hit his back",
        "now he is standing still, he is in pain. his lower back hurts.",
        "he can move his legs but the pain is sharp and constant.",
        "we are on a trail 2km from the car. i have signal.",
      ]);
    });
  });
}
