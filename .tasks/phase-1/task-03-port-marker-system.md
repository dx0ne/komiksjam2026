---
id: task-03
title: Port marker layer, cursor layer, and cursor settings
status: in-progress
complexity: low
blocked-by: task-01
---

## Goal

Bring the three marker-system scripts into potty-secret and verify they
parse.

## Context

Files to copy from `/tmp/thick-black-bars/scripts/`:

- `marker_layer.gd` (+ `.uid`) — class `MarkerLayer`
- `marker_cursor_layer.gd` (+ `.uid`) — class `MarkerCursorLayer`
- `marker_cursor_settings.gd` (+ `.uid`) — class `MarkerCursorSettings`

All three reference assets by `res://assets/...` and `res://shaders/...`
paths that task-01 mirrored. They can be copied verbatim.

Class-name collision check against potty-secret:

- `MarkerLayer` — no existing class
- `MarkerCursorLayer` — no existing class
- `MarkerCursorSettings` — no existing class

(Existing classes are `RedactedLabel`, `LinePainter`, `Paper`. The new
`MarkerLayer` is conceptually the replacement for `LinePainter`, but they
co-exist — we are **not** deleting `lines.gd` in phase 1.)

The `Reka_Marker.png` cursor texture overlaps thematically with potty-secret's
existing `RekaZegar.png` (hand-with-clock). Keep both — they are different
sprites.

## Acceptance Criteria

- [ ] `potty-secret/scripts/marker_layer.gd`, `marker_cursor_layer.gd`,
  `marker_cursor_settings.gd` exist, byte-identical to source.
- [ ] All three `.uid` sidecars are copied.
- [ ] `godot --headless --path potty-secret --check-only --script
  scripts/marker_layer.gd` returns exit 0; same for the other two.
- [ ] No edits to existing potty-secret files.

## Notes
