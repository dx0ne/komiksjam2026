# Potty Secret — game loop (`game2`)

Main scene: `game2.tscn` · Logic: `game2.gd` · Words: `WordManager` (autoload)

## Fantasy

You are a ministry clerk during a timed shift. Confidential memos land on your desk filled with words from the master list. Toilet intel tells you which terms are **forbidden today**. Black out only those words. Wrong marks hurt you; a clean sheet earns a stamp. Send papers to briefing and stack up correct redactions before the clock runs out. The longer you work, the fewer planted words are guaranteed on intel—forcing you to reroll or gamble.

## One shift (high level)

```
START SHIFT
  ├─ clock starts (ShiftClock, 180s)
  ├─ shift score = 0.0 (WordManager.shift_score)
  ├─ spawn paper (random memo from master_list, difficulty-aware rigging)
  └─ roll toilet intel (3 random words from WordManager.pick_random_words)

LOOP until clock ends:
  ├─ Read toilet strip (3 words)
  ├─ Mark forbidden words on memo (marker on TextRenderer)
  ├─ Post-it updates live: "+X/Y" (X correct planted, Y planted total this paper)
  │   Floating popups show +1/+2/-0.5 per marked word
  │
  ├─ OPTION A — Pull toilet handle
  │     └─ New random forbidden trio
  │        Post-it X recomputed (may increase/decrease based on new intel)
  │        Scored words keep their deltas locked (no re-scoring)
  │
  └─ OPTION B — Briefcase (send_to_briefing)
        ├─ Apply submit penalty: unscored planted words → -0.5 each
        ├─ Shift score updated with penalty
        ├─ Stamp if marked_planted == planted_total AND no false redactions
        └─ New paper, new toilet intel

CLOCK ENDS
  ├─ Auto-brief current paper (apply penalty, score it, no new paper)
  └─ ending.tscn (good if shift_score > 0.0)
```

## Paper content

| Source | What |
|--------|------|
| `WordManager.master_list` | Pool of all possible words |
| Document | N words (2–3) chosen with partial rigging to current intel (K words from intel, N-K from master pool) |
| Toilet intel | 3 random words from `WordManager.pick_random_words()` |

Rigging level K depends on **elapsed time** (see "Difficulty phases" below). On reroll, toilet intel changes but document content is *not* regenned—only the "currently on intel" flags recompute.

Illegal tokens = word boxes in `TextRenderer` whose `"illegal"` flag is true (i.e., the word is in current intel).

## Difficulty phases

Each paper's rigging level K is determined at spawn time by elapsed clock:

| Elapsed time | K | Effect |
|---|---|---|
| 0 – 60s | N | All planted words are on intel (easiest) — includes paper #1 (clean-win teaching round) |
| 60 – 120s | 1 | Exactly 1 planted word on intel (medium) |
| 120 – 180s | 0 | No planted words on intel (hardest) |

`K` words are drawn from current intel; the remaining `N - K` from master pool. Words are deduplicated. If intel or master pool is too small, top up from the other.

Intel is rolled in `_ready` BEFORE the first paper spawns, so paper #1 gets the full K=N treatment.

## Marking rules and at-mark scoring

| Coverage tier | Result | Score transition |
|---|---|---|
| No coverage | Untouched | No delta |
| ≥ 50% coverage (half) | Partial | If planted ∧ on-intel: **+1** (untouched → partial) |
| ≥ 100% coverage (full) | Full | If planted ∧ on-intel: **+2** (untouched → full) or **+1** (partial → full) |
| ≥ 50% on non-planted/illegal word | Wrong | **-0.5** (untouched → wrong, for any non-target) |

**Key:** Scoring happens at mark-time (stroke finish), not at briefcase. Once a word is scored, its delta is **locked** — reroll does not change it.

Stroke color feedback:
- Sum of deltas this stroke > 0 → green accent
- Sum of deltas this stroke < 0 → red
- Sum == 0 → marker color

## Submit-time penalty

