/// LLM Service for Survival AId
/// 
/// Architecture:
///   - [LlmService.generateResponse] is the single entry point.
///   - In production, this calls MediaPipe GenAI with the bundled Gemma 2B model.
///   - During development/Windows testing, it falls back to [_AdaptiveMock],
///     a rule-based engine that demonstrates the same adaptive reasoning Gemma provides.

class LlmService {
  // Future production hook:
  // LlmInferenceEngine? _engine;

  bool _isInitialized = false;

  Future<void> init() async {
    // Production: load model from assets
    // _engine = await LlmInferenceEngine.create('assets/models/gemma-2b-it-gpu-int4.bin');
    _isInitialized = true;
  }

  /// Generates a contextually-adaptive response from the survival assistant.
  ///
  /// [conversationHistory] — all prior messages, oldest first.
  /// [currentProtocolContext] — the current protocol node question/instruction.
  /// [userMessage] — the user's free-form input.
  Future<String> generateResponse({
    required List<String> conversationHistory,
    required String currentProtocolContext,
    required String userMessage,
  }) async {
    if (!_isInitialized) await init();

    // === Production path (Gemma 2B via MediaPipe) ===
    // final prompt = _buildPrompt(conversationHistory, currentProtocolContext, userMessage);
    // return await _engine!.generateResponse(prompt);

    // === Development path: adaptive rule-based mock ===
    return _AdaptiveMock.respond(
      history: conversationHistory,
      protocolContext: currentProtocolContext,
      userMessage: userMessage,
    );
  }

  String _buildPrompt(List<String> history, String context, String userMessage) {
    final historyText = history.takeLast(6).join('\n');
    return """<start_of_turn>system
You are Survival AId, an offline wilderness emergency assistant. 
Your role is to ADAPT to the user's actual situation, resources, and constraints.
Never repeat a step they just said they can't do. Always offer a realistic alternative.
Speak calmly, directly, and in plain language. No jargon.
Current emergency protocol context: "$context"
<end_of_turn>
<start_of_turn>conversation_history
$historyText
<end_of_turn>
<start_of_turn>user
$userMessage
<end_of_turn>
<start_of_turn>model
""";
  }
}

/// Takes strings from the end of a list (helper since Dart lacks .takeLast)
extension _ListTakeLast<T> on List<T> {
  List<T> takeLast(int n) => length <= n ? this : sublist(length - n);
}

