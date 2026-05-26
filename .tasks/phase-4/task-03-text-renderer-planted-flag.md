---
id: task-03
title: Add planted flag and set_planted_words to text_renderer
status: done
complexity: medium
blocked-by: ~
---

## Goal

Give `text_renderer.gd` a notion of "this word is one of the document's
planted illegals" — independent of whether it's currently in toilet intel.
Phase 5 scoring needs both signals at mark time.

## Context

`potty-secret/scripts/text_renderer.gd` currently sets
`word_boxes[i]["illegal"]` based on whether the word matches current toilet
intel. With the new model:

- `illegal` keeps its meaning (= currently on intel) — drives the on-screen highlight.
- New `planted` flag = true iff this word was inserted from the template's
  `{illegal_a|b|c}` slots, regardless of intel state.

Both are needed at stroke-finished time: scoring is positive only if
`planted AND illegal-at-the-moment`.

## Acceptance Criteria

- [x] New member variable: `var planted_words: Array[String] = []`.
- [x] New setter: `func set_planted_words(words: Array[String]) -> void:` — stores normalized words and re-applies `planted` to all `word_boxes`.
- [x] `_relayout()` sets `box["planted"] = planted_lookup.has(box["word"])` for every word_box, alongside the existing `illegal` flag.
- [x] `set_forbidden_words()` does NOT alter `planted` — only `illegal`.
- [x] Calling `set_planted_words([])` is safe (clears all `planted` flags).
- [x] No regressions: a freshly loaded document with both planted-words and forbidden-words set should have `planted` AND `illegal` true for matching boxes.

## Notes

Normalize via the existing `normalize_word()` helper (or whichever
case/diacritics-stripping function the renderer already uses for `illegal`
matching) so the comparison key matches what `word_boxes` use.

This task adds API only — it does not yet wire `set_planted_words` from
`game2.gd`. Task-04 does that wiring.

### Implementation (completed)

Modified `D:/Projects/komiksjam2026/potty-secret/scripts/text_renderer.gd`:

- Added `var planted_words: Array[String] = []` member variable (line 16).
- Added `func set_planted_words(words: Array[String]) -> void:` (lines 51–58):
  - Uses `planted_words.assign(words)` to store normalized source words.
  - Builds `planted_lookup` dict via `_normalize_word()` — same normalizer used by `illegal`.
  - Iterates `word_boxes` setting `box["planted"]` independently of `illegal`.
  - Calls `queue_redraw()`.
- Updated `_relayout()` to build a parallel `planted_lookup` and emit `"planted": planted_lookup.has(canonical_word)` in every appended box dict, alongside the existing `"illegal"` key.
- `set_forbidden_words()` unchanged — it does not touch `planted`.
- Passing `[]` to `set_planted_words` is safe: empty lookup makes all `planted` false.
- Both flags use independent dictionaries so a word can be both `planted` and `illegal` simultaneously.
