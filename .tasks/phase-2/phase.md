---
phase: 2
title: Game scene integration — build game2.tscn
status: open
opened: 2026-05-14
closed: ~
---

## Goal

Build `potty-secret/game2.tscn` as the new game scene: keeps the existing
furniture (background, frame, clock, toilet handle, ashtray, hand) but
replaces the paper / redaction surface with the thick-black-bars
`TextRenderer` + `MarkerLayer` stack. The set of forbidden words for the
current paper comes from `WordManager.current_toilet_words` (driven by the
toilet-handle pull), exactly as today. Submit / next-document buttons mirror
the existing actions where possible.

Scoring and win/lose are stubbed: submitting just locks the marker and shows
post-submit marks; the next-document action clears the surface and asks
`WordManager` for a new batch.

## Exit Criteria

- `game2.tscn` runs at 1920×1080 inside the existing project.
- The decorative layout matches `game.tscn` closely enough to feel like the
  same game.
- Pulling the toilet handle still produces three toilet messages whose words
  define the illegal set for the current paper.
- The player can redact illegal words with the marker; on submit, ticks /
  crosses appear per word; missed illegal words blink red.
- Score / verdict UI is a placeholder; no scene change to `ending.tscn`.

## Tasks

- [ ] task-01-scaffold-game2-scene.md
- [ ] task-02-controller-boot-wordmanager.md
- [ ] task-03-submit-and-next-document.md
- [ ] task-04-verification.md
