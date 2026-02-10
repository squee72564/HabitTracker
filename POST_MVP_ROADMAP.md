# Habit Tracker Post-MVP Roadmap

This roadmap extends the shipped MVP with UX and control improvements discovered during Stage 9 closeout.

## Status Legend

- [ ] Not started
- [x] Completed
- [~] In progress (replace manually when needed)

## Guardrails (Carry Forward)

- Keep local-first architecture (no cloud sync/auth unless explicitly added in a future roadmap).
- Keep hybrid time model intact:
  - UTC instants are canonical for event ordering/duration.
  - `localDayKey` is immutable once written.
  - No historical rebucketing after timezone changes.
- Keep Flutter-native state approach unless complexity forces a change.

## Stage P0: Product Clarifications and UX Contracts

- [x] P0.1 Define archive vs delete policy in product docs:
  - Archive behavior and visibility.
  - Whether permanent delete is supported and from where.
  - Whether unarchive is user-accessible in-app.
- [x] P0.2 Define relapse undo semantics:
  - Undo latest relapse only vs undo specific relapse.
  - Time window/guardrails for undo.
  - UX language for history-changing actions.
- [x] P0.3 Define grid tap interaction contract:
  - Positive mode: add/remove completion for selected day.
  - Negative mode: add/remove relapse marker for selected day.
  - Allowed day range (historical/future) and mode-specific constraints.
- [x] P0.4 Define color strategy:
  - Expanded default palette requirements.
  - Custom color picker constraints (contrast, storage format, fallback rules).
- [x] P0.5 Define icon catalog strategy:
  - Source and size of icon set.
  - Pagination/virtualization requirements.
  - Selection behavior on small screens and large text scale.
- [x] P0.6 Stage exit check: all contracts approved and reflected in docs before implementation stages begin.

### P0 Locked Contracts (2026-02-10)

1. Archive/Delete/Unarchive policy
   - Archiving remains the default removal path from active lists.
   - Archived habits are hidden from Home but retained with full history.
   - In-app unarchive is required via an explicit archived habits management surface.
   - Permanent delete is supported only for archived habits and is a separate destructive action.
   - Permanent delete removes the habit and all linked data (events and reminder preference rows) in one transaction.
   - Permanent delete requires stronger confirmation than archive/unarchive.
2. Relapse undo semantics
   - Undo is limited to the latest relapse event for a habit.
   - Undo specific historical relapses is not part of the quick action path.
   - No time window is enforced; the guardrail is "latest relapse only."
   - UX language must be explicit that history is being changed (for example, "Undo latest relapse").
3. Grid tap interaction contract
   - Grid cells are interactive only for past or current local days; future days are read-only.
   - Positive mode: tap toggles completion for the selected `localDayKey` (add if absent, remove if present).
   - Negative mode: tap toggles a relapse marker for the selected `localDayKey` (add if absent, clear day marker if present).
   - Positive edits are allowed from habit creation day through today.
   - Negative edits are allowed from today back to 7 local days, matching the existing relapse backdate guardrail.
4. Color strategy
   - Keep a curated expanded default palette with accessible contrast coverage across light and dark foregrounds.
   - Add optional custom color selection in create/edit flow.
   - Persist colors as uppercase `#RRGGBB` hex strings.
   - Existing stored colors must render exactly as saved; no lossy coercion to nearest preset.
   - Invalid stored hex values fall back to the app brand color for rendering safety.
5. Icon catalog strategy
   - Use Material `Icons` as the source for post-MVP icon expansion.
   - Replace chip list with icon-only grid selection.
   - Paginate by fixed pages and support horizontal page swiping once catalog size exceeds viewport.
   - Grid must adapt columns by available width and remain usable at large text scales.
   - Icon-only controls must retain accessibility labels/semantics for screen readers.

## Stage P1: Habit Form UX Upgrade (Icons + Colors)

- [x] P1.1 Replace icon chip list with compact icon-only grid selection UI.
- [x] P1.2 Expand icon catalog significantly and organize for discoverability.
- [x] P1.3 Add pagination or horizontal swiping between icon pages when icon count exceeds viewport.
- [x] P1.4 Make icon grid responsive (column count adapts to width; no overflow at large text scales).
- [x] P1.5 Remove icon text labels from selection controls while preserving accessibility semantics.
- [x] P1.6 Expand default color palette with curated accessible options.
- [x] P1.7 Add optional custom color selection flow (e.g., picker/wheel) with persisted hex values.
- [x] P1.8 Enforce contrast-safe foreground behavior for both preset and custom colors.
- [x] P1.9 Update edit flow so existing stored colors/icons always render without lossy fallback.
- [x] P1.10 Add/update widget tests for icon grid behavior, responsive layout, and color selection/persistence.
- [x] P1.11 Stage exit check: create/edit form remains stable on small screens and high text scaling with expanded icon/color options.

