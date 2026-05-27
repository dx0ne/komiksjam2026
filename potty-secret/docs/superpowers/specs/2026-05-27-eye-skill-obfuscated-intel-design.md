---
title: Eye-Skill via Obfuscated Intel
status: draft
date: 2026-05-27
supersedes: docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md (difficulty model only)
---

# Eye-Skill via Obfuscated Intel

## Problem

Playtest of the K-rigging difficulty model exposed a structural randomness problem in the late shift. With `K=0` in phase 3 (120–180s), the planted words on the paper and the words on the toilet intel are drawn from independent pools. The player has no information they can act on — the only viable action is to spam the toilet handle hoping the next random intel trio happens to overlap with the planted slots. Pull is free, so the optimal play degrades into reroll spam, and "skill of the eye" never engages because there is nothing on the page to scan *for*.

`K=1` in phase 2 only mitigates this. One guaranteed match is on intel, but the other 1–2 planted slots are still RNG, so the player still pull-spams for them.

The root cause is treating *probability of overlap* as the difficulty dial. The fix is to remove RNG-as-difficulty entirely and replace it with *reading difficulty*: the intel always covers the planted words at the canonical level, but the displayed forms are obfuscated, and the player has to recognise the match through typos, synonyms, and decoys.

## Design intent

- Every paper is solvable. Intel always names (some obfuscation of) the planted words.
- Difficulty comes from how hard the obfuscation is to read, and how many lookalike decoys try to fool the eye.
- The "pull the lever" action is no longer a gamble for better RNG — it is a clean "next paper" advance, at a small clock cost that creates per-paper time pressure.
- The briefcase art stays. It is the visual spawn point for new papers, not an interactive control.

## Data model

`WordManager.master_list` is replaced by a list of **canonical entries**:

```gdscript
[
    {
        "canonical": "ALIENS",
        "typos": ["ALLENS", "ALOIENS", "ALIENZ", "ALIANS"],
        "synonyms": ["THEM", "OUTSIDERS", "VISITORS"],
    },
    {
        "canonical": "MINISTER",
        "typos": ["MNISTER", "MINSITER", "MIINSTER"],
        "synonyms": ["BOSS", "CHIEF"],
    },
    ...
]
```

Two helpers on `WordManager`:

- `canonicalize(word: String) -> String` — reverse lookup from any variant/canonical to canonical. Returns `""` if `word` is not in any entry (i.e., the word is a "clean" non-target).
- `display_variants(canonical: String, mode: int) -> Array[String]` — returns the pool of allowable display forms for the given obfuscation mode. Modes: `CANONICAL`, `TYPO`, `SYNONYM`, `TYPO_OR_SYNONYM`.

Canonical-to-canonical matching is the only matching rule. A mark on a paper word satisfies an intel entry if both reduce to the same canonical.

## Generation rules

Each new paper spawn does three things:

1. **Pick N planted canonicals.** N = 2–3, chosen as today (template-driven). Sample without replacement from `master_list`.
2. **Render the paper.** Each planted slot is rendered as a display variant of its canonical, picked according to the phase's paper-variant rule (see *Phase ramp*). Non-planted slots in the template are filled from a pool of *decoy canonicals* — canonicals sampled to be visually close to one of the intel display variants. Decoy slot count and visual-similarity strictness scale by phase.
3. **Render the intel.** Each planted canonical is rendered as a display variant, picked according to the phase's intel-variant rule. Intel always lists *all* N planted canonicals (no `K` knob, no subset, no extras).

Decoy similarity is judged by a simple visual-distance function on display strings: e.g., length match within ±1, edit distance ≤ 2, or shared first letter. Decoys are drawn from canonicals *not* in the current paper's planted set. Whether the decoy distance metric is procedural or curated is left to implementation; a curated decoy pool per canonical is the cleanest answer and fits the existing word-curation workflow.

## Phase ramp

| Phase | Elapsed | Paper variant rule | Intel variant rule | Decoys |
|---|---|---|---|---|
| **Teaching** | 0 – 60s | canonical only | canonical only | 0 |
| **Light** | 60 – 120s | canonical only | typo OR synonym | 1–2 obvious lookalikes |
| **Full** | 120 – 180s | canonical OR typo | typo + synonym mixed | 2–4 close-call lookalikes |

Paper #1 spawns inside the Teaching window (elapsed = 0s), so it always lands with canonical-only paper + canonical-only intel. This replaces the old "intel rolls in `_ready` before paper #1" trick — in the new model intel cannot precede the paper (intel is derived from the paper's planted canonicals), so the teaching guarantee now comes purely from the phase rule on elapsed time.

## Player actions

| Input | Action |
|---|---|
| Drag marker on paper | At-mark scoring (rules unchanged — see *Scoring*) |
| Toilet handle (click) | `_pull()` → lock current paper score, spawn new paper + new intel, -2s on `ShiftClock` |
| Cofefe (click) | +10s on `ShiftClock` (unchanged) |
| Briefcase (`Teczka` + `Teczka2`) | Non-interactive scenery. New papers visually originate from between the two sprites on spawn |
| **1** (debug) | Pull lever |
| **7** (debug) | Skip to ending (unchanged) |
| **D**, **M** | Debug overlay / marker mode (unchanged) |

The briefcase as an interactive submit button (`_send_to_briefing`) and the submit-time penalty subsystem (`_apply_submit_penalty`) are removed from the active loop. The code can stay in tree for now (commented or behind a debug flag) but is not reachable from gameplay.

