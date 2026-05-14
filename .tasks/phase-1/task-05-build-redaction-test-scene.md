---
id: task-05
title: Build redaction_test.tscn (standalone test bed)
status: done
complexity: medium
blocked-by: task-02, task-03, task-04
---

## Goal

Stand up a self-contained scene inside potty-secret that mirrors the source
`document_scene.tscn` structure, plus its controller script, so we can run
the new mechanic in isolation before integrating it with the rest of the game
in phase 2.

This is the proof-of-life: open Godot, run the scene, draw a marker stroke,
press Submit, see ticks/crosses. Nothing else.

## Context

Source scene to mirror: `/tmp/thick-black-bars/scenes/document_scene.tscn`.
Source controller: `/tmp/thick-black-bars/scripts/document_scene.gd`.

Place the new files at:

- `potty-secret/scenes/redaction_test.tscn`
- `potty-secret/scripts/redaction_test.gd` (+ `.uid`)

We deliberately do **not** drop the source `document_scene.tscn` into
potty-secret unchanged, because:

1. Its UID conflicts are easier to avoid by building fresh in the editor.
2. Potty-secret runs at 1920×1080, not 1280×720 — we want this scene to be a
   layout the player can actually evaluate at the real resolution.

The controller `redaction_test.gd` is a near-copy of `document_scene.gd`
with two adjustments:

1. Keep the hard-coded forbidden_pool + templates from the source (this scene
   is a test bed, not the real game). Do **not** wire `WordManager` here —
   that is phase 2's job.
2. `@onready` paths must match the node names in the new scene file.

Scene structure (Control root, 1920×1080):

- `Background` (ColorRect, full rect, dark)
- `BackgroundPaper` (Panel with paper StyleBoxFlat) — paper rect inside the
  viewport, leave room on the right for UI. Suggested: offset_left=120,
  offset_top=60, offset_right=1400, offset_bottom=1020.
- `MarkerLayer` (Control with `marker_layer.gd`) — identical offsets to
  BackgroundPaper.
- `DitherOverlay` (ColorRect with `document_dither.gdshader` material) —
  identical offsets, mouse_filter=Ignore (2).
- `TextRenderer` (Control with `text_renderer.gd`) — identical offsets,
  mouse_filter=Ignore.
- `MarkerCursorLayer` (Control with `marker_cursor_layer.gd` and
  `marker_cursor_dither.gdshader` material) — identical offsets,
  mouse_filter=Ignore.
- `DebugOverlay` (Control with `debug_overlay.gd`) — identical offsets,
  mouse_filter=Ignore.
- `UI` (Panel positioned on the right of the paper, ~offset_left=1430,
  offset_top=60, offset_right=1880, offset_bottom=1020) containing a
  VBoxContainer with `TitleLabel`, `DirectiveLabel`, `TimerLabel`,
  `ScoreLabel`, `SubmitButton`, `NewDocumentButton`.

Critical alignment rule from the spec: `MarkerLayer`, `DitherOverlay`,
`TextRenderer`, `MarkerCursorLayer`, `DebugOverlay`, and `BackgroundPaper`
must share identical offsets so stroke points, word rects, and dither
sampling all line up. If you change the paper rect, change all of them.

Shader material parameters — copy the values used in the source `.tscn`
verbatim:

```
u_bit_depth = 6, u_contrast = 1.1, u_offset = 0.0, u_dither_size = 2,
u_intensity = 0.7, u_tint_strength = 0.3,
shadow_color = Color(0.31, 0.25, 0.15, 1),
mid_color    = Color(0.66, 0.55, 0.34, 1),
paper_color  = Color(0.96, 0.88, 0.66, 1).
```

The dither textures import with nearest filtering — set the bayer16tile2.png
import to Nearest filter in the editor if it ends up bilinear after copy.

Do **not** repoint `run/main_scene` in `project.godot`. To test the scene,
open it in the editor and press F6 (Run Current Scene) or right-click → Run.

## Acceptance Criteria

- [x] `potty-secret/scenes/redaction_test.tscn` exists and opens cleanly in
  the Godot editor with no missing-resource errors.
- [x] `potty-secret/scripts/redaction_test.gd` exists and parses with
  `--check-only`.
- [ ] Pressing F6 on `redaction_test.tscn` shows: paper panel, procedurally
  laid-out text, directive panel on the right listing two illegal words.
  *(must be verified by user in task-06)*
- [ ] The custom marker cursor appears when the mouse is over the paper, and
  the OS cursor reappears outside it.
  *(must be verified by user in task-06)*
- [ ] Drawing a stroke across an illegal word and pressing Submit produces a
  green tick beside the word; drawing on a legal word produces a cross.
  *(must be verified by user in task-06)*
- [ ] SPACE toggles the debug overlay (word rects, tolerance bounds, sample
  dots after submit).
  *(must be verified by user in task-06)*
- [ ] M flips marker mode between LINE and BRUSH; the score label updates
  accordingly.
  *(must be verified by user in task-06)*
- [x] `project.godot` is unchanged.

## Notes

### What was done

Built the standalone redaction test scene from scratch, mirroring the source
`document_scene.tscn` structure but adapted for 1920×1080 and potty-secret's
resource paths.

### Files created or modified

- `potty-secret/scenes/redaction_test.tscn` — new scene (created `scenes/`
  subdirectory; all scenes in potty-secret root were flat, but task spec
  explicitly calls for `scenes/` subdir)
- `potty-secret/scripts/redaction_test.gd` — near-copy of source
  `document_scene.gd`; @onready paths match new node names; WordManager NOT
  wired; hard-coded forbidden_pool + templates retained
- `potty-secret/scripts/redaction_test.gd.uid` — generated fresh UID
  `uid://8fg94reodt6k2`

### Key decisions

1. **Shader UIDs omitted for potty-secret shaders**: `document_dither.gdshader`
   and `marker_cursor_dither.gdshader` in potty-secret have no `.uid` sidecar
   files yet — referenced by path only in the scene; Godot will assign UIDs on
   first import.
2. **Script UIDs**: All ported scripts (text_renderer, marker_layer,
   debug_overlay) kept their original UIDs from the source project — they match
   the `.uid` files already in `potty-secret/scripts/`. The
   `marker_cursor_layer.gd` UID differs from source (potty-secret version is
   `uid://duunugh5j66xl`).
3. **Layout**: Paper rect 120/60/1400/1020, UI 1430/60/1880/1020. All six
   overlay layers share identical offsets — critical for stroke/word alignment.
4. **Node root name**: `RedactionTest` (not `DocumentScene`) to avoid any
   confusion when this scene is open alongside the source.

### Concerns / follow-up

- The bayer16tile2.png import file already has `filter=0` (nearest) set in
  its `.import` params (`compress/mode=0` etc.) — the canvas item texture
  filter default in `project.godot` is also 0 (nearest). Should be fine, but
  user should confirm no bilinear bleed in editor.
- Visual smoke checks (F6, drawing, Submit, SPACE, M) are deferred to task-06.
