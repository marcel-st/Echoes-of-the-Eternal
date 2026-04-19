# Developer Guide — Echoes of the Eternal

This project is a **Godot 4.6** top-down 2D RPG with data-driven narrative, quests, saves, and audio. This guide explains how the code is organized, how content flows into the game, and how to extend systems safely.

## Requirements

- **Godot 4.6** (see `project.godot` → `config/features`; match **export templates** to your exact editor build).
- **Python 3** for the narrative importer (`tools/import_narrative.py`).

## Repository layout

| Path | Purpose |
|------|---------|
| `core/` | Autoload services: events, routing, save, settings, input, small UI helpers. |
| `scenes/` | Playable scenes: `main`, world maps, player, HUD, interactables. |
| `gameplay/` | Gameplay systems (e.g. `quest_manager.gd`). |
| `narrative/` | Dialogue, portraits, world flags. |
| `world/` | Lore catalog (`lore_manager.gd`) and world-adjacent logic. |
| `audio/` | `AudioManager` — music, UI SFX, world SFX, ambience. |
| `core/audio/` | **`SoundManager`** — pooled **SFX** (`play_sfx`), music/ambience helpers; named Kenney paths via `KenneyPackPaths`. |
| `data/` | **Runtime** JSON consumed in-game (`dialogue/`, `quests/`, `items/`, `world/`, `npcs/`). |
| `data/source/narrative/` | **Authoring** source for the importer (markdown + JSON). |
| `tools/` | `import_narrative.py` — regenerates runtime `data/*` outputs. |
| `docs/` | Design and process docs (narrative pipeline, art, alpha, **this guide**). |
| `export_presets.cfg` | Export preset **Linux/X11** (tracked for reproducible builds). |
| `scripts/` | Helper shell scripts (e.g. Linux export). |

Generated/editor caches are ignored (see `.gitignore`): `.godot/`, `builds/`, etc.

## Boot flow

1. **Main scene:** `res://scenes/main.tscn` (`project.godot` → `run/main_scene`).
2. **`main.gd`** wires global signals (autosave, map transitions, music), loads save state, and hosts **`WorldRoot`** for the active map.
3. **Initial map:** `SceneRouter.load_initial_map()` defaults to **`res://scenes/world/overworld.tscn`** unless a save restores another map (`SceneRouter.DEFAULT_MAP_SCENE`).

## Autoload singletons (`project.godot`)

| Name | Script | Role |
|------|--------|------|
| `EventBus` | `core/game/event_bus.gd` | Global signals: dialogue, quests, UI prompts, map changes, `sfx_requested`, `lore_discovered`, etc. |
| `SettingsManager` | `core/config/settings_manager.gd` | Player settings. |
| `InputProfiles` | `core/config/input_profiles.gd` | Action maps / rebinding. |
| `SaveManager` | `core/save/save_manager.gd` | Slot save/load; coordinates `SaveData` + gameplay state. |
| `SceneRouter` | `core/game/scene_router.gd` | Loads/unloads map scenes under `WorldRoot`; emits `map_changed`. |
| `QuestManager` | `gameplay/quests/quest_manager.gd` | Loads `data/quests/quests.json`; tracks states and objective progress. |
| `DialogueManager` | `narrative/dialogue/dialogue_manager.gd` | Loads `data/dialogue/dialogues.json`; runs dialogue requests. |
| `PortraitRegistry` | `narrative/dialogue/portrait_registry.gd` | Speaker portraits for UI. |
| `WorldFlags` | `narrative/flags/world_flags.gd` | Key/value flags for conditions and story state. |
| `LoreManager` | `world/lore_manager.gd` | Lore entries from `data/world/lore_entries.json`; discovery + runtime dialogue registration. |
| `AudioManager` | `audio/audio_manager.gd` | Music tracks, UI/world SFX, ambience; listens to `EventBus.sfx_requested`. |
| `SoundManager` | `core/audio/SoundManager.gd` | Short **SFX** by logical name or `res://` path; dialogue typewriter uses `play_sfx("dialogue_blip", …)`. |

**Guideline:** Prefer **`EventBus` signals** for cross-feature reactions (e.g. UI prompts, audio hooks) instead of hardwiring nodes to each other.

## Maps, player, and transitions

- **Maps** live under `scenes/world/*.tscn` with optional sibling `*.gd` for `resolve_transition(player_position)` returning a dictionary with `map_scene_path` and `spawn_id`, or empty prompt behavior.
- **Player** is `scenes/player/player.tscn` (group `player`). Movement and combat hooks live in `player.gd`.
- **Map change:** `main.gd` listens for transition zones and calls `SceneRouter.request_map_change(...)` when the player confirms.

## Narrative pipeline (summary)

Authoring lives in `data/source/narrative/`. The importer produces:

