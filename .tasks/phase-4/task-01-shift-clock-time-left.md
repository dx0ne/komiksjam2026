---
id: task-01
title: Add ShiftClock.time_left getter
status: pending
complexity: low
blocked-by: ~
---

## Goal

Expose `time_left` directly on `ShiftClock` so callers (notably `game2.gd`'s
new phase-selection logic) don't reach through `game_timer`.

## Context

`potty-secret/clock.gd` currently only exposes the inner `Timer` node
(`game_timer`). The new phase rules (spec §1) compute `elapsed = 180.0 -
clock.time_left` at every paper spawn. A wrapper property keeps call sites
clean.

## Acceptance Criteria

- [ ] `ShiftClock.time_left: float` returns `game_timer.time_left` (or equivalent property-getter pattern).
- [ ] No existing `clock.gd` callers regress.
- [ ] `clock.time_left` is callable from `game2.gd` without warnings.

## Notes

Simplest pattern in GDScript 2:

```gdscript
var time_left: float:
    get: return game_timer.time_left if game_timer else 0.0
```

Guard against `game_timer == null` for safety during init.
