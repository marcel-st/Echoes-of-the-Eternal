# Art Direction Guide

This document defines the visual direction for Echoes of the Eternal so the game feels modern, cohesive, and readable across Windows, Linux, and Steam Deck.

## 1) Visual target

- **Style:** modernized top-down pixel art RPG.
- **Reference mood:** classic SNES readability + richer modern lighting and UI polish.
- **Output resolution:** 1920x1080.
- **Gameplay readability first:** gameplay-critical objects always have strong silhouette contrast.

## 2) Pixel scale and technical rules

- Character sprite baseline: **32x48** pixels.
- Small props: **16x16** or **32x32**.
- Major props/structures: multiples of 16, visually scaled against the current 2.4x-2.5x character sprites. A walkable village house should read as at least 2-3 characters wide and taller than a character.
- Keep nearest-neighbor filtering for world sprites.
- Avoid mixed texel density within the same region.
- Approved Tiny Town atlas coordinates live in `world/tiny_town_tiles.gd`; do not add raw atlas coordinates directly to map painters.
- Outdoor world maps are painted through `world/world_painter.gd` using `assets/tilesets/tiny_town.tres`. Add new atlas cells by naming them in `world/tiny_town_tiles.gd` first, then use the named constant from a painter.
- Village buildings use prefab scenes rather than one-off TileMap stamps. `scenes/objects/VillageHouse.tscn` is the current scale reference for Oakhaven houses.

## 3) Color and palette system

Use a global base palette plus biome accents:

- **Oakhaven:** moss greens, warm stone, amber lantern highlights.
- **Whispering Vales:** deep greens + misty cyan accents.
- **Sunken Library:** muted blue-gray + pale parchment highlights.
- **Cinder Peaks:** charcoal, rust red, ember orange.
- **Sinking Sands:** warm ochre, faded bronze, desaturated sky tones.

Rules:

- Keep important interactables 10-20 percent brighter than surrounding props.
- Reserve high-saturation accents for quest-critical props, effects, and UI highlights.
- Keep text/UI contrast WCAG-friendly against dark translucent panels.

## 4) Character design language

- Shared body proportions across cast.
- Distinct silhouette per major character (Kaelen, Elara, Malakor, key NPCs).
- Use one strong accent color per character for immediate recognition.
- Portraits should match in framing, lighting direction, and line weight.

## 5) Lighting and atmosphere

- Use subtle 2D lighting; avoid overbloom.
- Ambient particles by biome:
  - dust motes (Oakhaven),
  - drifting leaves/spores (Vales),
  - ash embers (Cinder),
  - sand drift (Sands),
  - mist motes (Library).
- Keep light color tied to biome palette for cohesion.

## 6) UI art direction

- Rounded, soft-corner dark panels with light borders.
- Use one icon family for all journal/dialogue/menu icons.
- Portrait panel style must be consistent between all dialogues.
- Keep UI scale readable on 1280x720 (Steam Deck).
- The HUD minimap is a functional navigation aid, not decorative art. It should show the current region, player position, and the active objective marker without covering dialogue or prompts.

## 7) Animation quality bar

Minimum target:

- Player: idle, walk (8-dir if available), interact, attack.
- Key NPCs: idle loop + at least one gesture/talk pose.
- Environmental loops: small looping motions (banners, particles, water/heat shimmer).

## 8) Asset consistency checklist (before merge)

- Same outline thickness across sprite sets.
- Same shadow direction or intentionally shadowless style.
- No mixed perspective angle between tiles and sprites.
- No unlicensed assets.
- Attribution entries added for every non-CC0 resource.
- Screenshot review passes should use local `Screenshot_*.png` files only; these are ignored and should not be committed.
- Interaction objects should not visually overlap their gameplay radius with quest NPCs unless intentionally designed. Lore plinths use a lower interaction priority than NPCs and should be placed away from primary dialogue clusters.
