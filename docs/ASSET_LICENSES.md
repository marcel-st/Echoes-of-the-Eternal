 # Asset Licenses and Attribution

 This file tracks all third-party assets included in this repository.

 ## License policy

 Preferred:
 - CC0
 - CC-BY 4.0 (with attribution)
 - OFL (fonts)

 Avoid:
 - Non-commercial (NC)
 - No derivatives (ND)
 - Any license with ambiguous commercial terms

## Kenney.nl — art & audio (license coverage)

**Creator:** Kenney Vleugels ([Kenney](https://www.kenney.nl/)). **Standard license for Kenney game assets:** [Creative Commons Zero (CC0 1.0 Universal)](https://creativecommons.org/publicdomain/zero/1.0/) — i.e. public domain dedication to the extent allowed by law. You may copy, modify, and distribute Kenney assets for any purpose (including commercial games) without asking permission; **attribution is not legally required** but is **encouraged** (this project lists packs in `assets/ATTRIBUTION.md`).

- **Authoritative copy per download:** each official pack includes a **`license.txt`** (also committed next to imported files under `assets/**` where applicable).
- **Optional full bundle:** developers may mirror Kenney’s all-in-one layout under `kenney_pack/` (gitignored); those files carry the same **CC0** terms from Kenney’s distribution. Runtime paths are documented in `core/config/kenney_pack_paths.gd`.
- **This repo’s MIT `LICENSE` file applies to original source code only**; see the *Third-party assets* section in `LICENSE` for the split.

If Kenney ever ships a pack under a different license, treat that pack’s **`license.txt`** as the source of truth and update this document.

 ## Attribution format

 For each imported pack, add:

 - **Pack Name**
 - **Creator**
 - **Source URL**
 - **License**
 - **Files used in project**
 - **Any required attribution text**

 ---

 ## Registered assets

### 1) Kenney UI Pack (RPG Expansion)
 - Creator: Kenney
- Source: https://kenney.nl/assets/ui-pack-rpg-expansion
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/sprites/ui/kenney_ui-pack-rpg-expansion/**`
  - `assets/ui/dialogue_arrow_blue_right.png` (continue-arrow glyph; same pack style / `arrowBlue_right`-class art)
 - Attribution text:
   - "UI Pack RPG Expansion by Kenney (CC0)."

### 2) Kenney Tiny Dungeon
 - Creator: Kenney
- Source: https://kenney.nl/assets/tiny-dungeon
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/sprites/world/kenney_tiny-dungeon/**`
 - Attribution text:
   - "Tiny Dungeon by Kenney (CC0)."

### 3) Kenney RPG Urban Pack
 - Creator: Kenney
- Source: https://kenney.nl/assets/rpg-urban-pack
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/sprites/world/kenney_rpg-urban-pack/**`
 - Attribution text:
  - "RPG Urban Pack by Kenney (CC0)."

### 4) Kenney Interface Sounds
 - Creator: Kenney
- Source: https://kenney.nl/assets/interface-sounds
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/audio/sfx/ui/kenney_interface-sounds/**`
 - Attribution text:
  - "Interface Sounds by Kenney (CC0)."

### 5) Kenney Music Jingles
 - Creator: Kenney
- Source: https://kenney.nl/assets/music-jingles
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/audio/music/kenney_music-jingles/**`
 - Attribution text:
  - "Music Jingles by Kenney (CC0)."

### 6) Kenney RPG Audio
 - Creator: Kenney
- Source: https://kenney.nl/assets/rpg-audio
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/audio/sfx/world/kenney_rpg-audio/**`
  - `assets/audio/ambience/kenney_rpg-audio/**`
 - Attribution text:
  - "RPG Audio by Kenney (CC0)."

### 7) Kenney UI Pack (base)
 - Creator: Kenney
- Source: https://kenney.nl/assets/ui-pack
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/sprites/ui/kenney_ui-pack/blue_default/**`
  - `assets/sprites/ui/kenney_ui-pack/license.txt`
 - Attribution text:
  - "UI Pack by Kenney (CC0)."

### 8) Kenney Input Prompts Pixel
 - Creator: Kenney
- Source: https://kenney.nl/assets/input-prompts-pixel
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/sprites/ui/kenney_input-prompts-pixel/glyph_*.png`
  - `assets/sprites/ui/kenney_input-prompts-pixel/Preview.png`
  - `assets/sprites/ui/kenney_input-prompts-pixel/Tilesheet.txt`
  - `assets/sprites/ui/kenney_input-prompts-pixel/license.txt`
  - `assets/ui/input_prompt_keyboard_e.png` (Kenney Keyboard & Mouse Default sheet cell; shipped for prompts without `kenney_pack/`)
 - Attribution text:
  - "Input Prompts Pixel by Kenney (CC0)."

### 9) Kenney UI Pack — Adventure (dialogue panels + `kenney_pack` paths)
 - Creator: Kenney
 - Source: https://kenney.nl/assets/ui-pack-adventure
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/ui/dialogue_panel_blue.png`, `assets/ui/dialogue_panel_inset_blue.png` (nine-patch / inset frame art)
  - `kenney_pack/UI assets/UI Adventure Pack/**` (when the optional bundle is present)

### 10) Kenney Fonts — Pixel
 - Creator: Kenney
 - Source: https://kenney.nl/assets/kenney-fonts
 - License: CC0 1.0 Universal
 - Files used:
  - `assets/fonts/Kenney_Pixel.ttf`

### 11) Kenney Scribble Platformer (player shadow)
 - Creator: Kenney
 - Source: https://kenney.nl/assets/scribble-platformer
 - License: CC0 1.0 Universal
 - Files used:
  - `kenney_pack/2D assets/Scribble Platformer/PNG/Default/ui_circle.png` (referenced from `player.tscn` when `kenney_pack` is installed)

### 12) Kenney Music Loops
 - Creator: Kenney
 - Source: https://kenney.nl/assets/music-loops
 - License: CC0 1.0 Universal
 - Files used:
  - `kenney_pack/Audio/Music Loops/Loops/Flowing Rocks.ogg` (default ambience bed via `SoundManager`)

### 13) Kenney Music Loops — Retro
 - Creator: Kenney
 - Source: https://kenney.nl/assets/music-loops (Retro subfolder in Kenney bundle)
 - License: CC0 1.0 Universal
 - Files used:
  - `kenney_pack/Audio/Music Loops/Retro/Retro Mystic.ogg` (lore plinth hum)

### 14) Kenney Impact Sounds (footsteps)
 - Creator: Kenney
 - Source: https://kenney.nl/assets/impact-sounds
 - License: CC0 1.0 Universal
 - Files used:
  - `kenney_pack/Audio/Impact Sounds/Audio/footstep_grass_*.ogg` (player footsteps)

### 15) Kenney UI Audio
 - Creator: Kenney
 - Source: https://kenney.nl/assets/ui-audio
 - License: CC0 1.0 Universal
 - Files used:
  - `kenney_pack/Audio/UI Audio/Audio/mouseclick1.ogg` (named SFX path in `SoundManager`)

### 16) Kenney Foley Sounds — Swords
 - Creator: Kenney
 - Source: https://kenney.nl/assets/foley-sounds
 - License: CC0 1.0 Universal
 - Files used:
  - `kenney_pack/Audio/Foley Sounds/Audio/Swords/sword2.ogg` (attack swing)

---

## Review checklist

- [x] Every imported pack listed here
- [x] License copied and verified
- [x] Attribution text present in `assets/ATTRIBUTION.md`
- [x] No NC/ND assets in shipped content
