import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import '../models/protocol.dart';

enum LlmStatus { loading, ready, mock, error }

class LlmState {
  final LlmStatus status;
  final String? errorMessage;

  const LlmState({required this.status, this.errorMessage});

  LlmState copyWith({LlmStatus? status, String? errorMessage}) {
    return LlmState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LlmService extends Notifier<LlmState> {
  InferenceModel? _model;

  @override
  LlmState build() {
    return const LlmState(status: LlmStatus.loading);
  }

  bool get isModelLoaded => state.status == LlmStatus.ready;

  String _buildSystemPrompt({
    required String situationContext,
    required String knowledgeBase,
  }) {
    return '''AIDEM MULTI-LANGUAGE PROTOCOL:
You are a highly skilled wilderness paramedic. 
Your primary knowledge base and protocols are in English, but you must help users in their native language.

WORKFLOW:
1. Analyze the user's input (it may be in any language).
2. If it's not in English, translate it internally to English.
3. Consult the REFERENCE MATERIAL (English) to determine the next medical step.
4. Compose your expert medical advice in English.
5. Translate that advice back into the user's original language.
6. OUTPUT ONLY the translated advice. DO NOT show your internal English reasoning.

$situationContext

REFERENCE MATERIAL (TRUST THIS ONLY):
$knowledgeBase

EMERGENCY TIER SYSTEM:
- TIER 1 (CRITICAL): Life-threatening (Bleeding, Unconscious). Action: Be brief, focus on immediate survival, recommend 911.
- TIER 2 (MODERATE): Stable but serious (Fractures, Deep cuts). Action: Provide detailed, multi-step first aid (splinting, pressure).
- TIER 3 (MINOR): Self-manageable (Scrapes, Sprains). Action: Provide thorough care instructions (cleaning, RICE method) and evacuation guidance.

STRICT STYLE RULES (MANDATORY):
1. FACT LOCK: If a fact is in CONFIRMED FACTS or SYSTEMIC STATUS, NEVER ask about it again. 
2. NO REPETITION: You are FORBIDDEN from asking the same question or giving the same instruction twice in a row. Move the conversation forward every turn.
3. PACE YOURSELF: Give ONLY 1 or 2 instructions at a time. Do NOT dump a wall of text.
4. NO INTROS: Start directly with the next survival step.
5. NO SYMPATHY AFTER TURN 1.
6. MANDATORY CHECK-IN: Always end with ONE question. If the user answered your last question, MOVE TO THE NEXT medical step immediately.

EXAMPLE CONVERSATION:
User: I have a cut in the forest. I have water and a bandana. I am walking home.
AI: Since you have water, gently rinse the wound once. Tell me when you have finished rinsing it.
User: I rinsed it.
AI: Good. Now use the bandana as a firm wrap to control any bleeding. Are you ready to start walking?
User: Yes, I'm ready.
AI: Keep your hand elevated above your heart level as you walk. Watch for slippery rocks or roots. Do you feel dizzy at all?''';
  }

  Future<bool> init() async {
    if (state.status == LlmStatus.ready && _model != null) return true;

    state = state.copyWith(status: LlmStatus.loading);
    print('LLM: Initializing Gemma model...');
    
    try {
      try {
        print('LLM: Attempting GPU initialization (2048 tokens)...');
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 2048,
          preferredBackend: PreferredBackend.gpu,
          supportImage: true,
        );
        print('LLM: GPU initialization successful.');
      } catch (gpuError) {
        print('LLM: GPU failed ($gpuError). Attempting CPU (1024 tokens)...');
        try {
          _model = await FlutterGemma.getActiveModel(
            maxTokens: 1024,
            preferredBackend: PreferredBackend.cpu,
            supportImage: true,
          );
          print('LLM: CPU initialization successful.');
        } catch (cpuError) {
          print('LLM: CPU (1024) failed ($cpuError). Attempting Conservative CPU (512 tokens)...');
          _model = await FlutterGemma.getActiveModel(
            maxTokens: 512,
            preferredBackend: PreferredBackend.cpu,
            supportImage: true,
          );
          print('LLM: Conservative CPU initialization successful.');
        }
      }

      state = state.copyWith(status: LlmStatus.ready);
      return true;
    } catch (e) {
      print('LLM: Final initialization error: $e');
      state = state.copyWith(status: LlmStatus.mock, errorMessage: e.toString());
      return false;
    }
  }

  Stream<String> generateResponseStream({
    required String userMessage,
    required String situationContext,
    required String knowledgeBase,
    required List<ChatMessage> recentHistory,
    String? imagePath,
  }) async* {
    if (state.status != LlmStatus.ready || _model == null) {
      await init();
    }

    if (state.status != LlmStatus.ready || _model == null) {
      final response = AdaptiveMock.respond(
        userMessage: imagePath != null ? "[IMAGE ATTACHED] $userMessage" : userMessage,
        situationContext: situationContext,
        historyCount: recentHistory.length,
      );
      for (final word in response.split(' ')) {
        yield '$word ';
        await Future.delayed(const Duration(milliseconds: 30));
      }
      return;
    }

    try {
      final systemInstruction = _buildSystemPrompt(
        situationContext: situationContext,
        knowledgeBase: knowledgeBase,
      );

      // Prepare image data if available
      Uint8List? imageBytes;
      if (imagePath != null) {
        try {
          imageBytes = await File(imagePath).readAsBytes();
        } catch (e) {
          print('LLM: Error reading image bytes: $e');
        }
      }

      final chat = await _model!.createChat(
        systemInstruction: systemInstruction,
        supportImage: true,
      );

      // Add history with strict role alternation
      bool lastWasUser = false;
      for (int i = 0; i < recentHistory.length; i++) {
        final msg = recentHistory[i];
        final isUser = msg.author == MessageAuthor.user;
        
        if (isUser) {
          if (lastWasUser) continue;
          
          Uint8List? histImageBytes;
          if (msg.imagePath != null) {
            try {
              histImageBytes = await File(msg.imagePath!).readAsBytes();
            } catch (e) {
              print('LLM: Error reading history image: $e');
            }
          }

          if (histImageBytes != null) {
            await chat.addQueryChunk(Message.withImage(
              text: msg.text,
              isUser: true,
              imageBytes: histImageBytes,
            ));
          } else {
            await chat.addQueryChunk(Message.text(
              text: msg.text,
              isUser: true,
            ));
          }
          lastWasUser = true;
        } else {
          // AI Response
          if (!lastWasUser && i > 0) continue;
          await chat.addQueryChunk(Message.text(
            text: msg.text,
            isUser: false,
          ));
          lastWasUser = false;
        }
      }

      // Add current user message
      if (imageBytes != null) {
        await chat.addQueryChunk(Message.withImage(
          text: userMessage,
          isUser: true,
          imageBytes: imageBytes,
        ));
      } else {
        await chat.addQueryChunk(Message.text(
          text: userMessage,
          isUser: true,
        ));
      }

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse && response.token.isNotEmpty) {
          yield response.token;
        }
      }

      await chat.close();
    } catch (e) {
      yield '\n\n[Error: ${e.toString()}]';
    }
  }

  Future<String> generateOnce(String prompt) async {
    if (state.status != LlmStatus.ready || _model == null) {
      return '';
    }

    try {
      final chat = await _model!.createChat();
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      final buffer = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) buffer.write(response.token);
      }
      await chat.close();
      return buffer.toString();
    } catch (e) {
      return '';
    }
  }

  Future<void> close() async {
    await _model?.close();
    _model = null;
    state = state.copyWith(status: LlmStatus.loading);
  }
}

