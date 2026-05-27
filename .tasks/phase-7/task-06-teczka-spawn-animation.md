---
id: task-06
title: Paper spawn animation originates from Teczka briefcase
status: in-progress
complexity: low
blocked-by: [task-05]
---

## Goal

Replace the current paper spawn animation (slides in from offset
`+200,+100`) with one that originates from between the `Teczka` and
`Teczka2` sprites in the background canvas group. Visually anchors the
briefcase as the source of new papers, completing the "briefcase
becomes scenery, but meaningful scenery" promise from the design.

After this task: every new paper visibly slides out from the briefcase
into its working position on the desk.

## Context

Current spawn animation (`game2.gd:118-125`):

```gdscript
var offset_pos := Vector2(randf_range(-30.0, 0.0), randf_range(-30.0, 0.0))
if animate_in:
    active_paper.position += Vector2(200, 100)
    var tween := create_tween()
    tween.tween_property(active_paper, "position", offset_pos, 0.35) \
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
else:
    active_paper.position = offset_pos
```

The briefcase sprites in `game2.tscn`:

- `Teczka` (unique-name id 1944249299) at `position = Vector2(1901, 466)` — parent: `CanvasLayer_background/CanvasGroup/Node2D`. Uses `art/Teczka.png`.
- `Teczka2` (unique-name id 295684005) at `position = Vector2(1939, 457)` — same parent. Uses `art/Teczka2.png`.

Midpoint of the two sprite positions: approximately `Vector2(1920, 461)`.

The active paper is parented to `%papers_container`. `Teczka` /
`Teczka2` are on a different CanvasLayer, so to position the paper at
the briefcase's spot we need to convert the briefcase's global position
into `papers_container`'s local space. Use `papers_container.to_local(teczka_global_pos)`
where `teczka_global_pos = %Teczka.global_position` (or a midpoint
computed from both).

Important: the briefcase sprites are in `CanvasLayer_background`. If
that CanvasLayer has a non-identity transform or offset, the global
position may not map cleanly. Verify by inspecting the scene tree in
the editor or by reading `game2.tscn` for any transform applied to
`CanvasLayer_background` / `CanvasGroup`. If complications arise, the
implementer may hardcode the midpoint `Vector2(1920, 461)` (or
empirically-tuned values) directly — that's an acceptable simplification
for v1.

## Acceptance Criteria

- [ ] In `_spawn_fresh_paper(animate_in)` (`game2.gd:105-130`), replace the spawn-animation block with a Teczka-anchored tween. Pseudocode:

  ```gdscript
  var offset_pos := Vector2(randf_range(-30.0, 0.0), randf_range(-30.0, 0.0))
  if animate_in:
      var teczka_a := get_node_or_null("%Teczka") as Sprite2D
      var teczka_b := get_node_or_null("%Teczka2") as Sprite2D
      var spawn_global: Vector2
      if teczka_a != null and teczka_b != null:
          spawn_global = (teczka_a.global_position + teczka_b.global_position) * 0.5
      else:
          spawn_global = Vector2(1920, 461)  # hardcoded fallback if unique-name lookup fails
      var spawn_local := %papers_container.to_local(spawn_global)
      active_paper.position = spawn_local
      # Optional: slight rotation start so the paper looks like it tumbles out.
      active_paper.rotation = deg_to_rad(randf_range(-8.0, 8.0))
      var tween := create_tween().set_parallel(true)
      tween.tween_property(active_paper, "position", offset_pos, 0.35) \
          .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
      tween.tween_property(active_paper, "rotation", 0.0, 0.35) \
          .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
  else:
      active_paper.position = offset_pos
      active_paper.rotation = 0.0
  ```

  Note the tween easing changes from `EASE_IN` to `EASE_OUT` — the paper should DECELERATE into its resting position, not accelerate away from the briefcase.

- [ ] Confirm that `%Teczka` and `%Teczka2` are accessible from `game2.gd` via the `%`-prefix unique-name resolver. The scene already declares them with `unique_id` attributes — verify the `unique_name_in_owner` flag is set on those nodes. If not, set it: open `game2.tscn` in the editor, select each sprite, enable "Access as Unique Name" in the inspector. (Implementer note: this may already be set; the `unique_id` attribute in the .tscn suggests yes, but unique-name access in code is a separate flag.)

- [ ] If unique-name access doesn't work (returns null), fall back to absolute pathing: `get_node("CanvasLayer_background/CanvasGroup/Node2D/Teczka")`. Note in Notes which method was needed.

- [ ] Input handling: input on the active paper should not fire while the spawn tween is in flight (otherwise the player could start marking before the paper lands). The cleanest fix is to lock the marker layer for the duration of the tween:

  ```gdscript
  if animate_in:
      # ... existing animate setup ...
      active_paper.marker_layer.set_locked(true)
      tween.tween_callback(func(): active_paper.marker_layer.set_locked(false)).set_delay(0.35)
  ```

  Add this only inside the `animate_in` branch — the non-animated branch leaves the marker unlocked as before.

- [ ] Smoke-test in the editor:
  - First paper (animate_in=false): no animation, paper appears in resting position.
  - Pull lever → next paper: visibly tweens from the briefcase corner into the working area over ~0.35s with a slight rotation settle. Marker input is locked until the tween finishes.
  - Repeat across several pulls — the spawn point should be consistent (same Teczka midpoint every time), the resting position varies slightly via the existing `offset_pos` jitter.

- [ ] If the visual feels too floaty or too snappy, the implementer may tune the duration (0.25–0.50s) and rotation range (±5–10°) inline. Document the final values in Notes.

## Notes

_Filled in after task completion._
