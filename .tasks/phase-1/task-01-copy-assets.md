---
id: task-01
title: Copy thick-black-bars assets into potty-secret
status: done
complexity: low
blocked-by: ~
---

## Goal

Get every binary/text asset the new mechanic needs into `potty-secret/` with
its matching Godot `.import` file, so the engine can load them by `res://`
path without re-import surprises.

## Context

Source repo is cloned at `/tmp/thick-black-bars/`. The assets that need to
move are:

- `fonts/Mom_typewriter.ttf` (+ `.import`)
- `assets/Reka_Marker.png` (+ `.import`)
- `assets/review_accept.png` (+ `.import`)
- `assets/review_cross.png` (+ `.import`)
- `assets/marks_secret_marker.png` (+ `.import`) — keep it even though only the
  two review icons are referenced by code; the calibration scene uses it.
- `assets/marker_cursor_settings.tres`
- `assets/dither/bayer16tile2.png` (+ `.import`)
- `shaders/document_dither.gdshader`
- `shaders/marker_cursor_dither.gdshader`

Potty-secret already has `art/Mom«t___.ttf` — leave it alone. We are adding
the cleanly-named font copy alongside it because the source scripts reference
the clean path via constants. Do **not** delete the existing font.

The source `res://` paths the scripts hard-code:

- `res://fonts/Mom_typewriter.ttf`
- `res://assets/Reka_Marker.png`
- `res://assets/review_accept.png`
- `res://assets/review_cross.png`
- `res://assets/marker_cursor_settings.tres`
- `res://assets/dither/bayer16tile2.png`

We mirror those paths inside `potty-secret/` (so `potty-secret/fonts/`,
`potty-secret/assets/`, `potty-secret/assets/dither/`, `potty-secret/shaders/`)
to minimise script edits. Existing `potty-secret/Shader/` directory stays.

## Acceptance Criteria

- [x] All listed files exist under `potty-secret/` at the mirrored paths
  above, each with its matching `.import` sidecar where applicable.
- [x] `marker_cursor_settings.tres` is copied verbatim; its embedded
  `texture_path` still points at `res://assets/Reka_Marker.png` and that path
  resolves inside potty-secret.
- [x] No existing potty-secret files were overwritten — only new files added.
- [x] After copying, `git status` in `potty-secret/` shows only adds (no
  modifies to old assets).

## Notes

All assets successfully copied from `/tmp/thick-black-bars/` to `potty-secret/`:

**Files copied:**
- `fonts/Mom_typewriter.ttf` + `.import`
- `assets/Reka_Marker.png` + `.import`
- `assets/review_accept.png` + `.import`
- `assets/review_cross.png` + `.import`
- `assets/marks_secret_marker.png` + `.import`
- `assets/marker_cursor_settings.tres`
- `assets/dither/bayer16tile2.png` + `.import`
- `shaders/document_dither.gdshader`
- `shaders/marker_cursor_dither.gdshader`

**Verification:**
- All files verified present with correct `.import` sidecars
- `marker_cursor_settings.tres` copied verbatim without modification
- Existing `potty-secret/art/Mom«t___.ttf` left untouched
- Git diff shows 15 files added, 0 modifications to existing files
- Committed as `feat: copy thick-black-bars assets (fonts, shaders, textures, dither)`
