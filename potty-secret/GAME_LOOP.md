# Potty Secret — game loop (`game2`)

Main scene: `game2.tscn` · Logic: `game2.gd` · Words: `WordManager` (autoload)

## Fantasy

You are a ministry clerk during a timed shift. Confidential memos land on your desk filled with words from the master list. Toilet intel tells you which terms are **forbidden today**. Black out only those words. Wrong marks hurt you; a clean sheet earns a stamp. Send papers to briefing and stack up correct redactions before the clock runs out.

## One shift (high level)

```
START SHIFT
  ├─ clock starts (ShiftClock)
  ├─ shift score = 0  (WordManager.shift_correct_illegal)
  ├─ spawn paper (random memo from master_list words)
  └─ roll toilet intel (3 forbidden words from THAT paper’s word pool)

LOOP until clock ends:
  ├─ Read toilet strip (3 words)
  ├─ Mark forbidden words on memo (marker on TextRenderer)
  ├─ Post-it updates live: "tak masz X/Y"
  │
  ├─ OPTION A — Pull toilet handle
  │     └─ New random forbidden trio (same paper, same text)
  │        X on post-it may change (more/fewer illegal tokens)
  │
  └─ OPTION B — Briefcase (send_to_briefieng)
        ├─ Add correct illegal marks to shift score (+N on post-it)
        ├─ Stamp if every illegal word covered & no false redactions
        └─ New paper + keep current toilet intel until next pull

CLOCK ENDS
  ├─ Auto-brief current paper (score it, no new paper)
  └─ ending.tscn (good if shift_correct_illegal > 0)
```

## Paper content

| Source | What |
|--------|------|
| `WordManager.master_list` | Pool of all possible words |
| Document | 6 random single-token words woven into a memo template |
| Toilet intel | 3 words chosen at random **from those 6** (so illegal targets always exist on the page) |

Illegal tokens = word boxes in `TextRenderer` whose normalized text matches any current toilet word.

## Marking rules

| Action | Result |
|--------|--------|
| Marker covers illegal word (half or full coverage) | Counts toward post-it **X/Y** and toward shift score on briefcase |
| Marker covers a clean (legal) word | Stroke turns red; post-it shows penalty `-N` (false redactions) |
| All illegal words covered, no false redactions | **Stamp** (`art/stempel.png`) on send |

Coverage uses grid cells over each word box (`REDACTION_TOLERANCE`, `COVERAGE_*` in `game2.gd`). Marker strokes are converted from `MarkerLayer` space into `TextRenderer` space before hit-testing.

## UI feedback

| Element | Meaning |
|---------|---------|
| Post-it `pointsLabel` | `tak masz X/Y` — correct illegal marks / illegal total on **this** paper |
| Post-it `pointsLabel_good` | `+N` — **shift** total (`WordManager.shift_correct_illegal`) |
| Post-it `pointsLabel_bad` | `-N` — false redactions on current paper |
| Stamp on paper | Perfect redaction on last briefed sheet |
| Toilet messages | Current forbidden list (flushed in on pull) |

## Player actions

| Input | Action |
|-------|--------|
| Drag marker on paper | Redact words |
| Toilet handle (click) | `toilet_pull()` → new forbidden trio, same memo |
| Briefcase (click) | `_send_to_briefing()` → score paper, maybe stamp, new memo |
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
| Memo layout & illegal flags | `scripts/text_renderer.gd` |
| Marker input & strokes | `scripts/marker_layer.gd` |
| Post-it / stamp visuals | `paper.gd` + `paper.tscn` (Posit) |
| Toilet word display | `toilet_msg.tscn` |
| Timer | `clock.gd` (`ShiftClock`) |
| Post-it refresh | `game2.gd` → `_on_stroke_finished()` → `_refresh_postit_and_penalty()` → `Paper.set_postit()` |

## Session state (`game2.gd`)

Each active paper keeps a `session` dictionary:

- `text` — memo string  
- `document_words` — 6 words used in the template  
- `strokes` — saved marker strokes  
- `stamped` — unused on current sheet until briefed  

Global shift state:

- `WordManager.current_toilet_words` — active forbidden list  
- `WordManager.shift_correct_illegal` — run score  
- `WordManager.good_ending` — set when shift ends  

## Design intent

- **Pressure:** clock + cofefe  
- **Risk:** marking off-list words  
- **Clarity:** toilet strip = law; post-it = progress on this sheet  
- **Reward:** stamp on perfect page; `+N` across the shift for every correct forbidden word briefed  

Tuning knobs: `clock.gd` `wait_time`, `COVERAGE_*` / `REDACTION_TOLERANCE`, `TOILET_INTEL_COUNT`, `templates` / `master_list`.
