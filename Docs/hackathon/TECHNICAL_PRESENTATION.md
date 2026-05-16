# AIDEM: Technical Deep Dive

**Architecture, Edge AI, and Deterministic Triage Logic**

## Project Overview

**AIDEM** is an emergency assistant designed for data-denied environments. In remote wilderness, disaster aftermath, or other no-signal conditions, AIDEM provides structured guidance without requiring an internet connection.

By running Google's **Gemma** model on-device, the app bridges the flexibility of generative AI with the reliability of a field manual. Its mission is to replace panic with protocol, helping users move through triage, navigation, and survival steps using source-backed guidance.

## 1. System Architecture: Hybrid Expert System

AIDEM combines language reasoning with deterministic safety constraints:

- **Deterministic layer**: a structured JSON protocol graph (`protocol.json`) that enforces critical sequencing, such as addressing life-threatening bleeding before secondary concerns.
- **Cognitive layer**: Google's **Gemma 4 E2B IT** model, running on-device through LiteRT-compatible inference. This layer helps interpret messy input, generate concise explanations, and summarize session context.

## 2. Core Technology Stack

- **Framework**: Flutter for Android and Windows hackathon demo targets.
- **LLM runtime**: LiteRT / `flutter_gemma` for local model execution.
- **Inference model**: Gemma 4 E2B IT LiteRT model.
- **State management**: Riverpod for reactive session and app state.
- **Local tools**: GPS capture, image input, voice dictation, text-to-speech, and local emergency-number data.

## 3. Data And Knowledge Engineering

The system's intelligence is grounded in two local datasets:

1. **`knowledge_base.json`**: 155 local guidance entries sourced from established first-aid, disaster, and wilderness-survival guidance families.
2. **`protocol.json`**: 166 deterministic protocol nodes. Each node includes source citations, GPS context flags where relevant, and explicit branch targets.

## 4. Advanced Inference Logic

- **Situational awareness (`ProtocolService`)**: monitors the user's position in the decision graph and injects relevant technical context into the prompt window.
- **Multilingual handling**: the prompt asks Gemma to interpret non-English input while preserving the protocol logic, then respond in the user's language when appropriate.
- **Context compaction**: the app keeps emergency-relevant facts, the current assessment node, active injury data, and recent turns available within the small local model context window.
- **Prompt hardening**: safety prompts prevent off-topic drift, unsupported diagnosis, repeated reassurance loops, and long unstructured medical responses.

## 5. Offline-First Challenges And Solutions

- **Memory management**: model setup and service code use explicit fallback paths when GPU initialization is unavailable.
- **Windows packaging**: `scripts/bundle_app.ps1` organizes LiteRT binaries, model-folder placement, and launcher scripts into a portable distribution.
- **Portable path handling**: packaging and model discovery resolve paths relative to the app or OS-provided directories, so contributors are not tied to a specific drive or local machine layout.

## 6. Security And Reliability

- **Local-only execution**: emergency context is processed on-device.
- **Auditable guidance**: critical workflow steps come from local protocol data rather than free-form generation alone.
- **Graceful degradation**: practice scenarios and structured protocol flows remain usable when the local model is unavailable.

**Technical Lead**: Antigravity AI

**Repository**: CosminSh/AIDEM
