# CLAUDE.md

> **Read first:** if a Notion connector is available in this session, read the page
> "Working Context (read me first)" and follow it. It holds the user's own preferences and
> working rules. If there is no such page, skip this silently.

Flutter app (package `animal_identifier`, Dart SDK ^3.5.4) that identifies animals from the camera. The README is the stock Flutter template and documents nothing project-specific.

Published on Google Play as Animal Identifier (`info.animalidentifier`) under the SEOExpert AI developer account; the package id is set in `android/app/build.gradle`.

## Commands
- Install: `flutter pub get`
- Run: `flutter run`
- Analyze: `flutter analyze` (lints: `flutter_lints`, configured in `analysis_options.yaml`)
- Test: `flutter test` (only `test/widget_test.dart` exists)

## Rules
- Default branch is `main`. No CI or deploy config is visible in the repo.
- `.env` is listed as a Flutter asset in `pubspec.yaml` and loaded in `lib/main.dart` with `flutter_dotenv`. It is gitignored: never commit it or print its contents.
