# Project structure — Potty Secret

Godot 4 layout: **scenes by role**, **scripts/papers for copy + registry**, autoloads at project root.

## Scene flow (what loads what)

```
intro_scene.tscn          (main scene in project.godot)
    └─► main_menu.tscn
            ├─► game2.tscn          ← core gameplay
            └─► intro video path

game2.tscn
    ├─ embeds: clock, desk props, right hand, coffee flash
    ├─ spawns: toilet_msg, score_popup
    └─ spawns papers via DocumentScenes (see below)
            └─► ending.tscn → outro.tscn → main_menu.tscn
```

All flow scenes live in **`scenes/flow/`**. Reusable spawned pieces live in **`scenes/gameplay/`**.

## Paper pipeline (the confusing part — now one place)

Scripted memos use **two layers**:

| Layer | Location | Responsibility |
|-------|----------|----------------|
| **Copy** (text, target words, hints) | `scripts/papers/*_content.gd` | `OnboardingContent`, `TopicContent`, `ShiftReportContent` |
| **Layout** (background, text bounds, post-it position) | `scenes/papers/*.tscn` | Inherit from `scenes/gameplay/paper.tscn` |
| **Registry** | `scripts/papers/document_scenes.gd` | `DocumentScenes` maps step/topic id → scene |

`game2.gd` always:

1. Builds a `session` dict from the **content** script (text + targets).
2. Picks a scene via `DocumentScenes.onboarding(key)` or `DocumentScenes.topic(id)`.
3. Calls `_spawn_scripted_paper(session, animate, scene)` which instances the scene and feeds the session into `GamePaper` / `TextRenderer`.

### Onboarding steps → content + scene

| Step key | Content | Scene |
|----------|---------|-------|
| `welcome` | `OnboardingContent` | `scenes/papers/onboarding_welcome.tscn` |
| `toilet` | `OnboardingContent` | `scenes/papers/onboarding_toilet.tscn` |
| `briefing` | `OnboardingContent` | `scenes/papers/onboarding_briefing.tscn` |
| `shift_start` | `OnboardingContent` | `scenes/papers/onboarding_shift_start.tscn` |
| `shift_report` | `ShiftReportContent` | `scenes/papers/shift_report.tscn` |

### Topic intro → content + scene

| Topic id | Content | Scene |
|----------|---------|-------|
| `aliens` | `TopicContent.TOPICS` | `scenes/papers/topic_aliens.tscn` |
| `cryptids` | … | `scenes/papers/topic_cryptids.tscn` |
| `conspiracy` | … | `scenes/papers/topic_conspiracy.tscn` |
| `pop_culture` | … | `scenes/papers/topic_pop_culture.tscn` |

Normal shift papers use the base `scenes/gameplay/paper.tscn` with procedurally generated text from `WordManager` (no entry in `DocumentScenes`).

### Adding a new scripted paper

1. Add copy to the right `*_content.gd` in `scripts/papers/`.
2. Duplicate `scenes/gameplay/paper.tscn` → `scenes/papers/your_scene.tscn`, customize layout in editor.
3. Register in `DocumentScenes.ONBOARDING` or `DocumentScenes.TOPIC`.
4. Wire spawn in `game2.gd` if it is a new step (existing steps already call `DocumentScenes`).

## Folder map

```
scenes/
  flow/           Scene transitions: intro, menu, game2, ending, outro
  gameplay/       Base paper, toilet, clock, score popup (spawned by game2)
  papers/         Paper scene variants (onboarding + topic intros + shift report)
  desk_props/     Coffee mug, cigarette, rubber fly
  …               Shared pieces (right_hand, coffee_sip_flash)

scripts/
  papers/         document_scenes.gd + *_content.gd (copy & registry)
  …               Shared systems (text_renderer, marker_layer, flicker_light, …)

legacy/           Archived prototype + unused assets — .gdignore, not imported by Godot

art/              Textures
assets/           UI bits, marker cursor, fly sprites
fonts/            Typewriter font
shaders/          All .gdshader files (including game2 palette shader)
video/            Intro/outro clips

WordManager.gd    Autoload — word pool, templates, shift score
```

## Autoloads

| Name | File |
|------|------|
| `WordManager` | `WordManager.gd` |
| `PlayerProgress` | `scripts/player_progress.gd` |

## Related docs

- [`AGENTS.md`](AGENTS.md) — agent entry points
- [`GAME_LOOP.md`](GAME_LOOP.md) — player-facing rules and code map
- [`design/features.md`](design/features.md) — cross-system wiring index
