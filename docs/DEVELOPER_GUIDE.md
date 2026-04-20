# Developer Guide — Echoes of the Eternal

This project is a **Godot 4.6** top-down 2D RPG with data-driven narrative, quests, saves, and audio. This guide explains how the code is organized, how content flows into the game, and how to extend systems safely.

## Requirements

- **Godot 4.6** (see `project.godot` → `config/features`; match **export templates** to your exact editor build).
- **Python 3** for the narrative importer (`tools/import_narrative.py`).

## Repository layout

| Path | Purpose |
|------|---------|
| `core/` | Autoload services: events, routing, save, settings, input, small UI helpers. |
| `core/systems/` | **`DialogueManager`** — dialogue + portrait manager (global autoload). |
| `core/audio/` | **`SoundManager`** — pooled **SFX** (`play_sfx`), music/ambience helpers; named Kenney paths via `KenneyPackPaths`. |
| `scenes/` | Playable scenes: `main`, world maps, player, HUD, interactables. |
| `gameplay/` | Gameplay systems (e.g. `quest_manager.gd`). |
| `narrative/` | Legacy dialogue scripts, portraits, world flags. |
| `world/` | Lore catalog (`lore_manager.gd`) and world-adjacent logic. |
| `audio/` | `AudioManager` — music, UI SFX, world SFX, ambience. |
| `data/` | **Runtime** JSON consumed in-game (`dialogue/`, `quests/`, `items/`, `world/`, `npcs/`). `characters.json` at root holds per-character portrait paths and UI colours. |
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
| `DialogueManager` | `core/systems/DialogueManager.gd` | Loads `data/dialogue/dialogues.json` + `data/characters.json`; drives `start_dialogue`, per-line signals, actor pausing. |
| `PortraitRegistry` | `narrative/dialogue/portrait_registry.gd` | Speaker display-name resolution and 6-colour palette fallback. |
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

### Starting dialogue

The primary entry point is `DialogueManager.start_dialogue(npc_id, dialogue_key)`:

```gdscript
# From NPC interact(), scene trigger, cutscene, etc.
DialogueManager.start_dialogue(“elara_001”, “MS_ACT1_01”)
```

This resolves the character's display name and portrait path from `data/characters.json`, freezes the NPC's `_process` (stopping wander and cooldown timers), then fires the dialogue pipeline through `EventBus.dialogue_requested`.

For scripted triggers that don't involve a specific NPC node, call the lower-level form directly:

```gdscript
DialogueManager.request_dialogue(&”MS_MALAKOR_TAUNT_01”, { “speaker_id”: “malakor_001” })
```

### NPC scene setup

- **`npc_base.tscn` / `npc_base.gd`:** `Area2D` NPC in group **`”npc”`** (added in `_ready`; required for `DialogueManager` to find and pause the node). Has an **`InteractPrompt`** child instanced from `scenes/ui/InteractPrompt.tscn`.
- `interact()` only fires when the player is in range **and** the prompt is **visible**.
- Dialogue id resolution order:
  1. `dialogue_by_flag_true` — if a `WorldFlags` key is **true**, use that dialogue id.
  2. `dialogue_by_quest_state` — map quest id → `{ “state_string”: “DIALOGUE_ID” }`.
  3. **`default_dialogue_id`** — fallback.

### DialogueBox rendering

`scenes/ui/DialogueBox.tscn` (CanvasLayer, layer 48) subscribes to `DialogueManager.dialogue_line_ready` and renders each line with:

- A **Timer-driven typewriter** (`TYPEWRITER_SEC_PER_CHAR = 0.038 s`); pressing Confirm while typing skips to full reveal.
- **`SoundManager.play_sfx(“dialogue_blip”, -14.0, true)`** on every revealed character → `KenneyPackPaths.UI_TICK_TYPEWRITER` (`tick_001.ogg`) with random pitch jitter.
- **Portrait area:** loads a `Texture2D` from the character's `”portrait”` path in `data/characters.json` when the file exists. When it doesn't, the `PortraitBackdrop` `ColorRect` is tinted with `PortraitRegistry.resolve_portrait_color()` so every speaker has a distinct colour identity before art ships.

### Per-line and choice signals

Connect these on `DialogueManager` to drive subtitles, voice-over, analytics, or any system that needs to react to spoken lines and player decisions:

| Signal | Arguments | When |
|--------|-----------|------|
| `dialogue_line_ready` | `speaker_name, text, portrait_path` | Each new line is displayed |
| `dialogue_choices_ready` | `dialogue_id, choices: Array` | Player is shown a choice list |
| `dialogue_choice_made` | `dialogue_id, choice_index, choice_data` | Player confirms a choice (before effects run) |

`dialogue_choice_made` is the recommended hook for **QuestManager** branching logic instead of coupling directly to the UI.

### Effect tokens (dialogue JSON outcomes)

Outcomes / effects in `data/dialogue/dialogues.json` are processed by `DialogueManager.apply_effects()`:

| Token | Effect |
|-------|--------|
| `set_flag:key=value` | Sets a `WorldFlags` entry |
| `start_quest:quest_id` | Calls `QuestManager.start_quest` |
| `set_quest_state:quest_id:state` | Transitions quest state |
| `complete_objective:quest_id:obj_id[:amount]` | Advances an objective counter |
| `complete_quest:quest_id` | Marks quest complete |
| `give_item:item_id[:amount]` | Emits `EventBus.item_received` |
| `jump_to:dialogue_id` | Immediately loads another dialogue |
| `prompt:text` | Emits `EventBus.request_ui_prompt` |
| bare token | Sets that flag to `true` (shorthand) |

### Movement locking

The player freezes automatically on `EventBus.dialogue_started` (`_dialogue_movement_lock = true` in `player.gd`) and unfreezes on `EventBus.dialogue_finished`. `DialogueBox._unhandled_input` marks all input handled while the box is visible, so attack and interact actions do not bleed through.

### InteractPrompt

`scenes/ui/InteractPrompt.tscn` renders a Kenney keyboard-E glyph above NPCs. The `Glyph` Sprite2D is `scale = Vector2(0.25, 0.25)` — at the project's Camera2D zoom of 4× this renders the 64×64 source icon at 64×64 screen pixels, matching the pixel-art character proportions. The script (`interact_prompt.gd`) prefers the kenney_pack path at runtime and falls back to `res://assets/ui/input_prompt_keyboard_e.png`; the `.tscn` references the fallback directly so the editor preview is always correct.

### Example — Herald Corwin (overworld)

`HeraldNPC` uses `default_dialogue_id = NPC_HERALD_CORWIN_FIRST` and `dialogue_by_flag_true = { “npc_corwin_met”: “NPC_HERALD_CORWIN_REPEAT” }`. First-conversation outcomes run `start_quest:MQ_01_AWAKENING` and `set_flag:npc_corwin_met=true`.

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
