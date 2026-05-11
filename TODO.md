# Project Tracking: AIDEM Offline Emergency Assistant
> Target: Gemma 4 Good Hackathon · May 18, 2026 · Track: Global Resilience

---

## 1. ⚙️ Environment & Setup
- [x] Install Node.js (v24+)
- [x] Install Flutter SDK to `G:\flutter` (downloading)
- [x] Project structure planned (UI, Data, Services, Core, Providers)
- [x] Run `flutter create survival_aid_app --org com.survivalaid`
- [x] Configure `pubspec.yaml`:
  - [x] Add `flutter_riverpod` (state management)
  - [x] Add `geolocator` (offline GPS)
  - [x] Add `speech_to_text` (voice input)
  - [x] Add `camera` (wound image capture)
  - [x] Add `sqflite` + `path_provider` (session logging)
  - [x] Add `google_fonts` (Inter typeface)
  - [x] Declare asset folders: `assets/data/`, `assets/models/`, `assets/images/`
- [x] Add `G:\Antigravity Projects\AIDEM\Assets\Models\gemma-2b-it-gpu-int4.bin` to assets
- [x] Run `flutter pub get` and verify no dependency conflicts
- [x] Confirm app launches on Android emulator (`flutter run`)
- [x] Confirm app launches on Windows Desktop (`flutter run -d windows`)

---

## 2. 🧠 Core Data & Protocol Logic
- [x] Protocol JSON schema designed (`id`, `question`, `source`, `branches`, `gps_context`)
- [x] Global emergency numbers database (`emergency_numbers.json`, 190+ countries)
- [x] `ProtocolNode` and `Branch` data models (Dart)
- [x] `ChatMessage` model with `MessageAuthor` enum
- [x] `ProtocolService` — load JSON, traverse tree, get node by ID
- [x] `EmergencyNumberService` — country lookup with 112 fallback
- [x] `GpsService` — decimal coords, DMS conversion, phonetic format
- [x] `RescueScriptService` — phonetic rescue script generator
- [x] Implement `SessionLogService` for SQLite logging (stubs)
- [x] Expand `protocol.json` with full decision tree:
  - [x] Root node: "Can you reach emergency services?" → YES / NO branches
  - [x] YES branch → Rescue Script flow (GPS + call script)
  - [x] NO branch → Triage: "Are you or someone with you injured?"
  - [x] Injury branch → Wound Assessment sub-tree:
    - [x] Bleeding control (tourniquet, direct pressure) — source: TCCC
    - [x] Burns — source: Red Cross
    - [x] Fractures / immobilization — source: Red Cross WFA
    - [x] Hypothermia / cold exposure — source: FEMA/Ready.gov
    - [x] Allergic reaction / anaphylaxis — source: WHO
    - [x] Concussion / head injury — source: Red Cross WFA
    - [x] Spinal injury precautions — source: Red Cross WFA
  - [x] Lost / No injury branch → Navigation / signaling sub-tree:
    - [x] Signal rescuers (whistle, mirror, fire) — source: NASAR
    - [x] Shelter priority (stay vs. move decision) — source: NASAR
    - [x] Water sourcing decision — source: Red Cross WFA
    - [x] Night/weather survival decisions — source: FEMA
    - [x] Choking & Drowning (CPR) — source: Red Cross
    - [x] Frostbite & Ticks — source: Red Cross / CDC
    - [x] Vehicle Survival — source: NPS
  - [x] Add `gps_context: true` flag to all relevant nodes
  - [x] Add `source` citation to every node
  - [x] Add `media` image paths where diagrams exist (tourniquet, pressure points)
- [x] Simple JSON session persistence (implemented)
- [x] JSON context compaction (implemented)

---

## 3. 🤖 Offline AI Integration (Gemma)
- [x] Gemma 2B GPU INT4 model downloaded by user
- [x] `LlmService` stub (stream-based inference, mock output)
- [x] `PromptManager` (strict system persona, RAG context injection)
- [x] Finalize MediaPipe / LiteRT plugin integration:
  - [x] Add `flutter_gemma` to `pubspec.yaml`
  - [x] Automatic model discovery on first launch
  - [x] Initialize `LlmInferenceEngine` with `.litertlm` model
  - [x] Set `maxTokens: 2048`, `preferredBackend: gpu`
  - [x] Implement streaming token-by-token response (`generateResponseStream`)
- [x] Connect `LlmService` to `PromptManager`:
  - [x] Inject current node text + source into every prompt
  - [x] Implement "refuse off-topic" logic
  - [x] Handle multimodal context history (remembers images)
- [x] Wound image triage (Gemma multimodal):
  - [x] Camera capture/gallery upload in chat
  - [x] Send image bytes + text prompt to Gemma
  - [x] Parse response and provide visual-first feedback
- [x] LLM status indicator (Ready / Loading / Mock / Error)
- [x] Graceful degradation: if model fails to load, fall back to structured-only mode

