# Repository Guidelines

## Project Structure & Module Organization

This is a Godot 4.6 2D RPG. Core autoload-style services live in `core/`, including event routing, scene routing, saves, settings, and sound. Runtime scenes are under `scenes/`: `scenes/main.tscn` starts the game, `scenes/world/` contains maps, `scenes/player/` contains the player, and `scenes/ui/` contains HUD and dialogue UI. Gameplay systems currently live in `gameplay/`, narrative helpers in `narrative/`, and world/lore code in `world/`. Runtime JSON data is in `data/`; editable narrative source is in `data/source/narrative/`. Assets are under `assets/`, with license notes in nearby `license.txt` files plus `assets/ATTRIBUTION.md` and `docs/ASSET_LICENSES.md`. Project documentation is in `docs/`, especially `docs/DEVELOPER_GUIDE.md` and `docs/BUILD.md`.

## Build, Test, and Development Commands

- `godot --headless --import --path .`: import assets on a fresh clone if textures or fonts are missing.
- `python3 tools/import_narrative.py`: regenerate runtime JSON after editing `data/source/narrative/`.
- `./scripts/export_linux_release.sh`: regenerate narrative data and export the Linux build using `export_presets.cfg`.
- `godot4 --headless --path . --export-release "Linux/X11" "builds/linux/echoes-of-the-eternal.x86_64"`: manual Linux export.

For local playtesting, open the folder in Godot 4.6 and press F5.

## Coding Style & Naming Conventions

Match the surrounding GDScript style. Use tabs for GDScript indentation, descriptive snake_case file and variable names, and PascalCase only where Godot class/resource conventions already use it. Prefer existing managers and signals, especially `EventBus`, `SceneRouter`, `DialogueManager`, `QuestManager`, `SaveManager`, `AudioManager`, and `SoundManager`, instead of adding direct scene coupling. Keep comments short and useful.

## Testing Guidelines

There is no formal automated test suite yet. Validate changes with focused manual smoke tests in Godot: movement, interaction, dialogue advance, map transitions, journal/HUD behavior, saves, and audio if touched. When narrative source changes, run `python3 tools/import_narrative.py` and review generated JSON for expected dialogue, quest, item, NPC, and lore updates.

## Commit & Pull Request Guidelines

Recent commits use short imperative subjects such as `Fix DialogueBox visuals...`, `Add dialogue UI...`, and `Document Kenney CC0 license...`. Keep commits focused and explain the changed area first. Pull requests should describe the change, list manual test coverage, link issues with `Fixes #123` when relevant, and include screenshots or clips for visual/UI changes. Do not mix unrelated refactors with bug fixes.

## Security & Asset Notes

Report security issues privately using `SECURITY.md`. Only add third-party assets that comply with `docs/ASSET_LICENSES.md`, and update `assets/ATTRIBUTION.md` when new asset sources are introduced. Do not commit local asset mirrors such as `kenney_pack/` or other large proprietary bundles.

## Code Search

Use `semble search` to find code by describing what it does or naming a symbol/identifier, instead of grep:

```bash
semble search "authentication flow" ./my-project
semble search "save_pretrained" ./my-project
semble search "save model to disk" ./my-project --top-k 10
```

Use `semble find-related` to discover code similar to a known location (pass `file_path` and `line` from a prior search result):

```bash
semble find-related src/auth.py 42 ./my-project
```

`path` defaults to the current directory when omitted; git URLs are accepted.

If `semble` is not on `$PATH`, use `uvx --from "semble[mcp]" semble` in its place.

## Workflow

1. Start with `semble search` to find relevant chunks.
2. Inspect full files only when the returned chunk is not enough context.
3. Optionally use `semble find-related` with a promising result's `file_path` and `line` to discover related implementations.
4. Use grep only when you need exhaustive literal matches or quick confirmation of an exact string.
