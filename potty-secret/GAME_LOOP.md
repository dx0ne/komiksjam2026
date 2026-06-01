# Potty Secret — game loop (`game2`)

Main scene: `game2.tscn` · Logic: `game2.gd` · Words: `WordManager` (autoload)

## Fantasy

You are a ministry clerk during a timed shift. Confidential memos land on your desk filled with words from the master list. Toilet intel tells you which terms are **forbidden today**. Black out only those words. Wrong marks hurt you; a clean sheet earns a stamp. Yank the toilet handle to discard the current memo and pull a new one — but every reroll is a new memo with new intel, so there is no "same paper, new intel" option. The longer you work, the harder it gets: typos appear on the memo, synonyms replace toilet intel in the final phase, and decoy entries are sprinkled into the memo to bait wrong marks.

## One shift (high level)

```
START SHIFT
  ├─ clock starts (ShiftClock, 180s)
  ├─ shift score = 0.0 (WordManager.shift_score)
  ├─ spawn paper #1 (template + planted canonicals, phase-aware display variants + decoys)
  └─ roll toilet intel from paper #1's planted canonicals (phase-aware obfuscation)

LOOP until clock ends:
  ├─ Read toilet strip (N intel entries, N == planted_total of current paper)
  ├─ Mark words on memo (marker on TextRenderer)
  │     │
  │     ├─ Per-word at-mark scoring runs on stroke finish.
  │     ├─ Post-it updates live: "X/Y" (X correct planted marked, Y planted total)
  │     ├─ Penalty badge counts wrong marks on this paper.
  │     ├─ Shift score updates immediately (cumulative across papers).
  │     └─ Floating popups show +1 / +2 / -0.5 per scored word.
  │
  └─ Pull toilet handle (only action available)
        ├─ Lock current paper's score (already locked at mark-time; no extra penalty)
        ├─ Check for stamp (all planted marked, zero wrongs) → stamp if earned
        ├─ Spawn new paper from briefcase (Teczka anchor)
        └─ Re-roll toilet intel from new paper's planted canonicals

CLOCK ENDS
  ├─ Lock current paper (no penalty, just check stamp eligibility)
  └─ ending.tscn (good if shift_score > 0.0)
```

The briefcase sprite (`send_to_briefieng`) is **scenery only** in phase-7. The `_send_to_briefing` function is retained as dead code in `game2.gd` for diff clarity and can be deleted in a follow-up.

## Paper content

| Source | What |
|--------|------|
| `WordManager.master_list` | Pool of canonical entries; each entry has `canonical` + `typos[]` + `synonyms[]` |
| Template | Randomly chosen from `WordManager.templates`; each template has 2 or 3 `{illegal_*}` slots |
| Document planted words | N canonicals (N == 2 or 3 depending on template) drawn from master list, each rendered as a phase-dependent display variant |
| Document decoys | 0–4 non-planted canonicals appended as a "Cross-reference also noted: …" sentence at end of document (phase-dependent count and similarity) |
| Toilet intel | One display entry per planted canonical, obfuscated per phase |

Intel **always** describes the current paper's planted canonicals (since task-03). Variant selection differs between paper-side rendering and intel-side rendering — see "Difficulty phases" below.

Word-box matching uses canonicalization: `text_renderer` runs longest-match N-gram canonicalization (up to 3 tokens) over the rendered text, so multi-word canonicals like "the Grays" or "Project Blue Book" become a single markable box. A box's `illegal` flag is true iff its canonical is in `WordManager.current_toilet_canonicals`; `planted` is true iff in the session's `planted_canonicals`; `decoy` is true iff in the session's decoy set.

## Difficulty phases

Phase is computed every spawn / intel roll from elapsed shift time:

| Elapsed time | Phase | Paper renders planted as | Intel renders as | Decoys |
|---|---|---|---|---|
| 0 – 60s   | `TEACHING` | canonical | canonical | 0 |
| 60 – 120s | `LIGHT`    | per slot 50/50 canonical or typo | canonical | 1–2, edit-distance ≤ 4 from any intel string |
| 120 – 180s | `FULL`     | per slot 50/50 canonical or typo | per slot 50/50 canonical or synonym | 2–4, edit-distance ≤ 2 from any intel string |

