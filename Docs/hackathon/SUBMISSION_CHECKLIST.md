# AIDEM Submission Checklist

Deadline rule: the Kaggle writeup must be submitted before the deadline. Draft or unsubmitted writeups are not judged.

## Kaggle Writeup

- [ ] Create a new Kaggle Writeup.
- [ ] Select the final track: `Global Resilience`.
- [ ] Paste/adapt `Docs/hackathon/KAGGLE_WRITEUP_FINAL.md`.
- [ ] Keep final text under 1,500 words.
- [ ] Add the architecture diagram from the writeup.
- [ ] Add final project links in the Attachments section.
- [ ] Submit once early, then edit/resubmit if needed.

## Video

- [ ] Keep video at 3:00 or shorter.
- [ ] Upload to YouTube.
- [ ] Set visibility to Public or Unlisted.
- [ ] Confirm judges can view without login.
- [ ] Add the direct YouTube link to the Kaggle Media Gallery.
- [ ] Add the same link under Project Links if useful.

## Public Code Repository

- [ ] Push final code to a public GitHub or Kaggle repository.
- [ ] Confirm the repository opens without login.
- [ ] Confirm README renders correctly.
- [ ] Confirm code shows Gemma integration clearly:
  - `aidem_app/lib/services/llm_service.dart`
  - `aidem_app/lib/providers/session_provider.dart`
  - `aidem_app/assets/data/protocol.json`
  - `aidem_app/test/protocol_adherence_eval_test.dart`
- [ ] Add repository link to Kaggle Writeup > Attachments > Project Links.

## Live Demo

- [ ] Build the final Android APK.
- [ ] Build the final Windows portable package if included.
- [ ] Attach Android APK or public release URL.
- [ ] Attach Windows portable package or public release URL if included.
- [ ] Include `Docs/hackathon/JUDGE_DEMO_GUIDE.md`.
- [ ] Verify demo mode works without model setup.
- [ ] Verify model setup screen points to the Gemma LiteRT download page.
- [ ] Verify first-run legal notice fits on desktop and mobile.

## Media Gallery

- [ ] Add a cover image.
- [ ] Add YouTube video.
- [ ] Add 3-6 screenshots:
  - no signal / airplane mode with AIDEM running,
  - home screen / demo mode,
  - active guidance screen,
  - GPS capture,
  - image input safety note,
  - rescue summary handoff.
- [ ] Use the new AIDEM logo in the cover image or final frame.

## Final Sanity Pass

- [ ] Run `flutter test`.
- [ ] Run `dart analyze`.
- [ ] Open the app once from the final build.
- [ ] Check links in the Kaggle writeup.
- [ ] Submit the Kaggle writeup before recording or editing consumes the final hours.
