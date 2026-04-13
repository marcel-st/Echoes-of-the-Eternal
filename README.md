# Echoes of the Eternal (Godot Starter)

2D RPG starter scaffold inspired by classic top-down adventures, prepared for a modern PC target (Windows/Linux/Steam Deck) with keyboard + gamepad support.

## Current status

This repository now contains a **Godot 4 starter architecture** with:

- Project setup (`project.godot`) targeting 1920x1080 output.
- Core AutoLoad systems for scene routing, save/load, settings, input profiles, dialogue, quests, and audio.
- A minimal playable loop:
  - `main.tscn` boot scene
  - `starter_map.tscn` with map boundaries
  - `player.tscn` with 8-direction movement and attack signal hook
  - basic HUD prompt panel and dialogue line display
- Data-driven starter JSON files for dialogue, quests, and items.

## Open in Godot

1. Install **Godot 4.2+**.
2. Open this folder as a project.
3. Run project (`F5`).
4. Controls:
   - Move: `WASD` / arrows / left stick
   - Interact: `E` / `Space` / gamepad south
   - Attack: `J` / Ctrl / gamepad west
   - Pause/menu: `Esc` / `Start`

## Project layout (high level)

```txt
core/         # autoload services (scene routing, save, settings, input, events)
scenes/       # runnable scenes (main, world map, player, HUD)
gameplay/     # quest/combat/inventory systems
narrative/    # dialogue manager + world flags
audio/        # music/sfx manager
data/         # data-driven content inputs (dialogue, quests, items)
assets/       # imported art/audio placeholders
```

## Narrative/script ingestion workflow

To let the agent turn your script into game content, add files into:

```txt
data/source/narrative/
```

Recommended files:

- `story_outline.md` (main arc and acts)
- `characters.json` (bios, speaking style, portraits)
- `dialogue_master.(md|json|csv)` (all lines + choices + outcomes)
- `quests_master.json` (quest definitions and objective steps)
- `world_lore.md` (locations, factions, item lore)

After placing files, ask:

> "Parse `data/source/narrative` and generate Godot dialogue/quest data + NPC interaction stubs."

I will convert your narrative into structured runtime files under `data/dialogue`, `data/quests`, and map them to interaction points.

See `docs/NARRATIVE_PIPELINE.md` for the full ingestion checklist and recommended file formatting examples.

## Data schema references

- `data/dialogue/sample_dialogue.json`
- `data/quests/sample_quest.json`
- `data/items/sample_items.json`

These sample files show the expected structure for branching dialogue, quest states, and starter item metadata.
