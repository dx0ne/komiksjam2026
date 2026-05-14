---
id: task-01
title: Scaffold game2.tscn — decor + redaction stack layout
status: pending
complexity: medium
blocked-by: ~
---

## Goal

Build a new scene file `potty-secret/game2.tscn` that visually mirrors
`game.tscn` (same background, frame, ashtray, clock, hand, coffee, paperclips,
toilet handle, post-process overlay) but replaces the `papers_container` /
`paper.tscn` subtree with the thick-black-bars redaction stack:
`BackgroundPaper` + `MarkerLayer` + `DitherOverlay` + `TextRenderer` +
`MarkerCursorLayer` + `DebugOverlay`. Attach a stub `game2.gd` script that
just `extends Node2D` and parses with `--check-only` so the scene loads
cleanly; the real controller logic comes in task-02 / task-03.

This task is layout only — no behavior beyond what's already in the ported
scripts. Pulling the toilet handle, pressing buttons, etc., are wired in
subsequent tasks.

## Context

### Source files to reference

- `potty-secret/game.tscn` — for the decor (Tlo, Ramka, Teczka, Teczka2,
  RekaZegar with clock, Kawa, Sprite2D ashtray, paperclips ×3,
  `toilet_handle/gimme_toilet_btn`, `gimme_toilet_btn2` near the briefcase,
  `marker_Node2D`, `Options`, and the post-process `CanvasLayer/ColorRect`
  with the `game2.gdshader` material).
- `potty-secret/scenes/redaction_test.tscn` — for the exact shader-material
  setup, sub-resource definitions, and layered Control offsets used by the
  redaction stack (`BackgroundPaper`, `MarkerLayer`, `DitherOverlay`,
  `TextRenderer`, `MarkerCursorLayer`, `DebugOverlay`).
- `potty-secret/game.gd` — the current controller, for reference only — do
  **not** copy it verbatim; the new `game2.gd` will be a stub here and gets
  fleshed out in task-02 / task-03.

### What stays from game.tscn

Copy every decor node verbatim into game2.tscn:

- `Tlo` (Sprite2D, background)
- `Ramka` (Sprite2D, frame)
- `Teczka`, `Teczka2` (briefcase sprites)
- `RekaZegar` (Sprite2D) with its child `clock` (`uid://cm4o4rmuagg1a`)
- `Kawa` (coffee sprite)
- `Sprite2D` at (1550, 17) using `art/Popielniczka.png` (ashtray)
- 3× `paperclip_node2d` instances (`uid://be4ckl5tcikud`)
- `toilet_handle` Node2D containing `gimme_toilet_btn`
- `toilet_msgs_container` Node2D
- `gimme_toilet_btn2` (the transparent end-game trigger over the briefcase)
- `marker_Node2D` (`uid://coi6b8h5bhedp`)
- `CanvasLayer / ColorRect` with the `ShaderMaterial` pointing at
  `Shader/game2.gdshader` (use the same shader_parameter values as
  game.tscn — copy the sub_resource verbatim)
- `Options/HBoxContainer/Options _Settings/OptionButton` subtree with the
  `options__settings.gd` script

Keep the existing `unique_name_in_owner = true` flags so `%toilet_handle`,
`%toilet_msgs_container`, `%clock`, `%papers_container` (rename) etc. still
resolve. (We will not have `%papers_container` in game2 — the new scene has
no paper stack; remove that node entirely.)

### What changes vs. game.tscn

Replace the `papers_container` Node2D + `paper_node2d` PackedScene instance
with the redaction stack from `redaction_test.tscn`. Place it where the
paper used to sit, inside the frame, at the project's 1920×1080 viewport.

A reasonable rect for the redaction surface: roughly the same horizontal
band where `paper.tscn` is positioned in the current game (the paper sprite
is scaled by ~0.93 and the container offsets it by `(654, 0)`). Aim for
something like `offset_left=480, offset_top=120, offset_right=1500,
offset_bottom=1020` — wide enough for procedural word layout but narrow
enough to leave room for the ashtray, coffee, clock, and toilet-handle
decor on either side. Tune by eye; the only hard constraint is that all
six stack layers (`BackgroundPaper`, `MarkerLayer`, `DitherOverlay`,
`TextRenderer`, `MarkerCursorLayer`, `DebugOverlay`) share **identical
offsets** — same alignment rule as `redaction_test.tscn`.

