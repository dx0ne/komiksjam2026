---
id: task-03
title: game2.gd — submit, next-document, marker-mode + debug shortcuts
status: done
complexity: medium
blocked-by: task-02
---

## Goal

Finish `game2.gd` by porting the submit and next-document flow from
`redaction_test.gd`, plus the SPACE / M keyboard shortcuts. After this
task:

- Pressing **Submit Review** locks the marker, scores each word box,
  places ticks / crosses, and blinks missed illegal words red. Score label
  shows a stub verdict (`APPROVED` / `REVIEW FAILED`) and counts — but
  **no scene change to `ending.tscn`** and no real win/lose evaluation.
- Pressing **New Document** clears the paper, regenerates the text using
  the current `WordManager.current_toilet_words` (does NOT pull a fresh
  batch — only the toilet handle does), and unlocks the marker.
- **SPACE** toggles `DebugOverlay`.
- **M** flips `MarkerLayer.mode` between `LINE` and `BRUSH`, updates the
  score label to show the current mode.
- The `gimme_toilet_btn2` briefcase trigger stays stubbed for phase 2
  (calls a no-op or just prints — scoring + verdict is phase 3).

## Context

### Files

- `potty-secret/game2.gd` — the controller, extended in task-02; this
  task adds the back half.
- `potty-secret/scripts/redaction_test.gd` — the source of the submit
  scoring algorithm; copy `_sample_stroke`, `_on_submit_pressed`,
  `_coverage_tier`, `_format_score`, `_update_score_label` verbatim,
  adjusting only the @onready paths if the game2 UI uses different node
  names.
- `potty-secret/scripts/text_renderer.gd`, `marker_layer.gd`,
  `debug_overlay.gd` — for the methods called by submit
  (`set_locked`, `apply_word_marks`, `apply_review_states`,
  `clear_strokes`, `reset_review`, `clear_stroke_samples`).

### Required behavior

#### Submit handler

Port `_on_submit_pressed` from `redaction_test.gd` essentially verbatim:

1. Sample every stroke in `marker_layer.strokes` via `_sample_stroke`.
2. For each word box in `text_renderer.word_boxes`, compute coverage
   tier with `_coverage_tier`; classify as illegal / legal; tally
   `fully`, `halfly`, `missed`, `false_redactions`, `score`.
3. Build `word_marks` list (tick / cross per word) and
   `missed_indices` list.
4. Compute `verdict` text from `score` vs `max_score *
   APPROVAL_FRACTION`.
5. Push the verdict + counters into the score label.
6. `debug_overlay.set_stroke_samples(all_samples)`,
   `marker_layer.apply_word_marks(word_marks)`,
   `text_renderer.apply_review_states(missed_indices)`,
   `marker_layer.set_locked(true)`.

No scene change. No call to `_on_time_out`. The verdict text in the score
label is the only signal.

#### New Document handler

Connect `NewDocumentButton.pressed` to a handler that calls
`_generate_document()` from task-02 (which already does the
clear-strokes / reset-review / unlock-marker / clear-samples /
update-directive / update-score-label sequence).

Important difference vs. the toilet handle: this button does **not**
pull a new batch from `WordManager`. The illegal set stays the same;
only the document text reshuffles. That matches the phase 2 spec
("next-document action clears the surface" — the *batch* changes only on
toilet pulls).

#### Keyboard shortcuts

Add to `_unhandled_input` (or extend the existing `_input`, your choice
— but `_unhandled_input` is cleaner so the buttons can absorb their own
key events first):

- `KEY_SPACE` (pressed, not echo) → `debug_overlay.toggle()`, mark
  input handled.
- `KEY_M` (pressed, not echo) → flip `marker_layer.mode` between
  `MarkerLayer.DrawMode.LINE` and `MarkerLayer.DrawMode.BRUSH`, update
  score label with `"Marker mode: LINE"` or `"Marker mode: BRUSH"`, mark
  input handled.

Watch out — task-02 may have used `_input` for game-action shortcuts
(`quit`, `rand_toilet_msg`, `rand_document`). Pick whichever Input
callback minimises double-handling; both are fine as long as you don't
let the same key fire two handlers.

