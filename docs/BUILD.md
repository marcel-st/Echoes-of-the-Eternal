# Build Instructions — Echoes of the Eternal

This document covers **local development runs**, **narrative data regeneration**, and **exporting release binaries** (Linux first; other platforms follow the same Godot export flow).

## Engine version

- **Godot 4.2+** matching `project.godot` (`config/features=4.2`).
- Install **export templates** for the **exact** engine version you use (Editor → Manage Export Templates, or download from Godot’s site).

Mismatch between editor and templates is the most common cause of failed exports.

## Prerequisites

- **Godot** editor or headless binary for your OS.
- **Python 3** for `tools/import_narrative.py`.

Optional:

- **`gh`** (GitHub CLI) for publishing releases from the command line.

## Regenerate runtime narrative data

Whenever you edit files under `data/source/narrative/`:

```bash
cd /path/to/Echoes-of-the-Eternal
python3 tools/import_narrative.py
```

Outputs include (among others):

- `data/dialogue/dialogues.json`
- `data/quests/quests.json`
- `data/items/items.json`
- `data/world/lore_entries.json`
- `data/npcs/npc_registry.json`

Commit these when you want the repo to reflect the new narrative state, or regenerate in CI before export.

## Run from the Godot editor

1. Open the project folder.
2. Ensure import completes (first open may take a minute).
3. **Project → Project Settings** is optional for day-to-day work; defaults are already set.
4. Press **F5** to run `scenes/main.tscn`.

## Linux export (recommended script)

The repo includes **`export_presets.cfg`** with a preset named **`Linux/X11`** targeting:

- `builds/linux/echoes-of-the-eternal.x86_64`
- `builds/linux/echoes-of-the-eternal.pck` (external pack; `embed_pck` is false)

Run:

```bash
cd /path/to/Echoes-of-the-Eternal
chmod +x scripts/export_linux_release.sh

# If `godot4` is on your PATH:
./scripts/export_linux_release.sh

# Or point at a specific binary:
GODOT_BIN="$HOME/Apps/Godot_v4.2.2-stable_linux.x86_64" ./scripts/export_linux_release.sh
```

The script runs **`import_narrative.py`** first, then **headless export**:

```text
godot4 --headless --path . --export-release "Linux/X11" "builds/linux/echoes-of-the-eternal.x86_64"
```

### Running the exported game

The `.pck` must sit **next to** the `.x86_64` binary:

```bash
cd builds/linux
chmod +x echoes-of-the-eternal.x86_64
./echoes-of-the-eternal.x86_64
```

## Headless export (manual)

```bash
python3 tools/import_narrative.py
godot4 --headless --path . --export-release "Linux/X11" "builds/linux/echoes-of-the-eternal.x86_64"
```

List presets from the command line (Godot 4.x):

```bash
godot4 --headless --path . --export-release --help
```

(Exact flags vary slightly by Godot minor version; the editor **Export** dialog remains the source of truth.)

## Windows / SteamOS notes

1. Add a **Windows Desktop** preset in the Godot editor (or duplicate Linux preset and adjust).
2. Export from the same project revision you tagged.
3. For Steam, you will later wrap the binary with Steamworks SDK / depot layout — out of scope for this alpha doc.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| Export fails: missing templates | Export templates not installed | Install templates matching your Godot version |
| Export fails: parse errors in `.tscn` | Scene saved by a newer incompatible format | Open and re-save in your 4.2.x editor, or align engine versions |
| Game runs but no dialogue | Stale or missing `data/dialogue/dialogues.json` | Run `import_narrative.py` |
| Silent `sfx_requested` | Old build or wrong bus | Verify `EventBus` wiring and `AudioManager` autoload order |
| Linux binary won’t start | Missing `.pck` beside executable | Keep both release artifacts together |

## CI (optional sketch)

A minimal pipeline would:

1. `python3 tools/import_narrative.py`
2. Download pinned Godot + templates
3. `godot --headless --path . --export-release "Linux/X11" dist/echoes-of-the-eternal.x86_64`
4. Upload `dist/*.x86_64` + `dist/*.pck` as release assets

## Related docs

- **`docs/DEVELOPER_GUIDE.md`** — architecture and extension points.
- **`docs/PLAYER_GUIDE.md`** — tester-facing instructions.
- **`docs/RELEASE_NOTES_ALPHA_0.1.md`** — example release notes for alpha builds.
