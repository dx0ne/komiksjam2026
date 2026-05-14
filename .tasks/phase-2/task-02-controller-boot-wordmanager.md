---
id: task-02
title: game2.gd — boot, document generation, toilet-handle batch wiring
status: pending
complexity: medium
blocked-by: task-01
---

## Goal

Replace the `game2.gd` stub with the boot + document-generation half of the
controller. After this task:

- Loading `game2.tscn` initialises the redaction stack with a generated
  document whose illegal set comes from `WordManager.current_toilet_words`.
- Pulling the toilet handle (`%toilet_handle` / `gimme_toilet_btn`) animates
  the handle, fetches a fresh batch of three words from `WordManager`,
  spawns three `toilet_msg.tscn` toilet-paper messages with those words
  (mirroring the current `game.gd` behavior), updates
  `WordManager.current_toilet_words`, and regenerates the document on the
  paper with the new illegal set.
- The directive label shows the current illegal words.
- The typewriter font is applied to the UI labels and buttons (same
  approach as `redaction_test.gd`).

Submit / next-document button handling, debug toggles, and the
`gimme_toilet_btn2` end-game trigger are **task-03**.

## Context

### Files

- `potty-secret/game2.gd` — the stub created in task-01; replace its body.
- `potty-secret/game2.tscn` — the scene built in task-01.
- `potty-secret/scripts/redaction_test.gd` — closest reference for the
  redaction stack boot sequence (`_load_typewriter_font`, `_apply_ui_font`,
  `_generate_document`, `_update_directive`).
- `potty-secret/game.gd` — for the existing toilet-handle behavior:
  `_on_gimme_toilet_btn_gui_input`, `toilet_pull`, `new_tolilet_msgs`,
  `clear_toiler`.
- `potty-secret/WordManager.gd` — autoload; `get_next_batch(count)` and
  `current_toilet_words`.
- `potty-secret/toilet_msg.tscn` / `toilet_msg.gd` — toilet-paper message
  scene; controller calls `.set_label(word)` and `.prep_tween()` (see
  `game.gd`).

### Required behavior

#### `_ready` flow

1. Compute `viewport_size`.
2. Load typewriter font (`res://fonts/Mom_typewriter.ttf`) and apply it to
   the UI subtree (`$UI` or equivalent) — copy `_load_typewriter_font` /
   `_apply_ui_font` helpers verbatim from `redaction_test.gd`.
3. Hook the `MarkerCursorLayer` to the `MarkerLayer`:
   `marker_cursor_layer.set_marker_layer(marker_layer)`.
4. Wire the debug overlay to the text renderer:
   `debug_overlay.text_renderer = text_renderer` and
   `debug_overlay.tolerance = REDACTION_TOLERANCE`.
5. Spawn the initial toilet messages (same batch-of-three logic as
   `game.gd::new_tolilet_msgs`) — this populates
   `WordManager.current_toilet_words` and the directive.
6. Generate the first document. `_generate_document()` reads
   `WordManager.current_toilet_words` (NOT the local `forbidden_pool` from
   the test scene).
7. Connect `%clock.time_out` — but leave the handler as a stub that just
   prints; the verdict / scene-change is phase 3.

#### `_input` flow

Keep the existing `game.gd` shortcuts that still make sense in game2:

- `is_action_pressed("quit")` → `get_tree().quit()`
- `is_action_pressed("rand_toilet_msg")` → `new_tolilet_msgs()`
- `is_action_pressed("rand_document")` → call the new-document flow
  (regenerate text on the current paper; task-03 may extend this)

Drop the `next_document` / mouse-wheel paper-scroll inputs — there's no
multi-paper stack in game2.

`KEY_SPACE` (debug toggle) and `KEY_M` (marker mode toggle) are **task-03**.

#### Toilet-handle wiring

- Connect `gimme_toilet_btn.gui_input` to a `_on_gimme_toilet_btn_gui_input`
  handler that mirrors `game.gd`: left/right click triggers `toilet_pull`.
