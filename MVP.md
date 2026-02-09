# MVP Product Definition (Updated for Hybrid Time Model)

1. Platform: Android-first Flutter app, offline-first, no account/login, no cloud sync.
2. Core objects: `Habit` and `HabitEvent`.
3. Two habit modes: Positive (`Todo`) and Negative (`Relapse`).
4. Time model: Hybrid.
5. Canonical event time stored in UTC.
6. Day-based habit logic uses a persisted local day key captured at event creation.
7. Local persistence stack is SQLite via Drift (`drift`, `drift_flutter`, `sqlite3_flutter_libs`) with code generation via `drift_dev` and `build_runner`.
8. MVP state management uses Flutter-native primitives (`setState`, `ValueNotifier`/`ChangeNotifier`) with no external framework unless complexity requires it.

## Feature Scope (V1)

1. Habit creation/editing.
2. Name (required, 1-40 chars).
3. Icon (from predefined icon set).
4. Color (from curated palette with contrast-safe text).
5. Mode (positive or negative).
6. Optional note/description (0-120 chars).
7. Habit tracking.
8. Positive mode supports one completion per local day (based on stored `localDayKey`).
9. Negative mode supports relapse timestamp (`now`, with optional backdate up to 7 days).
10. Streak rules.
11. Positive streak = consecutive `localDayKey` completions.
12. Negative streak = elapsed duration since last relapse UTC instant (displayed in local format).
13. Home/dashboard.
14. Habit cards with name, icon, current streak, and quick action button.
15. Quick action behavior.
16. Positive: mark done / undo today.
17. Negative: log relapse now.
18. GitHub-style grid.
19. Monthly view per habit.
20. Daily cells.
21. Positive mode: done vs missed vs future.
22. Negative mode: relapse-day marker (recommended for V1 consistency).
23. Basic settings.
24. Start week on Monday/Sunday.
25. 12h/24h time format.
26. Optional reminder notification per habit (single daily reminder, local only).

## Data Model (Simple + Durable)

1. `Habit`: `id`, `name`, `iconKey`, `colorHex`, `mode`, `createdAtUtc`, `archivedAtUtc` (nullable).
2. `HabitEvent`: `id`, `habitId`, `eventType` (`complete` or `relapse`), `occurredAtUtc`, `localDayKey` (`YYYY-MM-DD`), `tzOffsetMinutesAtEvent`, `source` (`manual`).
3. Derived values (not source of truth): current streak, best streak, monthly grid state.
4. Storage implementation: local SQLite tables managed by Drift (no cloud sync for MVP).

Using event history avoids edge-case bugs and lets you recompute streaks reliably.

## Rules to Lock In (Important)

1. UTC is the source of truth for event ordering and duration calculations.
2. `localDayKey` is immutable once written and is used for day-bucket logic.
3. If timezone changes, historical streak day-bucketing does not shift retroactively.
4. Positive day boundary is determined at event creation from device local time and persisted via `localDayKey`.
5. Duplicate actions.
6. Positive: one completion per habit per `localDayKey`; second tap toggles undo.
7. Negative: multiple relapses allowed; latest `occurredAtUtc` resets elapsed streak.
8. Backdating allowed up to 7 days; must compute and persist matching `localDayKey`.
9. Deletion uses archive (soft delete) by default.
10. Validation prevents empty names and case-insensitive duplicates.

## Edge Cases to Explicitly Handle

1. Device timezone change after events are logged.
2. Midnight boundary logging (23:59/00:00 behavior).
3. Undo/re-log recomputation for positive streaks.
4. Negative mode with no relapse yet shows "Started X ago" from `createdAtUtc`.
5. Leap day/month boundaries in monthly grid.
6. Archived habit visibility and stats behavior.
7. Long names on small screens.
8. Color contrast/accessibility failures.
9. App reinstall/data loss expectation (no sync in MVP).
10. Manual clock skew risk (accept as device-trust limitation for V1).

## UI/UX Guardrails

1. Primary interaction is one tap from home.
2. Strong visual distinction between positive and negative modes.
3. Action labels/icons clearly communicate effect.
4. Grid includes legend/tooltips for first-time clarity.
5. Consistency over configurability in V1.

## Out of Scope

1. Cloud sync/auth/multi-device.
2. Social/sharing.
3. Advanced recurrence.
4. Advanced analytics beyond streak + monthly grid.
5. Widgets/watch integration.

## Acceptance Criteria (V1)

1. User can create/edit/archive habits with name/icon/color/mode.
2. User can log positive completion and negative relapse from home.
3. Streaks update correctly after log/undo/backdate/timezone change.
4. Monthly grid renders correctly for both modes using persisted day keys.
5. Data persists across app restarts.
6. Works on common Android screen sizes without layout breakage.
