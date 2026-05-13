import 'context_compaction_service.dart';

class ConversationGuard {
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

  static String fallbackResponseForContext(SituationContext ctx) {
    final facts = ctx.answeredFacts.join(' ').toLowerCase();
    final incident = ctx.incidentType.toLowerCase();
    final injury = ctx.injuryType?.toLowerCase() ?? '';

    if (incident.contains('burn')) {
      final noBlisters = facts.contains('no blisters');
      final red = facts.contains('red');
      final pain = facts.contains('sharp pain')
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
      if (facts.contains('possible broken bone') ||
          facts.contains('cannot stand') ||
          facts.contains('numbness')) {
        return 'Keep the injured area still and avoid putting weight on it. If you can, send a clear photo, and tell me whether there is numbness, a crooked shape, or severe pain.';
      }
      if (facts.contains('swelling') ||
          facts.contains('movement is possible')) {
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