- `toilet_pull()` animates `%toilet_handle` (down then back up, same tween
  as `game.gd`) and on completion calls `new_tolilet_msgs()`.
- `new_tolilet_msgs()` clears `%toilet_msgs_container`, calls
  `WordManager.get_next_batch(3)`, assigns to
  `WordManager.current_toilet_words`, spawns three `toilet_msg.tscn`
  instances with `.set_label(words[i])` and tweens them into position
  (same animation as `game.gd::new_tolilet_msgs`), and finally calls
  `_generate_document()` so the paper text refreshes with the new illegal
  set.

#### `_generate_document` flow

Adapt `redaction_test.gd::_generate_document` to read the illegal words
from `WordManager.current_toilet_words` instead of `active_forbidden_words`:

- Pull two illegal terms from `WordManager.current_toilet_words` (the
  master list has 6 entries and a pull yields 3; use the first two).
- Template-fill text with names + the two illegal words (reuse the
  template + names arrays from `redaction_test.gd`; this is still
  procedural placeholder copy, not a localised string from the original
  game).
- Call `text_renderer.set_document(text, illegal_words)`,
  `marker_layer.clear_strokes()`, `text_renderer.reset_review()`,
  `marker_layer.set_locked(false)`, `debug_overlay.clear_stroke_samples()`,
  `_update_directive()`, `_update_score_label("…")`.
- Guard against an empty `WordManager.current_toilet_words` — if the
  player loads game2 before the first toilet pull (initial _ready should
  have spawned messages, but be defensive), fall back to the first two
  entries of `WordManager.master_list`.

#### Constants

Use the same constants as `redaction_test.gd`:

```
REDACTION_TOLERANCE := 12.0
SAMPLE_STEP := 6.0
COVERAGE_CELL_WIDTH := 8.0
COVERAGE_HALF_RATIO := 0.50
COVERAGE_FULL_RATIO := 0.70
COVERAGE_MIN_CELLS := 2
APPROVAL_FRACTION := 0.75
TYPEWRITER_FONT_PATH := "res://fonts/Mom_typewriter.ttf"
```

These constants are used by submit logic in task-03 but it's fine to
declare them here so task-03 doesn't have to re-touch the top of the file.

### Out of scope for this task

- `_on_submit_pressed`, `_sample_stroke`, `_coverage_tier`,
  `_format_score`, `apply_word_marks`, `set_locked(true)`, missed-word
  blink — **task-03**.
- New Document button handler / next-document logic — **task-03**.
- `KEY_SPACE` (debug toggle), `KEY_M` (marker mode) — **task-03**.
- `gimme_toilet_btn2` (the briefcase end-game trigger) — **task-03** (stub
  it to do nothing for now; task-03 may keep it stubbed too since scoring
  is deferred).
- `_on_time_out` real verdict — keep the connection but stub the handler.

## Acceptance Criteria

- [ ] `potty-secret/game2.gd` parses cleanly:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script game2.gd`
  exits 0.
- [ ] Full project headless import still succeeds with no new warnings:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --quit`
  exits 0.
- [ ] `_ready` populates `WordManager.current_toilet_words` (via the
  initial toilet-message batch) before calling `_generate_document`, OR
  the document generator falls back to `WordManager.master_list` if the
  list is empty.
- [ ] `gimme_toilet_btn.gui_input` is connected and triggers
  `toilet_pull`; `toilet_pull` ends with `new_tolilet_msgs`; the latter
  refreshes `WordManager.current_toilet_words` AND triggers
  `_generate_document` so the paper updates.
- [ ] `text_renderer.set_document(...)` is called with the illegal-word
  array from `WordManager.current_toilet_words`.
- [ ] Directive label shows the two illegal words after each toilet pull.
- [ ] `project.godot` is unchanged.

## Notes

(filled in by implementer)
