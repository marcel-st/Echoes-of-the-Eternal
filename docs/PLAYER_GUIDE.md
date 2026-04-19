# Player Guide — Echoes of the Eternal

*Echoes of the Eternal* is an early **alpha** top-down adventure: explore maps, talk to townsfolk, read lore, follow quests in your journal, and use gates to travel between regions. Expect rough edges, placeholder content, and systems still in progress.

## Starting the game

### From source (Godot)

1. Install **Godot 4.6** (match the project’s `config/features`).
2. Open this repository folder as a project.
3. Press **F5** (Run Project).

### From a Linux build

1. Download **`echoes-of-the-eternal.x86_64`** and **`echoes-of-the-eternal.pck`** from the release page.
2. Place both files in the **same folder**.
3. In a terminal: `chmod +x echoes-of-the-eternal.x86_64`
4. Run: `./echoes-of-the-eternal.x86_64`

If the game window is large for your display, resize the window (project uses a scalable window).

## Controls

| Action | Keyboard / mouse | Gamepad |
|--------|------------------|---------|
| Move | **W A S D** or arrow keys | Left stick |
| Interact | **E**, **Space** | South face button (often **A** on Xbox layout) |
| Attack | **J**, **Ctrl** | West face button (often **X**) |
| Journal / pause menu | **Esc** | **Start** |

Exact bindings may follow your OS layout; see in-game HUD hints when available.

## What to do in the alpha

- **Talk to NPCs** when a prompt appears near them (interact key). While the **dialogue box** is open, **movement is paused**; press **E** or **Space** (confirm) to skip the typewriter or advance the line, **Esc / cancel** to close when allowed.
- **Open the journal** with Esc / Start to see **active quests** and **discovered lore** titles.
- **Explore map exits** — when you stand in a travel zone, the HUD shows a confirm prompt; press **Interact** (or the same binding shown) to change regions.
- **Inspect lore plinths** for world text (counts toward your journal’s lore list when discovered).

## Saves

- The project uses an **autosave** loop after important changes (quests, flags, lore, map changes).
- **Quit to desktop** from the OS window close also triggers save flush logic in the main scene where implemented.

If you are testing from the editor, note that save data lives under the editor’s **user data** path for this project name.

## Audio and atmosphere

- **Music** may change per region.
- **Footsteps and swings** and some world sounds are routed through the global audio bus.

## Feedback during alpha

Use **`docs/ALPHA_PLAYTEST_FEEDBACK.md`** as a template, or open a GitHub issue with:

- What you were doing
- Whether you were blocked
- Anything confusing (objectives, prompts, map exits)

## Lore content note

Some lore entries are long-form design text used to prove the pipeline; in a shipping game these would be rewritten into shorter in-world excerpts.
