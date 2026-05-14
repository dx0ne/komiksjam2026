---
title: Potty-Secret · Thick-Black-Bars Port
repo: private
---

## Goal

Import the new word-based text rendering and marker-redaction mechanic from
`github.com/dx0ne/thick-black-bars` into `potty-secret/` as a new game scene
(`game2.tscn`). The new scene replaces the click-on-redact-buttons flow in the
current `game.tscn` / `paper.tscn` with the thick-marker-stroke flow: text is
laid out word-by-word, each word has a hit-box, and the player drags a thick
black marker over forbidden words.

Scope is limited to the game scene. Intro, menu, ending, and outro scenes stay
untouched. Scoring and win/lose decisions are explicitly out of scope for now
— we wire up the rendering and marking, and stub the verdict.

## Source

- Spec: `/tmp/thick-black-bars/docs/2026-05-14-rendering-marking-dithering-spec.md`
- Reference scene: `/tmp/thick-black-bars/scenes/document_scene.tscn`
- Reference scripts: `text_renderer.gd`, `marker_layer.gd`, `marker_cursor_layer.gd`,
  `marker_cursor_settings.gd`, `debug_overlay.gd`, `document_scene.gd`

## Target

- Engine: Godot 4.6, `gl_compatibility`, 1920×1080 viewport
- Autoload `WordManager` keeps its master list and `current_toilet_words` API
- Existing decor (background, frame, clock, toilet handle, ashtray, hand) is
  preserved in the new scene; the paper/redaction surface is the only thing
  swapped out
- New scene file: `potty-secret/game2.tscn`
- `project.godot` is **not** repointed yet — `game.tscn` remains main scene
  until the new flow is tested

## Phases

- Phase 1: Foundation — copy assets and scripts, stand up a standalone
  redaction-test scene that mirrors `document_scene.tscn` and verifies the new
  system runs inside potty-secret
- Phase 2: Game scene integration — build `game2.tscn` that combines the new
  text/marker system with potty-secret's existing furniture (background, clock,
  toilet, hand) and drives forbidden-words from `WordManager.current_toilet_words`
- Phase 3 (deferred): Scoring, ending wiring, win/lose verdict
