# AIDEM Submission Status

Last updated: 2026-05-14

## Ready Locally

- Final Kaggle writeup draft: `Docs/KAGGLE_WRITEUP_FINAL.md`
- Judge demo guide: `Docs/JUDGE_DEMO_GUIDE.md`
- Final video script: `Docs/FINAL_VIDEO_SCRIPT.md`
- Submission checklist: `Docs/SUBMISSION_CHECKLIST.md`
- Upload templates: `Docs/UPLOAD_TEMPLATES.md`
- Kaggle cover image: `Docs/media/aidem-cover.png`
- Public README cleaned and updated.
- App module README cleaned and updated.

## Build Status

- Final app builds were intentionally not rebuilt by Codex after user direction.
- Before submission, build fresh release artifacts and then upload them:
  - `Releases/AIDEM-Android.apk`
  - `Releases/AIDEM-Windows-Portable.zip`, if submitting Windows too
- Existing files in `Releases/` may be useful references, but the final submission should use freshly built packages.

## Verification Performed

Command:

```bash
cd aidem_app
dart analyze
```

Result:

- Completed successfully.
- No analyzer errors.
- Existing info-level lint warnings remain, mostly `avoid_print` and deprecated `withOpacity` / speech APIs.

Command:

```bash
cd aidem_app
flutter test
```

Result:

- Timed out locally before returning test output.
- Focused Flutter test runs also timed out locally.
- Direct `dart run test` is not valid for these tests because they import `flutter_test` and require the Flutter test runner.

## Remaining User-Owned Submission Tasks

- Upload final code to a public repository.
- Upload the video to YouTube as Public or Unlisted.
- Upload or attach the live demo build files.
- Add public URLs to the Kaggle writeup:
  - YouTube video
  - public code repository
  - live demo / release files
- Capture final screenshots for the media gallery, especially the no-signal / airplane-mode proof shot.
- Submit the Kaggle writeup before the deadline.