## Scoring

Rules are unchanged in *value* but reframed in *trigger condition*:

| Coverage tier | Match check | Result |
|---|---|---|
| ≥ 50% coverage | `canonicalize(marked_word)` is in current intel canonicals | +1 (first), +2 if reaches full from untouched, +1 (partial → full) |
| ≥ 50% coverage | `canonicalize(marked_word)` is NOT in current intel canonicals (decoy or clean) | -0.5 |
| No coverage | — | No delta |

A word's score is **locked** once it transitions to `full` or `wrong`. Reroll-of-intel does not exist anymore (pull replaces the whole paper), so the locked-deltas concern from phase 5 is moot, but the lock invariant stays for re-stroke handling on the same paper.

The "planted vs. on-intel" distinction the old TextRenderer carried (`"planted"` and `"illegal"` flags) collapses: in the new model, every planted word is on-intel by construction. The `illegal` flag becomes equivalent to "canonical is in current intel canonicals," computed at render time and at intel roll. Decoy words are flagged `"decoy"` — same scoring as any non-target wrong mark (-0.5), but the flag is useful for debug overlay and analytics.

## Visual: papers spawn from the briefcase

When `_pull()` spawns a new paper, the paper's transform is animated from the midpoint of `Teczka` (1901, 466) and `Teczka2` (1939, 457) into its working position on the desk. A short tween (~0.3s) with a slight rotation feels right; the exact curve is a frontend-design call.

This replaces the current instant-replace. The animation should not block input — the new paper is markable as soon as the tween finishes, ideally fading in word boxes once it lands.

## What this kills

- The `K=0` dead state. Intel always names planted canonicals at the canonical level.
- Spam-pull-for-RNG. Pull does not change the canonical match shape; it just trades the current puzzle for a fresh one.
- The submit-penalty path. No briefcase, no `_apply_submit_penalty`.
- The "planted but not illegal" branch of TextRenderer. Planted ⇔ on-intel by construction.

## What this adds

- Curated `variants` data: typos + synonyms per canonical. Authoring task, not engineering.
- `canonicalize()` and `display_variants()` on `WordManager`.
- Decoy selection in document generation (curated decoy pools per canonical is the cleanest path; procedural near-neighbour search is the fallback).
- Phase-aware variant picker for both paper rendering and intel rendering.
- Tween animation from `Teczka` to working position on paper spawn.

## Deferred

- **Character-over-character typewriter strike-overs.** Visual effect where two letters are typed over each other — fits the ministry typewriter aesthetic. Worth doing later; not blocking.
- **Briefcase repurposing.** Could become a bonus submit ("triple score this paper, then advance") in a future phase. For now, scenery only.
- **Foreign-language synonyms.** "Aesopian language" (Cold War coded euphemisms) could be a phase-4 obfuscation layer. Future.

## Open tuning knobs

- **Pull cost (-2s).** Carried over from the earlier discussion when pull-spam was a concern. With briefcase gone, spam is no longer the issue, but -2s still creates per-paper time pressure and makes cofefe meaningful (cofefe = +10s ≈ 5 pulls of headroom). Default to -2s; trivial to retune.
- **Phase boundaries (60s / 120s).** Same as today. Revisit after playtesting the new ramp.
- **Decoy count per phase.** "1–2 obvious" and "2–4 close-call" are starting points. Tune via playtest.
- **Variant pool sizes.** 3–5 typos and 2–4 synonyms per canonical is enough variety without huge content cost. Tune as content grows.

## Code map (estimated touch list)

| Concern | File | Change |
|---|---|---|
| Canonical data model | `WordManager.gd` | Replace `master_list` strings with dicts; add `canonicalize`, `display_variants` |
| Document generation | `game2.gd` (template fill) | Pick canonicals, pick display variants by phase, add decoy slots |
| Intel generation | `WordManager.gd` (`pick_random_words`) | Return intel as canonicals + display variants; replace random-word-from-pool semantics |
| Word flags | `scripts/text_renderer.gd` | Add `decoy` flag; rewire `illegal` to compute from canonical-in-intel-canonicals |
| Pull action | `game2.gd` (`toilet_pull`) | Now spawns new paper + new intel, -2s clock, locks current paper score |
| Briefcase | `game2.gd` (`_send_to_briefing`) | Remove from input; sprite stays in scene |
| Submit penalty | `game2.gd` (`_apply_submit_penalty`) | Remove from active loop |
| Paper spawn animation | `paper.gd` / `game2.gd` | Tween from `Teczka` position into working position on spawn |
| Phase rules | `game2.gd` (`_current_k`) | Replace `_current_k()` with `_current_phase()` returning the variant + decoy rules |
| Data file | new: `variants.json` or similar | Curated canonicals + typos + synonyms + decoy pools |

## Implementation impact

Medium. The biggest cost is content — authoring the variant pool — not engineering. Engineering changes are localised to `WordManager`, `game2.gd` document/intel generation, and a small TextRenderer flag update. The spawn animation is a small additional task. Scoring code and stroke handling are untouched.

Recommend bundling as **Phase 7** in `.tasks/`, with sub-tasks roughly: (1) data model + canonicalize, (2) variant authoring, (3) paper + intel generation rewrite, (4) decoy logic, (5) pull semantics + briefcase removal, (6) Teczka spawn animation, (7) playtest.
