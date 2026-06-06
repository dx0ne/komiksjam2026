# Agent guide — Potty Secret

Godot 4 project. Main gameplay scene: `scenes/flow/game2.tscn` / `scenes/flow/game2.gd`. Word data and shift score: `WordManager` autoload.

Read this file first when touching gameplay, atmosphere, or cross-scene wiring. For folder layout and what loads what, see [`STRUCTURE.md`](STRUCTURE.md).

---

## Documentation map

| Doc | Purpose | When to read |
|-----|---------|--------------|
| [`STRUCTURE.md`](STRUCTURE.md) | Folder layout, scene flow, paper copy vs layout vs registry | Finding files, adding papers, understanding spawn chain |
| [`GAME_LOOP.md`](GAME_LOOP.md) | Core shift loop, scoring, difficulty phases, session state, code map | Gameplay, marking, papers, toilet intel, phases |
| [`design/features.md`](design/features.md) | **Feature index** — triggers, owners, and side effects for coupled systems | Light flicker, shadows, cofefe, onboarding, anything that signals across nodes |
| [`docs/superpowers/specs/`](docs/superpowers/specs/) | Original design specs (historical / authoritative for those features) | Scoring model, obfuscated intel, phase ramp rationale |

**Rule of thumb:** `GAME_LOOP.md` = *what the player does*. `design/features.md` = *what code hooks into what*.

---

## `design/` folder

- Markdown and notes only — **not** game assets.
- Contains `.gdignore` so Godot does not scan or import this folder.
- Safe place for living design docs that should stay in-repo but out of the editor filesystem.

Do not put `.gd`, `.tscn`, or textures here.

---

## Feature index (`design/features.md`)

Catalog of **cross-cutting behaviors**: systems where one owner emits a signal or flips shared state and other nodes react (e.g. point light `flicker_off` → desk shadow alpha).

Each entry should name:

1. **Owner** — script / scene that owns the logic
2. **Triggers** — clock threshold, input, signal, onboarding step, etc.
3. **Affects** — nodes, autoloads, or UI that change as a result

Use the [Point light flicker / Desk shadows](design/features.md#desk-shadows) entries as the template.

### When to update

Update `design/features.md` in the **same change** when you:

- Add or connect a signal consumed elsewhere
- Introduce shared state read by multiple systems (e.g. `_point_light_lit`)
- Wire a prop to gameplay (mug → clock, drag → marker lock)
- Add a scene node meant to react to an existing system (new shadow sprite, new flicker consumer)

Skip the index for local, single-file behavior with no external coupling.

### How to update

1. Add one row to the **Quick index** table (Feature, Owner, Triggers, Affects).
2. Add a short section with a table or bullet list for constants, signals, and consumers.
3. If the feature is core player-facing rules, also update `GAME_LOOP.md` — the feature index is not a substitute for gameplay docs.

---

## Code entry points

| Area | Location |
|------|----------|
| Shift orchestration | `scenes/flow/game2.gd` |
| Words / topics / scoring data | `WordManager.gd` |
| Memo layout & word boxes | `scripts/text_renderer.gd` |
| Paper copy, registry, custom layouts | `scripts/papers/`, `scenes/papers/`, `scenes/gameplay/paper.tscn` |
| Marker input & strokes | `scripts/marker_layer.gd` |
| Shift timer | `scenes/gameplay/clock.gd` |
| Desk lamp flicker | `scripts/flicker_light.gd` |
| Saved onboarding / topic intro | `scripts/player_progress.gd` |

Main scene unique nodes use `%Name` (e.g. `%PointLight2D`, `%KawaCien`, `%Cofefe`).
