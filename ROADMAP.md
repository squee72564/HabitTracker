# Habit Tracker MVP Roadmap

This roadmap is derived from `MVP.md` and is designed to be completed in small, checkable steps.

## Status Legend

- [ ] Not started
- [x] Completed
- [~] In progress (replace manually when needed)

## Stage 0: Project Foundation

- [x] R0.1 Lock MVP state management to Flutter-native primitives (`setState`, `ValueNotifier`/`ChangeNotifier`) and document in `README.md` (no external framework unless needed later).
- [x] R0.2 Lock local database stack to Drift + SQLite (`drift`, `drift_flutter`, `sqlite3_flutter_libs`) and document schema strategy.
- [x] R0.3 Add required dependencies for persistence (`drift`, `drift_flutter`, `sqlite3_flutter_libs`, `drift_dev`, `build_runner`), notifications, and timezone-safe date utilities.
- [x] R0.4 Create folder structure for `core`, `features`, `data`, `domain`, `presentation`.
- [x] R0.5 Set up app theme tokens (spacing, radii, typography, semantic colors).
- [x] R0.6 Add a lightweight logger and global error boundary.
- [x] R0.7 Add lint rules and baseline CI command (`flutter analyze`, `flutter test`).
- [x] R0.8 Add `README` section describing MVP scope and out-of-scope boundaries.
- [x] R0.9 Stage 0 exit check: app runs on Android emulator and CI checks pass locally.

## Stage 1: Domain Model + Hybrid Time Model

- [x] R1.1 Implement `Habit` entity (`id`, `name`, `iconKey`, `colorHex`, `mode`, `createdAtUtc`, `archivedAtUtc`).
- [x] R1.2 Implement `HabitEvent` entity (`id`, `habitId`, `eventType`, `occurredAtUtc`, `localDayKey`, `tzOffsetMinutesAtEvent`, `source`).
- [x] R1.3 Add enum/value objects for `HabitMode`, `HabitEventType`, and validation constraints.
- [x] R1.4 Implement helper to generate `localDayKey` from device local time (`YYYY-MM-DD`).
- [x] R1.5 Implement helper to capture `tzOffsetMinutesAtEvent` at event creation.
- [x] R1.6 Add domain validation for name length, note length, and case-insensitive duplicate names.
- [x] R1.7 Add unit tests for date conversion, `localDayKey` generation, and validation rules.
- [x] R1.8 Stage 1 exit check: all domain tests pass, including midnight and timezone boundary tests.

## Stage 2: Persistence Layer (Offline-First, Drift + SQLite)

- [x] R2.1 Define Drift tables for `habits` and `habit_events` backed by local SQLite.
- [x] R2.2 Add indexes for `habitId`, `occurredAtUtc`, `localDayKey`, and active habits query.
- [x] R2.3 Implement repository interfaces for habits and events.
- [x] R2.4 Implement repository adapters for CRUD and query operations.
- [x] R2.5 Implement soft archive (`archivedAtUtc`) behavior for habits.
- [x] R2.6 Implement transaction-safe writes for event creation + duplicate checks.
- [x] R2.7 Add migration strategy for schema versioning.
- [x] R2.8 Add repository tests for save/load/edit/archive flows.
- [x] R2.9 Stage 2 exit check: data persists across app restart and archive behavior is stable.

## Stage 3: Habit Creation and Editing UI

- [x] R3.1 Build habit list/home scaffold with empty state.
- [x] R3.2 Build create habit form with fields: name, icon picker, color picker, mode, optional note.
- [x] R3.3 Enforce validation errors inline (required name, char limits, duplicate names).
- [x] R3.4 Build edit habit flow with prefilled values.
- [x] R3.5 Implement archive action with confirmation dialog.
- [x] R3.6 Ensure color choices maintain contrast-safe text in previews/cards.
- [x] R3.7 Add widget tests for create/edit/archive form behaviors.
- [x] R3.8 Stage 3 exit check: user can create/edit/archive habits successfully from UI.

## Stage 4: Tracking Actions (Positive + Negative)

