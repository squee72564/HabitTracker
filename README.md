# Habit Tracker

Android-first Flutter habit tracker MVP with offline-first, local-only storage.

## MVP Behavior

- Create, edit, and archive habits with name, icon, color, mode, and optional note.
- Use two modes:
  - Positive (`Todo`): one completion per local day, second tap undoes today.
  - Negative (`Relapse`): log relapse now or backdate up to 7 days.
- Compute streaks with a hybrid time model:
  - Persist UTC instants for canonical ordering and elapsed-duration math.
  - Persist immutable local day keys (`YYYY-MM-DD`) for day-bucket logic.
- Render a monthly per-habit grid:
  - Positive mode: done, missed, and future day states.
  - Negative mode: relapse-day marker states.
- Persist all data locally in SQLite via Drift.

## Tech Constraints

- Flutter-native state primitives only (`setState`, `ValueNotifier`, `ChangeNotifier`).
- Local persistence only (`drift`, `drift_flutter`, `sqlite3_flutter_libs`).
- No cloud sync, auth, or background service architecture for MVP.

## Getting Started (Android)

1. Install dependencies:
   - `flutter pub get`
2. Run on Android emulator or device:
   - `flutter run -d android`

## Validation Commands

- `flutter pub get`
- `flutter analyze`
- `flutter test`

## Release Build (Android)

1. Configure signing:
   - Copy `android/key.properties.example` to `android/key.properties`.
   - Set `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.
2. Build release APK:
   - `flutter build apk --release`
3. Build release App Bundle:
   - `flutter build appbundle --release`
4. Optional local install check:
   - `adb install -r build/app/outputs/flutter-apk/app-release.apk`

If `android/key.properties` is not present, Gradle falls back to debug signing so local release artifact generation still works.
Use `RELEASE_CHECKLIST.md` for pre-release verification and final smoke-test tracking.

## Known Limitations (MVP)

- Data is local-only and device-bound.
- No cloud backup or sync across devices.
- Uninstalling the app can permanently delete habit history.
- Historical day buckets are immutable by design and will not rebucket after timezone changes.
- Device clock/timezone is trusted at event creation time; manual clock skew can affect captured timestamps/day keys.

## Out of Scope

- Cloud sync/auth/multi-device data.
- Social/sharing features.
- Advanced recurrence rules.
- Advanced analytics beyond streaks and monthly grid.
- Widgets/watch integrations.
