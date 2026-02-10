# Habit Tracker

Android-first Flutter habit tracker with offline-first, local-only storage.

## Current Behavior (MVP + Post-MVP)

- Create, edit, and archive habits with name, icon, color, mode, optional note, and optional reminder.
- Manage archived habits in Settings:
  - Unarchive archived habits back to Home.
  - Permanently delete archived habits only, with typed habit-name confirmation.
- Tracking modes:
  - Positive (`Todo`): quick action marks today done, second tap undoes today.
  - Negative (`Relapse`): quick action logs relapse when no relapse exists, otherwise undoes the latest relapse only.
- Monthly per-habit grid supports day taps:
  - Future days are read-only in both modes.
  - Positive mode toggles completion for any past or current local day.
  - Negative mode toggles relapse markers for today and the previous 7 local days.
- Backdate flow for negative mode logs relapse up to 7 local days.
- Reminder model:
  - Per-habit daily reminder toggle and time are configurable.
  - Global reminders switch pauses/resumes scheduling while preserving per-habit reminder preferences.
- Reset flow in Settings requires typing `RESET` and permanently clears habits, events, reminders, and app settings.
- Hybrid time model:
  - Persist UTC instants (`occurredAtUtc`) for ordering and elapsed duration.
  - Persist immutable local day keys (`localDayKey`, `YYYY-MM-DD`) for day-bucket logic.
  - Persist `tzOffsetMinutesAtEvent` for each event.
- Persist all app data locally in SQLite via Drift.

## Tech Constraints

- Flutter-native state primitives only (`setState`, `ValueNotifier`, `ChangeNotifier`).
- Local persistence only (`drift`, `drift_flutter`, `sqlite3_flutter_libs`).
- No cloud sync/auth or remote backend.

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
Use `RELEASE_CHECKLIST.md` for pre-release verification, destructive-action and grid-editing regressions, and final smoke-test tracking.

## Known Limitations

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
