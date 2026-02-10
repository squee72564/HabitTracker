# AGENTS.md

## App Summary
This repository is a Flutter project for an Android-first habit tracker MVP. The app is offline-first, local-data only, and currently focused on core habit creation, tracking, streaks, and monthly visualization. Time handling follows a hybrid model: store canonical UTC instants and persist local day keys for day-based logic.

## Project Structure
Use only the high-signal paths below during normal agent work:
- `lib/`: primary app code.
  - `core/`: shared app primitives (theme, logging, app bootstrap/error boundary).
  - `domain/`: entities, validation, and time/streak business logic.
  - `data/`: Drift/SQLite persistence and notification scheduling adapters.
  - `presentation/`: UI screens/widgets and interaction flows.
- `test/`: automated coverage aligned to runtime structure.
  - `domain/`: pure logic and time-model unit tests.
  - `data/`: repository/database behavior tests.
  - `presentation/`: widget and flow regressions.
- `android/`: Android app config, manifests/resources, Gradle build/signing setup.
- `tool/`: local helper scripts (for example CI convenience commands).
- Root product/docs/config files: `MVP.md`, `ROADMAP.md`, `README.md`, `pubspec.yaml`, `analysis_options.yaml`.

Platform folders like `ios/`, `web/`, `macos/`, `linux/`, and `windows/` are generated scaffolding unless a task explicitly targets those platforms.

## Commands
Use Flutter-native commands:
- Install deps: `flutter pub get`
- Add DB runtime deps: `flutter pub add drift drift_flutter sqlite3_flutter_libs`
- Add DB codegen deps: `flutter pub add --dev drift_dev build_runner`
- Generate Drift code: `dart run build_runner build --delete-conflicting-outputs`
- Watch Drift codegen: `dart run build_runner watch --delete-conflicting-outputs`
- Run on Android: `flutter run -d android`
- Static analysis: `flutter analyze`
- Run tests: `flutter test`
- Run a specific test file: `flutter test test/widget_test.dart`
- Build release APK: `flutter build apk --release`
- Build Play Store bundle: `flutter build appbundle --release`

## Testing Expectations

- Add or update tests when implementing non-trivial logic
- Widget tests preferred for UI behavior
- Pure Dart logic should be unit tested
- Default validation sequence for implementation changes:
  - `flutter pub get` (must pass)
  - `flutter analyze` (must report no issues)
  - `flutter test` (must pass all tests)
- For focused verification during development, run a specific file as needed:
  - `flutter test test/widget_test.dart`
- If persistence schema/codegen changes are made, regenerate before analyze/test:
  - `dart run build_runner build --delete-conflicting-outputs`

## MVP & Roadmap
Read these files only as needed focusing on progressive disclosure

1. `MVP.md`: source of truth for scope, rules, edge cases, and acceptance criteria.
2. `ROADMAP.md`: execution plan with granular stage tasks and checkboxes.

## Implementation Constraints

### Do
- Keep state local and simple unless MVP.md requires otherwise
- Prefer Flutter SDK primitives before introducing new packages
- Write small widgets with explicit responsibilities

### Don’t
- Introduce state management frameworks (Riverpod, Bloc, etc.) unless explicitly requested
- Add persistence beyond local storage
- Add background services or notifications unless scoped in MVP.md

## Time Handling Rules

- Persist timestamps as UTC `DateTime`
- Derive and store local day keys (YYYY-MM-DD) for streaks and aggregations
- Never infer day boundaries from UTC alone

## Commit & PR Expectations

- If available, use `$atomic-commit-generator` skill
- Use conventional commit messages
- Prefer one logical change per commit
