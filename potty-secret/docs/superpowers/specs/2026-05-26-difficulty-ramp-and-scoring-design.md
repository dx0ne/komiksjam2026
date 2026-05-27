# Difficulty Ramp and At-Mark Scoring

Date: 2026-05-26
Status: Approved (pending user review)
Scope: `game2.gd`, `paper.gd`, `WordManager.gd`, `text_renderer.gd`, plus one new floating-label scene.

## Goal

Reshape the 180-second shift into a throughput game: the player processes as many papers as possible, with difficulty ramping over the shift. Toilet intel is no longer rigged to the document; the document is (partially) rigged to the intel, and the rigging weakens over time. Scoring happens at mark-time and is locked once awarded.

## Current behavior (what we are changing)

- `_pick_toilet_words_for_session()` rigs toilet intel to always match the document's illegal words. Every paper is solvable without rerolling.
- `text_renderer.word_boxes[i]["illegal"]` is true iff that word appears in current intel. A document word's "illegal" status is purely a function of intel.
- `_evaluate_paper()` re-derives the whole paper's score on every stroke and on submit.
- `WordManager.shift_correct_illegal: int` counts correctly-marked illegals; stamp is awarded if all illegals are marked AND `false_redactions == 0`.

## New behavior

### 1. Phase rules (document generation)

When a new paper spawns, look at the clock to decide how many of the template's `N` slots are drawn from current intel (`K`) versus the master pool (`N - K`). Time elapsed = `180.0 - clock.game_timer.time_left`. (Add a `time_left: float` property on `ShiftClock` that returns `game_timer.time_left` to keep call sites clean.)

The first toilet intel roll happens BEFORE the first paper spawns in `_ready`, so paper #1 falls under the normal `elapsed < 60s` rule (K=N → clean-win teaching round).

| Trigger | K | Notes |
|---|---|---|
| elapsed < 60s | N | All planted words guaranteed on intel. Includes paper #1 (teaches the mechanic by being immediately winnable). |
| 60s ≤ elapsed < 120s | 1 | Exactly one planted word from intel; the rest from master pool. |
| elapsed ≥ 120s | 0 | All random. |

