import 'protocol.dart';

class DemoTurn {
  final MessageAuthor author;
  final String text;

  const DemoTurn({required this.author, required this.text});
}

class DemoScenario {
  final String id;
  final String title;
  final String subtitle;
  final String currentNodeId;
  final String situationSummary;
  final List<String> tags;
  final List<DemoTurn> turns;

  const DemoScenario({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.currentNodeId,
    required this.situationSummary,
    required this.tags,
    required this.turns,
  });

  List<ChatMessage> toChatMessages() {
    final base = DateTime.now().subtract(Duration(minutes: turns.length));

    return [
      for (var i = 0; i < turns.length; i++)
        ChatMessage(
          text: turns[i].text,
          author: turns[i].author,
          timestamp: base.add(Duration(minutes: i)),
        ),
    ];
  }
}

const demoScenarios = [
  DemoScenario(
    id: 'lost_hiker_ankle',
    title: 'Lost hiker',
    subtitle: 'Ankle injury, no signal, alone',
    currentNodeId: 'lost_protocol',
    situationSummary:
        'Lost hiker, alone, possible ankle sprain, no cell signal, needs location-safe rescue plan.',
    tags: ['GPS', 'Injury', 'No signal'],
    turns: [
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            '[DEMO MODE] Protocol-based guidance is active. If emergency services are reachable, call them first. What happened and are you in immediate danger?',
      ),
      DemoTurn(
        author: MessageAuthor.user,
        text:
            'I slipped off a trail, my ankle is swelling, I am alone, and I do not have signal.',
      ),
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            'You are alone with a possible ankle injury and no signal. Do not keep walking unless there is immediate danger. Sit, protect the ankle, note your surroundings, and conserve battery. Can you safely share GPS from the location button?',
      ),
    ],
  ),
  DemoScenario(
    id: 'severe_bleeding_no_kit',
    title: 'Severe bleeding',
    subtitle: 'No kit, improvised pressure control',
    currentNodeId: 'bleeding_protocol',
    situationSummary:
        'Severe bleeding, no first-aid kit, needs direct pressure and escalation guidance.',
    tags: ['Bleeding', 'No kit', 'Urgent'],
    turns: [
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            '[DEMO MODE] Protocol-based guidance is active. Call emergency services first if you can. Tell me the injury and whether bleeding is heavy or spurting.',
      ),
      DemoTurn(
        author: MessageAuthor.user,
        text:
            'Deep cut on my forearm, blood is coming fast. I do not have a first-aid kit.',
      ),
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            'Treat this as severe bleeding. Apply firm direct pressure with the cleanest cloth available and do not keep checking the wound. If blood soaks through, add more cloth on top. Keep the limb still and tell me: is the bleeding slowing after continuous pressure?',
      ),
    ],
  ),
  DemoScenario(
    id: 'burn_image_path',
    title: 'Burn assessment',
    subtitle: 'Image-assisted safety triage',
    currentNodeId: 'burn_protocol',
    situationSummary:
        'Thermal burn on hand, image-assisted triage, needs cooling, coverage, and uncertainty handling.',
    tags: ['Image', 'Burn', 'Follow-up'],
    turns: [
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            '[DEMO MODE] You can attach a burn photo. I can describe visible signs, but I cannot diagnose depth from an image alone.',
      ),
      DemoTurn(
        author: MessageAuthor.user,
        text:
            'I burned my hand on a stove and attached a photo. The skin is red with some blistering.',
      ),
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            'From the description/photo path, this may involve blistering. Cool the burn under clean cool running water for 20 minutes if available. Do not use ice or butter. Remove rings if safe. Is the burn larger than the patient palm, on the face/genitals, or from chemicals/electricity?',
      ),
    ],
  ),
  DemoScenario(
    id: 'hypothermia_exposure',
    title: 'Hypothermia risk',
    subtitle: 'Cold exposure after rain',
    currentNodeId: 'hypothermia_protocol',
    situationSummary:
        'Cold exposure after rain, shivering, wet clothing, needs shelter, insulation, and gentle rewarming.',
    tags: ['Cold', 'Shelter', 'Monitor'],
    turns: [
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            '[DEMO MODE] Protocol-based guidance is active. Describe the temperature, clothing, and symptoms.',
      ),
      DemoTurn(
        author: MessageAuthor.user,
        text:
            'We got soaked in rain. My friend is shivering hard and getting confused.',
      ),
      DemoTurn(
        author: MessageAuthor.ai,
        text:
            'Confusion with cold exposure can be serious. Move them out of wind/rain, remove wet outer layers if you can replace them with dry insulation, protect the head/neck, and handle gently. Do not give alcohol. Are they awake enough to swallow warm sweet drinks?',
      ),
    ],
  ),
];
