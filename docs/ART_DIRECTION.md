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
- Major props/structures: multiples of 16.
- Keep nearest-neighbor filtering for world sprites.
- Avoid mixed texel density within the same region.

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
