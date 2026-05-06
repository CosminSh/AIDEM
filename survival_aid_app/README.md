# AIDEM App Module 📱

This is the main Flutter implementation of **AIDEM**, an offline emergency assistant powered by on-device LLMs.

## 🚀 Features in this Module
- **Offline LLM Integration**: Full implementation of MediaPipe GenAI for Gemma inference.
- **Triage Logic**: Deterministic protocol state machine for emergency assessments.
- **Dynamic Context**: Situational awareness that adapts LLM prompts based on triage progress.
- **Resource Management**: Optimized for low-memory environments and airplane-mode reliability.

## 🛠️ Development Setup

### Platform Specifics
- **Windows**: Requires Visual Studio 2022 with C++ desktop development workload.
- **Android**: Requires NDK and CMake. Ensure the device supports GLES3 or Vulkan for optimal inference speeds.

### Model Integration
The app looks for models in the following priority:
1.  **Saved Path**: Previously used model location.
2.  **Portable Path**: `models/` directory relative to the executable.
3.  **Assets Path**: `Assets/Models/gemma-4-E2B-it.litertlm`

### Build Commands
```bash
# Debug run
flutter run

# Build Windows Release (bundled)
./scripts/bundle_app.ps1 # Custom script for portable distribution

# Build Android App Bundle
flutter build appbundle
```

## 📂 Structure
- `lib/services/llm_service.dart`: Interface for model communication.
- `lib/services/protocol_service.dart`: The deterministic triage engine.
- `lib/providers/`: Riverpod state management.
- `assets/protocols/`: JSON definitions for medical and survival protocols.

---
For the full project overview, architecture, and vision, see the [Main Project README](../README.md).
