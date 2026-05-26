---
id: task-03
title: Add planted flag and set_planted_words to text_renderer
status: in-progress
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

- [ ] New member variable: `var planted_words: Array[String] = []`.
- [ ] New setter: `func set_planted_words(words: Array[String]) -> void:` — stores normalized words and re-applies `planted` to all `word_boxes`.
- [ ] `_relayout()` sets `box["planted"] = planted_lookup.has(box["word"])` for every word_box, alongside the existing `illegal` flag.
- [ ] `set_forbidden_words()` does NOT alter `planted` — only `illegal`.
- [ ] Calling `set_planted_words([])` is safe (clears all `planted` flags).
- [ ] No regressions: a freshly loaded document with both planted-words and forbidden-words set should have `planted` AND `illegal` true for matching boxes.

## Notes

Normalize via the existing `normalize_word()` helper (or whichever
case/diacritics-stripping function the renderer already uses for `illegal`
matching) so the comparison key matches what `word_boxes` use.

This task adds API only — it does not yet wire `set_planted_words` from
`game2.gd`. Task-04 does that wiring.
