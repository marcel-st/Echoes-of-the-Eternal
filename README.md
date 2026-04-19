# Echoes of the Eternal

2D top-down RPG built in **Godot 4.6**, with data-driven dialogue and quests, saves, regional maps, and keyboard + gamepad support (Windows / Linux / Steam Deck–friendly).

## Story

*Echoes of the Eternal* follows **Kaelen**—once tied to a vast **Living Archive** of memory—and the people caught between restoration and forgetting: shards of identity, old alliances, and a world still reacting to choices buried under amnesia. It is **my own story at its core**, with **expansions and rewrites shaped with Gemini** so the arc, side characters, and quest beats read like a **proper RPG**: clearer motives, richer dialogue, and room to grow as the game does.

I am **vibecoding** much of this—experimenting, iterating, and learning in public—yet I would **love help** from anyone who wants to make it **nicer-looking and genuinely playable**: art passes, UI polish, balance, bugs, accessibility, and playtesting all count. **Storyline additions, changes, and expansions are welcome**; treat the narrative as a living draft. The aim is an **excellent free, open-source game** anyone can enjoy and build on.

**License:** game source and scripts in this repository are under the [MIT License](LICENSE). Bundled third-party art and audio remain under their respective licenses — see [`docs/ASSET_LICENSES.md`](docs/ASSET_LICENSES.md) and [`assets/ATTRIBUTION.md`](assets/ATTRIBUTION.md).

## Community

| Document | Purpose |
|----------|---------|
| [Contributing](CONTRIBUTING.md) | Branch workflow, PR expectations, narrative import, conduct pointer |
| [Security](SECURITY.md) | How to report vulnerabilities privately |
| [Code of Conduct](CODE_OF_CONDUCT.md) | Community standards |

## Documentation

| Guide | Description |
|-------|-------------|
| [Developer guide](docs/DEVELOPER_GUIDE.md) | Architecture, autoloads, dialogue UI, NPCs, narrative pipeline, saves, audio |
| [Player guide](docs/PLAYER_GUIDE.md) | Controls, alpha loop, saves, feedback |
| [Build instructions](docs/BUILD.md) | Engine version, asset import, narrative import, Linux export |

Additional references: [Narrative pipeline](docs/NARRATIVE_PIPELINE.md), [Art direction](docs/ART_DIRECTION.md), [Alpha release plan](docs/ALPHA_RELEASE_PLAN.md).

## Current status

- **Boot:** `scenes/main.tscn` → `SceneRouter` loads **`scenes/world/overworld.tscn`** by default (save games can restore other maps).
- **Systems:** `EventBus`, `SceneRouter`, `SaveManager`, `DialogueManager`, `QuestManager`, `AudioManager`, **`SoundManager`** (overlapping SFX pool), `WorldFlags`, `LoreManager`, etc. (see developer guide).
- **UI:** HUD, journal, **`DialogueBox.tscn`** (typewriter + continue prompt), world **`InteractPrompt`** for NPCs and props.
- **Data:** `data/dialogue/dialogues.json`, `data/quests/quests.json`, and related JSON under `data/`.

## Open in Godot

1. Install **Godot 4.6** (match `project.godot` `config/features`).
2. Open this folder as a project.
3. On first clone, let the editor **import** assets (or run `godot --headless --import --path .` once) so textures and fonts resolve.
4. Press **F5** to run.

### Controls (default)

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move | **W A S D** / arrows | Left stick |
| Interact / dialogue advance | **E**, **Space** | South (e.g. A) |
| Attack | **J** | West (e.g. X) |
| Pause / journal | **Esc** | **Start** |

Exact bindings are registered at runtime by `InputProfiles` (`core/config/input_profiles.gd`).

## Project layout (high level)

```txt
core/          # autoload services, audio (SoundManager), config, save, events
scenes/        # main, world maps, player, HUD, UI (DialogueBox, InteractPrompt)
gameplay/      # quests
narrative/     # dialogue manager, portraits, flags
audio/         # AudioManager — music, routed UI/world SFX
data/          # runtime JSON (dialogue, quests, items, world)
assets/        # shipped textures, fonts, tilesets (Kenney-derived where noted)
docs/          # design and engineering docs
tools/         # narrative import, optional Kenney / tileset helpers
```

## Narrative workflow

Authoring under `data/source/narrative/` is merged into runtime JSON by:

```bash
python3 tools/import_narrative.py
```

See **`docs/NARRATIVE_PIPELINE.md`** for formats and checklist.

## Art and attribution

- **`docs/ART_DIRECTION.md`** — visual direction  
- **`docs/ASSET_LICENSES.md`** — approved sources and licenses  
- **`assets/ATTRIBUTION.md`** — pack-level attribution  

Optional local **Kenney all-in-one** copy: `kenney_pack/` (gitignored). Paths are documented in `core/config/kenney_pack_paths.gd`. A local `.resources/` mirror is also gitignored.
