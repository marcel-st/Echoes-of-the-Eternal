# Alpha Release Plan (Linux)

This plan targets a local playable alpha build for Linux laptops (including CachyOS).

## Scope Lock (Alpha 0.1)

Playable slice:

1. `MQ_01_AWAKENING`
2. `MQ_02_EMPATHY`
3. `MQ_03_COURAGE`
4. `MQ_09_GLASS_TRIBUNAL`
5. `SQ_BRAM_01`
6. `SQ_CALDRIN_01`

Content freeze rule:

- Treat `data/source/narrative/*` as locked for the next test cycle.
- Only fix blockers, progression bugs, UI clarity, and performance issues.

## Build Checklist (Must Pass)

1. Game launches to `main.tscn`.
2. Quest chain progression works from `MQ_01` to `MQ_09`.
3. Journal updates while playing.
4. Dialogue never hard-locks interaction.
5. Save -> quit -> relaunch -> load restores:
   - map
   - player position
   - quest progress/state
   - lore discovery
6. Audio behaves across map transitions (music + one-shot SFX).
7. No critical errors in debugger during the full alpha route.

## Test Session Cadence

- Session length: 30-45 minutes.
- Route: same route each run for comparable feedback.
- Frequency: daily or every second day for rapid iteration.

## Test Feedback Log Template

For each run, record:

- Build: `alpha-x.y.z`
- Route covered:
- Blockers:
- Confusing quest/objective text:
- Dialogue pacing:
- Combat feel:
- Performance notes (FPS/stutter points):
- Best moment:
- Top 3 fixes for next build:

## Versioning

- `alpha-0.1.0`: first buildable vertical slice.
- `alpha-0.1.1+`: bugfix/stability only.
- `alpha-0.2.0`: next feature increment after blocker burn-down.
