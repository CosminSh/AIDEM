import 'context_compaction_service.dart';

class ConversationGuard {
  static bool _hasAny(String text, List<String> values) {
    return values.any(text.contains);
  }

  static bool looksLikeExtractionJson(String response) {
    final trimmed = response.trim();
    return trimmed.startsWith('{') &&
        trimmed.endsWith('}') &&
        trimmed.contains('"summary"') &&
        trimmed.contains('"incident_type"');
  }

  static bool repeatsLastQuestion({
    required String previousAiMessage,
    required String response,
  }) {
    if (previousAiMessage.trim().isEmpty || response.trim().isEmpty) {
      return false;
    }

    String normalize(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ?]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final previous = normalize(previousAiMessage);
    final current = normalize(response);
    if (previous == current) return true;

    final repeatedBleedingCheck =
        previous.contains('soaking through') &&
        previous.contains('not slowing') &&
        current.contains('soaking through') &&
        current.contains('not slowing');
    if (repeatedBleedingCheck) return true;

    final repeatedHeavyBleedingCheck =
        previous.contains('bleeding') &&
        previous.contains('heavy') &&
        current.contains('bleeding') &&
        current.contains('heavy');
    if (repeatedHeavyBleedingCheck) return true;

    final rawQuestions = RegExp(
      r'([^?.!]+\?)',
    ).allMatches(previousAiMessage).map((m) => m.group(1) ?? '').toList();
    final previousQuestion = rawQuestions.isEmpty
        ? null
        : normalize(rawQuestions.last).replaceAll('?', '').trim();
    return previousQuestion != null &&
        previousQuestion.length > 12 &&
        current.contains(previousQuestion);
  }

  static bool isTooLongOrArticleStyle(String response) {
    final trimmed = response.trim();
    if (trimmed.length > 520) return true;
    final lineCount = '\n'.allMatches(trimmed).length + 1;
    if (lineCount > 5) return true;
    final lower = trimmed.toLowerCase();
    return lower.contains('###') ||
        lower.contains('**') ||
        lower.contains('1.') ||
        lower.contains('2.') ||
        lower.contains('immediate first aid steps') ||
        lower.contains('how to signal for help') ||
        lower.contains('what to do when help arrives');
  }

  static bool skipsInitialFieldTriage({
    required SituationContext ctx,
    required String response,
  }) {
    final facts = ctx.answeredFacts.join(' ').toLowerCase();
    final injury = ctx.injuryType?.toLowerCase() ?? '';
    final lacks = ctx.confirmedLacks.join(' ').toLowerCase();
    final noSignal =
        facts.contains('no phone signal') || lacks.contains('signal');
    final fieldLegInjury =
        injury.contains('knee') ||
        injury.contains('ankle') ||
        injury.contains('leg') ||
        facts.contains('injury is on the knee');
    final bleedingMentioned =
        facts.contains('cut is bleeding') || facts.contains('bleeding');
    final dangerSignsKnown =
        facts.contains('breathing is normal') ||
        facts.contains('no head injury') ||
        facts.contains('no head impact') ||
        facts.contains('dizziness') ||
        facts.contains('confusion');
    final lower = response.toLowerCase();
    final asksDangerSigns =
        lower.contains('head') ||
        lower.contains('dizzy') ||
        lower.contains('confused') ||
        lower.contains('breathing');

    return noSignal &&
        fieldLegInjury &&
        bleedingMentioned &&
        !dangerSignsKnown &&
        !asksDangerSigns;
  }