## Stage P2: Reminder UX Refactor (Per-Habit + Global Control)

- [ ] P2.1 Add per-habit reminder toggle and time controls into create/edit habit flow.
- [ ] P2.2 Decide and implement edit-mode behavior for reminder defaults vs existing reminder rows.
- [ ] P2.3 Add global reminders master toggle in Settings.
- [ ] P2.4 Ensure global toggle disables scheduling while preserving per-habit preferences for later re-enable.
- [ ] P2.5 Keep week-start/time-format settings behavior unchanged unless intentionally redesigned.
- [ ] P2.6 Update startup reminder sync logic to honor global toggle.
- [ ] P2.7 Add migration/default handling for global reminder setting persistence.
- [ ] P2.8 Add tests for:
  - Reminder creation via habit form.
  - Permission flows.
  - Global on/off interactions with per-habit reminders.
- [ ] P2.9 Stage exit check: reminders are predictable from both habit form and settings entry points.

## Stage P3: Data Lifecycle Controls (Reset, Archive, Unarchive, Delete)

- [ ] P3.1 Add in-app "Reset all data" action in Settings.
- [ ] P3.2 Require typed confirmation phrase for destructive reset execution.
- [ ] P3.3 Implement transactional data wipe across habits, events, reminders, and app settings.
- [ ] P3.4 Add post-reset UX confirmation and safe app state reinitialization.
- [ ] P3.5 Add explicit archive management UI:
  - View archived habits.
  - Unarchive action.
- [ ] P3.6 Clarify and implement permanent delete policy:
  - If supported, add a separate destructive path with stronger confirmation.
  - If not supported, document archive-only behavior clearly in-app.
- [ ] P3.7 Add tests for reset and archive/unarchive/delete lifecycle behavior, including restart persistence.
- [ ] P3.8 Stage exit check: destructive actions require deliberate confirmation and leave no ambiguous state.

## Stage P4: Tracking Interaction Expansion (Undo Relapse + Grid Day Editing)

- [ ] P4.1 Add undo support for negative-mode relapse tracking per approved contract.
- [ ] P4.2 Ensure streak recalculation and UI summaries update correctly after relapse undo.
- [ ] P4.3 Add interactive grid cell tapping for positive-mode day completion toggles.
- [ ] P4.4 Add interactive grid cell tapping for negative-mode day relapse toggles per approved rules.
- [ ] P4.5 Enforce day-edit guardrails (future dates, backdate bounds, duplicate protection).
- [ ] P4.6 Preserve hybrid time model invariants when editing historical days.
- [ ] P4.7 Add tests for:
  - Grid-driven event add/remove.
  - Undo/re-log parity between quick-action and grid interactions.
  - Timezone and midnight edge behavior after grid edits.
- [ ] P4.8 Stage exit check: quick action and grid editing paths remain behaviorally consistent.

## Stage P5: Documentation and Post-MVP Acceptance

- [ ] P5.1 Update `README.md` with new post-MVP interaction patterns and constraints.
- [ ] P5.2 Update `MVP.md` or create addendum docs for archive/delete and reminder architecture changes.
- [ ] P5.3 Add a dedicated regression checklist for destructive actions and grid editing.
- [ ] P5.4 Perform manual Android smoke pass on emulator and physical device for all post-MVP features.
- [ ] P5.5 Stage exit check: docs and tested behavior match shipped functionality.

## Post-MVP Acceptance Checklist

- [ ] PM-A1 Icon selection is compact, icon-only, and scalable to a large catalog.
- [ ] PM-A2 Color selection supports richer defaults and optional custom colors with safe contrast.
- [ ] PM-A3 Per-habit reminder controls are available in create/edit, with coherent global reminder control.
- [ ] PM-A4 Users can intentionally reset all app data through guarded confirmation flow.
- [ ] PM-A5 Negative-mode relapse supports undo with clear streak/event outcomes.
- [ ] PM-A6 Grid day interactions can add/remove events while preserving hybrid time invariants.
- [ ] PM-A7 Archive/unarchive/delete behavior is explicit in UX and documentation.