Implementation: `_pick_document_word_pool(count)` accepts the per-call `K` from a new `_current_k(count)` helper. K is clamped to `[0, count]`. Words from intel and master pool are de-duplicated before substitution into the template. If intel is empty or smaller than K (shouldn't happen but defensive), top up from master pool.

### 2. At-mark scoring

Each word in the document carries a `score_state`:

- `untouched` (initial)
- `partial` — has earned +1
- `full` — has earned cumulative +2
- `wrong` — has earned -0.5

On `stroke_finished`, recompute each word's cumulative coverage tier across ALL strokes on the paper. For each word whose tier *crossed a threshold it had not previously crossed* (i.e. untouched→partial, untouched→full, or partial→full), apply the transition table:

| Tier reached | `planted ∧ on-intel-now` | From state | Transition | Delta |
|---|---|---|---|---|
| partial | true | untouched | partial | +1 |
| full | true | untouched | full | +2 |
| full | true | partial | full | +1 (delta) |
| partial | true | full | no-op | 0 |
| partial or full | false | untouched | wrong | -0.5 |
| any | — | partial / full / wrong | no-op | 0 |

`on-intel-now` is evaluated once, at the moment the stroke is finished. After locking, the score does not change even if intel later flips.

A word that is `planted ∧ on-intel` but the stroke only grazes (sub-`partial` tier) is *not* scored — same as today's "tier == none" case.

The delta is added to `WordManager.shift_score` (float) immediately.

### 3. Submit-time penalty

When the player presses the briefcase:

- For each word with `planted == true AND state == untouched` → -0.5, set state = `wrong`.
- Then advance to next paper (or end the shift, if the timer is up).

This is *not* a re-evaluation — it only scores previously unscored words. In phase 3 this will hurt; that is the intended tension. The player's decision tree: reroll → maybe land intel that covers planted words → mark them, vs. submit fast and bleed.

### 4. Per-paper UI

Existing `paper.gd` displays are retuned:

- **Post-it `X/Y`**: `X` = count of planted words with `state ∈ {partial, full}`. `Y` = number of planted slots in this paper's template (2 or 3, fixed at spawn).
- **Penalty number**: count of words with `state == wrong`. Includes both stroke-time wrongs and submit-time penalties (the latter only visible briefly before paper advance).
- **Stamp**: earned iff `X == Y AND penalty == 0` at submit time. Visually the same as today.

Reroll does *not* mutate `X`, `Y`, or penalty — only the on-screen highlighting of "currently-on-intel" words.

### 5. Shift UI

`WordManager.shift_correct_illegal: int` is replaced by `WordManager.shift_score: float`. Displayed via `paper.set_shift_score(score: float)` with one decimal place. Negative values shown with leading `-` (e.g. `-1.5`); positive values with leading `+` (e.g. `+28.5`); zero shows empty string. This is the only place the player sees a negative cumulative number — important feedback if they're bleeding score.

`shift_correct_illegal` is removed entirely (no callers outside `game2.gd` and `paper.gd`). Initialize `shift_score = 0.0` at the same spot the old field was initialized in `game2.gd._ready()`.

### 6. Visual feedback (stroke color + floating numbers)

On every `stroke_finished`, accumulate the deltas from this stroke (sum across all affected words) and:

- **Stroke color**: keep current behavior, but generalize:
  - sum > 0 → marker color (green-ish accent if currently red, leave alone if currently fine)
  - sum < 0 → red (existing `Color(0.75, 0.1, 0.1, 0.9)`)
  - sum == 0 → marker color
- **Floating number**: for each *individual* word transition, spawn a small `Label` node at the word's rect center showing `+1`, `+2`, `-0.5`. Animation: fade in 0.05s, drift up 18 px and fade out over 0.55s, then `queue_free`.

Implementation: new scene `score_popup.tscn` with `score_popup.gd`. `game2.gd` spawns one per transition inside the paper's coordinate space.

### 7. Reroll behavior (unchanged mechanics, new consequence)

`toilet_pull()` and `_roll_toilet_intel()` keep their current flow. The only change in `_apply_toilet_to_current_paper()`: it refreshes the renderer's "currently on intel" flags but does *not* touch `word_scores`.

The first roll at `_ready` and subsequent rolls all use `WordManager.pick_random_words(TOILET_INTEL_COUNT)` — `_pick_toilet_words_for_session()` is deleted.

## Data model

### `WordManager.gd`

- Remove: `shift_correct_illegal: int`
- Add: `shift_score: float = 0.0`
- (Existing `pick_random_words(count)` is already suitable; no change.)

### `game2.gd`

- Add: `_paper_index: int = 0` (increments on each `_spawn_fresh_paper`)
- `session` dict additions:
  - `"planted_words": Array[String]` — replaces `"document_words"` (rename for clarity)
  - `"word_scores": Dictionary` — keyed by word_box index, value `{state: String, points: float}`
  - `"planted_total": int` — `N`, cached for post-it Y
- Remove `_evaluate_paper`, `_color_stroke_by_result` (replaced by `_score_stroke_incremental`), `_pick_toilet_words_for_session`.
- Add:
  - `_current_k(count: int) -> int`
  - `_score_stroke_incremental(stroke_index: int) -> Dictionary` — returns `{deltas: Array, sum: float, wrongs_added: int}`
  - `_spawn_score_popup(world_pos: Vector2, delta: float)`
  - `_apply_submit_penalty() -> int` — returns count of new wrongs

### `text_renderer.gd`

- `word_boxes[i]` gets a new key: `"planted": bool`, set in `_relayout()` based on a `planted_words: Array[String]` member.
- New setter: `set_planted_words(words: Array[String])`. Called by `_load_session` after `set_document`.
- `"illegal"` keeps its current meaning (currently on intel) — still drives the visual highlight.

### `paper.gd`

- `set_postit(x, y)` semantics change but signature stays. Caller already passes the new meaning.
- `set_shift_score(score: float)` — change parameter type, update label format string to `"%.1f"`.

### New: `score_popup.tscn` + `score_popup.gd`

- Root: `Node2D` with a `Label` child.
- Script accepts `setup(text: String, color: Color)` and runs the fade/drift tween, freeing itself on completion.

## Code changes (file-by-file summary)

| File | Change type |
|---|---|
| `WordManager.gd` | Rename `shift_correct_illegal` → `shift_score`, change type to float. |
| `game2.gd` | Replace `_evaluate_paper`, `_pick_toilet_words_for_session`, `_color_stroke_by_result` with incremental scoring + phase-aware doc generation + submit penalty. Add `_paper_index`. |
| `text_renderer.gd` | Add `planted` flag and `set_planted_words()`. |
| `paper.gd` | Update `set_shift_score` parameter type to `float`, handle negative values in label format. |
| `clock.gd` | Add `time_left: float` wrapper property forwarding to `game_timer.time_left`. |
| `score_popup.tscn` + `.gd` | New. Floating delta labels. |

## Risks and open items

1. **Phase 3 feels punishing**: submit penalty + low chance of intel match means phase 3 papers can net negative score per paper. Players may end up worse than skipping. *Mitigation*: leave it — the user explicitly chose "penalize all unmarked planted at submit". Monitor in playtest.
2. **Reroll spam in phase 3**: optimal strategy may be "reroll continuously until any planted word is on intel, then mark". The 0.4s handle animation is the only cost. Could feel grindy. *Mitigation*: leave alone for now, but flag for playtest.
3. **Word boundary edge cases**: planted multi-word phrases. `_single_token_master_words()` already filters these for the document. No change in behavior.
4. **First-paper override**: paper #1 with K=0 means the player may submit a 0-marked paper and eat -2 or -3 immediately. *Mitigation*: optionally show a small "PULL FOR INTEL →" arrow hint on paper #1. **Decision: defer to playtest, not in initial scope.**
5. **Floating label coordinate space**: words are in `text_renderer` local space, but the popup needs to sit on the paper at a stable position. Spawn the popup as a child of `paper` (not `text_renderer`) with position translated via `paper.text_renderer.position + word_rect.get_center()`.

## Out of scope

- Changing the 1.25s post-stamp delay
- Adding reroll cooldown or per-paper reroll limit
- Stamp visual change
- Adjusting `COVERAGE_*` thresholds or `REDACTION_TOLERANCE`
- Ending-screen score display (separate touch-up if needed)
- Tuning the phase boundaries (60/120) post-playtest — that's a tuning task, not design