  static bool asksAnsweredFact({
    required SituationContext ctx,
    required String response,
  }) {
    final facts = ctx.answeredFacts.join(' ').toLowerCase();
    final lacks = ctx.confirmedLacks.join(' ').toLowerCase();
    final lower = response.toLowerCase();
    final noSharpPain = _hasAny(facts, [
      'no sharp pain',
      'pain is mild and not sharp',
    ]);
    final noNumbness = _hasAny(facts, ['no numbness', 'not numb']);
    final noDeformity = _hasAny(facts, [
      'no crooked shape',
      'normal shape',
      'no deformity',
    ]);
    final moderateOrMildPain = _hasAny(facts, [
      'pain is moderate',
      'pain is mild',
      'no sharp pain',
    ]);
    final controlledBleeding =
        facts.contains('bleeding has stopped') ||
        facts.contains('bleeding is not heavy') ||
        facts.contains('bleeding is almost stopped') ||
        facts.contains('bleeding is slowing');
    final stableSwelling =
        facts.contains('swelling is not getting worse') ||
        facts.contains('no swelling') ||
        facts.contains('symptoms are improving');
    final canBearWeight = facts.contains('can stand or bear weight');
    final asksWeight =
        lower.contains('put weight') ||
        lower.contains('bear weight') ||
        lower.contains('can you walk') ||
        lower.contains('can you stand');
    final asksSharpOrNumb =
        lower.contains('sharp pain') ||
        lower.contains('numbness') ||
        lower.contains('numb');
    final asksDeformity =
        lower.contains('crooked') ||
        lower.contains('deformity') ||
        lower.contains('deformed') ||
        lower.contains('normal shape');
    final asksSeverePain = lower.contains('severe pain');
    final asksBleeding =
        lower.contains('bleeding') &&
        (lower.contains('still') ||
            lower.contains('slowing') ||
            lower.contains('coming on') ||
            lower.contains('coming'));
    final asksSwelling =
        lower.contains('swelling') &&
        (lower.contains('worse') || lower.contains('getting'));
    final suggestsColdPack =
        lower.contains('cold pack') || lower.contains('ice');
    final avoidWeight =
        lower.contains('avoid putting weight') ||
        lower.contains('avoid weight') ||
        lower.contains('keep weight off');
    final stalePressure =
        controlledBleeding &&
        lower.contains('keep') &&
        (lower.contains('pressure') || lower.contains('pressing'));

    if (asksWeight && facts.contains('can stand or bear weight')) return true;
    if (avoidWeight && canBearWeight) return true;
    if (asksBleeding && controlledBleeding) return true;
    if (stalePressure) return true;
    if (asksSwelling && stableSwelling) return true;
    if (asksSharpOrNumb && (noSharpPain || noNumbness)) return true;
    if (asksDeformity && noDeformity) return true;
    if (asksSeverePain && moderateOrMildPain) return true;
    if (suggestsColdPack &&
        (facts.contains('no cold pack') || lacks.contains('cold pack'))) {
      return true;
    }
    return false;
  }

