---
id: task-02
title: game2.gd — verdict + ending.tscn transition (clock, briefcase, debug shortcut)
status: done
complexity: medium
blocked-by: task-01
---

## Goal

Wire the end-of-shift verdict on `game2.gd` to mirror the original
`game.gd` flow: compute win/lose from `paper_results` (built in
task-01), set `WordManager.good_ending`, and `change_scene_to_file` to
`res://ending.tscn`.

After this task, three paths reach the verdict:

1. **Clock timeout** (`%clock.time_out`) — always ends the shift, no
   guard. Papers not yet submitted count as fails.
2. **Briefcase trigger** (`gimme_toilet_btn2`) — only ends the shift
   if the current paper has been submitted (`submit_button.disabled ==
   true` after task-01, or equivalently `paper_results.size() > 0` AND
   `marker_layer` is locked). Otherwise: print a debug message and do
   nothing — same as the original `try_end_game()`'s "all filled"
   guard.
3. **`skip_to_ending` action** (already mapped in `project.godot`) —
   developer shortcut, always ends the shift like clock timeout.

`ending.gd` already reads `WordManager.good_ending` to decide which
video to play; this phase just needs to set it correctly before the
scene change.

## Context

### Files

- `potty-secret/game2.gd` — extended.
- `potty-secret/game.gd` lines 50-57 (`_on_time_out`), 175-182
  (`try_end_game`), 31-32 (`skip_to_ending` input) — reference for the
  verdict/win-lose logic.
- `potty-secret/WordManager.gd` line 10 — defines
  `var good_ending: bool = false`.
- `potty-secret/ending.gd` line 32 — reads `WordManager.good_ending`.
- `potty-secret/project.godot` — should already define the
  `skip_to_ending` input action; verify (read-only) that it exists. If
  it does not, leave `project.godot` alone and skip the input handler;
  log the fact in Notes.

### Win condition

Mirror the original (`game.gd:50-57`):

```gdscript
var win := paper_results.size() > 0
for passed in paper_results:
    if not passed:
        win = false
WordManager.good_ending = win
get_tree().change_scene_to_file("res://ending.tscn")
```

Equivalent: `win = paper_results.size() > 0 and not paper_results.has(false)`.

The `paper_results.size() > 0` guard is new vs. the original (the
original assumed at least one paper existed because `add_document()`
ran twice in `_on_ready`). In game2 it's possible to hit the clock
timeout before submitting anything; in that edge case `win = false`
(bad ending plays), which is the intuitive outcome — you ran out of
time without reviewing a single paper.

### Required changes in `game2.gd`

1. **Replace the `_on_time_out` stub** (currently just `print(...)`) with
   the verdict path:

   ```gdscript
   func _on_time_out() -> void:
       _end_shift()
   ```

2. **Add `_end_shift()`** — extracts the win-compute + scene-change so
   all three entry points can share it:

   ```gdscript
   func _end_shift() -> void:
       var win := paper_results.size() > 0
       for passed in paper_results:
           if not passed:
               win = false
       WordManager.good_ending = win
       get_tree().change_scene_to_file("res://ending.tscn")
   ```

3. **Replace `_on_gimme_toilet_btn2_gui_input`** (currently no-op print)
   with the guarded end-game:

   ```gdscript
   func _on_gimme_toilet_btn2_gui_input(event: InputEvent) -> void:
       if event is InputEventMouseButton and event.pressed:
           _try_end_shift()
   ```

   ```gdscript
   func _try_end_shift() -> void:
       # Mirror game.gd's try_end_game: only end if the player finished
       # reviewing the current paper. After task-01, that's exactly
       # "submit_button is currently disabled" (we disable it on
       # submit, re-enable on new document).
       if submit_button.disabled:
           _end_shift()
       else:
           print("[game2] briefcase pressed but current paper not yet submitted — ignored")
   ```

4. **Add the `skip_to_ending` debug shortcut** to the existing `_input`
   block (where `quit`, `rand_toilet_msg`, `rand_document` already
   live):

   ```gdscript
   if event.is_action_pressed("skip_to_ending"):
       _end_shift()
   ```

   Verify the action exists in `project.godot` first; if it does not,
   skip this handler and note it.

### Out of scope

- Any edit to `ending.tscn`, `ending.gd`, `WordManager.gd`,
  `clock.gd`, or `project.godot`.
- Changing the verdict label format from task-01.
- Re-resetting `paper_results` after the scene change (the player
  starts a fresh `game2` from the menu next time, which re-runs
  `_ready`; the field is instance-scoped).
- Disabling the briefcase if `paper_results` is empty (the guard is on
  "current paper submitted", not "any paper submitted" — so e.g.
  pressing briefcase before submitting the very first paper just
  prints).
- A "submission count" UI on the briefcase or clock — out of scope.

## Acceptance Criteria

- [x] Full project headless import succeeds:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --quit`
  exits 0 with no new warnings.
- [x] `_on_time_out` calls `_end_shift()`.
- [x] `_end_shift()` exists and: (a) computes `win` per the spec, (b)
  sets `WordManager.good_ending`, (c) calls
  `get_tree().change_scene_to_file("res://ending.tscn")`.
- [x] `_on_gimme_toilet_btn2_gui_input` calls `_try_end_shift()` on
  mouse-button press; `_try_end_shift()` only runs `_end_shift()` when
  `submit_button.disabled` is true.
- [x] `skip_to_ending` action is wired in `_input` (or it's documented
  in Notes that the action is missing from `project.godot`).
- [x] No edits outside `potty-secret/game2.gd`.

## Notes

### What was done

Implemented verdict + ending transition in `potty-secret/game2.gd`:

1. **`_on_time_out`** — replaced the stub print with a call to `_end_shift()`.
2. **`_end_shift()`** — new function; computes `win` from `paper_results` (false if empty or any false result), sets `WordManager.good_ending`, calls `get_tree().change_scene_to_file("res://ending.tscn")`.
3. **`_on_gimme_toilet_btn2_gui_input`** — replaced no-op stub with a call to `_try_end_shift()` on any mouse-button press.
4. **`_try_end_shift()`** — new function; checks `submit_button.disabled`; calls `_end_shift()` if true, otherwise prints an ignored message.
5. **`skip_to_ending` shortcut** — added `if event.is_action_pressed("skip_to_ending"): _end_shift()` to the existing `_input` block. The action was confirmed present in `project.godot` (line 64: `skip_to_ending={`).

### Files modified

- `potty-secret/game2.gd` (only file changed)

### Verification

- Headless import (baseline before changes): exit 0, no warnings.
- Headless import (after implementation): exit 0, no warnings.
- `git diff --name-only HEAD` shows only `potty-secret/game2.gd` modified.

### `skip_to_ending` in project.godot

**Found.** `project.godot` line 64 defines the `skip_to_ending` input action. Handler wired as specified.

### Deviations from spec

None. Implementation matches the spec exactly.