/// Adaptive mock engine. Detects constraints and resource gaps from what the user typed,
/// and provides real alternative wilderness medicine/survival advice.
class _AdaptiveMock {
  static String respond({
    required List<String> history,
    required String protocolContext,
    required String userMessage,
  }) {
    final msg = userMessage.toLowerCase();

    // === Detect resource/capability gaps ===
    final bool lacksWater = _lacks(msg, ['water', 'liquid', 'drink', 'clean water', 'running water']);
    final bool lacksBandage = _lacks(msg, ['bandage', 'cloth', 'dressing', 'gauze', 'wrap']);
    final bool lacksKit = _lacks(msg, ['kit', 'supplies', 'first aid', 'equipment', 'gear']);
    final bool lacksTourniquet = _lacks(msg, ['tourniquet']);
    final bool lacksPhone = _lacks(msg, ['phone', 'signal', 'cell', 'service', 'reception', 'call']);
    final bool lacksFireMaking = _lacks(msg, ['fire', 'lighter', 'matches', 'flint']);
    final bool alone = msg.contains('alone') || msg.contains('by myself') || msg.contains('just me');
    final bool bleeding = msg.contains('bleed') || msg.contains('blood') || msg.contains('cut');
    final bool pain = msg.contains('pain') || msg.contains('hurt') || msg.contains('painful');
    final bool unconscious = msg.contains('unconscious') || msg.contains('passed out') || msg.contains('not waking');

    // === Specific adaptive responses ===

    // Wound + no water
    if (lacksWater && (protocolContext.contains('wound') || protocolContext.contains('wash') || protocolContext.contains('clean') || bleeding)) {
      return "Without water, don't leave the wound untreated. Improvise:\n\n"
          "• Use any clear liquid — diluted sports drink, even fresh urine in an extreme case (it's sterile when fresh).\n"
          "• Irrigate gently by squeezing liquid from a cloth above the wound to flush debris out.\n"
          "• Avoid rubbing alcohol directly — it damages tissue. Use it diluted if that's all you have.\n\n"
          "Once flushed, cover with the cleanest material available (inside of a shirt, a bag) and apply firm pressure. "
          "What do you have to cover it with?";
    }

    // Wound + no bandage
    if (lacksBandage && (protocolContext.contains('wound') || protocolContext.contains('bandage') || protocolContext.contains('dress'))) {
      return "No bandage needed — improvise a dressing from what you have:\n\n"
          "• Tear a strip from the inside of a shirt or sock (inside = cleaner).\n"
          "• Fold it into a thick pad and press firmly over the wound.\n"
          "• Tie it snugly with another strip — tight enough to stop bleeding, but you should still feel your pulse below it.\n\n"
          "Do NOT use leaves, moss, or soil — they introduce bacteria. Once covered, elevate the limb above heart level if possible. "
          "Is the bleeding still active or has it slowed?";
    }

    // No tourniquet for severe bleeding
    if (lacksTourniquet && (protocolContext.contains('tourniquet') || protocolContext.contains('bleed'))) {
      return "No tourniquet? A field tourniquet will work:\n\n"
          "1. Cut or tear a strip of clothing at least 2 inches wide (narrow strips cause more damage).\n"
          "2. Wrap it TWICE around the limb, 2-3 inches above the wound.\n"
          "3. Tie a half-knot, place a stick or pen on top, tie another knot over it.\n"
          "4. Twist the stick until bleeding stops completely — don't loosen it.\n"
          "5. Note the time. Tourniquet can stay on up to 2 hours.\n\n"
          "Have you been able to stop the bleeding?";
    }

    // No phone signal
    if (lacksPhone && (protocolContext.contains('call') || protocolContext.contains('signal') || protocolContext.contains('rescue'))) {
      return "No signal — that's why we plan for this. Do these in order:\n\n"
          "1. Try moving to high ground (even 50m of elevation can restore a signal bar).\n"
          "2. Try SMS — texts use a fraction of the bandwidth of a call and may get through on weak signals.\n"
          "3. If no signal at all: switch your phone to airplane mode to conserve battery, turn it on for 2 minutes every hour.\n\n"
          "Once your situation is stable, focus on making yourself visible (I can guide you through signaling methods). "
          "Are you in an open area or under tree cover?";
    }

    // Alone + injured
    if (alone && (bleeding || pain)) {
      return "Being alone changes things — you have to be your own triage team. Here's your priority order:\n\n"
          "1. STOP any life-threatening bleeding first (everything else can wait).\n"
          "2. Make yourself visible — if you can't move far, create a signal near you.\n"
          "3. Conserve heat and energy — this buys you time.\n"
          "4. DO NOT push yourself to walk out if the injury is serious — a bad decision while alone can turn survivable into fatal.\n\n"
          "Tell me: can you walk? And do you know roughly which direction safety is?";
    }

    // Person is unconscious
    if (unconscious) {
      return "If someone is unconscious:\n\n"
          "1. Check breathing — watch the chest for 10 seconds. If not breathing, begin CPR (30 compressions, 2 rescue breaths).\n"
          "2. If breathing: roll them into the RECOVERY POSITION — on their side, top knee bent forward, head tilted slightly back to keep airway open.\n"
          "3. Do NOT leave them alone unless you absolutely must go for help.\n"
          "4. Check for response every few minutes — call their name loudly.\n\n"
          "Are they breathing?";
    }

    // No fire-making ability
    if (lacksFireMaking && (protocolContext.contains('fire') || protocolContext.contains('warm') || protocolContext.contains('signal'))) {
      return "No lighter or matches? Friction fire is very hard without practice. Focus on alternatives:\n\n"
          "• WARMTH: Layer everything you have — clothing, a space blanket, even dry leaves stuffed inside a jacket insulate well.\n"
          "• SIGNAL: A bright X made of clothing on open ground is visible to search aircraft for miles. Make it as large as possible.\n"
          "• SHELTER: Get out of the wind. A natural windbreak (boulder, dense bush) reduces heat loss massively.\n\n"
          "How cold is it roughly, and do you have any kind of outer layer?";
    }

    // No kit / nothing
    if (lacksKit) {
      return "No kit is harder, but people survive with improvisation every year. Let's work with what you have.\n\n"
          "Tell me specifically:\n"
          "• What's the injury or situation?\n"
          "• What do you have on you right now — clothing, bag, phone, food, anything?\n"
          "• Are you alone?\n\n"
          "With those details I can give you a specific plan using only what's available.";
    }

    // Generic: ask clarifying questions
    if (msg.length < 30 || msg.contains('what') || msg.contains('how') || msg.contains('should')) {
      final contextSnippet = protocolContext.split('.').first;
      return "I want to give you advice that actually works for your situation.\n\n"
          "Right now we're at: \"$contextSnippet.\"\n\n"
          "To adapt: tell me what resources you have nearby, if anyone else is with you, "
          "and the most urgent thing you're dealing with right now. "
          "The more detail you give, the better I can help.";
    }

    // Fallback — still better than the old canned message
    return "Got it. Based on what you've said, let's adapt the plan.\n\n"
        "Can you tell me: what do you actually have available right now? "
        "Even small things — clothing, a bag, any tools — change what's possible. "
        "I'll give you a step-by-step that works with only what you have.";
  }

  static bool _lacks(String msg, List<String> keywords) {
    for (final kw in keywords) {
      if ((msg.contains("no $kw") ||
          msg.contains("don't have $kw") ||
          msg.contains("dont have $kw") ||
          msg.contains("without $kw") ||
          msg.contains("no access to $kw") ||
          msg.contains("can't use $kw") ||
          msg.contains("cant use $kw") ||
          msg.contains("lost my $kw") ||
          msg.contains("left my $kw"))) {
        return true;
      }
    }
    return false;
  }
}
