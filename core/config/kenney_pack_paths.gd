extends RefCounted
class_name KenneyPackPaths

## Paths into the local Kenney all-in-one pack under `kenney_pack/` (gitignored).
## Godot does not import assets under dot-folders (e.g. `.resources/`), so use this name
## and copy or symlink the pack here: `kenney_pack/` → same layout as Kenney's bundle.

const _R := "res://kenney_pack/"

#region 2D — Tiny Dungeon + RPG Urban
## Soft filled circle (transparent outside) — squashed under feet for character shadows.
const CHARACTER_SHADOW_CIRCLE := _R + "2D assets/Scribble Platformer/PNG/Default/ui_circle.png"
const TINY_DUNGEON_TILEMAP_PACKED := _R + "2D assets/Tiny Dungeon/Tilemap/tilemap_packed.png"
const TINY_DUNGEON_TILES_DIR := _R + "2D assets/Tiny Dungeon/Tiles/"
const RPG_URBAN_TILEMAP_PACKED := _R + "2D assets/RPG Urban Pack/Tilemap/tilemap_packed.png"
#endregion

#region UI — Adventure pack panels
const UI_PANEL_BLUE := _R + "UI assets/UI Adventure Pack/PNG/panel_blue.png"
const UI_PANEL_INSET_BLUE := _R + "UI assets/UI Adventure Pack/PNG/panelInset_blue.png"
#endregion

#region Input — loose PNGs (keyboard + Xbox)
## `Default/` = 64×64 glyphs; `Double/` = 128×128. Prefer Default for HUD / world prompts.
const INPUT_KB_DEFAULT := _R + "Icons/Input Prompts/Keyboard & Mouse/Default/"
const INPUT_KB_DOUBLE := _R + "Icons/Input Prompts/Keyboard & Mouse/Double/"
const INPUT_XBOX_DOUBLE := _R + "Icons/Input Prompts/Xbox Series/Double/"
## Same art as Kenney `Default/keyboard_e.png` (sheet cell 640,320 @ 64×64); shipped under `assets/ui` so UI works without `kenney_pack/`.
const KEYBOARD_E := "res://assets/ui/input_prompt_keyboard_e.png"
#endregion

#region Audio
const AUDIO_MUSIC_JINGLE_RETRO := _R + "Audio/Music Jingles/Audio (Retro)/"
const AUDIO_INTERFACE := _R + "Audio/Interface Sounds/Audio/"
const AUDIO_UI_PACK := _R + "Audio/UI Audio/Audio/"
const AUDIO_MUSIC_LOOPS := _R + "Audio/Music Loops/Loops/"
const AUDIO_MUSIC_LOOPS_RETRO := _R + "Audio/Music Loops/Retro/"
const AUDIO_RPG := _R + "Audio/RPG Audio/Audio/"
const AUDIO_FOLEY_SWORDS := _R + "Audio/Foley Sounds/Audio/Swords/"
const AUDIO_IMPACT_FOOTSTEPS := _R + "Audio/Impact Sounds/Audio/"

const MUSIC_OVERWORLD := AUDIO_MUSIC_JINGLE_RETRO + "jingles-retro_03.ogg"
const MUSIC_MYSTIC := AUDIO_MUSIC_JINGLE_RETRO + "jingles-retro_06.ogg"
const MUSIC_CINDER := AUDIO_MUSIC_JINGLE_RETRO + "jingles-retro_09.ogg"
const MUSIC_VELDT := AUDIO_MUSIC_JINGLE_RETRO + "jingles-retro_12.ogg"
const MUSIC_DUNES := AUDIO_MUSIC_JINGLE_RETRO + "jingles-retro_15.ogg"

const UI_SELECT := AUDIO_INTERFACE + "select_003.ogg"
const UI_CONFIRM := AUDIO_INTERFACE + "confirmation_002.ogg"
const UI_BACK := AUDIO_INTERFACE + "back_002.ogg"
const UI_ERROR := AUDIO_INTERFACE + "error_003.ogg"
const UI_OPEN := AUDIO_INTERFACE + "open_002.ogg"
const UI_CLOSE := AUDIO_INTERFACE + "close_002.ogg"
## Short Interface ticks — blip when interact prompt appears; beep during dialogue typewriter.
const UI_TICK_POP := AUDIO_INTERFACE + "tick_002.ogg"
const UI_TICK_TYPEWRITER := AUDIO_INTERFACE + "tick_001.ogg"
const SFX_UI_CLICK := AUDIO_INTERFACE + "click_003.ogg"
const SFX_UI_MOUSE_CLICK := AUDIO_UI_PACK + "mouseclick1.ogg"

## No literal *wind* / *forest* ambience filename in the Kenney all-in bundle here; this loop reads as soft outdoor bed.
const AMBIENCE_FOREST_BED := AUDIO_MUSIC_LOOPS + "Flowing Rocks.ogg"
## Soft looping “magic” bed (Kenney Music Loops — Retro). Used by lore plinth proximity hum.
const LORE_PLINTH_MAGIC_HUM := AUDIO_MUSIC_LOOPS_RETRO + "Retro Mystic.ogg"

const WORLD_FOOTSTEP := AUDIO_RPG + "footstep04.ogg"
## Soft grass steps (Kenney Impact Sounds) — player uses these via `AudioStreamPlayer2D`.
const FOOTSTEP_GRASS_SOFT_0 := AUDIO_IMPACT_FOOTSTEPS + "footstep_grass_000.ogg"
const FOOTSTEP_GRASS_SOFT_1 := AUDIO_IMPACT_FOOTSTEPS + "footstep_grass_001.ogg"
const FOOTSTEP_GRASS_SOFT_2 := AUDIO_IMPACT_FOOTSTEPS + "footstep_grass_002.ogg"
const WORLD_INTERACT := AUDIO_RPG + "doorOpen_2.ogg"
const WORLD_SWING := AUDIO_FOLEY_SWORDS + "sword2.ogg"
const WORLD_MAP_TRANSITION := AUDIO_RPG + "doorClose_2.ogg"

const AMBIENCE_CREAK := AUDIO_RPG + "creak2.ogg"
#endregion

#region World props / plinth (loose tiles from Tiny Dungeon `Tiles/`)
const TILE_PROP_B := TINY_DUNGEON_TILES_DIR + "tile_0038.png"
const TILE_PROP_D := TINY_DUNGEON_TILES_DIR + "tile_0044.png"
const TILE_PROP_F := TINY_DUNGEON_TILES_DIR + "tile_0051.png"
const TILE_PROP_G := TINY_DUNGEON_TILES_DIR + "tile_0052.png"
const TILE_LORE_PLINTH := TINY_DUNGEON_TILES_DIR + "tile_0088.png"
#endregion
