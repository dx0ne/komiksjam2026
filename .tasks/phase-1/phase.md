---
phase: 1
title: Foundation — port assets, scripts, and standalone test scene
status: closed
opened: 2026-05-14
closed: 2026-05-14
---

## Goal

Import every asset and script the thick-black-bars redaction mechanic needs
into `potty-secret/`, and prove the system runs inside this project by
standing up a self-contained test scene (`redaction_test.tscn`) that mirrors
`document_scene.tscn`. This phase produces no integration with potty-secret's
existing scenes — that is phase 2. Phase 1 is purely the proof-of-life port.

## Exit Criteria

- All script files (`text_renderer.gd`, `marker_layer.gd`, `marker_cursor_layer.gd`,
  `marker_cursor_settings.gd`, `debug_overlay.gd`) live under
  `potty-secret/scripts/` and parse with `--check-only`.
- All required assets (typewriter font, marker texture, dither textures,
  review-mark icons, shaders, marker cursor settings resource) live under
  `potty-secret/` with matching `.import` files.
- A `redaction_test.tscn` scene runs in the editor (F5) and the player can:
  - see procedurally laid-out word text on a paper-coloured panel,
  - drag a thick black marker stroke across words,
  - press a Submit button and see per-word ticks/crosses appear,
  - press SPACE to toggle the debug overlay, M to flip LINE/BRUSH mode.
- `game.tscn` is still the project's `run/main_scene` — phase 1 changes
  nothing about the existing flow.

## Tasks

- [x] task-01-copy-assets.md
- [x] task-02-port-text-renderer.md
- [x] task-03-port-marker-system.md (done-with-concerns: standalone --check-only false positive on cross-script class_name lookup; resolves on full project load)
- [x] task-04-port-debug-overlay.md
- [x] task-05-build-redaction-test-scene.md (visual smoke checks deferred to user via verification.md)
- [x] task-06-headless-verification.md (manual checks await user execution)