class AdaptiveMock {
  static String respond({
    required String userMessage,
    required String situationContext,
    int historyCount = 0,
  }) {
    final msg = userMessage.toLowerCase();
    final ctx = situationContext.toLowerCase();

    if (_isBackInjury(msg) || (msg.contains('fell') && msg.contains('back'))) {
      return "CRITICAL: Do not move him. Call 911 now. Keep him completely still — his spine may be injured. Do not let him sit up, stand, or walk. Support his head in the position you found him. Is he breathing normally?";
    }

    if (msg.contains('bleeding') && (msg.contains('heavy') || msg.contains('a lot') || msg.contains("won't stop") || msg.contains(' spurting'))) {
      return "CRITICAL: Apply firm pressure directly to the wound with whatever is available — shirt, towel, anything. If blood soaks through, add more layers without removing the first. Call 911 while doing this. If the bleeding is from an arm or leg and won't stop, a tourniquet may be needed 2-3 inches above the wound. Are you near any help?";
    }

    if (msg.contains('unconscious') || msg.contains('not waking') || msg.contains('not breathing')) {
      return "Call 911 immediately. Check if he is breathing by looking at his chest for 10 seconds. If not breathing, start CPR — push hard and fast on the center of his chest, 30 compressions then 2 breaths. If breathing, put him on his side in recovery position. Keep his airway clear. Do not leave him alone.";
    }

    final lacksWater = _lacks(msg, ['water', 'clean water', 'running water']);
    final lacksBandage = _lacks(msg, ['bandage', 'cloth', 'dressing', 'gauze']);
    final lacksTourniquet = _lacks(msg, ['tourniquet']);
    final lacksSignal = _lacks(msg, ['signal', 'phone', 'cell', 'reception', 'call']);
    final isAlone = msg.contains('alone') || msg.contains('by myself');
    final isUnconscious = msg.contains('unconscious') || msg.contains('not waking');

    if (lacksWater && (_isBleeding(msg) || ctx.contains('wound') || ctx.contains('cut'))) {
      return "Without water, use any clear liquid available to clean the wound — diluted sports drink works, even fresh urine is sterile. Flush by squeezing liquid from a cloth above the wound, don't rub. Cover with the cleanest available material, the inside of a shirt works. What can you use to cover it?";
    }

    if (lacksBandage && (_isBleeding(msg) || ctx.contains('wound') || ctx.contains('cut'))) {
      return "Improvise a bandage. Tear a strip from the INSIDE of a shirt or sock — inside is cleaner. Fold into a thick pad and press firmly onto the wound. Tie snugly with another strip, tight enough to feel resistance but you should still feel a pulse below it. Elevate the limb above heart level. Is the bleeding still active or slowing?";
    }

    if (lacksTourniquet && (msg.contains('bleeding') || msg.contains('blood'))) {
      return "Make a field tourniquet. Cut or tear a strip of clothing AT LEAST 2 inches wide — narrow strips cause more damage. Wrap it twice around the limb 2-3 inches above the wound. Tie a half-knot, place a stick on top, tie another knot over it. Twist until bleeding stops completely then secure it. Note the time. Leave on for up to 2 hours. Has the bleeding slowed?";
    }

    if (_isBleeding(msg) && !lacksBandage && !msg.contains('deep') && !msg.contains('bad')) {
      return "For a minor cut, clean it gently with water if available. Apply pressure with a clean cloth until bleeding stops. Keep it elevated if possible. Cover with a bandage or clean cloth. Keep it dry for 24 hours. If you notice redness, swelling, or pus, seek medical help when possible. Do you have everything you need right now?";
    }

    if (msg.contains('broken') || msg.contains('fracture') || (msg.contains('fell') && msg.contains('wrist'))) {
      return "For a suspected fracture, immobilize the area — don't try to straighten it. Apply ice wrapped in cloth to reduce swelling, but never directly on skin. Keep it elevated. Do not give food or water in case you need surgery. Can you splint it with something firm like a stick or magazine rolled around it? Call your brother and get to urgent care if the pain is severe.";
    }

    if (lacksSignal && !ctx.contains('signal')) {
      return "No signal — try moving to higher ground, even 50 meters can restore a bar. Try SMS first, texts work on weaker signals than calls. Switch to airplane mode between attempts to conserve battery. Do you have anything reflective to signal with if you see a plane or rescuer?";
    }

    if (isAlone && !ctx.contains('alone')) {
      return "Since you're alone, your priorities are: control any active bleeding first, then make yourself visible from above if possible, then conserve body temperature by insulating from the ground. Do not try to walk out if you're injured — staying put is safer. Can you control the bleeding first?";
    }

    if (historyCount > 2 && (msg.contains('lost') || msg.contains('forest') || msg.contains('mountain'))) {
      return "STAY WHERE YOU ARE. Moving makes rescue 10 times harder. Can you get to high ground? Do you have anything reflective to signal from the air? Keep your phone on for any signal updates.";
    }

    return "Tell me the most urgent problem right now. What do you have available to help — cloth, water, phone signal? The more specific you are about what you need, the faster I can help.";
  }

  static bool _lacks(String msg, List<String> keywords) {
    return keywords.any((kw) =>
        msg.contains('no $kw') ||
        msg.contains("don't have $kw") ||
        msg.contains('dont have $kw') ||
        msg.contains('without $kw') ||
        msg.contains('lost my $kw') ||
        msg.contains("can't use $kw"));
  }

  static bool _isBackInjury(String msg) {
    return msg.contains('back') || msg.contains('spinal') || msg.contains('neck');
  }

  static bool _isBleeding(String msg) {
    return msg.contains('bleed') || msg.contains('blood') || msg.contains('cut') || msg.contains('wound');
  }
}