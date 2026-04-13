#!/usr/bin/env python3
"""Convert narrative source files into runtime JSON payloads.

This importer reads curated files from data/source/narrative and generates
runtime data consumed by Godot managers:
  - data/dialogue/dialogues.json
  - data/quests/quests.json
  - data/items/items.json
  - data/world/lore_entries.json
  - data/npcs/npc_registry.json
"""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SOURCE_DIR = ROOT / "data" / "source" / "narrative"
OUTPUT_DIALOGUE = ROOT / "data" / "dialogue" / "dialogues.json"
OUTPUT_QUESTS = ROOT / "data" / "quests" / "quests.json"
OUTPUT_ITEMS = ROOT / "data" / "items" / "items.json"
OUTPUT_LORE = ROOT / "data" / "world" / "lore_entries.json"
OUTPUT_NPCS = ROOT / "data" / "npcs" / "npc_registry.json"


def _load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _load_text(path: Path) -> str:
    with path.open("r", encoding="utf-8") as handle:
        return handle.read()


def _sanitize_dialogue_id(raw: str) -> str:
    return raw.replace("-", "_").replace(" ", "_").upper()


def _clean_markdown_text(raw: str) -> str:
    output_lines: list[str] = []
    for line in raw.splitlines():
        stripped = line.strip()
        if not stripped:
            output_lines.append("")
            continue
        if stripped.startswith("import "):
            continue
        if stripped.startswith("# Define "):
            continue

        if (" = \"\"\"" in line) or (" = '''" in line):
            rhs = line.split("=", 1)[1]
            line = rhs
        line = line.replace('"""', "").replace("'''", "")
        if line.strip() in {"story_outline =", "world_lore ="}:
            continue
        output_lines.append(line)
    return "\n".join(output_lines).strip()


def _parse_markdown_sections(path: Path) -> list[dict[str, str]]:
    cleaned = _clean_markdown_text(_load_text(path))
    if not cleaned:
        return []

    sections: list[dict[str, str]] = []
    current_title = path.stem.replace("_", " ").title()
    current_lines: list[str] = []
    section_index = 1

    for line in cleaned.splitlines():
        stripped = line.strip()
        if stripped == "---":
            continue
        if stripped.startswith("#"):
            if current_lines:
                sections.append(
                    {
                        "id": f"{path.stem}_{section_index:03d}",
                        "source": path.name,
                        "title": current_title,
                        "text": " ".join(current_lines).strip(),
                    }
                )
                section_index += 1
                current_lines = []
            current_title = stripped.lstrip("#").strip()
            continue
        if stripped:
            current_lines.append(stripped)

    if current_lines:
        sections.append(
            {
                "id": f"{path.stem}_{section_index:03d}",
                "source": path.name,
                "title": current_title,
                "text": " ".join(current_lines).strip(),
            }
        )
    return sections


def _build_speaker_lookup(
    characters_payload: dict[str, Any], npcs_payload: dict[str, Any]
) -> dict[str, str]:
    lookup: dict[str, str] = {}

    for entry in characters_payload.get("characters", []):
        if not isinstance(entry, dict):
            continue
        entry_id = str(entry.get("id", "")).strip()
        if not entry_id:
            continue
        lookup[entry_id] = str(entry.get("name", entry_id))

    for entry in npcs_payload.get("sidequest_npcs", []):
        if not isinstance(entry, dict):
            continue
        entry_id = str(entry.get("id", "")).strip()
        if not entry_id:
            continue
        lookup[entry_id] = str(entry.get("name", entry_id))

    return lookup


