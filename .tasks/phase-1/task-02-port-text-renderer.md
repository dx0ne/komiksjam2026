---
id: task-02
title: Port text_renderer.gd
status: in-progress
complexity: low
blocked-by: task-01
---

## Goal

Bring `scripts/text_renderer.gd` into potty-secret unchanged and verify it
parses against the project.

## Context

`text_renderer.gd` from the source repo references
`TYPEWRITER_FONT_PATH = "res://fonts/Mom_typewriter.ttf"`. Since task-01 puts
the font at the same `res://` path, the script can be copied verbatim.

Place it at `potty-secret/scripts/text_renderer.gd` and copy the matching
`.uid` file (`text_renderer.gd.uid`) so the existing scene UID references in
the source `document_scene.tscn` keep working when we re-instance it in
task-05.

`text_renderer.gd` declares `class_name TextRenderer`. Potty-secret has no
existing class with that name (greppable: `RedactedLabel`, `LinePainter`,
`Paper` are the existing class_names) so there is no collision.

## Acceptance Criteria

- [ ] `potty-secret/scripts/text_renderer.gd` exists, byte-identical to
  `/tmp/thick-black-bars/scripts/text_renderer.gd`.
- [ ] `potty-secret/scripts/text_renderer.gd.uid` exists, byte-identical to
  the source `.uid`.
- [ ] `godot --headless --path potty-secret --check-only --script
  scripts/text_renderer.gd` returns exit 0.
- [ ] No edits to any other existing potty-secret file.

## Notes