---

## 4. 📱 UI/UX Implementation

### 4a. Design System ✅
- [x] `AppColors` (background, surface, textPrimary, textSecondary, accentRed, accentBlue, success, warning)
- [x] `AppTheme` dark theme with Inter font

### 4b. Widgets ✅
- [x] `ChatBubble` (AI left / User right, styled corners)
- [x] `EmergencyButton` (pulsing ScaleTransition animation)
- [x] `OptionsPanel` (multiple-choice protocol branches)
- [x] `LocationCard` (Decimal / DMS / Altitude display)
- [x] `GpsIndicator` (acquiring / ready / error states with glow)
- [x] `PracticeModeOverlay` (banner + watermark, IgnorePointer)
- [x] `ChatListView` (scrollable, auto-scroll to latest)
- [x] `LlmLoadingBar` (progress bar for model initialization)
- [x] `StepProgressIndicator` (e.g., "Step 3 of 7" within a protocol)
- [x] `ImageCaptureButton` (contextual, only visible at wound node)
- [x] `MicButton` (large, persistent voice input trigger)
- [x] `ConfirmationStep` ("Done? Say yes or tap to continue")
- [x] `DiagramCard` (renders embedded protocol diagram images)

### 4c. Screens
- [x] `HomeScreen` — "I Need Help" + "Practice" + GPS indicator
- [x] `ActiveSessionScreen` — chat + options + Gemma input + mic
- [x] `RescueScriptScreen` — red background, phonetic script, copy button
- [x] `SettingsScreen` — language, text size, coordinate format, disclaimer
- [x] `MyLocationScreen`:
  - [x] Decimal degrees display
  - [x] DMS display
  - [x] Altitude
  - [x] Timestamped position log list (from SQLite)
  - [x] Share/copy coordinates button
- [x] `StepDetailScreen` (expanded view, shows diagram if available)
- [x] `SessionSummaryScreen`:
  - [x] Full session path (node IDs + user choices + timestamps)
  - [x] Location log timeline
  - [x] "Share summary" action (for when rescuers arrive)
- [x] `OnboardingDisclaimerScreen` (first-launch only, one-time acknowledgment):
  - [x] Red Cross / WHO / NASAR protocol credit
  - [x] Medical disclaimer
  - [x] "I understand" button to unlock app

---

## 5. 🔌 State Management (Riverpod)
- [x] `SessionState` model (`currentNode`, `chatHistory`, `isEmergencyActive`, `isPracticeMode`)
- [x] `SessionNotifier` (`startEmergency`, `startPractice`, `handleUserSelection`)
- [x] Wire `SessionNotifier` as a `StateNotifierProvider`
- [x] Create `gpsProvider` (`StreamProvider` from `geolocator`)
- [x] Create `llmProvider` (`FutureProvider` for model initialization)
- [x] Create `countryProvider` (watches GPS stream, resolves country via reverse geocode or cached lookup)
- [x] Create `emergencyNumberProvider` (derives from `countryProvider`)
- [x] Wire all providers into their respective screens

---

## 6. 📡 Hardware & Platform Features
- [x] **GPS (offline GNSS)**:
  - [x] Request permissions for location access
  - [x] Stream real-time position via `geolocator`
  - [x] Display coordinates in DMS format
  - [x] Share location to AI context with one tap
- [x] **Voice Input (hands-free)**:
  - [x] Integrate `speech_to_text` package
  - [x] Pulse UI feedback during recording
  - [x] Transcription automatically populates chat input
- [x] **Camera (wound triage)**:
  - [x] Integrate `image_picker` (Camera/Gallery)
  - [x] Send visual data to multimodal pipeline
  - [x] AI analysis of injuries from shared photos

---

## 7. ✅ Quality & Testing
- [ ] Test complete happy path in Airplane Mode (Android):
  - [ ] GPS acquires fix
  - [ ] Protocol loads from JSON
  - [ ] Gemma generates response
  - [ ] Rescue script generated with real coordinates
- [x] Test Practice Mode (no GPS, no real escalation)
- [x] Test LLM anti-hallucination: ask off-topic questions, verify refusal
- [x] Test ambiguous voice input classification
- [x] Test emergency numbers lookup for at least 10 different countries
- [ ] Performance: first Gemma token < 3 seconds on mid-range device
- [ ] Accessibility: minimum font size 18px, high contrast, large tap targets
- [x] Review all protocol nodes for source citation completeness

---

## 8. 🎬 Hackathon Demo & Submission
- [ ] Record 3-5 min demo video:
  - [ ] Scene 1: Solo hiker, no signal (problem setup)
  - [ ] Scene 2: Tap "I need help" → Signal found → Rescue Script with GPS
  - [ ] Scene 3: Restart → No signal → Injured → Wound image → Bleeding control steps
  - [ ] Scene 4: Lost, no injury → Coordinate display + signaling protocol
  - [ ] Scene 5: Show airplane mode ON + GPS active + Gemma running
  - [ ] Closing: Future roadmap callout
