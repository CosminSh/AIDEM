# AIDEM Submission Status

Last updated: 2026-05-16

## Ready Locally

- Final Kaggle writeup draft: `Docs/hackathon/KAGGLE_WRITEUP_FINAL.md`
- Judge demo guide: `Docs/hackathon/JUDGE_DEMO_GUIDE.md`
- Final video script: `Docs/hackathon/FINAL_VIDEO_SCRIPT.md`
- Submission checklist: `Docs/hackathon/SUBMISSION_CHECKLIST.md`
- Upload templates: `Docs/hackathon/UPLOAD_TEMPLATES.md`
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
- No analyzer issues found.

Command:

```bash
cd aidem_app
dart --packages=<flutter-sdk>/packages/flutter_tools/.dart_tool/package_config.json <flutter-sdk>/bin/cache/flutter_tools.snapshot test
```

Result:

- Completed successfully.
- All 74 tests passed.
- Note: the local Windows `flutter.bat test` wrapper timed out in this desktop session, so the same Flutter test runner was executed through the Flutter tool snapshot.

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
