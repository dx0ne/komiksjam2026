---
id: task-05
title: Pull = advance to new paper; briefcase deactivated
status: done
complexity: low
blocked-by: [task-03]
---

## Goal

Cut the pull lever over to its new role: it now locks the current
paper's score (no penalty for unmarked planted), spawns a new paper,
then rolls intel from the new paper's canonicals. The briefcase
`_send_to_briefing` flow is removed from gameplay; the sprite remains
as scenery. `_apply_submit_penalty` becomes unreachable from gameplay.

After this task: there is only one advance action (pull). Briefcase is
visual-only.

## Context

Current pull flow (`game2.gd:251-261`):

```gdscript
func toilet_pull() -> void:
    # ...handle bounce tween...
    tween.tween_callback(_roll_toilet_intel)
```

After the handle animation, `_roll_toilet_intel` runs, which (in task-03)
re-rolls intel display variants for the CURRENT paper's canonicals.

Current briefcase flow (`game2.gd:360-402`):

- `_on_send_to_briefieng_gui_input` → `_send_to_briefing`
- `_send_to_briefing` applies submit penalty, checks stamp, spawns new paper

Debug actions (`game2.gd:76-79`):

- `rand_toilet_msg` (key `1`) → `toilet_pull`
- `rand_document` (key `2`) → `_send_to_briefing`
- `skip_to_ending` (key `7`) → `_end_shift`

End-of-shift behavior (`game2.gd:687-690`): `_on_time_out` calls
`_send_to_briefing(false)` to finalize the active paper, then
`_end_shift`. With submit penalty gone, this becomes a plain
"freeze the paper, lock the score, transition to ending" sequence.

## Acceptance Criteria

- [x] Rewrite `toilet_pull()`:

  ```gdscript
  func toilet_pull() -> void:
      var original_pos := Vector2.ZERO
      var offset_pos := original_pos + Vector2(0, 100)
      var trans_time := 0.2

      var tween := create_tween()
      tween.tween_property(%toilet_handle, "position", offset_pos, trans_time) \
          .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
      tween.tween_property(%toilet_handle, "position", original_pos, trans_time) \
          .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
      tween.tween_callback(_advance_to_new_paper)
  ```

- [x] Add `func _advance_to_new_paper() -> void`:

  ```gdscript
  func _advance_to_new_paper() -> void:
      # Lock current paper score: simply save the current session strokes (already done at stroke time).
      # No submit penalty: unmarked planted words DO NOT incur a -0.5 deduction.
      _save_session()
      _check_and_apply_stamp()
      _spawn_fresh_paper(true)   # builds new session including planted_canonicals
      _roll_toilet_intel(true)   # rolls intel from new paper's canonicals
  ```

- [x] Remove the briefcase input wiring. In `_ready()` (`game2.gd:48-50`):

  ```gdscript
  # BEFORE:
  %send_to_briefieng.gui_input.connect(_on_send_to_briefieng_gui_input)
  # AFTER:
  # send_to_briefieng is now visual-only; no gui_input handler.
  ```

  The `%send_to_briefieng` node remains in the scene. The `_on_send_to_briefieng_gui_input` and `_send_to_briefing` functions may stay defined (for ease of reverting) but are unreferenced. Add a comment: `# DEAD CODE (phase-7): briefcase is scenery. Functions retained for diff clarity; safe to delete in a follow-up.`

- [x] Rebind debug key `2` (`rand_document` action) to call `toilet_pull` so debug-driven advance still works:

  ```gdscript
  if event.is_action_pressed("rand_document"):
      toilet_pull()
  ```

  Alternative: remove the binding entirely (debug-only and now redundant with key `1`). Implementer's call — leave a note in Notes.

- [x] Update `_on_time_out()`:

  ```gdscript
  func _on_time_out() -> void:
      # No more submit penalty — the active paper's score is whatever was earned at mark-time.
      _save_session()
      _check_and_apply_stamp()
      _end_shift()
  ```

- [x] `_apply_submit_penalty()` is no longer called from any gameplay path. Either:
  - Delete it (cleaner, follows YAGNI), OR
  - Leave it defined with a `# UNREACHABLE in phase-7+` comment for future reference.

  Recommend deletion. The function is small and easy to reconstruct from git history if a future phase wants a "bonus submit" mechanic.