- [x] R4.1 Add quick action button on habit cards for one-tap interaction.
- [x] R4.2 Positive mode: implement mark done for today (`localDayKey`-based).
- [x] R4.3 Positive mode: implement second tap as undo for today's completion.
- [x] R4.4 Positive mode: enforce max one completion per habit per `localDayKey`.
- [x] R4.5 Negative mode: implement log relapse now.
- [x] R4.6 Negative mode: implement backdate relapse up to 7 days.
- [x] R4.7 Negative mode: allow multiple relapse events; latest UTC event defines current elapsed streak.
- [x] R4.8 Add unit tests for duplicate prevention, undo behavior, and backdate constraints.
- [x] R4.9 Stage 4 exit check: all tracking actions function correctly from the home screen.

## Stage 5: Streak Calculation Engine

- [x] R5.1 Implement positive streak calculator from sorted unique completion `localDayKey` values.
- [x] R5.2 Implement positive best streak calculator.
- [x] R5.3 Implement negative current streak as duration since latest relapse `occurredAtUtc`.
- [x] R5.4 Implement fallback text for negative mode with no relapse: `Started X ago` from `createdAtUtc`.
- [x] R5.5 Add timezone-change resilience tests (historical local day keys never shift).
- [x] R5.6 Add midnight edge tests for both modes (23:59 and 00:00 boundaries).
- [x] R5.7 Add leap day/month boundary tests.
- [x] R5.8 Stage 5 exit check: streak outputs match `MVP.md` rules across all edge-case tests.

## Stage 6: Dashboard and Monthly Grid Visualization

- [x] R6.1 Build home dashboard cards showing icon, name, mode, current streak, quick action.
- [x] R6.2 Build monthly calendar grid component (GitHub-style daily cells).
- [x] R6.3 Positive mode grid: map each day to done/missed/future state.
- [x] R6.4 Negative mode grid: render relapse-day marker style consistently.
- [x] R6.5 Add month navigation controls and current month indicator.
- [x] R6.6 Add legend/tooltips for first-time clarity.
- [x] R6.7 Add responsive behavior for small Android devices (cell size and text overflow handling).
- [x] R6.8 Add widget tests for card states and grid rendering.
- [x] R6.9 Stage 6 exit check: dashboard and monthly view are usable and visually consistent.

## Stage 7: Settings + Notifications

- [ ] R7.1 Build settings screen with week start toggle (Monday/Sunday).
- [ ] R7.2 Build time format toggle (12h/24h).
- [ ] R7.3 Add per-habit local reminder configuration (single daily reminder).
- [ ] R7.4 Schedule/cancel local notifications for enabled habits.
- [ ] R7.5 Handle Android notification permission flow and disabled-permission fallback UX.
- [ ] R7.6 Persist settings and reminder configurations across restarts.
- [ ] R7.7 Stage 7 exit check: settings apply globally and reminders fire on-device.

## Stage 8: QA, Hardening, and Accessibility

- [ ] R8.1 Add integration test covering create habit -> log event -> streak update -> grid update.
- [ ] R8.2 Add regression test for timezone change scenario.
- [ ] R8.3 Add regression test for undo and re-log behavior.
- [ ] R8.4 Validate text scaling and overflow safety for long habit names.
- [ ] R8.5 Validate color contrast in all habit card states.
- [ ] R8.6 Run performance check with realistic event volume (at least 12 months of events).
- [ ] R8.7 Conduct manual Android smoke test on emulator and one physical device.
- [ ] R8.8 Stage 8 exit check: no P1/P2 bugs and acceptance criteria are satisfied.

## Stage 9: Release Preparation (Android MVP)

- [ ] R9.1 Finalize app icon, app name, and Android package metadata.
- [ ] R9.2 Add release build config and verify signed APK/AAB generation.
- [ ] R9.3 Update `README.md` with install/run steps and MVP behavior notes.
- [ ] R9.4 Add known limitations section (no sync, device clock trust model, local-only data).
- [ ] R9.5 Create a pre-release checklist and complete final smoke test.
- [ ] R9.6 Stage 9 exit check: Android release artifact is buildable and installable.

## MVP Acceptance Checklist (from `MVP.md`)

- [ ] A1 User can create/edit/archive habits with name/icon/color/mode.
- [ ] A2 User can log positive completion and negative relapse from home.
- [ ] A3 Streaks update correctly after log/undo/backdate/timezone change.
- [ ] A4 Monthly grid renders correctly for both modes using persisted day keys.
- [ ] A5 Data persists across app restarts.
- [ ] A6 App works on common Android screen sizes without layout breakage.
