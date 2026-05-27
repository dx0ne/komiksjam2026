---
phase: 7
title: Eye-skill via obfuscated intel
status: open
opened: 2026-05-27
closed:
---

## Goal

Replace the K-rigging difficulty model with canonical-based matching:
intel always names the paper's planted words at the canonical level, but
display forms are obfuscated with typos and synonyms, and obfuscation
plus decoy density ramp with elapsed time. Removes the K=0 dead state
and the pull-spam loop. Briefcase becomes scenery (papers spawn from
between the `Teczka` + `Teczka2` sprites); pull is the only advance
action and is free.

## Exit Criteria

- `WordManager.master_list` migrated to canonical-entry shape: `{canonical, typos[], synonyms[]}`. All existing 28 entries have at least 1 typo and 1 synonym authored.
- `WordManager.canonicalize(word)` returns canonical for any variant or canonical, `""` for unknown words. `WordManager.display_variants(canonical, mode)` returns the pool for a given obfuscation mode.
- `WordManager.pick_random_canonicals(count)` returns canonicals (replaces `pick_random_words` semantics where appropriate); `current_toilet_words` continues to hold the *display strings* shown on intel, plus a parallel `current_toilet_canonicals` holds the canonicals for matching.
- `game2.gd._build_session()` picks canonicals first; renders each planted slot in the template as a display variant chosen by the phase rule.
- Intel rolls AFTER paper generation (using the paper's planted canonicals) — not from a random pool. The old "roll intel in `_ready` before paper #1" trick is removed.
- A new `_current_phase()` replaces `_current_k()`, returning `PHASE_TEACHING` / `PHASE_LIGHT` / `PHASE_FULL` based on elapsed time (0–60s / 60–120s / 120–180s).
- Decoy words are appended to each paper as a phase-aware noise sentence (0 / 1–2 / 2–4 decoys), rendered as display variants chosen to be visually close to intel's variants. Marking a decoy yields the existing -0.5 wrong-mark penalty.
- `text_renderer.gd` no longer drives `illegal` from membership in `current_toilet_words` (string match). It uses `WordManager.canonicalize(box.word)` and tests membership in `WordManager.current_toilet_canonicals`. Behavior: a paper word marked correctly iff its canonical is in the current intel canonical set.
- Pull lever: `toilet_pull()` now locks current paper score, spawns a new paper, then rolls intel from the new paper's canonicals. No clock cost.
- Briefcase: `_on_send_to_briefieng_gui_input` no longer triggers `_send_to_briefing`. The sprite remains in the scene as scenery. The keyboard debug action `rand_document` (key `2`) is similarly disconnected from `_send_to_briefing` (or rebound to `toilet_pull` so debug still works).
- `_apply_submit_penalty` is removed from the active loop (function may stay in tree, unreachable from gameplay; or be deleted — implementer's call).
- Paper spawn: animation starts from the midpoint of `Teczka` (1901, 466) and `Teczka2` (1939, 457) in the background canvas group, tweens to the working desk position over ~0.35s.
- Playtest checklist `.tasks/phase-7/playtest-results.md` exists, covering: teaching-phase clean win, light-phase intel obfuscation, full-phase paper-and-intel obfuscation, decoy mismarking penalty, pull-as-advance flow, briefcase no longer interactive, Teczka spawn animation.

## Reference

Design spec: `potty-secret/docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md`

Previous (superseded) difficulty spec: `potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md` — difficulty-model sections only.

## Tasks

- [ ] task-01-canonical-data-model.md
- [ ] task-02-paper-gen-canonical.md
- [ ] task-03-intel-from-paper.md
- [ ] task-04-decoy-injection.md
- [ ] task-05-pull-rewrite-no-briefcase.md
- [ ] task-06-teczka-spawn-animation.md
- [ ] task-07-playtest-checklist.md
