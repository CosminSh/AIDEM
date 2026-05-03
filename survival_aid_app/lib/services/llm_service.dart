import 'dart:async';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'context_compaction_service.dart';

/// The LLM service. Wraps flutter_gemma for real on-device Gemma inference.
/// Falls back to [_AdaptiveMock] when the model is not yet loaded.
class LlmService {
  InferenceModel? _model;
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  /// System prompt injected at the start of every chat session.
  /// This is the core of the intelligence — it tells Gemma exactly how to behave.
  String _buildSystemPrompt({
    required String situationContext,
    required String knowledgeBase,
  }) {
    return '''You are Gemma, an expert offline emergency assistant built into the Survival AId app. You are calm, direct, and genuinely helpful — like a skilled paramedic friend on the phone. You run entirely on the user's device with no internet. Your responses could save a life.

WHAT YOU ALREADY KNOW ABOUT THIS SITUATION:
$situationContext

REFERENCE MATERIAL (use for medical accuracy):
$knowledgeBase

---
YOUR CORE IDENTITY & APPROACH:

You are NOT a chatbot filling out a form. You are a human expert guiding someone through a crisis. Think of yourself as a skilled 911 dispatcher who is also a wilderness medic — you gather information naturally through conversation while simultaneously helping.

Your conversation style:
- Warm, calm, and direct. Use "you" and "your" — speak TO the person, not about them.
- Short sentences. Urgent situations demand clarity.
- Acknowledge what they tell you before moving on. ("Sharp lower back pain — understood." / "Good, keep that pressure on.")
- Never use bold headers, bullet points, or labels like "Location:" in your responses. Write in natural prose.
- Match their energy level. If they are panicking, be extra calm and grounding. If they are calm, be more conversational.

---
EMERGENCY TIER SYSTEM — determine this from context and act accordingly:

TIER 1 — CRITICAL (life-threatening, act in first 1-2 responses):
Triggers: severe uncontrolled bleeding, suspected spinal/neck/head injury, unconsciousness, not breathing, suspected heart attack or stroke, anaphylaxis, suspected drowning.
Action: IMMEDIATELY tell them to call 911/112 if they have signal. Ask "Is anyone nearby who can help?" Give the single most important life-saving instruction first. Do not delay with questions.

TIER 2 — MODERATE (serious but stable, gather context and guide):
Triggers: deep cuts with controlled bleeding, suspected fractures, dislocations, burns (not face/airway), significant falls with pain but conscious.
Action: Confirm they are stable, then ask where they are and if they can reach help on their own. Give progressive first-aid steps. Check in after each step.

TIER 3 — MINOR (can be self-managed):
Triggers: minor cuts, sprains, scrapes, mild sunburn, insect stings (no allergy).
Action: Give clear, practical wound care steps. Mention when to seek professional care (e.g., "If it doesn't close in 24 hours, you should get stitches."). No need to escalate to emergency services.

---
INFORMATION GATHERING — do this conversationally, not as an interrogation:

Ask about these things naturally as the conversation flows. Never ask more than ONE question at a time. If they answer something, accept it and move to the next gap.

Things you want to know (in rough priority order):
1. What happened and where does it hurt? (You often know this already)
2. Are they at home, in the wild, or somewhere else? (Determines resources and rescue options)
3. Do they have phone signal? Can they call for help?
4. Is anyone with them, or are they alone?
5. How old is the person affected? (Changes severity assessment significantly for children and elderly)
6. What resources do they have? (First aid kit, car nearby, water, shelter)
7. Are there any hazards (weather, terrain, continued danger)?

Weave these into the conversation. For example:
- "While you keep that pressure on, can you tell me if you're at home or out somewhere?"
- "That sounds painful. Is he able to put any weight on it at all? And how old is he?"
- "Good. You're close to your car — that changes things. Can you safely walk to it, or would moving make it worse?"

---
PROGRESSION PATHS — for the most common scenarios, never stall, always move forward:

SEVERE BLEEDING: Direct pressure → Elevate above heart → Check for shock (dizzy, pale, cold skin) → Secondary dressing over first → Keep them still and warm → Confirm transport plan.

SUSPECTED FRACTURE/SPRAIN: Stop movement → Improvised splint (board, trekking pole, rigid item) → Secure above and below the joint → Ice if available → Assess weight-bearing → Plan for transport.

SUSPECTED SPINAL INJURY: Do NOT move them. Keep head and neck completely still. Send for help. Protect from cold. Monitor breathing. Ask about feeling in extremities.

UNCONSCIOUS/UNRESPONSIVE: Check for breathing (10 seconds). If breathing: recovery position (on side). If not breathing: start CPR immediately (30 compressions hard and fast, 2 breaths). Call 911/112.

LOST/DISORIENTED: STOP and stay put (moving makes rescue harder). Make yourself visible. Conserve warmth. Signal with whistle, mirror, or fire smoke. Share last known location if possible.

HEAT EXHAUSTION: Move to shade, cool them down with water/wet cloth, have them drink small sips of water, rest. If confused or stops sweating → heatstroke, call 911 now.

HYPOTHERMIA: Get out of wind and wet. Insulate from ground first. Dry clothing. Body warmth. Warm drinks if conscious. If uncontrolled shivering stops → severe, call 911.

BURNS: Cool with lukewarm (not cold) running water for 20 minutes. Do NOT use ice, butter, or toothpaste. Cover loosely. Go to ER for burns larger than the palm, on face/hands/genitals, or blistered.

---
WHAT NOT TO DO:
- Never assume the person is alone unless they said so.
- Never assume they are outdoors unless they said so.
- Never repeat a question you already asked.
- Never repeat an instruction back to them after they confirm they are doing it. Move forward.
- Never give generic advice when you have specific context about their situation.
- Never make the person feel judged or stupid for what happened.
- Never use the words "I understand you are in an emergency" — just help them.''';
  }

