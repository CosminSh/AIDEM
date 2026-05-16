# AIDEM Judge Demo Guide

This guide is for the public repository and Kaggle writeup attachments.

## Recommended Demo Path

1. Install the Android APK or open the Windows portable build.
2. Start AIDEM.
3. Read and accept the readiness/legal notice.
4. If you have a local Gemma LiteRT model, select it in setup.
5. If you do not have the model ready, continue with practice/demo mode.
6. From the home screen, choose the Best Demo scenario.
7. Use a no-signal injury prompt such as:

```text
I twisted my ankle badly while running in the forest. I have no signal, I am in pain, and I cannot put weight on it.
```

8. Observe that AIDEM:
   - prioritizes contacting emergency services when possible,
   - keeps guidance short,
   - asks targeted follow-up questions,
   - stays inside protocol and safety boundaries,
   - can log GPS/image/voice context,
   - prepares a rescue handoff summary.

## Full Local Gemma Path

AIDEM is designed to run Gemma locally on device through the Flutter Gemma / LiteRT stack.

1. Download the recommended Gemma 4 E2B IT LiteRT model.
2. Open the app setup screen.
3. Select the `.litertlm` model file.
4. After setup, the app can run the model locally without cloud inference.

## Offline Proof Shot For Video Or Gallery

For the strongest demo, capture one screenshot or video clip showing:

- airplane mode or no-signal indicator,
- AIDEM open and responding,
- local model ready indicator or setup screen,
- GPS/location capture if available.

## Demo Builds

After creating final release builds, use one or both of these for the Kaggle "Live Demo" requirement:

- Android APK: `Releases/AIDEM-Android.apk`
- Optional zipped Windows package: `Releases/AIDEM-Windows-Portable.zip`

Public Kaggle/GitHub release URL:

```text
Add the public build link here after upload.
```

## Known Limitations

- AIDEM does not diagnose medical conditions.
- AIDEM does not replace emergency services or professional rescue.
- Image input is treated as visible context only.
- GPS can work offline, but the device still needs location permissions and sky visibility.
- Full local AI behavior depends on a compatible local Gemma LiteRT model.
