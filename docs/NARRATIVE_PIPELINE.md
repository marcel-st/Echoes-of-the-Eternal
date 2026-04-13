# Narrative & Script Pipeline

This document explains how to hand over your story content so it can be integrated into the game quickly and safely.

## 1) Where to place source files

Create this folder structure and drop your source material there:

```txt
res://data/source/narrative/
  story_outline.md
  world_lore.md
  characters.json
  dialogue_master.json
  npcs.json
  quest_master.json
  items.json
  main_story.md
```

You can also use `.txt` if you prefer.

## 2) Preferred format per file

Use consistent headings and structured blocks. Example:

```md
# NPC: Elder Mira
id: elder_mira

## Bio
- ...

## Dialogue Nodes
### node: intro_first_meet
speaker: elder_mira
text: "..."
conditions:
  - met_elder_mira == false
choices:
  - text: "Who are you?"
    next: intro_who_are_you
effects:
  - set_flag: met_elder_mira=true
```

For quests:

```md
# Quest: The Broken Bridge
id: q_broken_bridge
type: side

## Start Conditions
- chapter >= 1
- flag.met_bridge == true

## Objectives
1. Speak to Toren
2. Gather 5 Ironwood
3. Return to Toren

## Rewards
- item: potion_small x3
- xp: 200
```

## 3) Minimum metadata to include

Always include:

- Stable IDs for every entity (`elder_mira`, `q_broken_bridge`, `ironwood`)
- Speaker IDs for dialogue lines
- Conditions (flags, quest state, item checks)
- Effects/outcomes after a node or quest step

## 4) How to hand it over to me

You can provide content in either way:

1. **Paste directly in chat** (for smaller batches), or
2. **Add files into `data/source/narrative/`** and tell me the paths.

Then I will:

1. Parse and normalize it into game data files (`res://data/dialogue`, `res://data/quests`, `res://data/items`)
2. Add any missing schema fields
3. Wire references in `DialogueManager`, `QuestManager`, and world flags
4. Add validation checks for missing IDs and broken links

## 5) Batch import workflow (recommended)

Deliver in this order for best results:

1. Characters + locations + items
2. Main questline
3. Side quests
4. NPC dialogue
5. Cutscene scripts

This order reduces dependency mismatches while building.

## 6) Quality checks I will run on each import

- Unknown IDs (speaker/quest/item/flag)
- Dialogue links that point to missing nodes
- Quest objectives with missing hooks
- Circular quest dependencies
- Reward definitions with unknown items