- [x] Stamp behavior: `_send_to_briefing` was the only path that set `session["stamped"] = true`. Since the briefcase is gone, the stamp never fires. Options:
  - Move stamp-eligibility check into `_advance_to_new_paper` so a clean redaction still earns a stamp before the paper is replaced.
  - Drop stamps entirely for this phase (mark as a follow-up if visual reward is missed in playtesting).

  Recommend: move the stamp check into `_advance_to_new_paper`. It's a small carry-over and keeps the existing visual reward intact. The check (lines 372-390 of `game2.gd`) is straightforward — extract into a helper `_check_and_apply_stamp()` and call from both `_advance_to_new_paper` (before the spawn) and `_on_time_out` (for the last paper). The stamp briefly displays before the paper queue_frees on advance — that's the same visual the old briefcase flow produced.

- [x] Verify in editor:
  - Click toilet handle → handle animates → new paper + new intel appear together.
  - Click briefcase → nothing happens (no scoring, no penalty, no new paper).
  - Press `1` → pull (same as click handle).
  - Press `2` → pull (rebound) OR no-op (if removed). Verify matches the implementer's choice.
  - Mark a planted word fully on phase-LIGHT paper, then pull: score is preserved (no -0.5 penalty for the remaining unmarked planted slot).
  - Clean-redact a paper, pull: stamp briefly visible during the spawn transition.
  - Let the shift clock run out: ending screen loads with shift_score reflecting only at-mark scoring.

## Notes

**Status:** DONE

**Summary:** Rewritten pull mechanic to advance to new paper without submit penalty. Briefcase is now visual-only scenery with no gameplay function.

**Changes Made:**

1. **toilet_pull() rewrite** (game2.gd:400-410)
   - Changed tween callback from `_roll_toilet_intel` to `_advance_to_new_paper`
   - Animation remains identical (down 100px, back up)

2. **New _advance_to_new_paper() function** (game2.gd:413-419)
   - Saves current session
   - Checks and applies stamp eligibility via `_check_and_apply_stamp()`
   - Spawns fresh paper with animate_in=true
   - Rolls new intel from fresh paper's canonicals
   - **No submit penalty applied** — unmarked planted words incur no -0.5 deduction

3. **Briefcase disconnected** (game2.gd:53)
   - Removed `%send_to_briefieng.gui_input.connect()` line from `_ready()`
   - Marked `_on_send_to_briefieng_gui_input()` and `_send_to_briefing()` with DEAD CODE comments
   - Node remains in scene as scenery

4. **Debug key 2 rebound** (game2.gd:80-81)
   - Changed `rand_document` action from `_send_to_briefing()` to `toilet_pull()`
   - Makes key 2 now equivalent to key 1 for advancing paper
   - Kept for debug convenience; implementer chose to keep rather than remove

5. **_on_time_out() updated** (game2.gd:865-869)
   - Removed call to `_send_to_briefing(false)`
   - Now calls `_save_session()` → `_check_and_apply_stamp()` → `_end_shift()`
   - Last paper score is locked at mark-time, no submit penalty path

6. **_apply_submit_penalty() deleted**
   - Function fully removed (YAGNI principle)
   - No longer called from any gameplay path
   - DEAD CODE _send_to_briefing() originally called it but no longer does

7. **Stamp eligibility extracted** (game2.gd:591-610)
   - New `_check_and_apply_stamp()` helper function
   - Checks: all planted words marked (partial or full) AND zero wrongs
   - Called from `_advance_to_new_paper()` **before spawn** (as spec recommended)
   - Called from `_on_time_out()` for last paper handling
   - Sets `session["stamped"] = true` and displays stamp if earned
   - Maintains existing visual reward (stamp briefly visible before paper queue_frees)

8. **Cleanup:**
   - Updated stale comment in `_word_coverage_tier_from_strokes()` that referenced deleted function

**Key Design Points:**
- Pull is now the **only advance action** (briefcase removed)
- Score locked at mark-time — no penalty for unmarked planted words on advance
- Stamps still work and display (visual reward preserved)
- Time-out behavior simplified — just save, check stamp, end shift
- DEAD CODE functions retained for ease of reverting in future

**Files Modified:**
- D:\Projects\komiksjam2026\potty-secret\game2.gd (net +28 lines, -24 lines)
- D:\Projects\komiksjam2026\.tasks\phase-7\task-05-pull-rewrite-no-briefcase.md (marked complete)
