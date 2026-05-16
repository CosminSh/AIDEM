# AIDEM Flutter App

This directory contains the main Flutter implementation of AIDEM, an offline emergency assistant powered by on-device Gemma reasoning and deterministic safety protocols.

## Main Capabilities

- Local Gemma 4 LiteRT model setup and inference through `flutter_gemma`.
- Protocol-constrained emergency guidance.
- Practice/demo scenarios for judging and training.
- Voice dictation, text-to-speech, image input, GPS capture, and rescue handoff summaries.
- Local protocol, knowledge-base, and emergency-number assets.
- Fallback/demo behavior when the local model is unavailable.

## Important Files

```text
lib/services/llm_service.dart                 Gemma prompt and inference service
lib/services/model_setup_service.dart         Local model install/selection flow
lib/services/conversation_guard_service.dart  Safety and repetition guardrails
lib/services/protocol_service.dart            Protocol loading and routing
lib/providers/session_provider.dart           Active session state and handoff export
assets/data/protocol.json                     Deterministic emergency protocol graph
assets/data/knowledge_base.json               Expanded local guidance text
assets/data/emergency_numbers.json            Local emergency-number database
test/protocol_adherence_eval_test.dart        Safety scenario evaluation set
```

## Development Setup

Requirements:

- Flutter SDK
- Android SDK for Android builds
- Visual Studio 2022 with C++ desktop workload for Windows builds

Install dependencies:

```bash
flutter pub get
```

Run:

```bash
flutter run -d windows
flutter run -d android
```

Test:

```bash
flutter test
dart analyze
```

## Model Setup

AIDEM looks for a local model in the following order:

1. The previously selected model path.
2. A portable `models/` directory beside the executable.
3. Bundled app model assets if present.

For the full hackathon demo, use the recommended Gemma 4 E2B IT LiteRT `.litertlm` model through the first-run setup screen.

## Release Packaging

Android:

```bash
flutter build apk --release
```

Windows:

```bash
flutter build windows --release
```

The helper script `scripts/bundle_app.ps1` can assemble local Android and Windows packages under the repository-level `Releases/` directory. The script resolves paths relative to its own location so it can run from any checkout path.

## Safety Note

AIDEM is emergency decision support, not a medical professional. The app prioritizes emergency services whenever reachable, avoids diagnosis, and keeps advice inside protocol and uncertainty boundaries.
