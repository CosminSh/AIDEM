# AIDEM Gemma 4 Good Hackathon Prize Plan

This document captures the highest-leverage improvements for making AIDEM competitive in the Gemma 4 Good Hackathon. The goal is to position AIDEM as an offline, safety-aware, field-ready Gemma 4 edge system, not just an emergency chatbot.

## 1. The App

### Prize Positioning

Target tracks:

- Global Resilience
- Safety & Trust
- LiteRT / Edge AI
- Health & Sciences as a secondary fit

Core app thesis:

> AIDEM is an offline emergency triage assistant for no-signal environments, combining Gemma 4 edge reasoning with deterministic safety protocols, GPS/location logging, multimodal inputs, and rescue-ready summaries.

### Must-Have Improvements

1. Add a judge-friendly demo mode

   Create one-tap demo scenarios that show the app at its best without requiring judges to invent inputs.

   Suggested scenarios:

   - Lost hiker with ankle injury and no signal
   - Severe bleeding with no first-aid kit
   - Burn injury with image input
   - Hypothermia risk after exposure

2. Make Gemma 4 structurally important

   The app should clearly use Gemma for more than generic chat.

   Strong uses:

   - Extract situation context from messy user input
   - Select or recommend protocol branches
   - Ask safety-critical follow-up questions
   - Convert symptoms, location, and history into a rescue summary
   - Handle multilingual user input while preserving protocol accuracy

3. Add visible safety and trust signals

   Add UI/state markers that make the safety layer obvious.

   Examples:

   - "Protocol-based guidance"
   - "Call emergency services first"
   - "Uncertain: seek professional care"
   - "Why this question matters"
   - "Rescue summary ready"

4. Strengthen rescue handoff

   The rescue summary should be one of the app's strongest screens.

   It should include:

   - Situation summary
   - Timeline of key answers/actions
   - GPS coordinates in decimal and DMS
   - Known hazards
   - Current condition
   - Actions already taken
   - Suggested dispatcher script

5. Make multimodal input matter

   Image capture should influence the workflow in at least one polished demo path.

   The app should:

   - State what it can observe from the image
   - State what it cannot safely infer
   - Ask one targeted follow-up
   - Route to the relevant protocol

6. Add proof of protocol adherence

   Build a small evaluation set of emergency scenarios and expected safety behavior.

   Minimum useful set:

   - 30-50 text scenarios
   - Expected escalation behavior
   - Expected protocol category
   - Forbidden unsafe advice
   - Pass/fail output in the repo

7. Improve offline reliability

   Judges should be able to test without setup pain.

   Priority:

   - Stable Android APK
   - Clear model installation path
   - Demo mode that works even if the model is unavailable
   - Obvious fallback/mock labeling
   - Packaged sample data

### Nice-To-Have Improvements

- Exportable rescue report as Markdown/PDF
- Simple "field kit unavailable" mode for improvised first aid
- Audio/hands-free demo flow
- Clear local privacy indicator
- Post-session review screen for Kaggle video footage

## 2. The Presentation

### Submission Story

The pitch should be emotionally clear and technically credible:

> Someone is injured, offline, panicking, and alone. AIDEM turns chaos into step-by-step action, keeps advice inside first-aid protocols, and creates a clean rescue handoff when help becomes reachable.

Avoid pitching it as:

- A generic survival chatbot
- A medical diagnosis app
- A replacement for rescuers or doctors

### 3-Minute Video Structure

1. Problem, 20-30 seconds

   Show a no-signal emergency: injury, panic, no search, no cloud access.

2. AIDEM in action, 90 seconds

   Show one polished scenario end to end:

   - User describes problem
   - AIDEM extracts context
   - AIDEM asks a critical follow-up
   - Protocol guidance appears
   - GPS/rescue summary is generated

3. Technical credibility, 40 seconds

   Show:

   - Gemma 4 running locally
   - LiteRT / edge deployment
   - Deterministic protocol layer
   - Local-only data flow
   - Multimodal input if ready

4. Impact and close, 20-30 seconds

   End with the human outcome:

   - Stay calm
   - Follow protocol
   - Aid them
   - Hand rescuers a clear timeline

### Kaggle Writeup Must Include

1. Clear problem framing

   Be specific: no-signal emergency first aid and rescue handoff for remote/disaster contexts.

2. Architecture diagram

   Show:

   - User input
   - Safety guard / deterministic protocol layer
   - Gemma 4 reasoning
   - Local knowledge base
   - GPS/image/speech tools
   - Rescue summary output

3. Gemma 4 usage explanation

   Explain exactly where Gemma helps:

   - Language understanding
   - Context extraction
   - Follow-up question generation
   - Summarization
   - Multilingual assistance

4. Safety design

   Include:

   - Not a doctor disclaimer
   - Emergency-service-first policy
   - Protocol constraints
   - Unsafe advice prevention
   - Uncertainty handling

5. Evaluation evidence

   Include the scenario test results:

   - Number of scenarios
   - Pass/fail rate
   - Examples of corrected unsafe paths
   - Known limitations

6. Demo instructions

   Make judge testing simple:

   - APK link
   - Windows package link if included
   - Model setup instructions
   - Demo mode instructions
   - Expected device requirements

### Prize Narrative

Use this framing repeatedly:

- Offline first
- Privacy preserving
- Field ready
- Protocol constrained
- Gemma 4 at the edge
- Built for resilience, not convenience

### Biggest Presentation Risks

- The app looks like a chatbot instead of a safety system
- The video does not show a full end-to-end emergency workflow
- The writeup does not prove Gemma 4 is essential
- Judges cannot easily run the demo
- The medical safety story is underdeveloped

## Immediate Priority Order

1. Build demo mode with 3-4 curated scenarios.
2. Polish rescue summary and dispatcher script screens.
3. Add scenario-based safety/protocol tests.
4. Make one image-input demo path work convincingly.
5. Package Android APK cleanly.
6. Record a tight 3-minute video around one emotional scenario.
7. Write the Kaggle submission around Global Resilience, Safety & Trust, and LiteRT edge AI.
