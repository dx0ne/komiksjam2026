---
title: Potty-Secret · Thick-Black-Bars Port
status: done
current-phase: 3
repo: private
github: https://github.com/dx0ne/komiksjam2026
created: 2026-05-14
---

## Goal

Replace potty-secret's click-on-redact-button flow with the thick-marker
word-redaction mechanic from `thick-black-bars`. New mechanic lives in a new
game scene (`game2.tscn`). Scoring/win-lose deferred — focus is on text
rendering and marker marking.

## Phases

- [x] Phase 1: Foundation — port assets, scripts, and a standalone test scene
- [x] Phase 2: Game scene — build `game2.tscn` driven by `WordManager.current_toilet_words`
- [x] Phase 3: Scoring & verdict — per-paper tally, briefcase/clock/skip end-shift, ending.tscn transition
