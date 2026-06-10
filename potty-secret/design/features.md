# Feature index

Living catalog of gameplay and desk-atmosphere systems. For the core shift loop, scoring, and difficulty phases see [`GAME_LOOP.md`](../GAME_LOOP.md). For original feature specs see [`docs/superpowers/specs/`](../docs/superpowers/specs/).

Maintenance rules for this file: [`AGENTS.md`](../AGENTS.md) § Feature index.

---

## Quick index

| Feature | Owner | Triggers | Affects |
|---------|-------|----------|---------|
| [Shift clock](#shift-clock) | `scenes/gameplay/clock.gd` | `start_shift()`, timer tick | Progress bar, clock hand, light flicker mode |
| [Difficulty phases](#difficulty-phases) | `scenes/flow/game2.gd` | Elapsed shift time | Paper variants, toilet intel, decoys |
| [Onboarding](#onboarding) | `game2.gd`, `scripts/papers/onboarding_content.gd`, `scripts/papers/document_scenes.gd` | First launch | UI visibility, scripted papers, progress save |
| [Topic intro newspaper](#topic-intro-newspaper) | `document_scenes.gd`, `topic_content.gd`, `paper.gd` | First shift per topic | Mark targets on desk paper; blocks shift until redacted |
| [Custom document scenes](#custom-document-scenes) | `scenes/papers/` | Scripted spawn | Background, text area, post-it layout per scene |
| [Point light flicker](#point-light-flicker) | `scripts/flicker_light.gd` | Clock time remaining | Light energy, `flicker_off` / `flicker_on` signals |
| [Desk shadows](#desk-shadows) | `game2.gd` | Light flicker, cofefe drag | `KawaCien`, `PopielniczkaCien` alpha |
| [Cofefe mug](#cofefe-mug) | `scenes/desk_props/cofefe.gd` | Click / drag | 1 sip/shift; +10s & +1 twitch force; `Inside` empties on use; smear, marker lock |
| [Papieros cigarette](#papieros-cigarette) | `scenes/desk_props/papieros.gd` | One click while unlit | −1 twitch force once; ~6 s fuse then stub |
| [Toilet handle attract](#toilet-handle-attract) | `game2.gd` | Idle 4s after handle visible | Handle sway + flash |
| [Rubber fly marker](#rubber-fly-marker) | `game2.gd` + `%Rubber` scene | Onboarding steps, stroke idle | Marker prop animation |
| [Marker review blink](#marker-review-blink) | `scripts/marker_layer.gd` | Review stroke colors applied | Tick/cross overlay pulse |
| [Missed-word text blink](#missed-word-text-blink) | `scripts/text_renderer.gd` | End-of-paper review | Highlight alpha on missed planted words |
| [Player progress](#player-progress) | `scripts/player_progress.gd` (autoload) | Onboarding / topic intro complete | `user://progress.cfg` |
| [Shift closure report](#shift-closure-report) | `game2.gd`, `shift_report_content.gd` | Clock `time_out` | Lamp override, paper exit tween, report paper, ending scene |
| [Game audio](#game-audio) | TBD autoload or `game2.gd` bus root | Marker draw, props, scoring, lamp, scene flow | `AudioStreamPlayer` nodes on `default_bus_layout.tres` buses |

---

## Shift clock

**Owner:** `scenes/gameplay/clock.gd` (`ShiftClock`, node `%clock_scn`)

| Constant / API | Value / behavior |
|----------------|------------------|
| Shift length | 180 s (`game_timer.wait_time`) |
| `start_shift()` | Resets timer, starts countdown, syncs progress bar |
| `add_time(seconds)` | Extends running timer (used by cofefe sip) |
| `time_out` signal | Emitted when timer hits zero → `game2._on_time_out` → ending scene |
| Visuals | Progress bar fill; `%RekaZegarek` rotates one full turn over the shift; animation speed ×2 in last 25% |

**Consumers:** `flicker_light.gd` reads `time_left` every frame to pick light mode.

---

## Difficulty phases

**Owner:** `game2.gd` — see [`GAME_LOOP.md`](../GAME_LOOP.md) § Difficulty phases.

Phase boundaries: `PHASE_TEACHING_END_S = 60`, `PHASE_LIGHT_END_S = 120`. Same enum names as gameplay phase (`TEACHING`, `LIGHT`, `FULL`) but distinct from light-flicker “tension” mode (naming collision — phases = word obfuscation, flicker = desk lamp).

---

## Onboarding

**Owners:** `scenes/flow/game2.gd`, `scripts/papers/onboarding_content.gd`, `scripts/player_progress.gd`

First-time players skip the normal shift until tutorial steps complete. Returning players (`PlayerProgress.has_completed_onboarding()`) jump to `SHIFT_START` briefing only.

### Step machine (`OnboardingStep`)

```
WELCOME → TOILET_LESSON → START_BRIEFING → (mark complete) → topic intro / normal shift
```

Returning player path:

```
SHIFT_START → topic intro / normal shift
```

| Step | Handle | Cofefe | Rubber | Advance when |
|------|--------|--------|--------|--------------|
| `WELCOME` | hidden | hidden | visible | All `WELCOME_TARGETS` marked on scripted paper |
| `TOILET_LESSON` | visible (attract idle) | hidden | hidden | Substep 0: post-it `pull`, toilet intel `pull` / `the` / `chain`. Substep 1: after pull → UFO / Area 51 intel + redact |
| `START_BRIEFING` | visible | hidden | visible | All `BRIEFING_TARGETS` marked → `PlayerProgress.mark_onboarding_complete()` |
| `SHIFT_START` | visible | visible | hidden | Shift-start targets marked |
| `DONE` | normal gameplay | normal | hidden | — |

Scripted copy and target word lists live in `OnboardingContent` (`scripts/papers/onboarding_content.gd`). Each step spawns a scene from `DocumentScenes.onboarding()` (under `scenes/papers/`). Progress checked on stroke finish via `_onboarding_check_progress()`. Target words stay **visible** on onboarding and topic-intro papers (optional `hide_target_words` on session if a scene needs invisible targets).

**Debug:** Page Down resets onboarding and reloads the scene (`PlayerProgress.reset_onboarding()`).

---

## Topic intro newspaper

**Owners:** `scripts/papers/topic_content.gd`, `scripts/papers/document_scenes.gd`, `scenes/flow/game2.gd`, `scenes/gameplay/paper.gd`

Before the first normal shift for each `WordManager.active_topic_id`, a **desk paper** scene (`DocumentScenes.topic()`) shows topic copy. Shown from `_begin_topic_shift()` when `PlayerProgress.has_seen_topic_intro()` is false.

- Copy and `targets` / `post_it_hint` in `TopicContent.TOPICS`; body built via `TopicContent.build_document_text()`
- Advance: redact all `targets` (transparent until marked) → `mark_topic_intro_seen()` → `_start_normal_shift()`
- Customize layout per topic in `scenes/papers/topic_*.tscn`

---

## Custom document scenes

**Owners:** `scenes/gameplay/paper.tscn` (base), `scenes/papers/*.tscn`, `scripts/papers/document_scenes.gd`

Inherit from `scenes/gameplay/paper.tscn` to author per-step layout in the editor:

| Node | Customize |
|------|-----------|
| `BackgroundGroup/BackgroundPaper` | Swap texture (background art) |
| `TextRenderer` | Position/size of markable text area |
| `Posit` | Post-it sprite position/rotation |
| `%PostItHint` | Label rect and typography on post-it (hint text set from code) |

Register new scenes in `DocumentScenes.ONBOARDING` or `DocumentScenes.TOPIC`. Gameplay spawn: `_spawn_scripted_paper(session, animate, scene)`.

---

## Point light flicker

**Owner:** `scripts/flicker_light.gd` (extends `PointLight2D`, node `%PointLight2D`)

Drives end-of-shift tension: desk lamp flickers, then goes dark.

### Modes (from `ShiftClock.time_left`)

| Mode | When | Behavior |
|------|------|----------|
| `STEADY` | > 10 s left | Full energy, no flicker |
| `TENSION` | 3 s < time ≤ 10 s | Random burst intervals; each burst = 3–5 rapid off/on blinks |
| `DARK` | ≤ 3 s left | Steady off until shift ends |

### Signals

| Signal | When emitted |
|--------|--------------|
| `flicker_off` | Lamp turns off (burst step or steady dark) |
| `flicker_on` | Lamp turns back on |

**Tuning exports:** `tension_interval_min/max`, `flicker_blinks_min/max`, on/off dwell times.

**Consumers:** `game2.gd` `_connect_point_light()` → updates `_point_light_lit` and refreshes desk shadows.

---

## Desk shadows

**Owner:** `game2.gd` — helpers `_fade_cien`, `_refresh_kawa_cien`, `_refresh_popielniczka_cien`

Shadow sprites are separate `Sprite2D` nodes under `CanvasLayer_strokes/CanvasGroup`, faded via `modulate.a` (not hidden), duration `KAWA_CIEN_FADE_DURATION` (0.15 s) unless instant (`duration = 0` on flicker).

| Node | `%` unique name | Visible when | Alpha rule |
|------|-----------------|--------------|------------|
| Coffee shadow | `KawaCien` | Cofefe mug visible | `_point_light_lit && ! _cofefe_dragging` |
| Ashtray shadow | `PopielniczkaCien` | Always (scene default) | `_point_light_lit` |
| Cigarette shadow | `Papieros/PapierosCien` | Papieros visible | `_point_light_lit` |

**Add a new shadow:** give the sprite `unique_name_in_owner`, call `_fade_cien("YourCien", alpha)` from the appropriate refresh handler, hook flicker handlers if it should follow the lamp.

---

## Cofefe mug

**Owner:** `scenes/desk_props/cofefe.gd` (instance `%Cofefe`)

| Input | Signal | Effect in `game2.gd` |
|-------|--------|----------------------|
| Short click (< 10 px move) | `sip_requested` | `consume_sip()` (max 1); `0/1` popup over mug; `+10s` popup over `%clock_scn`; `%CoffeeSipFlash` screen brighten ~1s; `game2._twitch_force += 1`; `Inside` empties |
| Drag | `drag_started` / `drag_ended` | Hides coffee shadow; locks marker during drag (gameplay only) |
| Drag release (moved) | `mug_placed(center, radius, drop_vector, speed)` | If over paper → `marker_layer.apply_mug_smear()` |

Mug raises z-order while dragging and tweens home on release.

---

## Papieros cigarette

**Owner:** `scenes/desk_props/papieros.gd` (instance `%Papieros`)

| State | Click | Visual |
|-------|-------|--------|
| Unlit | First (only) click → place + `puff_requested` (−1 force) | On desk; then tweens to ashtray |
| Burning | No further clicks (`MAX_PUFFS` 1) | Region shrinks ~6 s (fuse); smoke at tip |
| Stub | Ignored | Stays on ashtray; no more calm clicks |

Lit placement: `%popielniczka.position + ASHTRAY_OFFSET_FROM_POP` (from `Papieros_used`), with pivot fix for left-anchored body; each puff after the first nudges ±`ROTATION_PER_PUFF` (~0.11 rad), alternating left/right from base `3.8013272`.

**Twitch force (`game2._twitch_force`):** Coffee +1 on the single sip. Cigarette −1 once on first puff (min 0). Jitters while force &gt; 0; rate/strength scale with force.

**Fuse:** ~6 s burn after the one puff; stub ends use. Coffee force unchanged after stub.

**Marker coupling:** During a twitch, `game2._sync_marker_jitter_to_hand()` sets `draw_position_offset` on the active paper’s `MarkerLayer` so ink follows the displaced hand, including points injected each frame while `drawing`.

**Reset:** `_reset_coffee_cigarette_for_shift()` on each normal shift start (twitch force 0, fresh cigarette).

---

## Toilet handle attract

**Owner:** `game2.gd`

When the toilet handle is visible and the player is idle for `ATTRACT_IDLE_DELAY` (4 s), `_start_handle_attract()` runs a looping sway (`±ATTRACT_SWAY_RAD`) and a brief modulate flash. Any input via `_register_player_activity()` stops attract and settles rotation.

Used during toilet lesson onboarding after the handle appears.

---

## Rubber fly marker

**Owner:** `%Rubber` scene + hooks in `game2.gd`

Rubber eraser prop visible during early onboarding (`WELCOME`, `START_BRIEFING`). Hidden during normal shift. `_notify_fly_marker_idle()` called after each stroke finish to drive fly-to-marker animation when implemented on the Rubber node.

---

## Marker review blink

**Owner:** `scripts/marker_layer.gd`

When review stroke colors are applied (`apply_stroke_colors`), wrong/right tick overlays blink: 3 pulses, half-period 0.33 s, alpha lerps between full and `BLINK_FADE` (0.3). Cleared by `clear_review()`.

---

## Missed-word text blink

**Owner:** `scripts/text_renderer.gd`

Separate from marker review: at end-of-paper review, missed planted words get a highlight whose alpha blinks (3 pulses, `BLINK_FADE` 0.35). Used for “you forgot to mark this” feedback on the memo text itself.

---

## Player progress

**Owner:** `scripts/player_progress.gd` (autoload `PlayerProgress`)

Persisted at `user://progress.cfg`:

| Key | Meaning |
|-----|---------|
| `onboarding_complete` | Skip full tutorial chain |
| `topics_intro_seen` | Dict of `topic_id → bool` for newspaper intro |

API: `has_completed_onboarding()`, `mark_onboarding_complete()`, `has_seen_topic_intro()`, `mark_topic_intro_seen()`, `reset_onboarding()`.

---

## Shift closure report

**Owners:** `scenes/flow/game2.gd`, `scripts/papers/shift_report_content.gd`, `scripts/flicker_light.gd`

After the shift clock hits zero, gameplay stays on the desk for a short closure beat before `ending.tscn`.

### Sequence

| Step | Behavior |
|------|----------|
| Clock `time_out` | Save session, stamp check, `_begin_shift_closure()` |
| Dark hold | `flicker_light.force_lamp(false)` — prevents auto relight when timer stops |
| Paper exit | Active memo tweens off (`_tween_paper_out`); handle / mug / cigarette hidden |
| Report in | Lamp `force_lamp(true)`; scripted paper from briefcase with stats + **accept** target |
| Proceed | Player redacts **accept** (same coverage rules as onboarding) → `_end_shift()` → outro videos |

### Report copy

Built by `ShiftReportContent.report_text(score, memos_processed, stamps)` — shift score, memo count (`_paper_index`), stamp count (`_shift_stamps`), compliance disposition.

### Lamp override API (`flicker_light.gd`)

| Method | Effect |
|--------|--------|
| `force_lamp(on: bool)` | Pin lamp on/off; ignores clock-driven modes |
| `release_lamp_override()` | Restore auto flicker (called on next shift start) |

**Consumers:** Desk shadows via existing `flicker_on` / `flicker_off` signals.

---

## Game audio

**Status:** Design only — no `AudioStreamPlayer` nodes or sound assets in repo yet. Master bus in `default_bus_layout.tres` is muted (−80 dB) until mix is wired.

**Owners (planned):** `scripts/marker_layer.gd` (marker loop), `scenes/desk_props/rubber.gd` (fly one-shots), `scenes/flow/game2.gd` (shift SFX orchestration), scene-local players for menu / props. Optional `AudioManager` autoload for shared one-shots and music crossfade.

### Global rules

| Rule | Detail |
|------|--------|
| **Video keeps its audio** | Intro, ending, and outro `.ogv` clips (`video/`) ship with embedded sound. Do not replace or mute unless adding a global duck slider later. |
| **No audio over video scenes** | `intro_scene.tscn`, `ending.tscn`, `outro.tscn` — no separate music/SFX layer unless explicitly mixed under video. |
| **Buses** | Plan at least `Master`, `Music`, `Ambient`, `SFX`. Unmute and tune when first assets land. Settings UI (`options__settings.gd`) has no volume controls yet. |

### Marker scribble (sampled loop)

**Owner:** `scripts/marker_layer.gd`

Do **not** fire a one-shot per stroke sample or per input event. Use one **looped** scribble stream per active paper (or global marker player) and gate it with periodic movement checks.

| Constant (planned) | Suggested start | Meaning |
|--------------------|-----------------|---------|
| `MARKER_SAMPLE_INTERVAL_S` | `0.2` | How often to test whether the cursor moved while `drawing` |
| `MARKER_MIN_MOVE_PX` | `2.0` | Movement below this counts as idle (stops loop) |

**Algorithm:**

1. While `drawing == false` → stop scribble loop if playing.
2. While `drawing == true` → every `MARKER_SAMPLE_INTERVAL_S`, compare current cursor position to last sample position.
3. If moved ≥ `MARKER_MIN_MOVE_PX` → call `play()` on the loop player **only if not already playing** (do not restart between checks).
4. If not moved → `stop()` the loop.
5. On `stroke_finished` → run one final sample, then stop if idle.

**Draw modes:** `DrawMode.BRUSH` and `DrawMode.LINE` may share one loop or use two streams (line = slightly drier). Toggle via **M** in `game2.gd`; switch stream on `set_mode()` if two assets exist.

**Also marker-owned (one-shots, not loop):**

| Trigger | Sound |
|---------|-------|
| Stroke finish, negative delta sum | Wrong-mark accent (short, not punishing) |
| `apply_mug_smear()` | Wet splat / bleed |

**Consumers:** Main menu uses the same `MarkerLayer` for PLAY / SAVE redaction (`main_menu.gd`) — share marker loop logic.

### Rubber fly (state-change one-shots only)

**Owner:** `scenes/desk_props/rubber.gd`

**No continuous buzz loop.** Play one-shots only when `State` changes. Centralize in a `_set_state(new)` helper so hop tweens do not stack sounds.

| Transition | Sound |
|------------|-------|
| → `LANDING` (`play_entrance`) | Buzz in + land |
| `LANDING` → `IDLE` | Settle tick |
| `IDLE` → `WALKING` | Short skitter |
| `WALKING` → `IDLE` | Stop skitter |
| → `FLYING_AWAY` (marker flee or click) | Buzz burst away |
| `FLYING_AWAY` → `RETURNING` | Direction whoosh |
| `RETURNING` → `IDLE` | Land tick |
| Click + `erase_requested` | Sharp buzz (+ optional erase wipe) |

Pitch / volume variation on one base clip is fine. Visible only during onboarding steps (`WELCOME`, `START_BRIEFING`); hidden in normal shift.

### Sound asset checklist

Assets not in repo; paths TBD under e.g. `audio/sfx/`, `audio/music/`.

#### Music & ambient

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| A1 | Shift ambient loop | `OnboardingStep.DONE`, normal shift | `game2.gd` |
| A2 | Menu ambient | `main_menu.tscn` | `main_menu.gd` |
| A3 | Tension layer | Lamp `TENSION` mode (`flicker_light.gd`, 3–10 s left) | `game2.gd` or lamp consumer |
| A4 | Dark-hold stinger | `_begin_shift_closure()` lamp forced off | `game2.gd` |
| A5 | Onboarding ambient | Tutorial before `DONE` | `game2.gd` |

#### Core gameplay

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| G1 | Marker scribble loop | Sampled movement while drawing | `marker_layer.gd` |
| G2 | Marker line loop (optional) | Line draw mode | `marker_layer.gd` |
| G3 | Stroke release | `stroke_finished` | `marker_layer.gd` |
| G4 | Wrong-mark accent | Red stroke in `_color_stroke_by_deltas` | `game2.gd` |
| G5 | Mug smear | `apply_mug_smear()` | `marker_layer.gd` |
| G6 | Score +1 / +2 / −0.5 | `_spawn_score_popup()` | `game2.gd` |
| G7 | Stamp slam | `paper.set_stamp_visible(true)` | `paper.gd` |

#### Paper & toilet

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| P1 | Memo spawn | `_prepare_paper_spawn(animate_in: true)` | `game2.gd` |
| P2 | Memo land | Spawn tween complete | `game2.gd` |
| P3 | Memo discard | `_tween_paper_out()` | `game2.gd` |
| P4 | Shift report arrive | Closure report spawn | `game2.gd` |
| T1 | Toilet handle pull | `toilet_pull()` | `game2.gd` |
| T2 | Intel strip spawn | `_spawn_toilet_intel_messages()` | `game2.gd` |
| T3 | Intel strip land | Strip position tween end | `game2.gd` |
| T4 | Handle attract creak (optional) | `_start_handle_attract()` | `game2.gd` |

#### Desk props

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| D1 | Coffee sip | `consume_sip()` | `cofefe.gd` |
| D2 | Coffee +10s ping (optional) | `_spawn_clock_time_popup()` | `game2.gd` |
| D3 | Mug drag / set-down (optional) | `drag_started` / home tween | `cofefe.gd` |
| D4 | Cigarette puff | `puff_requested` | `papieros.gd` |
| D5 | Cigarette on ashtray | `_place_on_ashtray()` | `papieros.gd` |
| D6 | Cigarette stub (optional) | `burned_out` (signal exists; not connected in `game2.gd`) | `papieros.gd` |
| D7 | Hand twitch (optional) | `_twitch_right_hand()` | `game2.gd` |
| D8–D14 | Fly state one-shots | `rubber.gd` state transitions | `rubber.gd` |

#### Lamp & menu

| ID | Asset | Trigger | Owner |
|----|-------|---------|-------|
| L1 | Lamp flicker click | `flicker_off` / `flicker_on` | `flicker_light.gd` consumer |
| L2 | Lamp final off | `DARK` mode steady off | `flicker_light.gd` consumer |
| L3 | Lamp relight | `force_lamp(true)` at closure | `game2.gd` |
| M1 | Play confirmed | PLAY redacted on menu | `main_menu.gd` |
| M2 | Save wipe | SAVE redacted | `main_menu.gd` |

#### Deferred (code exists, not wired in main loop)

| ID | Asset | Trigger | Notes |
|----|-------|---------|-------|
| X1 | Review tick / cross blink | `apply_stroke_colors()` | `marker_layer.gd`; end-of-paper review not called from `game2.gd` |
| X2 | Missed-word blink | `apply_review_states()` | `text_renderer.gd`; same |

### Implementation priority

| Tier | IDs | Goal |
|------|-----|------|
| **MVP** | G1, G6, G7, P1–P3, T1–T2, D1, D4, D8–D14, A1, L1–L2 | Playable shift feels complete |
| **Atmosphere** | A3–A5, D7, T4, L3 | Tension and onboarding polish |
| **Polish** | G3–G5, D2–D3, D6, M1–M2, P4, X1–X2 | Juice and edge cases |

### Video audio (no separate assets)

| File | Scene |
|------|-------|
| `video/intro-do-gry-mp4.ogv` | `intro_scene.tscn` |
| `video/Speaker-intro_1.ogv` | `ending.tscn` (intro roll) |
| `video/outro-redacted-proper_1.ogv` | `ending.tscn` (good) |
| `video/outro-aliens_1.ogv` | `ending.tscn` (bad) |
| `video/newspaper.ogv` | `outro.tscn` |

### When to update this section

Update in the **same change** when:

- Adding `AudioStreamPlayer` nodes or an audio autoload
- Connecting a new signal → SFX hook (mirror [feature index rules](../AGENTS.md))
- Changing marker sampling rules or fly state machine
- Adding volume / mute settings

---

## Related docs

| Doc | Scope |
|-----|-------|
| [`GAME_LOOP.md`](../GAME_LOOP.md) | Shift loop, scoring, phases, code map |
| [`docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md`](../docs/superpowers/specs/2026-05-26-difficulty-ramp-and-scoring-design.md) | At-mark scoring spec |
| [`docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md`](../docs/superpowers/specs/2026-05-27-eye-skill-obfuscated-intel-design.md) | Canonical / typo / synonym model |