#### `gimme_toilet_btn2` stub

The existing `game.gd` uses this for "end the game". For game2 phase 2:
keep the connection if it's already wired in the scene, but the handler
should just `print("end-game trigger — deferred to phase 3")` or
`pass`. Do not call `_on_time_out` or change scene.

#### `_on_time_out` stub

Already stubbed in task-02; leave it alone. The clock can fire its
signal but nothing happens.

### Out of scope

- Real scoring / win-lose / `ending.tscn` transition — phase 3.
- Localised document text from the original game (Polish copy from
  `paper.tscn`). Procedural placeholder text from the test scene is fine
  for phase 2.
- Any change to `WordManager` itself.

## Acceptance Criteria

- [ ] `potty-secret/game2.gd` still parses cleanly:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script game2.gd`
  exits 0.
  **Known limitation (same as task-02):** `--check-only --script` exits 1 with
  `Identifier not found: WordManager` because the autoload is not registered
  in headless single-script mode. The full project import (below) is the
  authoritative parse check.
- [x] Full project headless import still succeeds:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --quit`
  exits 0 with no new warnings.
  **Verified:** EXIT 0, no warnings.
- [x] `SubmitButton.pressed` is connected to `_on_submit_pressed`; the
  handler locks the marker, places ticks / crosses, applies missed-word
  blink via `text_renderer.apply_review_states`, and updates the score
  label.
- [x] `NewDocumentButton.pressed` is connected to a handler that calls
  `_generate_document` (clears strokes, regenerates text using current
  `WordManager.current_toilet_words`, unlocks marker).
- [x] `KEY_SPACE` toggles `DebugOverlay`; `KEY_M` flips marker mode and
  updates the score label.
- [x] `gimme_toilet_btn2` is wired to a no-op / print stub (NOT to
  `_on_time_out`).
- [x] Submit does NOT change scene to `ending.tscn`.
- [x] `project.godot` is unchanged.

## Notes

### What was done

Extended `potty-secret/game2.gd` (task-02 skeleton) with the submit /
next-document flow and debug shortcuts. No other files were modified.

### Changes to `potty-secret/game2.gd`

- **`_ready`:** Added `submit_button.pressed.connect(_on_submit_pressed)`,
  `new_document_button.pressed.connect(_generate_document)`, and
  `$gimme_toilet_btn2.gui_input.connect(_on_gimme_toilet_btn2_gui_input)`.
- **`_unhandled_input`:** New method — `KEY_SPACE` → `debug_overlay.toggle()`;
  `KEY_M` → flip `marker_layer.mode` between LINE/BRUSH and update score
  label. Uses `_unhandled_input` (not `_input`) so buttons absorb their key
  events first. Game-action shortcuts (`quit`, `rand_toilet_msg`,
  `rand_document`) remain in the existing `_input`.
- **`_sample_stroke`**, **`_on_submit_pressed`**, **`_coverage_tier`**,
  **`_format_score`**: ported verbatim from `potty-secret/scripts/redaction_test.gd`.
  No node-path adjustments needed — `game2.gd` already used the same
  `@onready` names as `redaction_test.gd`.
- **`_on_gimme_toilet_btn2_gui_input`**: no-op stub — prints and returns;
  does not call `_on_time_out` or change scene.
- `_on_time_out` stub left unchanged (phase 3 concern).

### Key decisions

- `gimme_toilet_btn2` has no `unique_name_in_owner` in the scene, so it is
  accessed via `$gimme_toilet_btn2` (direct child path), not `%gimme_toilet_btn2`.
- `_generate_document` is connected directly to `NewDocumentButton.pressed`
  (no wrapper function) — it already performs the full clear / regenerate /
  unlock sequence and does NOT call `WordManager.get_next_batch`, satisfying
  the "no new batch on New Document" requirement.
- Submit handler ends with `marker_layer.set_locked(true)` and a comment
  confirming no scene change; the `_on_time_out` stub is untouched.

### Verification results

| Command | Exit code | Notes |
|---------|-----------|-------|
| `--check-only --script game2.gd` | 1 | Expected — WordManager autoload absent in single-script mode (same as task-02) |
| `--quit` (full project) | 0 | No errors, no warnings |