def _dialogue_node(
    node_id: str,
    speaker_name: str,
    lines: list[str],
    choices: list[dict[str, Any]] | None = None,
    metadata: dict[str, Any] | None = None,
    outcomes: list[str] | None = None,
) -> tuple[str, dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for line in lines:
        entries.append({"speaker": speaker_name, "text": line})

    if choices and entries:
        entries[-1]["choices"] = choices

    node: dict[str, Any] = {"entries": entries}
    if metadata:
        node["meta"] = metadata
    if outcomes:
        node["outcomes"] = outcomes
    return node_id, node


def _normalize_reward_to_effect(reward_token: str) -> str:
    token = reward_token.strip()
    if token == "set_name_kaelen":
        return "set_flag:kaelen_named=true"
    if token.startswith("unlock_map_marker_"):
        marker_name = token.replace("unlock_map_marker_", "")
        return f"set_flag:map_marker_{marker_name}=true"
    if token == "give_item_heart_piece":
        return "give_item:art_heart_piece:1"
    return f"prompt:Reward applied: {token}"


def _append_unique(outcomes: list[str], value: str) -> None:
    if value and value not in outcomes:
        outcomes.append(value)


def _extend_unique(outcomes: list[str], values: list[str]) -> None:
    for value in values:
        _append_unique(outcomes, value)


def _action_to_effects(node_id: str, action: str) -> list[str]:
    action_token = action.strip()
    if not action_token:
        return []

    mapped: list[str] = []
    if action_token == "unlock_map_marker_library":
        mapped.extend(
            [
                "set_flag:map_marker_library=true",
                "set_flag:elara_intro_complete=true",
                "start_quest:MQ_01_AWAKENING",
                "set_quest_state:MQ_01_AWAKENING:active",
                "prompt:Journal updated: The First Spark",
            ]
        )
    elif action_token == "give_item_heart_piece":
        mapped.extend(
            [
                "give_item:art_heart_piece:1",
                "complete_quest:SQ_BRAM_01",
                "prompt:Received Fragment of Vitality",
            ]
        )
    else:
        mapped.append(f"prompt:Action triggered: {action_token}")

    if node_id == "MS_SHARD_RECOVERY_01":
        mapped.extend(
            [
                "set_flag:shard_identity_recovered=true",
                "complete_objective:MQ_01_AWAKENING:objective_04:1",
            ]
        )
    return mapped


def _map_dialogue_quest_id(
    raw_quest_id: str, node_id: str, known_quest_ids: set[str]
) -> str:
    if raw_quest_id in known_quest_ids:
        return raw_quest_id
    if node_id.startswith("SQ_"):
        parts = node_id.split("_")
        if len(parts) >= 3:
            candidate = f"{parts[0]}_{parts[1]}_01"
            if candidate in known_quest_ids:
                return candidate
    return raw_quest_id


def _dedupe_ordered(values: list[str]) -> list[str]:
    seen: set[str] = set()
    output: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        output.append(value)
    return output


def build_dialogues(
    dialogue_payload: dict[str, Any],
    quest_payload: dict[str, Any],
    characters_payload: dict[str, Any],
    npcs_payload: dict[str, Any],
    speaker_lookup: dict[str, str],
    known_quest_ids: set[str],
) -> dict[str, Any]:
    root = dialogue_payload.get("dialogue_master", {})
    output: dict[str, Any] = {}

    for entry in root.get("main_story", []):
        if not isinstance(entry, dict):
            continue
        node_id = str(entry.get("id", "")).strip()
        if not node_id:
            continue
        speaker_id = str(entry.get("speaker", "unknown"))
        speaker_name = speaker_lookup.get(speaker_id, speaker_id)
        lines = [str(line) for line in entry.get("lines", [])]

        raw_choices = entry.get("choices", [])
        choices: list[dict[str, Any]] = []
        for choice in raw_choices:
            if not isinstance(choice, dict):
                continue
            mapped_choice: dict[str, Any] = {"text": str(choice.get("text", "..."))}
            if "next_id" in choice:
                mapped_choice["next"] = str(choice["next_id"])
            if "reward" in choice:
                mapped_choice["effect"] = _normalize_reward_to_effect(
                    str(choice["reward"])
                )
            choices.append(mapped_choice)

        metadata: dict[str, Any] = {}
        if "trigger_state" in entry:
            metadata["trigger_state"] = entry["trigger_state"]
        if "action" in entry:
            metadata["action"] = entry["action"]
        if "vfx_trigger" in entry:
            metadata["vfx_trigger"] = entry["vfx_trigger"]

        outcomes: list[str] = []
        if "action" in entry:
            _extend_unique(outcomes, _action_to_effects(node_id, str(entry["action"])))
        if node_id == "MS_ACT1_02":
            _extend_unique(
                outcomes,
                [
                    "set_flag:elara_intro_complete=true",
                    "start_quest:MQ_01_AWAKENING",
                    "set_quest_state:MQ_01_AWAKENING:active",
                ],
            )
        if node_id == "MS_MALAKOR_TAUNT_01":
            _append_unique(outcomes, "complete_objective:MQ_01_AWAKENING:objective_03:1")

        outcomes = _dedupe_ordered(outcomes)
        key, node = _dialogue_node(
            node_id=node_id,
            speaker_name=speaker_name,
            lines=lines,
            choices=choices if choices else None,
            metadata=metadata if metadata else None,
            outcomes=outcomes if outcomes else None,
        )
        output[key] = node

    for entry in root.get("side_quests", []):
        if not isinstance(entry, dict):
            continue
        node_id = str(entry.get("id", "")).strip()
        if not node_id:
            continue
        speaker_id = str(entry.get("speaker", "unknown"))
        speaker_name = speaker_lookup.get(speaker_id, speaker_id)
        lines = [str(line) for line in entry.get("lines", [])]

        raw_quest_id = str(entry.get("quest_id", "")).strip()
        quest_id = _map_dialogue_quest_id(raw_quest_id, node_id, known_quest_ids)
        state = str(entry.get("state", "")).strip()

        metadata = {
            "quest_id": quest_id,
            "state": state,
        }
        outcomes: list[str] = []
        if state == "not_started" and quest_id:
            _extend_unique(
                outcomes,
                [
                    f"start_quest:{quest_id}",
                    f"set_quest_state:{quest_id}:active",
                ],
            )
        if state == "complete" and quest_id:
            _append_unique(outcomes, f"complete_quest:{quest_id}")

        if "action" in entry:
            metadata["action"] = entry["action"]
            _extend_unique(outcomes, _action_to_effects(node_id, str(entry["action"])))

        outcomes = _dedupe_ordered(outcomes)
        key, node = _dialogue_node(
            node_id,
            speaker_name,
            lines,
            metadata=metadata,
            outcomes=outcomes if outcomes else None,
        )
        output[key] = node

    for side_quest in quest_payload.get("quest_master", {}).get("side_quests", []):
        if not isinstance(side_quest, dict):
            continue
        quest_id = str(side_quest.get("id", "")).strip()
        if not quest_id or quest_id in output:
            continue
        speaker_id = str(side_quest.get("giver_id", "unknown"))
        speaker_name = speaker_lookup.get(speaker_id, speaker_id)
        objectives = side_quest.get("objectives", [])
        first_objective = (
            str(objectives[0]) if isinstance(objectives, list) and objectives else ""
        )
        lines = [
            f"{side_quest.get('title', quest_id)}: {first_objective}",
            "I can use your help. Return when this is done.",
        ]
        outcomes = _dedupe_ordered(
            [f"start_quest:{quest_id}", f"set_quest_state:{quest_id}:active"]
        )
        key, node = _dialogue_node(quest_id, speaker_name, lines, outcomes=outcomes)
        output[key] = node

    flavor_index = 1
    for entry in root.get("world_flavor", []):
        if not isinstance(entry, dict):
            continue
        speaker_id = str(entry.get("speaker", "unknown"))
        speaker_name = speaker_lookup.get(speaker_id, speaker_id)
        lines = [str(line) for line in entry.get("lines", [])]
        node_id = f"WORLD_FLAVOR_{flavor_index:03d}"
        flavor_index += 1
        metadata = {"condition": entry.get("condition", "")}
        key, node = _dialogue_node(node_id, speaker_name, lines, metadata=metadata)
        output[key] = node

    merchant = root.get("merchant_dialogue", {})
    if isinstance(merchant, dict):
        for merchant_id, payload in merchant.items():
            if not isinstance(payload, dict):
                continue
            speaker_name = speaker_lookup.get(merchant_id, merchant_id)
            greetings = payload.get("greeting", [])
            for idx, line in enumerate(greetings, start=1):
                node_id = f"MERCHANT_{merchant_id.upper()}_{idx:02d}"
                key, node = _dialogue_node(node_id, speaker_name, [str(line)])
                output[key] = node

            if "insufficient_funds" in payload:
                node_id = f"MERCHANT_{merchant_id.upper()}_INSUFFICIENT"
                key, node = _dialogue_node(
                    node_id,
                    speaker_name,
                    [str(payload["insufficient_funds"])],
                )
                output[key] = node
            if "upgrade_complete" in payload:
                node_id = f"MERCHANT_{merchant_id.upper()}_UPGRADE"
                key, node = _dialogue_node(
                    node_id,
                    speaker_name,
                    [str(payload["upgrade_complete"])],
                )
                output[key] = node

    for character in characters_payload.get("characters", []):
        if not isinstance(character, dict):
            continue
        char_id = str(character.get("id", "")).strip()
        if not char_id:
            continue
        node_id = f"CHAR_{_sanitize_dialogue_id(char_id)}_PROFILE"
        speaker_name = str(character.get("name", char_id))
        speech = character.get("speech", {}) if isinstance(character.get("speech"), dict) else {}
        details = (
            character.get("narrative_details", {})
            if isinstance(character.get("narrative_details"), dict)
            else {}
        )
        lines = [
            str(details.get("backstory", "")).strip(),
            str(details.get("motivation", "")).strip(),
            str(speech.get("key_phrase", "")).strip(),
        ]
        lines = [line for line in lines if line]
        if not lines:
            continue
        key, node = _dialogue_node(node_id, speaker_name, lines)
        output[key] = node

    npc_quest_map = {
        "npc_baker_001": "SQ_BRAM_01",
        "npc_mercant_003": "SQ_MILO_01",
        "npc_knight_002": "SQ_KESTRAL_01",
    }
    for npc in npcs_payload.get("sidequest_npcs", []):
        if not isinstance(npc, dict):
            continue
        npc_id = str(npc.get("id", "")).strip()
        if not npc_id:
            continue
        node_id = f"NPC_{_sanitize_dialogue_id(npc_id)}_INTRO"
        speaker_name = str(npc.get("name", npc_id))
        speech = npc.get("speech", {}) if isinstance(npc.get("speech"), dict) else {}
        side_quest = (
            npc.get("side_quest", {})
            if isinstance(npc.get("side_quest"), dict)
            else {}
        )
        lines = [
            str(speech.get("key_phrase", "")).strip(),
            str(side_quest.get("description", "")).strip(),
            f"Reward: {side_quest.get('reward', 'Unknown')}",
        ]
        lines = [line for line in lines if line]
        outcomes: list[str] = []
        linked_quest = npc_quest_map.get(npc_id, "")
        if linked_quest and linked_quest in known_quest_ids:
            outcomes = _dedupe_ordered(
                [
                f"start_quest:{linked_quest}",
                f"set_quest_state:{linked_quest}:active",
                ]
            )
        if lines:
            key, node = _dialogue_node(
                node_id,
                speaker_name,
                lines,
                outcomes=outcomes if outcomes else None,
            )
            output[key] = node

    # Backfill missing choice targets with safe placeholder nodes.
    missing_nodes: set[str] = set()
    for node in output.values():
        if not isinstance(node, dict):
            continue
        entries = node.get("entries", [])
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if not isinstance(entry, dict):
                continue
            choices = entry.get("choices", [])
            if not isinstance(choices, list):
                continue
            for choice in choices:
                if not isinstance(choice, dict):
                    continue
                next_id = str(choice.get("next", "")).strip()
                if next_id and next_id not in output:
                    missing_nodes.add(next_id)

    for missing_id in sorted(missing_nodes):
        key, node = _dialogue_node(
            missing_id,
            "Narrator",
            ["The memory frays here. Return when more of the story is restored."],
        )
        output[key] = node

    return output


def _objectives_to_structured(objectives: list[Any]) -> list[dict[str, Any]]:
    structured: list[dict[str, Any]] = []
    for index, objective in enumerate(objectives, start=1):
        structured.append(
            {
                "id": f"objective_{index:02d}",
                "description": str(objective),
                "required": 1,
            }
        )
    return structured


def build_quests(quest_payload: dict[str, Any]) -> dict[str, Any]:
    root = quest_payload.get("quest_master", {})
    output_quests: list[dict[str, Any]] = []

    def append_quest(raw: dict[str, Any], quest_kind: str) -> None:
        quest_id = str(raw.get("id", "")).strip()
        if not quest_id:
            return

        requirements = str(raw.get("requirements", "None"))
        default_state = "available" if requirements.lower() == "none" else "locked"
        rewards = raw.get("rewards", {})
        description = str(
            raw.get(
                "narrative_unlock",
                raw.get("description", raw.get("title", "")),
            )
        )

        output_quests.append(
            {
                "id": quest_id,
                "title": str(raw.get("title", quest_id)),
                "description": description,
                "state": default_state,
                "type": quest_kind,
                "giver_id": str(raw.get("giver_id", "")),
                "location": str(raw.get("location", "")),
                "requirements": requirements,
                "objectives": _objectives_to_structured(raw.get("objectives", [])),
                "rewards": rewards,
                "next_quest": str(raw.get("next_quest", "")),
                "status_change": str(raw.get("status_change", "")),
            }
        )

    for entry in root.get("main_quests", []):
        if isinstance(entry, dict):
            append_quest(entry, "main")

    for entry in root.get("side_quests", []):
        if isinstance(entry, dict):
            append_quest(entry, "side")

    return {"quests": output_quests}


def build_items(items_payload: dict[str, Any]) -> dict[str, Any]:
    inventory = items_payload.get("inventory_master", {})
    output: dict[str, Any] = {}

    category_map = {
        "weapons": "weapon",
        "mnemurgy_tools": "tool",
        "key_artifacts": "artifact",
        "consumables": "consumable",
    }

    for source_category, category in category_map.items():
        for entry in inventory.get(source_category, []):
            if not isinstance(entry, dict):
                continue
            item_id = str(entry.get("id", "")).strip()
            if not item_id:
                continue

            output[item_id] = {
                "name": str(entry.get("name", item_id)),
                "type": category,
                "subtype": str(entry.get("type", "")),
                "description": str(entry.get("description", "")),
                "lore": str(entry.get("lore", "")),
                "mechanics": entry.get("mechanics", {}),
                "progression": str(entry.get("progression", "")),
                "impact": str(entry.get("impact", "")),
                "upgrade_id": str(entry.get("upgrade_id", "")),
            }

    return output


def build_lore_entries(
    story_outline_path: Path, main_story_path: Path, world_lore_path: Path
) -> dict[str, Any]:
    sections: list[dict[str, str]] = []
    sections.extend(_parse_markdown_sections(story_outline_path))
    sections.extend(_parse_markdown_sections(main_story_path))
    sections.extend(_parse_markdown_sections(world_lore_path))

    return {
        "entries": sections,
        "sources": [
            story_outline_path.name,
            main_story_path.name,
            world_lore_path.name,
        ],
    }


def build_npc_registry(
    characters_payload: dict[str, Any], npcs_payload: dict[str, Any]
) -> dict[str, Any]:
    characters: dict[str, Any] = {}
    npcs: dict[str, Any] = {}
    lookup: dict[str, str] = {}

    for entry in characters_payload.get("characters", []):
        if not isinstance(entry, dict):
            continue
        entry_id = str(entry.get("id", "")).strip()
        if not entry_id:
            continue
        profile = {
            "name": str(entry.get("name", entry_id)),
            "role": str(entry.get("role", "")),
            "archetype": str(entry.get("archetype", "")),
            "speech_style": str((entry.get("speech", {}) or {}).get("style", "")),
            "key_phrase": str((entry.get("speech", {}) or {}).get("key_phrase", "")),
            "backstory": str(
                (entry.get("narrative_details", {}) or {}).get("backstory", "")
            ),
            "motivation": str(
                (entry.get("narrative_details", {}) or {}).get("motivation", "")
            ),
        }
        characters[entry_id] = profile
        lookup[entry_id] = profile["name"]

    for entry in npcs_payload.get("sidequest_npcs", []):
        if not isinstance(entry, dict):
            continue
        entry_id = str(entry.get("id", "")).strip()
        if not entry_id:
            continue
        profile = {
            "name": str(entry.get("name", entry_id)),
            "location": str(entry.get("location", "")),
            "speech_style": str((entry.get("speech", {}) or {}).get("style", "")),
            "key_phrase": str((entry.get("speech", {}) or {}).get("key_phrase", "")),
            "side_quest_title": str(
                (entry.get("side_quest", {}) or {}).get("title", "")
            ),
            "side_quest_description": str(
                (entry.get("side_quest", {}) or {}).get("description", "")
            ),
            "side_quest_reward": str(
                (entry.get("side_quest", {}) or {}).get("reward", "")
            ),
        }
        npcs[entry_id] = profile
        lookup[entry_id] = profile["name"]

    return {
        "characters": characters,
        "npcs": npcs,
        "lookup": lookup,
    }


def _write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def main() -> None:
    dialogue_payload = _load_json(SOURCE_DIR / "dialogue_master.json")
    quest_payload = _load_json(SOURCE_DIR / "quest_master.json")
    characters_payload = _load_json(SOURCE_DIR / "characters.json")
    npcs_payload = _load_json(SOURCE_DIR / "npcs.json")
    items_payload = _load_json(SOURCE_DIR / "items.json")

    speaker_lookup = _build_speaker_lookup(
        characters_payload=characters_payload,
        npcs_payload=npcs_payload,
    )

    quests = build_quests(quest_payload)
    known_quest_ids = {
        str(quest.get("id", "")).strip()
        for quest in quests.get("quests", [])
        if isinstance(quest, dict)
    }
    known_quest_ids = {quest_id for quest_id in known_quest_ids if quest_id}

    dialogues = build_dialogues(
        dialogue_payload=dialogue_payload,
        quest_payload=quest_payload,
        characters_payload=characters_payload,
        npcs_payload=npcs_payload,
        speaker_lookup=speaker_lookup,
        known_quest_ids=known_quest_ids,
    )
    items = build_items(items_payload)
    lore_entries = build_lore_entries(
        story_outline_path=SOURCE_DIR / "story_outline.md",
        main_story_path=SOURCE_DIR / "main_story.md",
        world_lore_path=SOURCE_DIR / "world_lore.md",
    )
    npc_registry = build_npc_registry(
        characters_payload=characters_payload,
        npcs_payload=npcs_payload,
    )

    _write_json(OUTPUT_DIALOGUE, dialogues)
    _write_json(OUTPUT_QUESTS, quests)
    _write_json(OUTPUT_ITEMS, items)
    _write_json(OUTPUT_LORE, lore_entries)
    _write_json(OUTPUT_NPCS, npc_registry)

    print("Generated runtime narrative data:")
    print(f" - {OUTPUT_DIALOGUE.relative_to(ROOT)}")
    print(f" - {OUTPUT_QUESTS.relative_to(ROOT)}")
    print(f" - {OUTPUT_ITEMS.relative_to(ROOT)}")
    print(f" - {OUTPUT_LORE.relative_to(ROOT)}")
    print(f" - {OUTPUT_NPCS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
