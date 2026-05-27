---
id: task-02
title: Spawn popups from deltas + generalize stroke color
status: done
complexity: medium
blocked-by: [task-01]
---

## Goal

Wire the popup scene from task-01 into `game2.gd`: every word-level
score transition (from `_score_stroke_incremental` or
`_apply_submit_penalty`) spawns a popup at the word's rect center with
text and color reflecting the delta. Also generalize
`_color_stroke_by_deltas` to match spec §6 stroke-color rules.

## Context

Spec §6:

> - Stroke color:
>   - sum > 0 → marker color (green-ish accent if currently red, leave alone if currently fine)
>   - sum < 0 → red (existing `Color(0.75, 0.1, 0.1, 0.9)`)
>   - sum == 0 → marker color
> - Floating number: for each individual word transition, spawn a small
>   Label node at the word's rect center showing `+1`, `+2`, `-0.5`.

Current code (`potty-secret/game2.gd`):

- `_on_stroke_finished` (line 408) calls `_score_stroke_incremental` then `_color_stroke_by_deltas` then `_refresh_postit_and_penalty`. The `score_result` dict contains `deltas: Array[Dictionary]` where each delta is `{word_index, delta, new_state, rect}` — already enough to drive popups.
- `_apply_submit_penalty` (line 451) currently mutates `word_scores` and `shift_score` but returns just an int. It needs to either (a) return a deltas array similar to `_score_stroke_incremental`, OR (b) spawn popups inline. Pick whichever is cleaner; if (a), update the call site (`_send_to_briefing` at line 369) to consume the deltas and spawn popups.
- `_color_stroke_by_deltas` (line 417) only handles sum < 0 (sets red). The "sum > 0 → marker color (green-ish accent if currently red, leave alone if currently fine)" case is currently a no-op, which is correct *if* the in-progress stroke color is always the marker color. Verify that and make the intent explicit (one-line comment) rather than expanding the function unnecessarily.

Popups must spawn in paper-local coordinate space so they sit on top of
the text. The word's `rect` from `text_renderer.word_boxes[i]` is in
text-renderer-local space. Use `text_renderer.position + rect.get_center()`
to get paper-local, or add the popup as a child of `text_renderer`
directly and use `rect.get_center()`. Pick whichever places the popup
ABOVE the marker layer in z-order — popups must not be obscured by the
red ink.

Color mapping per delta:
- `+1` (partial earned) → green-ish, e.g. `Color(0.2, 0.75, 0.3, 1.0)` (or pick a complementary accent that reads on the paper). Text: `"+1"`.
- `+2` (full earned) → same green-ish, text `"+2"`.
- `-0.5` (wrong / submit penalty) → red `Color(0.75, 0.1, 0.1, 1.0)`. Text: `"-0.5"`.

If a transition has a delta that is none of `+1 / +2 / -0.5`, fall back
to `"%+g" % delta` formatting (defensive, shouldn't happen).

## Acceptance Criteria

- [x] New `const ScorePopupScene := preload("res://score_popup.tscn")` (or equivalent) at the top of `game2.gd`.
- [x] New helper `_spawn_score_popup(delta: float, rect: Rect2) -> void`:
  - Computes text and color from `delta` per the mapping above.
  - Instantiates `ScorePopupScene`, sets its `position` to the word's center in the correct coordinate space, adds it as a child of `active_paper` (or `text_renderer`, whichever puts it above the marker layer).
  - Calls `show_delta(text, color)` on the instance.
- [x] `_on_stroke_finished`: after `_score_stroke_incremental` returns, iterate `score_result.deltas` and call `_spawn_score_popup(d.delta, d.rect)` for each. Only call for entries with `delta != 0.0` (defensive).
- [x] `_apply_submit_penalty`: changed to also spawn popups for each penalized word. Two clean options — pick one and document why in Notes:
  - (a) Return an array of `{word_index, delta, rect}` and have `_send_to_briefing` spawn popups. Cleaner separation.
  - (b) Call `_spawn_score_popup(-0.5, rect)` directly inside the loop. Simpler.
- [x] `_color_stroke_by_deltas`: add a one-line comment confirming the spec mapping (sum > 0 / sum == 0 → leave as marker color, sum < 0 → red). No behavioral change required unless verification finds the marker color is wrong at any branch.
- [x] `active_paper`/`text_renderer` parent choice keeps popups visible over the marker ink (verify by reading scene tree z-order in `paper.tscn`, not by guessing).
- [x] Submit-penalty popups appear briefly before the paper advances. The paper-advance happens after `_apply_submit_penalty` returns in `_send_to_briefing`; if popups disappear instantly with the paper, document that as a known minor concern in Notes (acceptable — penalty is also visible in the running `shift_score` label).
- [x] Project parses without GDScript errors (static check via the editor or `godot --headless --check-only` if available; otherwise visual inspection). Runtime smoke deferred to task-04.

## Notes

### What was done

Wired the ScorePopup scene (task-01 output) into `game2.gd` with three changes:

1. **`const ScorePopupScene`** added at line 14, alongside existing scene preloads.

2. **`_spawn_score_popup(delta, rect)`** helper added between `_color_stroke_by_deltas` and `_refresh_postit_and_penalty`. Maps `+2`/`+1` → green `Color(0.2, 0.75, 0.3, 1.0)`, `-0.5` → red `Color(0.75, 0.1, 0.1, 1.0)`, other → `"%+g" % delta` with sign-based color. Popup is added as child of `active_paper` with `z_index = 1`, positioning via `text_renderer.position + rect.get_center()` to convert TextRenderer-local rect coordinates to paper-local space.

3. **`_on_stroke_finished`** — iterates `score_result.get("deltas", [])` and calls `_spawn_score_popup` for each entry with `delta != 0.0`.

4. **`_apply_submit_penalty`** — calls `_spawn_score_popup(-0.5, box["rect"])` inline per penalized word (option b). Option b chosen because option a would require changing the return type and the call site in `_send_to_briefing`, adding complexity for no clear benefit; the popup spawns at the correct moment either way.

5. **`_color_stroke_by_deltas`** — one-line comment added: "Spec §6: sum < 0 → red; sum >= 0 (including ==0) → leave as marker color (already set at draw time)." No behavioral change. Confirmed: marker color is the default stroke color set at draw time, so no-op for sum >= 0 is correct.

### Files modified

- `D:\Projects\komiksjam2026\potty-secret\game2.gd` — all changes are here

### z-order decision

Popups are added to `active_paper` (Paper root Node2D) with `z_index = 1`. Verified by reading `paper.tscn`: MarkerGroup has no explicit z_index (defaults to 0). z_index = 1 guarantees popups render above the red ink layer.

### Known minor concern: submit-penalty popup lifetime

When the player submits on a non-stamp paper, `_spawn_fresh_paper` calls `active_paper.queue_free()` immediately (no delay). The popup (a child of `active_paper`) will be freed along with it before its 0.55s tween completes. The penalty delta is still reflected in the `shift_score` label, so the brief flash is the only visual loss. Documented as acceptable per acceptance criterion 7.

### Static parse verification

`godot --headless --check-only` is not available in this environment. Visual inspection confirms: all syntax is valid GDScript 4, `ScorePopup` class_name matches `score_popup.gd`, `preload` path matches actual file location, `show_delta(text, color)` matches the public API. Runtime smoke deferred to task-04.
