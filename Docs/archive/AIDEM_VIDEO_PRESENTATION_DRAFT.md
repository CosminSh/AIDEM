# AIDEM Video Presentation Draft

## Core Message

AIDEM exists for the moment when the tools we rely on disappear.

We are used to having instant knowledge in our pockets, but most of that knowledge depends on a live internet connection, cloud services, battery, and phone signal. In many emergencies, those are exactly the things that fail first.

AIDEM fills that gap: local AI guidance for offline emergencies. It uses Gemma 4 running on the device, constrained by safety rules, official first-aid and survival guidance, and a protocol-based workflow. It is not a doctor, not a replacement for emergency services, and not a general chatbot. It is a calm, offline assistant that helps a person take the next safe step and preserve the details rescuers will need later.

## Recommended Video Shape

Target length: 3 minutes.

Main voices:

- Developer: frames the problem, explains the app and technology.
- Medic: sets the safety boundary and credibility.
- Optional third voice: runner, outdoor user, rescue volunteer, or disaster-preparedness voice to make the impact human.

Main visual story:

A woman is running alone in a forest. She falls, hits her leg or arm, and realizes she has no signal. AIDEM guides her through checking danger, describing the injury, using voice input if her hands are busy, sharing GPS location locally, and generating a rescue handoff for when she reaches help or signal returns.

## 3-Minute Script

### 0:00-0:20 - Hook: The Gap

Visuals:

- Close shot of a phone showing no signal.
- Runner alone on a forest trail.
- Quick cuts: search app failing, emergency call unavailable, low battery, anxious breathing.

Developer voiceover:

> We have become used to instant answers from our devices. If we need to know something, we search. If something goes wrong, we call. But in many real emergencies, there is no signal, no stable power, and no access to cloud-based tools.

On-screen text:

> No signal. No search. No cloud.

### 0:20-0:45 - What AIDEM Is

Visuals:

- AIDEM home screen.
- Airplane mode or no-signal indicator.
- Local model status / LLM ready indicator if available.
- App guiding an emergency scenario.

Developer on camera:

> AIDEM is our attempt to fill that missing space. It is an offline emergency assistant that can run on the device, using Gemma 4 for local reasoning and language understanding. The goal is not to replace professionals. The goal is to help someone stay calm, follow trusted guidance, and keep track of critical information until help becomes reachable.

Visual overlay:

> Gemma 4 on-device
> Protocol-based guidance
> Local session timeline
> Rescue handoff

### 0:45-1:10 - Medic Safety Boundary

Visuals:

- Medic speaking directly to camera.
- Intercut with app screen showing "call emergency services first" or rescue handoff.
- Show emergency numbers database briefly.

Medic:

> An app should never replace calling emergency services. If you can call, you call. But there are situations where someone is truly offline: hiking, disasters, remote roads, storms, or power outages. In those moments, structured guidance can be useful, especially if it reminds the user what not to do, asks simple questions, and keeps information ready for rescuers.

Optional medic follow-up:

> What matters is that the app stays inside safe boundaries: it should avoid diagnosis, avoid overconfidence, and prioritize professional care whenever that is possible.

### 1:10-1:55 - Use Case: Injured Runner Offline

Visuals:

- Runner falls on trail and checks phone.
- Opens AIDEM.
- Uses dictation: "I fell while running. My leg hurts and I cannot stand well. I have no signal."
- AIDEM extracts the situation and asks one follow-up.
- Show short, step-by-step protocol guidance.
- Show text-to-speech reading the next step if available.

Developer voiceover:

> In this scenario, a runner falls in the forest and cannot get online. Instead of a blank search page, she opens AIDEM. She can type or dictate what happened. Gemma helps interpret the messy situation report, while the app keeps the answer constrained by emergency protocols.

App guidance examples to show:

- "Move out of immediate danger if you can do so safely."
- "Do not continue running on the injured leg."
- "Check for severe bleeding, head injury, or trouble breathing."
- "Can you bear weight on the leg?"

Developer voiceover:

> The app does not try to diagnose her. It helps her check immediate danger, avoid making the injury worse, and take the next practical step.