- `data/dialogue/dialogues.json`
- `data/quests/quests.json`
- `data/items/items.json`
- `data/world/lore_entries.json`
- `data/npcs/npc_registry.json`

**Always run** after editing source narrative files:

```bash
python3 tools/import_narrative.py
```

Full checklist and formats: **`docs/NARRATIVE_PIPELINE.md`**.

## NPCs and dialogue

- **`npc_base.tscn` / `npc_base.gd`:** `Area2D` NPC with **`InteractPrompt`**. `interact()` only runs when the player is in range **and** the prompt is **visible** (so UI and intent stay aligned). Dialogue id resolution:
  - `dialogue_by_flag_true` — if `WorldFlags` says a flag is **true**, use that dialogue id (e.g. repeat lines after `set_flag:…` in JSON outcomes).
  - `dialogue_by_quest_state` — map quest id → `{ "state_string": "DIALOGUE_ID" }`.
  - **`default_dialogue_id`** — fallback.
- **Runtime lines:** `data/dialogue/dialogues.json` (ids are string keys, e.g. `NPC_HERALD_CORWIN_FIRST`). Outcomes can call `start_quest:…`, `set_flag:…`, `prompt:…`, etc. (see `DialogueManager.apply_effects` / `_apply_effect_token`).
- **Opening the box:** call **`DialogueManager.request_dialogue(dialogue_id, context_dict)`** (or emit `EventBus.dialogue_requested`). The **`DialogueBox`** scene (`scenes/ui/DialogueBox.tscn`) listens and renders lines with a **Timer**-driven typewriter; per-character ticks use **`SoundManager.play_sfx("dialogue_blip", …)`**.
- **Signals (movement / UI):** `EventBus.dialogue_started` / **`dialogue_finished`** / `dialogue_closed`. The player freezes on **`dialogue_started`** and unfreezes on **`dialogue_finished`** (emitted when `DialogueManager.close_active_dialogue()` runs, before `dialogue_closed`).
- **Example — Herald Corwin (overworld):** `HeraldNPC` uses `default_dialogue_id = NPC_HERALD_CORWIN_FIRST` and `dialogue_by_flag_true` so `npc_corwin_met` selects **`NPC_HERALD_CORWIN_REPEAT`**. First conversation outcomes start **`MQ_01_AWAKENING`** (“The First Spark”) and set the met flag.

## Lore plinths

- **`lore_plinth.tscn`:** `lore_entry_id` ties to `data/world/lore_entries.json` via `LoreManager`.
- Discoveries persist through **`SaveManager`** / `SaveData.lore_discovered` and emit **`EventBus.lore_discovered`** for autosave and UI refresh.

## Saves

- **Resource:** `core/save/save_data.gd` (`SaveData`) — map path, player position, flags, quest state, lore discovery, etc.
- **Flow:** `SaveManager.save_game` / `load_game`; `main.gd` debounces autosaves on quest/flag/lore changes.

## Audio

- **Music:** regional mapping in `scenes/main.gd` (`MAP_MUSIC`) + `AudioManager.TRACKS`.
- **Decoupled SFX:** gameplay emits `EventBus.sfx_requested` with ids matching `AudioManager.WORLD_SOUNDS` / UI pools.

## Adding a feature (checklist)

1. **Data first** (if narrative-driven): edit `data/source/narrative/*`, run `import_narrative.py`, verify generated JSON.
2. **Runtime code:** extend the smallest surface (one manager or one scene) and connect via **`EventBus`** where possible.
3. **Scenes:** prefer instancing existing patterns (`npc_base`, `lore_plinth`, map `Area2D` gates).
4. **Save/load:** if it is player progress, extend `SaveData` + import/export in `SaveManager` + any `main.gd` hooks.
5. **Export sanity:** run a **Release** export locally (see **`docs/BUILD.md`**) before tagging.

## Debugging tips

- Run from the editor with **Remote** scene tree to verify `WorldRoot` children and the player group.
- Watch **Output** for missing resources or JSON parse warnings from managers.
- If dialogue or quests seem stale, confirm you re-ran **`tools/import_narrative.py`** and that IDs in scenes match JSON.

## Related documents

- **`docs/NARRATIVE_PIPELINE.md`** — author → runtime data workflow.
- **`docs/BUILD.md`** — export templates, Linux build, CI notes, headless import.
- **`docs/PLAYER_GUIDE.md`** — controls and gameplay orientation for testers.
- **`docs/ART_DIRECTION.md`**, **`docs/ASSET_LICENSES.md`**, **`assets/ATTRIBUTION.md`** — visual and legal source of truth for art/audio.
- **`CONTRIBUTING.md`**, **`SECURITY.md`**, **`CODE_OF_CONDUCT.md`** — community and GitHub hygiene at repo root.
