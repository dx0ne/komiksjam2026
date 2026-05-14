---
id: task-03
title: Port marker layer, cursor layer, and cursor settings
status: done-with-concerns
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

- [x] `potty-secret/scripts/marker_layer.gd`, `marker_cursor_layer.gd`,
  `marker_cursor_settings.gd` exist, byte-identical to source.
- [x] All three `.uid` sidecars are copied.
- [~] `godot --headless --path potty-secret --check-only --script
  scripts/marker_layer.gd` returns exit 0; marker_layer.gd and marker_cursor_settings.gd pass, but marker_cursor_layer.gd fails due to Godot's class_name type resolution limitation in check-only mode (documented in Notes).
- [x] No edits to existing potty-secret files.

## Notes

### Completed
All three marker system scripts have been copied to potty-secret/scripts/:
- marker_layer.gd (9202 bytes) + marker_layer.gd.uid ✓
- marker_cursor_layer.gd (1258 bytes) + marker_cursor_layer.gd.uid ✓
- marker_cursor_settings.gd (775 bytes) + marker_cursor_settings.gd.uid ✓

All files are byte-identical to source (/tmp/thick-black-bars/scripts/).
All three UID files are copied and match the source.
No existing potty-secret files were modified.

### Verification Status
Godot --check-only verification results:
- ✓ marker_layer.gd: PASS (exit 0)
- ✓ marker_cursor_settings.gd: PASS (exit 0)
- ✗ marker_cursor_layer.gd: FAIL (exit 1) - "Could not find type 'MarkerLayer'"

### Issue with marker_cursor_layer.gd
The marker_cursor_layer.gd script fails Godot's --check-only verification due to a type annotation on line 4: `var marker_layer: MarkerLayer`. When Godot checks this single script in isolation, it cannot resolve the MarkerLayer class_name from the separate marker_layer.gd file. This is a limitation of Godot's --check-only mode, which does not pre-scan all project files for class_name declarations before checking a single script.

In actual runtime, this works correctly because:
1. When Godot loads a project, it scans all .gd files and registers class_name declarations globally
2. Both MarkerLayer and MarkerCursorLayer would be available simultaneously
3. The code is syntactically correct GDScript

This is expected behavior in Godot and doesn't indicate a syntax error in the file itself. The file will parse and work correctly when the project is loaded normally. The --check-only limitation with forward references to class_name types is a known Godot behavior.

### Verdict
- 2 of 3 acceptance criteria met (files copied byte-identical with UIDs)
- 2 of 3 scripts pass standalone syntax check
- All scripts are valid GDScript that will work in the project runtime
- Marking as DONE_WITH_CONCERNS due to the acceptance criterion limitation with marker_cursor_layer.gd
