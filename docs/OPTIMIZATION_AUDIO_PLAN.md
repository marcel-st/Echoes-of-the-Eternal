# Optimization + Audio Enhancement Plan (Executed)

This plan covers gameplay polish, technical optimizations, and open/free audio integration.

## Goals

1. Improve responsiveness and reduce noisy runtime behavior.
2. Add robust, reusable audio infrastructure (music/SFX/UI/ambience).
3. Integrate free/open licensed audio content.
4. Keep systems data-driven and maintainable.

## Workstreams

### A) Runtime and UX optimizations
- Add debounced autosave to avoid repeated save writes on bursty event chains.
- Add prompt de-duplication/cooldown so HUD messages are readable and stable.
- Reduce repetitive dialogue-choice node churn and improve dialogue input feedback.
- Keep NPC interactions and ambient behavior lightweight.

### B) Audio engine improvements
- Expand `AudioManager` to support:
  - keyed music tracks (`play_music_track`)
  - keyed ambience loops (`play_ambience`, `stop_ambience`)
  - one-shot SFX/UI playback helpers (`play_sfx`, `play_ui`)
  - safer fade transitions and stop/restart handling
- Initialize and map known track/effect ids to imported assets.
- Emit/consume audio events through `EventBus` for decoupled integration.

### C) Content integration (open/free assets)
- Import CC0 Kenney packs:
  - Interface Sounds
  - Music Jingles
  - RPG Audio
- Organize by purpose:
  - `assets/audio/music/...`
  - `assets/audio/sfx/ui/...`
  - `assets/audio/sfx/world/...`
  - `assets/audio/ambience/...`
- Update attribution and license ledgers.

### D) Gameplay/UI audio hooks
- Map transitions -> transition SFX.
- Player attack/interact/footsteps -> world SFX.
- Dialogue open/choice/close -> UI SFX.
- Journal open/close -> UI SFX.
- Lore inspect -> world interact SFX.

## Validation checklist

- All referenced audio files exist and load.
- No stale property names (`wander_enabled`) remain.
- Prompt spam and autosave burst behavior reduced.
- Attribution docs contain every imported pack and path.

