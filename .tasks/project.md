---
title: Potty-Secret · Thick-Black-Bars Port
status: done
current-phase: 6
repo: private
github: https://github.com/dx0ne/komiksjam2026
created: 2026-05-14
---

## Goal

Replace potty-secret's click-on-redact-button flow with the thick-marker
word-redaction mechanic from `thick-black-bars`. Phases 1-3 shipped the core
mechanic. Phases 4-6 reshape the 180s shift into a throughput game with
difficulty ramping and at-mark scoring (see
`potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`).

## Phases

- [x] Phase 1: Foundation — port assets, scripts, and a standalone test scene
- [x] Phase 2: Game scene — build `game2.tscn` driven by `WordManager.current_toilet_words`
- [x] Phase 3: Scoring & verdict — per-paper tally, briefcase/clock/skip end-shift, ending.tscn transition
- [x] Phase 4: Foundation & phase-aware document generation — data model migration + K-from-intel doc gen
- [x] Phase 5: At-mark scoring + submit penalty — replace whole-paper re-evaluation with locked per-mark deltas
- [x] Phase 6: Score popups + verification — floating +/- numbers, stroke color tuning, doc sync, playtest
