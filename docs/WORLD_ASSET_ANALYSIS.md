# World Asset Analysis

This project currently uses a top-down, pixel-scale 2D camera. The usable Kenney packs need to match that projection and sprite density, otherwise the world reads as a collage.

## Best Fit For The Current World

- `Tiny Town`: primary outdoor pack. It has matching top-down terrain, grass, sand, stone, paths, fences, signs, lamps, wells, trees, and village-readable props at the same 16 px tile scale. This is the right base for Oakhaven, Whispering Vales, exterior roads, and readable overworld landmarks.
- `Tiny Dungeon`: best fit for interior or ruin maps. Its wall/floor/prop language is the same scale as Tiny Town, but reads as enclosed dungeon space. It should be used for future interiors, the Sunken Library interior, crypts, sealed ruins, and underground scenes.
- `Micro Roguelike` and the `Roguelike * Pack` series: usable for later combat arenas, enemy sprites, special dungeons, or icon-like props, but visually darker and denser than Tiny Town. Use selectively so they do not fight the outdoor palette.
- `Minimap Pack`: useful as direction for the HUD map style, but not as the source for the live minimap. A drawn minimap can follow actual map state, current scene, player position, and objective markers without maintaining separate static art.

## Limited Or Future Use

- `RPG Urban Pack` and `Roguelike City Pack`: good packs, wrong setting for the current fantasy village unless the story later reaches a modern city or pre-collapse district.
- `RTS Medieval (Pixel)`: thematically close, but its overview-map scale is different from the player-scale top-down scenes. Better for a region/world map screen than walkable gameplay terrain.
- `Map Pack` and `Cartography Pack`: useful for menus, quest maps, or journal illustrations, not for live walkable spaces.

## Rejected For Runtime Maps

- Isometric packs: wrong projection for the current camera and collision layout.
- Platformer packs: side-view terrain does not fit top-down movement.
- Large vector/foliage/background packs: inconsistent scale and rendering style compared with Tiny Town.
- Monochrome or one-bit packs: useful for special UI or dream sequences, but not as the main world style.

## Implementation Direction

The outdoor scenes should share one generated tile language built from Tiny Town, with each region distinguished by layout, density, and palette:

- Oakhaven: structured crossroads, fenced village green, lamps, signs, well, groves, and readable paths to exits.
- Whispering Vales: denser forest edges, winding central trail, meadow clearings, and organic clusters.
- Sunken Library exterior: stone ruin mass, broken courtyards, grave markers, and overgrown approaches.
- Sinking Sands: sand base, broken stone pads, sparse landmarks, and clear road direction.
- Cinder Peaks: stone/ash base, rough rock fields, hard-edged routes, and smaller safe platforms.

This keeps the world expandable: future maps can add new painter functions or replace generated layouts with authored TileMap layers while preserving the same asset scale.

## Current Approved Tiny Town Runtime Set

Runtime painters should use `world/tiny_town_tiles.gd` instead of embedding raw atlas coordinates. The current approved cells are intentionally small: grass, grass speckle, flowers, dirt center/edges, stone floors, ruin floor/wall, sign, and small rock. If a new decorative prop is needed, first inspect it in an indexed atlas/contact sheet and add a named constant before using it in a map.

Village buildings are assembled as prefabs, not raw map stamps. `scenes/objects/VillageHouse.tscn` is the current Oakhaven house baseline: wide roof, brown wall set, visible door, nearest-neighbor rendering, and scaled to match the current large character sprites.

## Implemented Runtime World Pass

The current maps use a shared painter in `world/world_painter.gd`:

- `paint_oakhaven()` builds the Oakhaven grass base, crossroads, village green, stone plaza, paths, house pads, and readable route toward the south gate.
- `paint_whispering_vales()` builds a denser forest-edge map with an organic path and clearing.
- `paint_sunken_library_entry()` builds the ruin approach using stone floors, ruin walls, and broken courtyard texture.
- `paint_sinking_sands()` builds the sand route with sparse landmarks and broken stone pads.
- `paint_cinder_peaks()` builds rough ash/stone routes with harder obstacle shapes.

Each painter creates or reuses map TileMapLayer nodes. Authored scene objects such as NPCs, lore plinths, gates, houses, and transition areas remain in the `.tscn` files so the map can stay data-driven and inspectable in the editor.

## HUD Minimap

The active minimap lives in `scenes/ui/minimap.gd` and is instanced from `scenes/ui/hud.tscn`. It draws directly from the current player position and scene path, then overlays a goal marker based on quest and flag state.

Current objective behavior:

- Before Herald Corwin is met, Oakhaven points the player toward the Herald.
- After `MQ_01_AWAKENING` starts or the relevant story flags are set, Oakhaven points toward the south gate.
- Non-Oakhaven maps point back toward the correct regional objective or Oakhaven depending on the active stage.

Keep the minimap independent from decorative map art. It should remain a compact gameplay tool that can be extended with discovered regions, fog of war, or quest categories later.

## Interaction Placement Rules

NPCs have higher interaction priority than lore plinths, and the player scans a small grace radius around NPCs so dialogue still works when standing just outside the visible prompt circle. Lore plinths intentionally use a smaller radius and lower priority.

Scene layout still matters: do not place a lore plinth or sign directly inside a primary NPC's interaction area. The Oakhaven chronicle plinth was moved away from Herald Corwin for this reason.