When briefcase is clicked:
- For each planted word with `state == untouched` (never marked, never penalized) → apply **-0.5**, set state = `wrong`.
- Shift score updated immediately.

This is the tension: short-circuit and bleed points, or reroll and hope for intel.

## UI feedback

| Element | Meaning |
|---------|---------|
| Post-it `X/Y` | X = count of planted words in state {partial, full}; Y = planted total on **this** paper |
| Post-it shift score | `+N` or `-N` — cumulative shift score (floored to 1 decimal place) |
| Post-it penalty badge | Count of words in state {wrong} |
| Floating label (+1, +2, -0.5) | Per-word delta, appears at mark time and drifts up |
| Stamp on paper | Perfect redaction (X == Y, penalty == 0) at submit time |
| Toilet messages | Current forbidden list |

## Player actions

| Input | Action |
|-------|--------|
| Drag marker on paper | Redact words; trigger stroke scoring on release |
| Toilet handle (click) | `toilet_pull()` → new forbidden trio, same memo, X/Y refresh |
| Briefcase (click) | `_send_to_briefing()` → apply submit penalty, score paper, maybe stamp, new memo |
| Cofefe (click) | +10 s on shift clock |
| **D** | Toggle debug overlay (word boxes / samples) |
| **M** | Toggle marker line / brush |
| **1** (debug) | Toilet pull |
| **2** (debug) | Briefcase |
| **7** (debug) | Skip to ending |

## Code map (where things live)

| Concern | File / node |
|---------|-------------|
| Shift orchestration | `game2.gd` |
| Word pools & shift score | `WordManager.gd` |
| Memo layout & planted/illegal flags | `scripts/text_renderer.gd` |
| Marker input & strokes | `scripts/marker_layer.gd` |
| Post-it / stamp visuals | `paper.gd` + `paper.tscn` (Posit) |
| Floating score popups | `score_popup.tscn` + `score_popup.gd` |
| Toilet word display | `toilet_msg.tscn` |
| Timer | `clock.gd` (`ShiftClock`) |
| Post-it refresh | `game2.gd` → `_on_stroke_finished()` → `_score_stroke_incremental()` + `_refresh_postit_and_penalty()` → `paper.set_postit()` / `paper.set_shift_score()` |
| At-mark scoring | `game2.gd` → `_score_stroke_incremental()` → per-word deltas + floating popups |
| Submit penalty | `game2.gd` → `_apply_submit_penalty()` → `paper.gd` |

## Session state (`game2.gd`)

Each active paper keeps a `session` dictionary:

- `text` — memo string
- `planted_words` — N words used in the template (planted slots)
- `planted_total` — N, cached for post-it Y
- `strokes` — saved marker strokes
- `word_scores` — Dictionary keyed by word box index: `{state: String, points: float}`
  - `state` ∈ {`untouched`, `partial`, `full`, `wrong`}
  - `points` = cumulative delta (e.g., 0.0 → 1.0 → 2.0 for untouched → partial → full)

Global shift state:

- `WordManager.shift_score` — cumulative float, updated at mark-time and submit-time
- `WordManager.current_toilet_words` — active forbidden list
- `WordManager.good_ending` — set when shift ends (true iff shift_score > 0.0)

## Design intent

- **Pressure:** clock + cofefe; phase-3 gambling (reroll vs. submit)
- **Risk:** marking off-list words (-0.5); leaving planted words unscored (submit penalty)
- **Clarity:** toilet strip = law; post-it X/Y = progress on this sheet; floating deltas = immediate feedback
- **Reward:** stamp on perfect page; visible cumulative score shift across the session
- **Difficulty ramp:** early papers favor intel match → late papers force fast decisions or massive reroll spam

Tuning knobs: `clock.gd` `wait_time`, `COVERAGE_*` / `REDACTION_TOLERANCE`, `TOILET_INTEL_COUNT`, `templates` / `master_list`, phase boundaries (60/120s) in `game2.gd._current_k()`.

For full at-mark scoring transition table and difficulty justification, see `potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`.
