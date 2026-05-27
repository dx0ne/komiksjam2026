---
id: task-01
title: score_popup scene + script (fade-in / drift-up / fade-out)
status: pending
complexity: low
blocked-by: []
---

## Goal

Create a standalone, self-contained popup scene that `game2.gd` can
instantiate per word transition. No `game2.gd` wiring in this task —
that is task-02. After this task the scene can be opened and previewed
in the Godot editor and exhibits the correct animation.

## Context

Spec §6 "Visual feedback":

> For each *individual* word transition, spawn a small `Label` node at
> the word's rect center showing `+1`, `+2`, `-0.5`. Animation: fade in
> 0.05s, drift up 18 px and fade out over 0.55s, then `queue_free`.

Implementation lives in a new scene `score_popup.tscn` with
`score_popup.gd`. The scene's root must accept a position assigned by
the caller (so the caller can put it at the word's rect center in
paper-local coordinates). The caller (task-02) will add the instance as
a child of `active_paper` (or `text_renderer`) and assign `position`
before/after adding to tree.

Files to create:
- `potty-secret/score_popup.tscn`
- `potty-secret/score_popup.gd`

## Acceptance Criteria

- [ ] `score_popup.gd`:
  - `class_name ScorePopup` extending `Node2D`.
  - Public API: `func show_delta(text: String, color: Color) -> void` — sets the label text + color, then starts the animation. The animation:
    1. Start at `modulate.a = 0.0`.
    2. Tween in parallel: `modulate:a → 1.0` over 0.05s (fade in), then `modulate:a → 0.0` over 0.50s (fade out, after the fade-in completes via a chained tween or a delay).
    3. Tween `position:y` upward by 18 px over the full 0.55s.
    4. On finished, `queue_free()`.
  - Default text is empty / default color is white (so the scene is editable without errors).
- [ ] `score_popup.tscn`:
  - Root `Node2D` named `ScorePopup`, script attached.
  - Single `Label` child (unique-name `%Label` so the script can resolve it via `%Label`).
  - Label font: prefer the project's existing UI font if one is obvious (look at how `paper.tscn`'s `pointsLabel*` is set up) — otherwise default Godot font is fine. Font size around 28–36 px, bold if cheap to do.
  - Label has `horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER` and `vertical_alignment = VERTICAL_ALIGNMENT_CENTER`, and the label is offset so its center sits at the root's `(0, 0)` (i.e. the spawn point in paper coordinates IS the center of the label).
- [ ] Tween uses `create_tween()` (parallel set where needed) — not `Tween` deprecated APIs. The tween must outlive the script call (assign to a local var with `set_parallel(true)` as needed; Godot 4 tweens run to completion regardless of local reference).
- [ ] No references to `game2.gd`, `WordManager`, `paper.gd`, or any project-specific singleton — this scene is fully standalone and reusable.
- [ ] Static check only: the file parses (no GDScript syntax errors when the project loads). Runtime behavior is verified in task-04.

## Notes

_Filled in by the subagent during/after implementation._
