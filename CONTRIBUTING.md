# Contributing

Thanks for helping improve AIDEM. This repository is prepared for hackathon evaluation, so changes should keep the app easy to review, run, and audit.

## Development

Work from the Flutter app directory:

```bash
cd aidem_app
flutter pub get
dart analyze
flutter test
```

Use Android or Windows for the validated demo paths:

```bash
flutter run -d android
flutter run -d windows
```

iOS, macOS, Linux, and web project folders are present because this is a Flutter codebase, but they are not part of the validated hackathon release unless explicitly documented in a release note.

## Pull Request Checklist

- Keep emergency guidance protocol-constrained and safety-first.
- Add or update tests when changing routing, prompts, protocol data, persistence, or safety behavior.
- Do not commit local models, release binaries, SDKs, signing files, or generated build output.
- Document any dependency override in `aidem_app/pubspec.yaml`.
- Update `CHANGELOG.md` for user-visible behavior, packaging, data, or safety changes.

## Documentation

- Main project story: `README.md`
- App implementation details: `aidem_app/README.md`
- Submission-ready materials: `Docs/hackathon/`
- Historical planning notes: `Docs/archive/`