### 1:55-2:25 - Features That Matter Offline

Visuals:

- Dictation button.
- Text-to-speech playback.
- Image input for wound or injury context.
- GPS/location screen.
- Emergency numbers database.
- Session summary or dispatcher script.

Developer on camera or voiceover:

> AIDEM is built around the realities of offline use. It supports dictation when typing is hard, text-to-speech when the user needs hands-free guidance, image input for visual context, GPS location capture, local emergency-number data, and a rescue summary that preserves the timeline of what happened.

Developer:

> Everything is designed around the same idea: reduce panic, keep the guidance short, and make the handoff to real help clearer.

### 2:25-2:45 - Technical Credibility

Visuals:

- Simple architecture graphic.
- App in airplane mode.
- Gemma / LiteRT model file or local model indicator.
- Protocol JSON or evaluation tests very briefly.

Developer:

> Under the hood, Gemma 4 runs locally through an edge AI setup. AIDEM combines that local reasoning with deterministic protocols, safety rules, and local data. Gemma helps with language understanding, follow-up questions, summarization, and adapting to messy real-world input. The protocol layer keeps the app from becoming a free-form medical chatbot.

On-screen text:

> Local AI + protocol constraints + rescue handoff

### 2:45-3:00 - Close: Empowerment

Visuals:

- Runner sitting safely off trail, following guidance.
- Rescue summary ready on screen.
- Final app logo or home screen.

Developer or shared voiceover:

> AIDEM is just a start. As local models get better, offline assistance can become more capable, more private, and more resilient. Our goal is simple: when connection is gone and panic is rising, the person still has a calm next step.

Final on-screen text:

> AIDEM
> Offline guidance when connection is not an option.

## Optional Third Voice

Use one short quote if the video feels too developer-heavy.

### Option A - Outdoor User

> I do not need an app to pretend it is a rescuer. I need it to help me slow down, check the basics, and remember what matters while I am alone.

### Option B - Search And Rescue / Preparedness Voice

> The first few minutes can decide how useful the later rescue handoff is. Location, timeline, symptoms, hazards, and what the person already tried are all details that can get lost under stress.

### Option C - Disaster Preparedness Voice

> Offline tools matter because emergencies do not wait for infrastructure to come back. A resilient app should still be useful when the network is down.

## Shot List

- Developer speaking to camera for the concept and technical credibility.
- Medic speaking to camera for the safety boundary.
- Runner in forest with phone showing no signal.
- Close-up of AIDEM opening while offline.
- Dictation input being used.
- AIDEM asking one targeted follow-up.
- Protocol guidance screen.
- Text-to-speech playback.
- Image input screen.
- GPS/location screen.
- Emergency numbers database.
- Rescue summary / dispatcher script.
- Airplane mode or no-signal proof shot.
- Local Gemma / model setup or model status screen.
- Final logo or home screen.

## Recording Notes

- Show one complete workflow, not a feature tour.
- Keep app responses short and legible on screen.
- Use subtitles for every spoken line.
- Do not claim diagnosis or guaranteed medical correctness.
- Say "call emergency services if you can" clearly.
- Make the offline proof visible: no signal, airplane mode, or local model indicator.
- End with the human outcome: calm, protocol, location, handoff.

## Shorter 90-Second Version

Developer:

> We are used to instant knowledge from our devices, but most of it depends on internet access. In emergencies, that connection may be gone. AIDEM is an offline emergency assistant built for that gap.

Medic:

> It does not replace emergency services. If you can call, call. But if you are truly offline, structured guidance can help someone avoid unsafe actions and preserve important details.

Developer:

> AIDEM uses Gemma 4 running on the device, combined with protocol-based safety rules and local emergency data. In this demo, a runner falls in the forest with no signal. She dictates what happened, the app asks a targeted follow-up, gives short step-by-step guidance, captures location, and prepares a rescue handoff.

Developer:

> It also supports text-to-speech, image input, GPS, emergency numbers, and local session summaries. This is the beginning of a field-ready offline assistant that can grow as local LLMs improve.

Closing:

> When connection is gone and panic is rising, AIDEM helps the person keep one calm next step.
