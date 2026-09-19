# CLAUDE.md

> **Read first:** if a Notion connector is available in this session, read the page
> "Working Context (read me first)" and follow it. It holds the user's own preferences and
> working rules. If there is no such page, skip this silently.

Flutter app (package `animal_identifier`, Dart SDK ^3.5.4) that identifies animals from the camera. The README is the stock Flutter template and documents nothing project-specific.

Published on Google Play as Animal Identifier (`info.animalidentifier`) under the SEOExpert AI developer account; the package id is set in `android/app/build.gradle.kts`. Current version is 1.1.0+6.

## Commands
- Install: `flutter pub get`
- Run: `flutter run`
- Analyze: `flutter analyze` (lints: `flutter_lints`, configured in `analysis_options.yaml`)
- Test: `flutter test` (widget, payment and the two service tests, none of which touch the network), and `cd proxy && npm test` for the proxy
- Release bundle: `flutter build appbundle --release` (JDK 17). It refuses to build without a signing file, see Rules.

## Rules
- Default branch is `main`. No CI or deploy config is visible in the repo.
- The app carries no Gemini key, model name or prompt. It posts to a small server-side proxy (`proxy/`, run on Google Cloud Run) whose base URL is `kProxyBaseUrl` in `lib/utils/app_config.dart` (override with `--dart-define=PROXY_BASE_URL=...`). The model, the prompts and the key live in the proxy and its secret store. There is no `.env` any more: never put a key back into the bundle.
- A credit is spent only after a successful identification, and a failure shows an honest error, never a made-up animal. New installs start with `kFreeStarterCredits` (2) free identifications.
- Release signing is read from `~/.animalwiki-signing/key.properties`, then `android/key.properties`. Both are gitignored: never commit them or print their contents. `*.jks` files stay out of git too.
- Play requirements met by 1.1.0+6: target API 36, Play Billing Library 8 (`in_app_purchase_android` 0.5.3), 16 KB page sizes. Keep the Android host on what the installed Flutter expects (AGP, Kotlin and Gradle are set in `android/settings.gradle.kts` and the Gradle wrapper).
