# Contributing to Echoes of the Eternal

Thank you for helping improve the project. This document explains how we work in this repository and what to include in a change.

## Before you start

- **Engine:** Open the project in **Godot 4.6** (see `project.godot` → `config/features`). Match export templates to your editor build.
- **Scope:** Prefer small, focused pull requests that solve one problem or add one feature.
- **Assets:** Third-party art and audio must comply with **`docs/ASSET_LICENSES.md`** and be recorded in **`assets/ATTRIBUTION.md`**. **Kenney** assets are typically **CC0 1.0 Universal** (see each pack’s `license.txt` and the Kenney section in `docs/ASSET_LICENSES.md`). Do not commit large proprietary bundles; use `kenney_pack/` or documented sync scripts as described in **`core/config/kenney_pack_paths.gd`**.

## Workflow

1. **Fork** the repository and create a branch from `main`.
2. **Implement** your change; keep diffs readable and follow existing naming and patterns in touched files.
3. **Run** the project in the editor (F5) and sanity-check the areas you changed (movement, dialogue, map transitions, saves).
4. **Narrative data:** If you edit files under `data/source/narrative/`, run `python3 tools/import_narrative.py` and commit the regenerated JSON when appropriate (see **`docs/NARRATIVE_PIPELINE.md`**).
5. **Open a pull request** using the PR template. Link related issues with `Fixes #123` when applicable.

## Code style

- Match the style of the surrounding GDScript (spacing, naming, minimal comments).
- Prefer **`EventBus` signals** and existing managers (`DialogueManager`, `QuestManager`, `SoundManager`) over tight coupling between scenes.
- Avoid unrelated refactors in the same PR as a bugfix.

## Security

Please do not report security issues in public issues. See **`SECURITY.md`** for how to contact maintainers privately.

## Community

We follow the **`CODE_OF_CONDUCT.md`**. Be respectful and assume good intent.