- [ ] Write `README.md`:
  - [x] Architecture diagram (ASCII or image)
  - [x] Protocol source citations table
  - [x] GPS implementation notes (offline GNSS, no internet)
  - [x] Local build instructions
  - [x] Responsible AI / disclaimer section
  - [ ] Airplane mode + GPS screenshot
- [ ] Final GitHub push (clean history, tag `v1.0-hackathon`)
- [ ] Submit to Kaggle/Google DeepMind hackathon portal

---

## Gemma Hackathon Prize Plan Implementation

### App
- [x] Build one-tap demo scenarios for lost hiker, severe bleeding, burn image flow, and hypothermia exposure
- [x] Make demo mode work even when the local model is unavailable, with clear mock/demo labeling
- [x] Show visible safety and trust markers in the live session UI
- [x] Add a stronger rescue handoff screen with situation summary, timeline, hazards, actions, and dispatcher script
- [x] Add a rescue-summary action from the active session header
- [x] Make multimodal image input matter in at least one polished demo path
- [x] Add a small scenario evaluation set for protocol adherence and unsafe-advice checks
- [x] Export a rescue report as Markdown/PDF or strengthen the existing Markdown export
- [x] Add a clear local privacy/offline indicator
- [x] Package a stable Android APK with demo instructions

### Presentation
- [x] Draft the Kaggle writeup around Global Resilience, Safety & Trust, and LiteRT edge AI
- [x] Add an architecture diagram showing user input, protocol layer, Gemma, local knowledge base, GPS/image/speech tools, and rescue summary output
- [x] Document exactly where Gemma is used: context extraction, follow-up questions, summarization, multilingual input, and protocol routing
- [x] Document safety design: emergency-service-first policy, protocol constraints, uncertainty handling, and unsafe-advice prevention
- [x] Include evaluation evidence from the scenario test set
- [x] Write simple judge demo instructions for APK, model setup, demo mode, and expected device requirements
- [x] Script a tight 3-minute demo video with one emotional end-to-end scenario

---

## 9. 🗺️ Future Roadmap (Post-Hackathon)
- [ ] Additional scenario modules (Flood, Earthquake, Wildfire, Avalanche, CBRN)
- [ ] Region packs (downloadable, offline map tiles + local SAR contacts)
- [ ] UTM / MGRS coordinate display option
- [ ] what3words integration (supplemental, clearly labeled)
- [ ] Offline map rendering (embedded OpenStreetMap tiles)
- [x] Track recording during self-evacuation
- [ ] Multi-person triage support
- [ ] Long-term off-grid medical care module
- [ ] Migrate JSON persistence to SQLite for "Black Box" flight-recorder style logging
- [x] Implement path-based GPS tracking (breadcrumbs)

---

## 🚀 10. Protocol Expansion Phase (Work in Progress)

### 🏥 Medical / Injury Gaps
- [x] Burns protocol (Thermal, Chemical, Electrical, Sunburn)
- [x] Eye injury (Foreign object, Chemical splash, Snow blindness)
- [x] Dental emergency (Broken tooth, Lost filling, Abscess)
- [x] Blister management (Pop or not, Padding, Infection watch)
- [x] Sprain / fracture improvised splinting
- [x] Allergic reaction (Mild) - Rashes, hives, itching
- [x] Ear / nose bleed (Altitude/Dry conditions)
- [x] Chest pain / heart attack (AHA protocols)
- [x] Diabetic emergency (Hypo/Hyperglycemia)
- [x] Seizure protocol & monitoring
- [x] Eye washing / chemical exposure

### 🔥 Survival Skills Gaps
- [x] Fire starting (The four core priorities)
- [x] Rope / knot skills (Improvised cordage, key knots)
- [x] Signaling kit improvisation (Mirror/Whistle alternatives)
- [x] Animal hazard awareness (Bear, Boar, Wolf)
- [x] River crossing safety
- [x] Avalanche protocol

### 🗺️ Navigation Gaps
- [x] Watch compass method
- [x] Terrain reading (Ridges, Valleys, Drainages)
- [x] Pace counting / distance estimation

### 🌋 Disaster Gaps
- [x] Tsunami protocol
- [x] Nuclear / radiation protocol (Shelter, iodine, contamination)
- [x] Civil unrest / urban emergency
- [x] Lightning protocol
- [x] Landslide / mudslide protocol

### 🧠 Contextual / Support Nodes
- [x] Hypothermia prevention (Layering, Caloric intake)
- [x] Water purification methods (Detailed)
- [x] Wound infection monitoring
- [x] Patient monitoring checklist (Vitals, Consciousness)
- [x] Evacuation decision tree (Wait vs. Move)
- [x] Mental health / panic management
