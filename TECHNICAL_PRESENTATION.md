# AIDEM: Technical Deep Dive
**Architecture, Edge AI, and Deterministic Triage Logic**

---

### Project Overview
**AIDEM** is a next-generation emergency assistant designed for "data-denied" environments. Whether in remote wilderness, after a catastrophic natural disaster, or in a war zone, AIDEM provides critical, life-saving guidance without requiring an internet connection. 

By running Google’s **Gemma** model entirely on-device, the app bridges the gap between the power of Generative AI and the absolute reliability of a physical field manual. Its primary mission is to replace panic with protocol, empowering users to perform high-stakes triage, navigation, and survival techniques using source-backed intelligence.

---

### 1. System Architecture: The Hybrid Expert System
AIDEM utilizes a **Hybrid Architecture** that combines the creative reasoning of Large Language Models (LLMs) with the safety and reliability of a deterministic Decision Tree.

*   **Deterministic Layer**: A structured JSON-based protocol tree (`protocol.json`) that enforces strict safety procedures (e.g., stopping major bleeding before checking for secondary injuries).
*   **Cognitive Layer**: Google’s **Gemma-4-E2B-IT** model, running on-device via **MediaPipe LLM Inference**. This layer provides nuanced explanations, adapts to complex queries, and maintains a "survival companion" persona.

### 2. Core Technology Stack
*   **Framework**: **Flutter** for cross-platform (Windows & Android) performance and high-fidelity UI.
*   **LLM Runtime**: **MediaPipe LLM Inference API**. Optimized for edge performance on mobile and desktop hardware.
*   **Inference Model**: **Gemma-4-E2B-IT (LiteRT)**. Quantized for low-latency, high-accuracy survival guidance.
*   **State Management**: **Riverpod** for robust, reactive session and context management.

### 3. Data & Knowledge Engineering
The system’s intelligence is grounded in two primary datasets:
1.  **`knowledge_base.json`**: A repository of 40+ technical protocols sourced from the **US Army (FM 21-76)**, **FEMA**, **NOAA**, and **Red Cross**.
2.  **`protocol.json`**: A decision-graph representing the triage flow. Each node contains source citations, GPS requirements, and logical branches.

### 4. Advanced Inference Logic
*   **Situational Awareness (`ProtocolService`)**: A mapping service that monitors the user’s position in the decision tree and injects relevant technical context into the LLM’s prompt window.
* ### 🌍 Multi-Language Translation Protocol
One of the core challenges with 2B models is maintaining reasoning consistency across languages. AIDEM solves this via a **Cognitive Bridge**:
- **Internalization**: The model is instructed to process non-English input as English concepts internally.
- **English-Centric Reasoning**: By using English as the "intermediate language" for logic, the AI leverages the highest-quality training data for medical protocols.
- **Native Reconstruction**: The final expert advice is reconstructed in the user's native language (Spanish, Romanian, French, etc.) only at the output stage.

### 🧠 Situation Context Compaction
To avoid the "forgetfulness" of small context windows, AIDEM uses a background **Compactor Service**:
*   **Context Compaction**: To survive the limited context windows of small on-device models, we implement a custom compaction service that prioritizes the **current assessment node**, **active injury data**, and **last 3 turns of history**.
*   **Prompt Hardening**: A strict system prompt architecture that prevents "reassurance loops," eliminates robotic repetition, and enforces an action-oriented communication style.

### 5. Offline-First Challenges & Solutions
*   **Memory Management**: Implemented aggressive resource cleanup for the MediaPipe runtime to prevent memory leaks during long-duration emergency sessions.
*   **Windows Packaging**: Developed a custom bundling script (`bundle_app.ps1`) to organize the LiteRT binaries, model files, and launch scripts into a professional, portable distribution.
*   **Cross-Drive Compilation**: Configured Gradle and CMake to handle non-standard build environments (G:\ vs C:\) ensuring build consistency for contributors.

### 6. Security & Reliability
*   **Local-Only Execution**: Zero telemetry. Zero external API calls. 100% of data stays in the device's RAM.
*   **High Reliability**: By embedding the entire knowledge base locally, the app remains functional in "Airplane Mode" or after catastrophic infrastructure failure.

---
**Technical Lead**: Antigravity AI
**Repository**: CosminSh/AIDEM