Add a UI panel for Submit / NewDocument / score / directive — mirror
`redaction_test.tscn` `UI/MarginContainer/VBoxContainer` (`TitleLabel`,
`DirectiveLabel`, `TimerLabel`, `ScoreLabel`, `SubmitButton`,
`NewDocumentButton`). Place it on the right edge of the screen, **but not
overlapping the toilet handle / briefcase area**. If the right side is too
busy, the UI can sit at the bottom strip or be tucked into a narrow
right-edge slot. Use your judgement; the goal is "the player can see
directive + score + submit / new-doc" without obscuring the existing decor.

Set `mouse_filter = 2` on `DitherOverlay`, `TextRenderer`,
`MarkerCursorLayer`, and `DebugOverlay`, same as `redaction_test.tscn`, so
they pass clicks through to `MarkerLayer`.

### Shader material values

Copy the `ShaderMaterial_dither` and `ShaderMaterial_marker_cursor_dither`
sub_resources from `redaction_test.tscn` verbatim — including parameter
values. Likewise the `StyleBoxFlat_paper` and `StyleBoxFlat_ui`.

### Controller stub

Create `potty-secret/game2.gd` with this body:

```gdscript
extends Node2D

# Phase 2 — controller stub. Document generation, toilet-handle wiring,
# submit, and next-document are implemented in task-02 and task-03.

func _ready() -> void:
    pass
```

Generate a fresh `.uid` sidecar for it (you can use any new Godot-style
UID, e.g. `uid://<random16>`). Reference the script from the root node in
`game2.tscn`.

Do **not** repoint `run/main_scene` in `project.godot` — `game.tscn`
remains the entry point until phase 3.

### What this task does NOT do

- No WordManager wiring. (task-02)
- No signal hookups for toilet handle, submit button, new-document button,
  or option button. (task-02 / task-03)
- No `_input` shortcuts. (task-03)
- No tweens. (task-02 / task-03)

## Acceptance Criteria

- [ ] `potty-secret/game2.tscn` exists, opens in the Godot editor without
  missing-resource / missing-UID errors.
- [ ] All decor nodes from `game.tscn` are present in `game2.tscn` (Tlo,
  Ramka, Teczka, Teczka2, RekaZegar/clock, Kawa, Sprite2D ashtray, 3×
  paperclip, toilet_handle/gimme_toilet_btn, toilet_msgs_container,
  gimme_toilet_btn2, marker_Node2D, CanvasLayer/ColorRect post-process,
  Options subtree).
- [ ] Redaction stack present in the same scene: `BackgroundPaper`,
  `MarkerLayer`, `DitherOverlay`, `TextRenderer`, `MarkerCursorLayer`,
  `DebugOverlay` — all sharing identical offsets, with `mouse_filter = 2`
  on the four pass-through layers.
- [ ] UI panel with `TitleLabel`, `DirectiveLabel`, `TimerLabel`,
  `ScoreLabel`, `SubmitButton`, `NewDocumentButton` exists in the scene.
- [ ] `papers_container` and the embedded `paper.tscn` instance are
  **absent** from `game2.tscn`.
- [ ] `potty-secret/game2.gd` exists with the stub body shown above and
  parses with `--check-only`:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --check-only --script game2.gd`
  returns exit code 0.
- [ ] `potty-secret/game2.gd.uid` exists with a fresh, syntactically valid
  Godot UID.
- [ ] `project.godot` is unchanged.
- [ ] Full project headless import still succeeds:
  `& "D:\Godot\Godot_v4.6.1\Godot_v4.6.1-stable_win64_console.exe" --headless --path potty-secret --quit`
  returns exit code 0 with no new missing-resource warnings.

## Notes

(filled in by implementer)
