# AIDEM Conversation QA Protocol

Use this protocol after changes to the emergency conversation flow, prompts, context extraction, quick replies, or offline LLM guardrails.

## Automated Gate

From `aidem_app`, run:

```powershell
flutter test test/active_session_screen_test.dart test/context_compaction_service_test.dart test/conversation_guard_service_test.dart test/adaptive_mock_test.dart test/scenario_rules_test.dart
```

This checks:

- yes/no buttons appear only for real yes/no questions
- user answers become remembered facts
- completed care is recorded only when the user confirms doing it
- extraction JSON is blocked from chat
- repeated questions fall back to a safer next step
- cut conversations do not conclude too early after light or slowing bleeding
- fall, allergy, poisoning, and other non-cut situations keep useful facts instead of generic "previous question" notes
- visible injuries can prompt for photos after urgent care is underway

## Manual Transcript Checks

Run these in the app after a Windows build when possible. The expected result is conversational, not list-based.

### Finger Burn, Mild

User: `i burned my finger while cooking`

Expected assistant behavior:

- asks what the user can see or feel, not burn-degree labels
- accepts `red, no blisters` as answered
- does not ask about blisters again unless symptoms change
- gives cooling/covering advice in plain language
- shows yes/no quick replies only for true yes/no questions

Regression inputs:

- `the burned area is red, no blisters`
- `dull pain`
- `and after that?`

Must not say:

- `blanching`
- `first, second, or third degree`
- `Does the pain feel sharp or dull?` after the user answered sharp/dull

### Finger Cut, Light Bleeding

User: `i cut my finger while cooking`

Expected assistant behavior:

- asks or advises about bleeding first
- accepts `it's not bleeding that bad` as "bleeding is not heavy"
- does not repeat `Is the bleeding still heavy?`
- gathers one more useful detail before concluding: deep/gaping, numbness, dirt, or whether it can be cleaned/covered

Regression inputs:

- `it's not bleeding that bad`
- `the bleeding almost stopped`
- `it's not bleeding anymore. what now?`

Must not do:

- jump straight to final warnings without asking about wound depth or numbness
- repeat firm-pressure instructions after the user says bleeding stopped
- show protocol option lists

### Guardrail Checks

If the model outputs a JSON extraction object, the app should replace it with a normal assistant response.

If the model repeats its last question, the app should replace it with the next useful first-aid step based on remembered facts.

### General Injury

User: `i fell and twisted my ankle`

Expected assistant behavior:

- keeps weight off the injured area before asking details
- remembers swelling, movement, numbness, deformity, and weight-bearing answers
- asks for a clear photo if swelling or strange shape would help, after immediate safety advice
- does not decide "minor sprain" before checking movement, feeling, and ability to bear weight

Regression inputs:

- `it is swollen but i can move it`
- `i can stand but it hurts`

### Allergy Or Sting

User: `a bee stung me and now i have a rash`

Expected assistant behavior:

- checks breathing and swelling of lips, tongue, face, or throat
- treats swelling or breathing trouble as urgent
- asks about an EpiPen when warning signs are present
- asks for a rash/sting photo only after breathing danger is addressed

Regression inputs:

- `my lips are swelling`
- `i have an epipen`

### Poisoning Or Chemical Exposure

User: `my kid swallowed cleaner`

Expected assistant behavior:

- says not to make them vomit
- asks what substance, how much, and when
- checks awake/breathing status
- does not mark "do not make them vomit" as completed care just because the user answers with symptoms

Regression inputs:

- `he is vomiting but awake`