  static String fallbackResponseForContext(SituationContext ctx) {
    final facts = ctx.answeredFacts.join(' ').toLowerCase();
    final incident = ctx.incidentType.toLowerCase();
    final injury = ctx.injuryType?.toLowerCase() ?? '';
    final lacks = ctx.confirmedLacks.join(' ').toLowerCase();
    final noSignal =
        facts.contains('no phone signal') || lacks.contains('signal');
    final controlledBleeding =
        facts.contains('bleeding has stopped') ||
        facts.contains('bleeding is not heavy') ||
        facts.contains('bleeding is almost stopped') ||
        facts.contains('bleeding is slowing');
    final bleedingStoppedOrNearly =
        facts.contains('bleeding has stopped') ||
        facts.contains('bleeding is almost stopped');
    final canBearWeight = facts.contains('can stand or bear weight');
    final cannotBearWeight =
        facts.contains('cannot stand') || facts.contains('cannot bear weight');
    final noSharpPain = _hasAny(facts, [
      'no sharp pain',
      'pain is mild and not sharp',
    ]);
    final positiveSharpPain =
        _hasAny(facts, ['sharp pain', 'severe pain']) && !noSharpPain;
    final noNumbness = _hasAny(facts, ['no numbness', 'not numb']);
    final positiveNumbness =
        _hasAny(facts, ['numbness or tingling', 'cannot feel']) && !noNumbness;
    final noDeformity = _hasAny(facts, [
      'no crooked shape',
      'normal shape',
      'no deformity',
    ]);
    final positiveDeformity =
        _hasAny(facts, ['possible broken bone', 'bone sticking out']) &&
        !noDeformity;
    final stableSwelling =
        facts.contains('swelling is not getting worse') ||
        facts.contains('no swelling') ||
        facts.contains('symptoms are improving');
    final noColdPack =
        facts.contains('no cold pack') || lacks.contains('cold pack');
    final dangerSignsKnown =
        facts.contains('breathing is normal') ||
        facts.contains('no head injury') ||
        facts.contains('no head impact') ||
        facts.contains('dizziness') ||
        facts.contains('confusion');
    final fieldLegInjury =
        injury.contains('knee') ||
        injury.contains('ankle') ||
        injury.contains('leg') ||
        facts.contains('injury is on the knee') ||
        facts.contains('environment is a forest or trail');

    if (incident.contains('radiation') ||
        incident.contains('contamination') ||
        facts.contains('radioactive') ||
        facts.contains('hazardous dust') ||
        facts.contains('unknown dust')) {
      return 'Move away from the dust and keep others away. Call emergency services or hazmat/poison control if reachable; remove contaminated outer clothing if safe, seal it in a bag, and wash exposed skin gently with soap and water.';
    }

    if (noSignal && fieldLegInjury && !dangerSignsKnown) {
      return 'Sit somewhere safe off the trail edge if you can. Keep steady pressure on the knee with the cleanest fabric available; did you hit your head, feel dizzy or confused, or have trouble breathing?';
    }

    if (noSignal &&
        controlledBleeding &&
        fieldLegInjury &&
        !bleedingStoppedOrNearly) {
      return 'Keep steady pressure with the cleanest fabric you have and keep dirt out of the wound. Tell me when the bleeding stops, or if it starts soaking through.';
    }

    if (noSignal &&
        controlledBleeding &&
        fieldLegInjury &&
        !canBearWeight &&
        !cannotBearWeight &&
        (noSharpPain || noNumbness || stableSwelling)) {
      return 'Before walking home, test only a few careful steps while holding support if you can. Can you bear weight on the knee without it giving way or pain suddenly worsening?';
    }

    if (noSignal &&
        controlledBleeding &&
        canBearWeight &&
        fieldLegInjury &&
        (noSharpPain || noNumbness)) {
      return 'Since the bleeding is controlled and you can bear weight, you can walk out slowly on a known safe route if there is no sharp pain, numbness, fast swelling, or knee giving way. Turn on battery saver, save your location, and stop if symptoms worsen.';
    }

    if (noSignal &&
        controlledBleeding &&
        canBearWeight &&
        fieldLegInjury &&
        stableSwelling) {
      return 'You can try walking back slowly on the safest known route. Turn on battery saver, save your location, keep the knee covered, and stop if bleeding restarts, pain gets sharp, the knee gives way, or you feel dizzy.';
    }

    if (noSignal && controlledBleeding && canBearWeight && fieldLegInjury) {
      return 'Good, you can bear weight and the bleeding does not sound heavy. Keep the knee protected with your cloth; do you feel sharp pain, numbness, or the knee giving way when you take a few careful steps?';
    }

    if (incident.contains('burn')) {
      final noBlisters = facts.contains('no blisters');
      final red = facts.contains('red');
      final pain = positiveSharpPain
          ? 'Sharp pain can still happen with a small burn.'
          : facts.contains('dull pain')
          ? 'Dull pain with red skin is usually less concerning.'
          : 'Pain is expected with a small burn.';

      if (red && noBlisters) {
        return '$pain Cool it under running water for 10-20 minutes if you have not already, then cover it loosely with a clean dry cloth. You can send a clear photo if you are unsure what it looks like; tell me if blisters appear, the skin turns numb or white, or the redness spreads.';
      }
      return 'Cool the burn under running water for 10-20 minutes and remove tight items near it if you can. If it is safe, send a clear photo or tell me whether the skin is red only, blistered, numb, white, or black.';
    }

    if (incident.contains('cut') ||
        incident.contains('bleed') ||
        injury.contains('cut')) {
      final stopped =
          facts.contains('bleeding has stopped') ||
          facts.contains('not bleeding anymore');
      final controlled =
          stopped ||
          facts.contains('bleeding is almost stopped') ||
          facts.contains('bleeding is slowing') ||
          facts.contains('bleeding is not heavy');

      if (stopped) {
        return 'Good, the bleeding has stopped. Rinse the cut with clean running water, pat around it dry, then cover it with a clean bandage. If you can, send a clear photo; is the cut deep or gaping, or does the area feel numb?';
      }
      if (controlled) {
        return 'Good, it does not sound like heavy bleeding. Keep gentle pressure for a few more minutes. When it stops, rinse it with clean running water, then send a photo if you can or tell me if the cut is deep, gaping, dirty, or numb.';
      }
      return 'Keep firm pressure on the cut with a clean cloth for a few minutes. Tell me if the bleeding is soaking through the cloth or not slowing down.';
    }

    if (incident.contains('choking') || incident.contains('breathing')) {
      if (facts.contains('not breathing') ||
          facts.contains('cannot cough or speak')) {
        return 'This is urgent. Call emergency services now if you can. If the person cannot breathe, cough, or speak, start choking first aid and tell me whether they are conscious.';
      }
      return 'Stay with the person and keep them upright if breathing is hard. Tell me if they can speak or cough normally.';
    }

    if (incident.contains('allergic')) {
      if (facts.contains('warning sign') ||
          facts.contains('trouble breathing') ||
          facts.contains('swelling')) {
        return 'This could be a serious allergic reaction. Use an epinephrine auto-injector if available and call emergency services now. Do they have an EpiPen or trouble breathing?';
      }
      return 'Watch closely for lip, tongue, face, or throat swelling, wheezing, or trouble breathing. If it is only a skin rash and breathing is normal, tell me what changed and whether they have allergy medicine.';
    }

    if (incident.contains('poison')) {
      if (facts.contains('unconscious') || facts.contains('not breathing')) {
        return 'Call emergency services now. Do not give food, drink, or make them vomit. Tell me what they swallowed or breathed in, if you know.';
      }
      return 'Do not make them vomit. Move away from fumes or chemicals if needed, and tell me what substance it was, how much, and when it happened.';
    }

    if (incident.contains('bite') || incident.contains('sting')) {
      if (facts.contains('snake bite')) {
        return 'Keep the person still and keep the bite below heart level if possible. Do not cut, suck, or ice it. Tell me where the bite is and whether there is swelling or trouble breathing.';
      }
      return 'Wash the bite or sting area with clean water if you can. Send a clear photo if it is safe, and tell me if swelling is spreading, breathing feels hard, or the area is very painful.';
    }

    if (incident.contains('injury') ||
        incident.contains('fall') ||
        incident.contains('fracture') ||
        incident.contains('sprain') ||
        injury.contains('injury')) {
      if (positiveDeformity || cannotBearWeight || positiveNumbness) {
        return 'Keep the injured area still and avoid putting weight on it. If you can, send a clear photo, and tell me whether there is numbness, a crooked shape, or severe pain.';
      }
      if (facts.contains('swelling') ||
          facts.contains('movement is possible')) {
        if (noColdPack) {
          return 'Rest the injured area and keep it protected with the cleanest cloth you have. Keep it raised if that is comfortable; tell me if pain, swelling, numbness, or movement gets worse.';
        }
        return 'Rest the injured area, use a cold pack wrapped in cloth, and keep it raised if that is comfortable. A clear photo can help; can you put weight on it or move it without sharp pain?';
      }
      return 'Keep the injured area still for now. Tell me where it hurts and whether it is swollen, crooked, numb, or hard to move.';
    }

    if (incident.contains('survival') ||
        incident.contains('lost') ||
        incident.contains('exposure')) {
      return 'Stay where you are if it is safe, conserve phone battery, and get out of immediate danger first. Tell me your biggest problem right now: injury, cold or heat, water, shelter, or signal.';
    }

    return 'Got it. Tell me what changed now, and I will move to the next safe step.';
  }
}