Decoy selection prefers non-planted canonicals whose display variants are visually similar (Levenshtein ≤ threshold) to one of the intel strings; if too few similar candidates exist, tops up with random non-planted canonicals. Decoys are rendered into a phase-appropriate trailing sentence ("Cross-reference also noted: …", "Additional surveillance flags: …", etc.).

Implementation: `game2.gd._current_phase`, `_paper_variant_mode_for_phase`, `_intel_variant_mode_for_phase`, `_pick_decoy_canonicals`, `_build_decoy_text`.

## Marking rules and at-mark scoring

Scoring happens at **stroke finish** (`_on_stroke_finished` → `_score_stroke_incremental`). Once a word transitions to `full` or `wrong`, its state is locked — pulling the handle (i.e. starting a new paper) doesn't unwind any deltas, it simply ends this paper's accumulation.

| Prior state | Coverage tier on this stroke | Target (planted ∧ on-intel)? | Result | Delta |
|---|---|---|---|---|
| untouched | half | yes | → partial | **+1** |
| untouched | full | yes | → full    | **+2** |
| partial   | full | yes | → full    | **+1** |
| untouched | half or full | no | → wrong | **−0.5** |
| partial   | any | (any) | (no change) | 0 |
| full / wrong | any | (any) | (no change) | 0 |

Coverage tiers (`COVERAGE_HALF_RATIO = 0.50`, `COVERAGE_FULL_RATIO = 0.70`, `COVERAGE_MIN_CELLS = 2`) come from cumulative samples across *all* strokes on this paper, not just the latest stroke.

Stroke color feedback:
- Stroke delta sum ≥ 0 → marker color (default)
- Stroke delta sum < 0  → red accent

## No submit penalty (phase-7)

The submit-time `-0.5` for unmarked planted words was removed in task-05. Leaving a planted word untouched is now **free** — you simply lose the +1/+2 you could have earned. The tension shifts from "submit penalty vs. reroll" to "spend more clock time scoring this paper vs. yank the handle and gamble on a better roll".

## UI feedback