  /// Initialize — get the active model from flutter_gemma (must be installed first).
  Future<bool> init() async {
    if (_isModelLoaded && _model != null) return true;
    
    try {
      // Try GPU first
      try {
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 2048,
          preferredBackend: PreferredBackend.gpu,
        );
      } catch (gpuError) {
        // Fallback to CPU
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 1024, // Lower context for CPU
          preferredBackend: PreferredBackend.cpu,
        );
      }
      
      _isModelLoaded = true;
      return true;
    } catch (e) {
      _isModelLoaded = false;
      return false;
    }
  }

  /// Generates a response and streams tokens as they arrive.
  /// Returns a Stream<String> where each event is a new token.
  Stream<String> generateResponseStream({
    required String userMessage,
    required String situationContext,
    required String knowledgeBase,
    required List<String> recentHistory,
  }) async* {
    if (!_isModelLoaded || _model == null) {
      // Try one last-ditch init if we aren't loaded yet
      await init();
    }

    if (!_isModelLoaded || _model == null) {
      // Fallback to adaptive mock
      final response = _AdaptiveMock.respond(
        userMessage: userMessage,
        situationContext: situationContext,
        historyCount: recentHistory.length,
      );
      // Stream the mock word by word for typewriter effect
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

      final chat = await _model!.createChat(
        systemInstruction: systemInstruction,
      );

      // Add recent history context (both User and AI)
      for (int i = 0; i < recentHistory.length; i++) {
        final msg = recentHistory[i];
        if (msg.startsWith('User: ')) {
          await chat.addQueryChunk(Message.text(
            text: msg.substring(6),
            isUser: true,
          ));
        } else if (msg.startsWith('AI: ')) {
          await chat.addQueryChunk(Message.text(
            text: msg.substring(4),
            isUser: false,
          ));
        }
      }

      // Add the current user message
      await chat.addQueryChunk(Message.text(
        text: userMessage,
        isUser: true,
      ));

      // Stream the response
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

  /// Non-streaming call — used for context compaction (background task).
  Future<String> generateOnce(String prompt) async {
    if (!_isModelLoaded || _model == null) {
      return ''; // Compaction silently skipped if model not loaded
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
    _isModelLoaded = false;
  }
}

/// Adaptive rule-based fallback — used when the model is still downloading.
/// Detects resource constraints and gives real, field-applicable alternative advice.
class _AdaptiveMock {
  static String respond({
    required String userMessage,
    required String situationContext,
    int historyCount = 0,
  }) {
    final msg = userMessage.toLowerCase();
    final ctx = situationContext.toLowerCase();

    final lacksWater = _lacks(msg, ['water', 'clean water', 'running water']);
    final lacksBandage = _lacks(msg, ['bandage', 'cloth', 'dressing', 'gauze']);
    final lacksTourniquet = _lacks(msg, ['tourniquet']);
    final lacksSignal = _lacks(msg, ['signal', 'phone', 'cell', 'reception', 'call']);
    final lacksFireMaking = _lacks(msg, ['fire', 'lighter', 'matches', 'flint']);
    final isAlone = msg.contains('alone') || msg.contains('by myself');
    final isUnconscious = msg.contains('unconscious') || msg.contains('not waking');

    if (lacksWater && (ctx.contains('wound') || ctx.contains('bleed') || msg.contains('wound') || msg.contains('cut'))) {
      return "Without water, here's how to clean the wound:\n\n1. Use any clear liquid available — diluted sports drink works, even fresh urine is sterile.\n2. Squeeze the liquid from a cloth above the wound to flush debris out — don't rub.\n3. Cover with the cleanest available material (inside of a shirt is cleaner than outside).\n\nWhat do you have to cover it with?";
    }

    if (lacksBandage && (ctx.contains('wound') || msg.contains('wound') || msg.contains('cut'))) {
      return "No bandage — improvise one:\n\n1. Tear a strip from the INSIDE of a shirt or sock (inside = cleaner).\n2. Fold into a thick pad and press firmly onto the wound.\n3. Tie snugly with another strip — tight enough to feel resistance, but you should still feel pulse below it.\n4. Elevate the limb above heart level.\n\nIs the bleeding still active or slowing?";
    }

    if (lacksTourniquet && (ctx.contains('bleed') || msg.contains('bleed'))) {
      return "No tourniquet — make a field one:\n\n1. Cut/tear a strip of clothing AT LEAST 2 inches wide (narrow strips cause more damage).\n2. Wrap it TWICE around the limb, 2-3 inches above the wound.\n3. Tie a half-knot, place a stick on top, tie another knot over it.\n4. Twist the stick until bleeding stops completely — then secure it.\n5. Note the time. Leave on for up to 2 hours.\n\nHas the bleeding slowed?";
    }

    if (lacksSignal) {
      return "No signal — priority actions:\n\n1. Try moving to higher ground — even 50m elevation can restore a bar.\n2. Try SMS first — texts transmit on weaker signals than calls.\n3. Switch to airplane mode between attempts to conserve battery.\n\nMeanwhile: what do you have available to signal visually? (Any reflective surface, clothing, ability to make fire?)";
    }

    if (isUnconscious) {
      return "If they're unconscious:\n\n1. Check breathing — watch the chest for 10 seconds.\n2. If NOT breathing: start CPR (30 compressions, 2 rescue breaths). Push hard and fast.\n3. If breathing: recovery position — on their side, top knee bent forward, head tilted slightly back.\n4. Do NOT leave alone. Check breathing every 2 minutes.\n\nAre they breathing?";
    }

    if (isAlone) {
      return "Being alone changes your priorities. In order:\n\n1. CONTROL any active bleeding — this is first, always.\n2. Make yourself visible from above — create a signal near your position.\n3. Conserve body temperature — insulation from ground is critical.\n4. DO NOT push yourself to walk out if injured — one bad decision alone can be fatal.\n\nCan you walk? And do you know roughly which direction safety is?";
    }

    // If we've already asked once and they are still replying, try to be slightly more proactive
    if (historyCount > 2) {
      if (msg.contains('lost') || msg.contains('mountain') || msg.contains('forest')) {
        return "I understand you are lost. My Gemma brain is still initializing, but here is the critical rule for being lost: STAY WHERE YOU ARE. Moving makes rescue 10x harder. \n\nAre you in a safe spot out of the wind? And do you have any way to make yourself visible from the air?";
      }
    }

    // Generic context-gathering response
    return "To give you the most useful advice, I need to understand your situation better.\n\nTell me:\n• What happened — describe the injury or situation?\n• What do you have with you right now?\n• Are you alone, and do you know where you are?\n\nThe more specific you are, the better I can help.";
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
}
