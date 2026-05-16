import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

  static String _limitText(String value, int maxChars) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) return trimmed;
    return '${trimmed.substring(0, maxChars)}...';
  }

  String _buildSystemPrompt({
    required String situationContext,
    required String knowledgeBase,
  }) {
    final trimmedContext = _limitText(situationContext, 1400);
    final trimmedKb = _limitText(knowledgeBase, 1100);
    // Prompt engineered specifically for Gemma-4-E2B-IT (litertlm).
    // Key design decisions:
    // - SESSION STATE block is injected first (highest attention weight).
    // - Short, imperative sentences — small models follow commands, not prose.
    // - Concrete WRONG/RIGHT examples targeting the exact loop failure mode.
    // - KB is placed last to act as reference, not as instructions.
    return '''You are AIDEM, an offline emergency first-aid helper. Be calm, plain, and practical.

RULES (FOLLOW EXACTLY):
1. LANGUAGE: Respond ONLY in the language shown in SESSION STATE.
2. FLOW: Treat CURRENT USER MESSAGE, KNOWN FACTS, and CARE ALREADY DONE as settled. Do not ask for them again.
3. PLAIN WORDS: No jargon or protocol labels. Do not say "blanching", "distal", "proximal", or ask the user to classify first/second/third degree. Ask what they can see or feel.
4. NEXT STEP: Give the next safe action and at most one simple question.
5. BREVITY: Write 1-3 short sentences. No headings, bullets, numbered lists, or intake labels.
6. VISION: If an image is provided, describe only visible signs and state uncertainty. Do not diagnose burn depth, fracture severity, infection spread, venom risk, internal injury, or hidden damage from an image alone. If immediate danger is controlled, ask for a clear photo when it would help: wounds, burns, swelling, bites, stings, rashes, deformity.
7. STUCK: If your next answer repeats the last answer, STOP and move to a different useful next step.
8. CHOICE QUESTIONS: If you asked an either/or question and the user picked one option, accept that answer and continue. Do not ask the same either/or question again.
9. CUTS: For a finger cut, do not decide it is minor until you know bleeding control plus at least one wound-detail check: deep/gaping, numbness/movement, dirt, or whether it can be cleaned and covered.
10. GENERAL TRIAGE: For any situation, first handle immediate danger, then learn the one most important missing fact before concluding. Use what the user already told you. Good missing facts are: breathing/consciousness, bleeding control, pain severity, movement/feeling, swelling/deformity, exposure/substance, location/signal, and available supplies.
11. PHOTO TIMING: Do not ask for a photo before urgent actions like calling emergency services, stopping heavy bleeding, cooling a burn, choking first aid, or using epinephrine. After the urgent step is underway, a photo can help visual assessment.
12. BLEEDING WORDING: Do not say bright red blood means an artery is involved. Treat spurting, pulsing, soaking through cloth, or bleeding that will not slow as the danger signs.
13. FIELD FALL WITH NO SIGNAL: If the user fell on a trail/forest and has a bleeding knee/ankle/leg, treat this as injury plus self-evacuation triage, not only a bleeding case. First check immediate danger/head/breathing, then bleeding control, then walking safety, then phone battery/location/route.
14. DO NOT LOOP BLEEDING: If the user says bleeding is not heavy, slowing, or stopped, do not ask if bleeding is heavy again. Move to covering/cleaning the wound, movement safety, or evacuation.
15. DO NOT LOOP WEIGHT-BEARING: If the user says they can stand, walk, or put weight on it, do not ask that again. If sharp pain/instability/numbness is unknown, ask that once; otherwise advise cautious movement or waiting.
16. SCOPE: If the user asks for unrelated help, refuse briefly and redirect to emergency, first-aid, survival, or rescue support.

$trimmedContext

REFERENCE MATERIAL (use to determine correct next step):
$trimmedKb

EXAMPLES:
User: it stopped bleeding
AI: Good, the bleeding has stopped. Cover it with the cleanest material you have; is there sharp pain or numbness?

User: i don't have a clean cloth
AI: Use the cleanest fabric you have, like the inside of a shirt. Press it firmly on the wound; do not use dirt, leaves, or stream water.

User: i have no signal but i can walk
AI: Turn on battery saver, save or note your location, and use the safest known route. Stop if pain, bleeding, dizziness, or weather gets worse.''';
  }

  Future<bool> init() async {
    if (state.status == LlmStatus.ready && _model != null) return true;

    state = state.copyWith(status: LlmStatus.loading);
    debugPrint('LLM: Initializing Gemma model...');

    try {
      try {
        debugPrint('LLM: Attempting GPU initialization (2048 tokens)...');
        _model = await FlutterGemma.getActiveModel(
          maxTokens: 2048,
          preferredBackend: PreferredBackend.gpu,
          supportImage: true,
        );
        debugPrint('LLM: GPU initialization successful.');
      } catch (gpuError) {
        debugPrint(
          'LLM: GPU failed ($gpuError). Attempting CPU (1024 tokens)...',
        );
        try {
          _model = await FlutterGemma.getActiveModel(
            maxTokens: 1024,
            preferredBackend: PreferredBackend.cpu,
            supportImage: true,
          );
          debugPrint('LLM: CPU initialization successful.');
        } catch (cpuError) {
          debugPrint(
            'LLM: CPU (1024) failed ($cpuError). Attempting Conservative CPU (512 tokens)...',
          );
          _model = await FlutterGemma.getActiveModel(
            maxTokens: 512,
            preferredBackend: PreferredBackend.cpu,
            supportImage: true,
          );
          debugPrint('LLM: Conservative CPU initialization successful.');
        }
      }

      state = state.copyWith(status: LlmStatus.ready);
      return true;
    } catch (e) {
      debugPrint('LLM: Final initialization error: $e');
      state = state.copyWith(
        status: LlmStatus.mock,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Stream<String> generateResponseStream({
    required String userMessage,
    required String situationContext,
    required String knowledgeBase,
    required List<ChatMessage> recentHistory,
    String? imagePath,
    String? lastAiMessage,
  }) async* {
    if (state.status != LlmStatus.ready || _model == null) {
      await init();
    }

    if (state.status != LlmStatus.ready || _model == null) {
      final response = AdaptiveMock.respond(
        userMessage: imagePath != null
            ? "[IMAGE ATTACHED] $userMessage"
            : userMessage,
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
          debugPrint('LLM: Error reading image bytes: $e');
        }
      }

      final chat = await _model!.createChat(
        systemInstruction: systemInstruction,
        supportImage: true,
      );

      // Do not feed prior assistant turns back into the small local model.
      // SESSION STATE carries the vetted memory; raw history can reinforce a
      // stale loop if an earlier answer was corrected by the guard.
      final historyForModel = recentHistory
          .where((message) => message.imagePath != null)
          .toList();

      // Add history with strict role alternation
      bool lastWasUser = false;
      for (int i = 0; i < historyForModel.length; i++) {
        final msg = historyForModel[i];
        final isUser = msg.author == MessageAuthor.user;
        final text = _limitText(msg.text, 220);

        if (isUser) {
          if (lastWasUser) continue;

          Uint8List? histImageBytes;
          if (msg.imagePath != null) {
            try {
              histImageBytes = await File(msg.imagePath!).readAsBytes();
            } catch (e) {
              debugPrint('LLM: Error reading history image: $e');
            }
          }

          if (histImageBytes != null) {
            await chat.addQueryChunk(
              Message.withImage(
                text: text,
                isUser: true,
                imageBytes: histImageBytes,
              ),
            );
          } else {
            await chat.addQueryChunk(Message.text(text: text, isUser: true));
          }
          lastWasUser = true;
        } else {
          // AI Response
          if (!lastWasUser && i > 0) continue;
          await chat.addQueryChunk(Message.text(text: text, isUser: false));
          lastWasUser = false;
        }
      }

      // Add current user message
      if (imageBytes != null) {
        await chat.addQueryChunk(
          Message.withImage(
            text: userMessage,
            isUser: true,
            imageBytes: imageBytes,
          ),
        );
      } else {
        await chat.addQueryChunk(Message.text(text: userMessage, isUser: true));
      }

      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse && response.token.isNotEmpty) {
          yield response.token;
        }
      }

      await chat.close();
    } catch (e) {
      debugPrint('LLM stream error, using adaptive fallback: $e');
      final response = AdaptiveMock.respond(
        userMessage: imagePath != null
            ? "[IMAGE ATTACHED] $userMessage"
            : userMessage,
        situationContext: situationContext,
        historyCount: recentHistory.length,
      );
      for (final word in response.split(' ')) {
        yield '$word ';
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  Future<String> generateExtraction(
    String prompt,
    List<ChatMessage> history,
  ) async {
    if (state.status != LlmStatus.ready || _model == null) return '';

    try {
      final chat = await _model!.createChat(supportImage: true);

      // Add history with images
      for (final msg in history) {
        if (msg.imagePath != null) {
          try {
            final bytes = await File(msg.imagePath!).readAsBytes();
            await chat.addQueryChunk(
              Message.withImage(
                text: msg.text,
                isUser: msg.author == MessageAuthor.user,
                imageBytes: bytes,
              ),
            );
          } catch (_) {
            await chat.addQueryChunk(
              Message.text(
                text: msg.text,
                isUser: msg.author == MessageAuthor.user,
              ),
            );
          }
        } else {
          await chat.addQueryChunk(
            Message.text(
              text: msg.text,
              isUser: msg.author == MessageAuthor.user,
            ),
          );
        }
      }

      // Add the extraction prompt
      await chat.addQueryChunk(Message.text(text: prompt, isUser: true));

      final buffer = StringBuffer();
      await for (final response in chat.generateChatResponseAsync()) {
        if (response is TextResponse) buffer.write(response.token);
      }
      await chat.close();
      return buffer.toString();
    } catch (e) {
      debugPrint('LLM: Extraction error: $e');
      return '';
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
    final combined = '$msg $ctx';
    final trailFallContext =
        _hasAny(combined, [
          'forest',
          'trail',
          'woods',
          'running',
          'runner',
          'jogging',
          'stumbled',
        ]) &&
        _hasAny(combined, [
          'fell',
          'fall',
          'stumbled',
          'knee',
          'ankle',
          'leg',
          'injury',
        ]);
    final fieldWound = _hasAny(combined, [
      'bleeding',
      'blood',
      'wound',
      'scrape',
      'cut',
    ]);
    final fieldNoSignal =
        _lacks(msg, ['signal', 'phone', 'cell', 'reception', 'call']) ||
        _hasAny(combined, ['no signal', 'no phone signal', 'lacks: signal']);
    final fieldNoBandage =
        _lacks(msg, ['bandage', 'cloth', 'dressing', 'gauze']) ||
        _hasAny(combined, [
          'no clean cloth',
          'no clean cloth or bandage',
          'lacks: bandage',
        ]);
    final bleedingStopped = _hasAny(combined, [
      'bleeding has stopped',
      'bleeding stopped',
      'stopped bleeding',
      'not bleeding anymore',
      'no bleeding',
    ]);
    final bleedingNotHeavy = _hasAny(combined, [
      'bleeding is not heavy',
      'not bleeding that bad',
      'not heavy',
      'not much bleeding',
      'only a little blood',
    ]);
    final canBearWeight = _hasAny(combined, [
      'can stand',
      'can walk',
      'can put weight',
      'can pui weight',
      'can pui',
      'can bear weight',
    ]);
    final noSharpPain = _hasAny(combined, [
      'no sharp pain',
      'not sharp',
      'just a bit of pain',
      'mild pain',
      'pain is mild',
    ]);
    final noNumbness = _hasAny(combined, [
      'no numbness',
      'not numb',
      'no numb',
    ]);

    if (_isOffTopic(msg)) {
      return "I can only help with emergency, first-aid, survival, or rescue support. Tell me the immediate safety problem, injuries, location, and what supplies you have.";
    }

    if (_isBackInjury(msg) || (msg.contains('fell') && msg.contains('back'))) {
      return "CRITICAL: Do not move him. Call 911 now. Keep him completely still — his spine may be injured. Do not let him sit up, stand, or walk. Support his head in the position you found him. Is he breathing normally?";
    }

    if (msg.contains('bleeding') &&
        (msg.contains('heavy') ||
            msg.contains('a lot') ||
            msg.contains("won't stop") ||
            msg.contains(' spurting'))) {
      return "CRITICAL: Apply firm pressure directly to the wound with whatever is available — shirt, towel, anything. If blood soaks through, add more layers without removing the first. Call 911 while doing this. If the bleeding is from an arm or leg and won't stop, a tourniquet may be needed 2-3 inches above the wound. Are you near any help?";
    }

    if (msg.contains('unconscious') ||
        msg.contains('not waking') ||
        msg.contains('not breathing')) {
      return "Call 911 immediately. Check if he is breathing by looking at his chest for 10 seconds. If not breathing, start CPR — push hard and fast on the center of his chest, 30 compressions then 2 breaths. If breathing, put him on his side in recovery position. Keep his airway clear. Do not leave him alone.";
    }

    if (msg.contains('[image attached]')) {
      if (_isBurn(msg) || ctx.contains('burn')) {
        return "Image received. I can use visible clues like redness, blistering, swelling, or charring, but I cannot safely diagnose burn depth from a photo alone. Cool the burn under clean cool running water for 20 minutes if available, then tell me if there are blisters, numb white or black skin, or the burn is larger than the patient's palm.";
      }
      if (_isBleeding(msg) || ctx.contains('wound') || ctx.contains('cut')) {
        return "Image received. I can use visible clues like bleeding, gaping edges, dirt, or swelling, but I cannot measure depth or rule out hidden damage from a photo. Keep pressure on any active bleeding, then tell me if the wound is deep, numb, dirty, or hard to move.";
      }
      if (_isBiteOrSting(msg) ||
          ctx.contains('bite') ||
          ctx.contains('sting')) {
        return "Image received. I can look for visible swelling, spreading redness, or a retained stinger, but I cannot identify every bite or venom risk from a photo. Wash the area if safe and tell me if swelling is spreading or breathing feels hard.";
      }
      return "Image received. I can use visible clues, but I cannot diagnose severity from a photo alone. Tell me what happened, whether there is severe bleeding, trouble breathing, confusion, or worsening pain.";
    }

    if (trailFallContext && (fieldWound || fieldNoSignal)) {
      final asksToWalk =
          msg.contains('safe to walk') ||
          msg.contains('walk now') ||
          msg.contains('walking home') ||
          msg.contains('walk home');
      if (bleedingStopped && canBearWeight && (noSharpPain || noNumbness)) {
        return "Since the bleeding has stopped and you can bear weight without sharp pain, you can start walking out slowly on a known safe route. Turn on battery saver, save your location, and stop if bleeding restarts, pain gets sharp, the knee gives way, or you feel dizzy.";
      }
      if (asksToWalk && bleedingStopped && canBearWeight) {
        return "You can try to walk out gently if there is no sharp pain, numbness, fast swelling, or knee giving way. Before moving, turn on battery saver and save or note your location.";
      }
      if (bleedingStopped) {
        return "Good, the bleeding has stopped. Cover or protect the wound with the cleanest material you have; can you stand or put weight on that leg without sharp pain or the knee giving way?";
      }
      if (fieldNoBandage) {
        return "Use the cleanest fabric you have, such as the inside of a shirt or sock, and press it firmly on the knee. Do not use dirt, leaves, or stream water; is the bleeding slowing or stopped?";
      }
      if (!_hasAny(combined, [
        'breathing is normal',
        'breathing fine',
        'no head injury',
        'no head impact',
        'did not hit my head',
        "didn't hit my head",
      ])) {
        return "Sit somewhere safe off the trail edge if you can. Keep steady pressure on the knee with the cleanest fabric available; did you hit your head, feel dizzy or confused, or have trouble breathing?";
      }
      if (canBearWeight && bleedingNotHeavy && (noSharpPain || noNumbness)) {
        return "Good, the bleeding is not heavy and you can bear weight without those warning signs. Keep the knee protected with your cloth, turn on battery saver, save your location, and walk out slowly on the safest known route.";
      }
      if (canBearWeight && bleedingNotHeavy) {
        return "Good, it does not sound like heavy bleeding and you can bear weight. Keep it protected, then tell me if there is sharp pain, numbness, the knee giving way, or swelling that is getting worse.";
      }
      if (bleedingNotHeavy) {
        return "Keep gentle pressure on the knee for a few more minutes and protect it from dirt. Can you stand or put weight on that leg without sharp pain or the knee giving way?";
      }
      if (_hasAny(combined, ['breathing is normal', 'breathing fine'])) {
        return "Press the cleanest fabric you have firmly on the bleeding knee and keep the leg still. Is the bleeding spurting, soaking through, or not slowing?";
      }
      return "Sit somewhere safe off the trail edge if you can and check for immediate danger first. Did you hit your head, feel dizzy or confused, or have trouble breathing?";
    }

    if (_isBurn(msg) || ctx.contains('burn')) {
      final noBlisters =
          msg.contains('no blister') ||
          msg.contains('no blisters') ||
          ctx.contains('no blisters');
      final alreadyCooled =
          ctx.contains('cooled the burn') ||
          msg.contains('cooled') ||
          msg.contains('running water') ||
          msg.contains('under water');
      final alreadyCovered =
          ctx.contains('covered the burn') || msg.contains('covered');

      if ((msg.contains('red') || ctx.contains('red skin')) && noBlisters) {
        if (alreadyCooled && !alreadyCovered) {
          return "That sounds like a mild surface burn. Cover it loosely with a clean dry cloth or bandage. Do not use ice, butter, or toothpaste. Watch for blisters, numbness, spreading redness, or worsening pain.";
        }
        return "That sounds like a mild surface burn. Cool it under cool running water for 10-20 minutes, then cover it loosely with a clean dry cloth or bandage. Do not use ice, butter, or toothpaste.";
      }

      if (alreadyCooled && !alreadyCovered) {
        return "Now cover the burn loosely with a clean dry cloth or bandage. Do not pop blisters. Is the skin white, black, numb, or getting worse?";
      }

      return "Cool the burn under cool running water for 10-20 minutes. Remove rings or tight items near it. Is the skin only red, or are there blisters, numbness, white skin, or black skin?";
    }

    if (_isAllergy(msg) || ctx.contains('allergic reaction')) {
      final warningSigns =
          msg.contains('trouble breathing') ||
          msg.contains("can't breathe") ||
          msg.contains('wheezing') ||
          msg.contains('swollen lips') ||
          msg.contains('tongue') ||
          msg.contains('throat');
      if (warningSigns) {
        return "This could be a serious allergic reaction. Use an epinephrine auto-injector if available and call emergency services now. Do they have an EpiPen or trouble breathing?";
      }
      return "Watch for trouble breathing or swelling of the lips, tongue, face, or throat. If breathing is normal, send a clear photo of the rash or sting if you can.";
    }

    if (_isStroke(msg) || ctx.contains('stroke')) {
      return "This could be a stroke. Call emergency services now and note the exact time symptoms started or when they were last normal. Keep them resting, do not give food, drink, or aspirin, and tell me if their face droops, one arm is weak, or speech is slurred.";
    }

    if (_isAsthmaOrBreathingEmergency(msg) || ctx.contains('asthma')) {
      return "Help them sit upright and use their prescribed quick-relief inhaler if they have one. Call emergency services now if they cannot speak normally, their lips look blue or gray, or the inhaler is not helping. Are they able to talk in full sentences?";
    }

    if (_isOverdose(msg) || ctx.contains('overdose')) {
      return "Call emergency services now. If they are very sleepy, not waking, breathing slowly, blue or gray, or making gurgling sounds, give naloxone if available. If they are not breathing normally, start CPR if trained. What did they take and when?";
    }

    if (_isCarbonMonoxideOrGas(msg) || ctx.contains('carbon monoxide')) {
      return "Get everyone to fresh air immediately and do not go back inside. Call emergency services or poison control from outside. Carbon monoxide can be deadly without smell or warning. Is anyone unconscious, confused, or having chest pain?";
    }

    if (_isPregnancyEmergency(msg) || ctx.contains('pregnancy')) {
      return "Call emergency services now if there is heavy bleeding, severe belly pain, seizure, fainting, trouble breathing, or birth seems imminent. Keep her warm, private, and clean. Is the baby coming now or are there warning signs?";
    }

    if (_isMentalHealthCrisis(msg) || ctx.contains('mental health crisis')) {
      return "If there is immediate danger, call emergency services now. If you are in the U.S., call or text 988. Stay with the person, speak calmly, and move weapons, pills, or hazards away only if you can do that safely. Are they in immediate danger right now?";
    }

    if (_isPoisoning(msg) || ctx.contains('poisoning')) {
      return "Do not make them vomit. Move away from fumes or chemicals if needed, and tell me what substance it was, how much, and when it happened.";
    }

    if (_isColdExposure(msg) || ctx.contains('hypothermia')) {
      return "Cold exposure with confusion or strong shivering can be serious. Get out of wind and rain, remove wet outer layers only if you can replace them with dry insulation, warm the core gently, and call emergency services if reachable. Are they awake enough to swallow warm sweet drinks?";
    }

    if (_isChokingOrBreathing(msg) || ctx.contains('breathing problem')) {
      return "This is urgent if they cannot breathe, cough, or speak. Call emergency services now if needed, and tell me whether they are conscious and able to cough.";
    }

    if (_isBiteOrSting(msg) || ctx.contains('bite') || ctx.contains('sting')) {
      if (msg.contains('snake')) {
        return "Keep the person still and keep the bite below heart level if possible. Do not cut, suck, or ice it. Tell me where the bite is and whether swelling or trouble breathing has started.";
      }
      return "Wash the bite or sting area with clean water if you can. Send a clear photo if it is safe, and tell me if swelling is spreading, breathing feels hard, or the area is very painful.";
    }

    if ((_isFallOrInjury(msg) || ctx.contains('injury reported')) &&
        !_isBleeding(msg) &&
        !msg.contains('broken') &&
        !msg.contains('fracture')) {
      if (msg.contains('back') || msg.contains('neck')) {
        return "Do not move if your neck or back may be hurt. Call emergency services if there is severe pain, numbness, weakness, or trouble moving. Are you breathing normally?";
      }
      if (msg.contains('swollen') || msg.contains('twisted')) {
        if (ctx.contains('no cold pack') || ctx.contains('lacks: cold pack')) {
          return "Rest the injured area and keep it protected with the cleanest cloth you have. Keep it raised if that is comfortable, and tell me if pain, swelling, numbness, or movement gets worse.";
        }
        return "Keep weight off it and use a cold pack wrapped in cloth. A clear photo can help if there is swelling or a strange shape. Can you move it or put weight on it without sharp pain?";
      }
      return "Keep the injured area still for now. Tell me where it hurts and whether it is swollen, crooked, numb, or hard to move.";
    }

    final lacksWater = _lacks(msg, ['water', 'clean water', 'running water']);
    final lacksBandage = _lacks(msg, ['bandage', 'cloth', 'dressing', 'gauze']);
    final lacksTourniquet = _lacks(msg, ['tourniquet']);
    final lacksSignal = _lacks(msg, [
      'signal',
      'phone',
      'cell',
      'reception',
      'call',
    ]);
    final isAlone = msg.contains('alone') || msg.contains('by myself');
    if (lacksWater &&
        (_isBleeding(msg) || ctx.contains('wound') || ctx.contains('cut'))) {
      return "Without clean water, do not scrub the wound or use unsafe fluids. Apply firm pressure with the cleanest cloth you have, cover it, and keep it protected until clean water or medical help is available. What can you use as a clean covering?";
    }

    if (lacksBandage &&
        (_isBleeding(msg) || ctx.contains('wound') || ctx.contains('cut'))) {
      return "Improvise a bandage. Tear a strip from the INSIDE of a shirt or sock — inside is cleaner. Fold into a thick pad and press firmly onto the wound. Tie snugly with another strip, tight enough to feel resistance but you should still feel a pulse below it. Elevate the limb above heart level. Is the bleeding still active or slowing?";
    }

    if (lacksTourniquet &&
        (msg.contains('bleeding') || msg.contains('blood'))) {
      return "Make a field tourniquet. Cut or tear a strip of clothing AT LEAST 2 inches wide — narrow strips cause more damage. Wrap it twice around the limb 2-3 inches above the wound. Tie a half-knot, place a stick on top, tie another knot over it. Twist until bleeding stops completely then secure it. Note the time. Leave on for up to 2 hours. Has the bleeding slowed?";
    }

    if (_isBleeding(msg) &&
        !lacksBandage &&
        !msg.contains('deep') &&
        !msg.contains('bad')) {
      return "For a minor cut, clean it gently with water if available. Apply pressure with a clean cloth until bleeding stops. Keep it elevated if possible. Cover with a bandage or clean cloth. Keep it dry for 24 hours. If you notice redness, swelling, or pus, seek medical help when possible. Do you have everything you need right now?";
    }

    if (msg.contains('broken') ||
        msg.contains('fracture') ||
        (msg.contains('fell') && msg.contains('wrist'))) {
      return "For a suspected fracture, immobilize the area — don't try to straighten it. Apply ice wrapped in cloth to reduce swelling, but never directly on skin. Keep it elevated. Do not give food or water in case you need surgery. Can you splint it with something firm like a stick or magazine rolled around it? Call your brother and get to urgent care if the pain is severe.";
    }

    if (lacksSignal && !ctx.contains('signal')) {
      return "No signal — try moving to higher ground, even 50 meters can restore a bar. Try SMS first, texts work on weaker signals than calls. Switch to airplane mode between attempts to conserve battery. Do you have anything reflective to signal with if you see a plane or rescuer?";
    }

    if (isAlone && !ctx.contains('alone')) {
      return "Since you're alone, your priorities are: control any active bleeding first, then make yourself visible from above if possible, then conserve body temperature by insulating from the ground. Do not try to walk out if you're injured — staying put is safer. Can you control the bleeding first?";
    }

    if (historyCount > 2 &&
        (msg.contains('lost') ||
            msg.contains('forest') ||
            msg.contains('mountain')) &&
        !(bleedingStopped && canBearWeight && noSharpPain)) {
      return "STAY WHERE YOU ARE. Moving makes rescue 10 times harder. Can you get to high ground? Do you have anything reflective to signal from the air? Keep your phone on for any signal updates.";
    }

    return "Tell me the most urgent problem right now. What do you have available to help — cloth, water, phone signal? The more specific you are about what you need, the faster I can help.";
  }

  static bool _lacks(String msg, List<String> keywords) {
    return keywords.any(
      (kw) =>
          msg.contains('no $kw') ||
          msg.contains("don't have $kw") ||
          msg.contains('dont have $kw') ||
          msg.contains('without $kw') ||
          msg.contains('lost my $kw') ||
          msg.contains("can't use $kw"),
    );
  }

  static bool _hasAny(String text, List<String> keywords) {
    return keywords.any(text.contains);
  }

  static bool _isBackInjury(String msg) {
    return msg.contains('back') ||
        msg.contains('spinal') ||
        msg.contains('neck');
  }

  static bool _isOffTopic(String msg) {
    final asksForEntertainment =
        msg.contains('tell me a joke') ||
        msg.contains('poem') ||
        msg.contains('write a poem') ||
        msg.contains('write me a poem') ||
        msg.contains('sing') ||
        msg.contains('movie recommendation');
    final asksForGeneralKnowledge =
        msg.contains('stock price') ||
        msg.contains('bitcoin') ||
        msg.contains('homework') ||
        msg.contains('essay') ||
        msg.contains('recipe') ||
        msg.contains('who won') ||
        msg.contains('capital of');

    return asksForEntertainment || asksForGeneralKnowledge;
  }

  static bool _isBurn(String msg) {
    return msg.contains('burn') ||
        msg.contains('burned') ||
        msg.contains('burnt') ||
        msg.contains('scald');
  }

  static bool _isBleeding(String msg) {
    return msg.contains('bleed') ||
        msg.contains('blood') ||
        msg.contains('cut') ||
        msg.contains('wound');
  }

  static bool _isFallOrInjury(String msg) {
    return msg.contains('fell') ||
        msg.contains('fall') ||
        msg.contains('twisted') ||
        msg.contains('sprained') ||
        msg.contains('hurt my') ||
        msg.contains('injured') ||
        msg.contains('broken') ||
        msg.contains('fracture');
  }

  static bool _isAllergy(String msg) {
    return msg.contains('allergic') ||
        msg.contains('allergy') ||
        msg.contains('hives') ||
        msg.contains('rash') ||
        msg.contains('bee sting') ||
        msg.contains('wasp sting') ||
        msg.contains('stung');
  }

  static bool _isPoisoning(String msg) {
    return msg.contains('poison') ||
        msg.contains('swallowed') ||
        msg.contains('overdose') ||
        msg.contains('too many pills') ||
        msg.contains('chemical') ||
        msg.contains('bleach') ||
        msg.contains('cleaner');
  }

  static bool _isStroke(String msg) {
    return msg.contains('stroke') ||
        msg.contains('face droop') ||
        msg.contains('slurred') ||
        msg.contains('one side weak') ||
        msg.contains('weak on one side') ||
        msg.contains('trouble speaking');
  }

  static bool _isAsthmaOrBreathingEmergency(String msg) {
    return msg.contains('asthma') ||
        msg.contains('inhaler') ||
        msg.contains('wheezing') ||
        msg.contains('shortness of breath');
  }

  static bool _isOverdose(String msg) {
    return msg.contains('overdose') ||
        msg.contains('naloxone') ||
        msg.contains('narcan') ||
        msg.contains('opioid') ||
        msg.contains('fentanyl') ||
        msg.contains('heroin') ||
        msg.contains('too many pills');
  }

  static bool _isCarbonMonoxideOrGas(String msg) {
    return msg.contains('carbon monoxide') ||
        msg.contains('co alarm') ||
        msg.contains('co detector') ||
        msg.contains('generator indoors') ||
        msg.contains('gas leak') ||
        msg.contains('smell gas');
  }

  static bool _isPregnancyEmergency(String msg) {
    return msg.contains('pregnant') ||
        msg.contains('pregnancy') ||
        msg.contains('labor') ||
        msg.contains('contractions') ||
        msg.contains('water broke') ||
        msg.contains('giving birth');
  }

  static bool _isMentalHealthCrisis(String msg) {
    return msg.contains('suicide') ||
        msg.contains('self harm') ||
        msg.contains('kill myself') ||
        msg.contains('kill himself') ||
        msg.contains('kill herself') ||
        msg.contains('mental health crisis');
  }

  static bool _isChokingOrBreathing(String msg) {
    return msg.contains('choking') ||
        msg.contains('choke') ||
        msg.contains("can't breathe") ||
        msg.contains('cannot breathe') ||
        msg.contains('not breathing') ||
        msg.contains('trouble breathing') ||
        msg.contains('wheezing');
  }

  static bool _isColdExposure(String msg) {
    return msg.contains('hypothermia') ||
        msg.contains('shivering') ||
        msg.contains('freezing') ||
        msg.contains('very cold') ||
        (msg.contains('cold') && msg.contains('wet')) ||
        (msg.contains('rain') && msg.contains('confused'));
  }

  static bool _isBiteOrSting(String msg) {
    return msg.contains('bite') ||
        msg.contains('bit me') ||
        msg.contains('sting') ||
        msg.contains('stung') ||
        msg.contains('snake') ||
        msg.contains('tick');
  }
}
