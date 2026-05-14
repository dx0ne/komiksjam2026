---
title: Potty-Secret · Thick-Black-Bars Port
status: in-progress
current-phase: 2
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
- [ ] Phase 2: Game scene — build `game2.tscn` driven by `WordManager.current_toilet_words`
- [ ] Phase 3: Scoring & verdict (deferred)