| Element | Meaning |
|---------|---------|
| Post-it `X/Y` | X = count of planted words in state {partial, full}; Y = `planted_total` on **this** paper |
| Post-it shift score | `+N` / `-N` — cumulative `WordManager.shift_score`, floored to 1 decimal |
| Post-it penalty badge | Count of words in state `wrong` on this paper |
| Floating label (+1, +2, −0.5) | Per-word delta at mark time, drifts up and fades |
| Stamp on paper | Awarded when X == Y and penalty == 0 (checked on toilet pull / time-out) |
| Toilet messages | Current intel list (phase-obfuscated display variants of paper's planted canonicals) |

## Player actions

| Input | Action |
|-------|--------|
| Drag marker on paper | Redact words; per-stroke at-mark scoring runs on release |
| Toilet handle (click) | `toilet_pull()` → save & lock current paper, check stamp, spawn new paper, re-roll intel |
| Cofefe (click) | Up to 5 sips: +10 s and +1 twitch force each; label shows sips left; coffee surface shifts perspective |
| Papieros (click) | Each click while lit −1 twitch force until stub; first click lights the fuse |
| **D** | Toggle debug overlay (word boxes / samples) |
| **M** | Toggle marker draw mode (line ↔ brush) |
| **1** (debug) | `rand_toilet_msg` → `toilet_pull()` (advance paper) |
| **2** (debug) | `rand_document` → `toilet_pull()` (advance paper; same effect as 1 since task-05) |
| **7** (debug) | Skip to ending |

The briefcase sprite is *not* clickable in gameplay; its `gui_input` connection was removed in `_ready`.

## Code map (where things live)

| Concern | File / node |
|---------|-------------|
| Shift orchestration | `game2.gd` |
| Word pools, canonical / typo / synonym data, shift score | `WordManager.gd` |
| Canonicalize / display-variants API | `WordManager.canonicalize`, `WordManager.display_variants` |
| Phase classification + variant policy | `game2.gd` → `_current_phase`, `_paper_variant_mode_for_phase`, `_intel_variant_mode_for_phase` |
| Decoy selection + rendering | `game2.gd` → `_pick_decoy_canonicals`, `_build_decoy_text`, `_edit_distance` |
| Memo layout, N-gram match, planted / illegal / decoy flags | `scripts/text_renderer.gd` (`_relayout`, `set_planted_canonicals`, `set_decoy_canonicals`, `set_forbidden_words`) |
| Marker input & strokes | `scripts/marker_layer.gd` |
| Paper visuals (post-it, stamp, penalty badge, shift score) | `paper.gd` + `paper.tscn` |
| Floating score popups | `score_popup.tscn` + `score_popup.gd` |
| Toilet word display | `toilet_msg.tscn` |
| Timer | `clock.gd` (`ShiftClock`) |
| Pull handle = advance paper | `game2.gd` → `toilet_pull()` → `_advance_to_new_paper` (tween → `_save_session` → `_check_and_apply_stamp` → `_spawn_fresh_paper(true)` → `_roll_toilet_intel`) |
| At-mark scoring | `game2.gd` → `_on_stroke_finished` → `_score_stroke_incremental` + popups |
| Stamp check | `game2.gd` → `_check_and_apply_stamp` (extracted from `_send_to_briefing` in task-05) |

## Session state (`game2.gd`)

Each active paper keeps a `session` dictionary:

- `text` — full memo string (template body + optional decoy sentence)
- `planted_words` — N display variants used in the template's `{illegal_*}` slots
- `planted_canonicals` — N canonicals (source of truth for matching, intel roll, stamp eligibility)
- `planted_total` — N, cached for post-it Y
- `decoys` — canonicals chosen as decoys (rendered into the appended sentence)
- `phase` — int(Phase) at spawn time (for debug / playtest tooling)
- `strokes` — saved marker strokes
- `word_scores` — Dictionary keyed by word box index: `{state: String, points: float}`
  - `state` ∈ {`untouched`, `partial`, `full`, `wrong`}
  - `points` = cumulative delta on this word (e.g. 0 → 1 → 2)
- `stamped` — bool, set when stamp eligibility was met on lock

Global shift state (on `WordManager`):

- `shift_score: float` — cumulative, updated at mark-time only (no submit penalty)
- `current_toilet_canonicals: Array[String]` — current intel as canonicals (source of truth for matching)
- `current_toilet_words: Array[String]` — current intel as display strings (what the toilet shows)
- `good_ending: bool` — set when shift ends (true iff `shift_score > 0.0`)

## Design intent

- **Pressure:** clock + cofefe; later phases force fast decisions because intel obfuscation and decoys make every mark riskier
- **Risk:** marking the wrong word (-0.5); leaving planted words untouched (just zero, no penalty)
- **Clarity:** toilet strip = law (but the law lies in later phases); post-it X/Y = progress on this sheet; floating deltas = immediate feedback
- **Reward:** stamp on perfect page; visible cumulative shift score across the session
- **Eye-skill ramp:** TEACHING reads literally → LIGHT adds memo typos while intel stays canonical → FULL adds synonym intel and tighter decoys

Tuning knobs: `clock.gd` `wait_time`; `COVERAGE_*` / `REDACTION_TOLERANCE` in `game2.gd`; `TOILET_INTEL_COUNT`, `WORDS_IN_DOCUMENT`; phase boundaries `PHASE_TEACHING_END_S` / `PHASE_LIGHT_END_S`; decoy count and edit-distance thresholds in `_pick_decoy_canonicals`; `templates` / `master_list` in `WordManager.gd`.

For the original spec docs, see `potty-secret/docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md` (at-mark scoring transition table) and `potty-secret/docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md` (canonical/typo/synonym model + phase obfuscation + decoys).
