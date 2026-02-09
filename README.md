# habit_tracker

Android-first Flutter habit tracker MVP with offline-first, local-only storage.

## MVP Scope

- Create, edit, and archive habits.
- Support two modes: positive (`Todo`) and negative (`Relapse`).
- Log habit events and compute streaks using a hybrid time model:
  - UTC timestamps for canonical event ordering.
  - Persisted local day keys (`YYYY-MM-DD`) for day-based logic.
- Show a monthly habit visualization grid.
- Keep state management Flutter-native only (`setState`, `ValueNotifier`, `ChangeNotifier`).

## Out of Scope (MVP)

- Cloud sync, auth, or multi-device data.
- Social/sharing features.
- Advanced recurrence rules.
- Advanced analytics beyond streaks and monthly grid.
- Widgets/watch integrations.

## Local-Only Data Model

- All source-of-truth data is stored on-device in SQLite via Drift (`drift`, `drift_flutter`, `sqlite3_flutter_libs`).
- Core persisted objects are `Habit` and `HabitEvent`.
- No remote backend is used for MVP; uninstalling the app can result in data loss.
