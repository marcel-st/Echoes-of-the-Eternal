#!/usr/bin/env python3
"""Convert narrative source files into runtime JSON payloads.

This importer reads curated files from data/source/narrative and generates
runtime data consumed by Godot managers:
  - data/dialogue/dialogues.json
  - data/quests/quests.json
  - data/items/items.json
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


def _load_json(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


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
) -> tuple[str, dict[str, Any]]:
    entries: list[dict[str, Any]] = []
    for line in lines:
        entries.append({"speaker": speaker_name, "text": line})

    if choices and entries:
        entries[-1]["choices"] = choices

    node: dict[str, Any] = {"entries": entries}
    if metadata:
        node["meta"] = metadata
    return node_id, node


def build_dialogues(
    dialogue_payload: dict[str, Any], speaker_lookup: dict[str, str]
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
                mapped_choice["effect"] = str(choice["reward"])
            choices.append(mapped_choice)

        metadata: dict[str, Any] = {}
        if "trigger_state" in entry:
            metadata["trigger_state"] = entry["trigger_state"]
        if "action" in entry:
            metadata["action"] = entry["action"]
        if "vfx_trigger" in entry:
            metadata["vfx_trigger"] = entry["vfx_trigger"]

        key, node = _dialogue_node(
            node_id=node_id,
            speaker_name=speaker_name,
            lines=lines,
            choices=choices if choices else None,
            metadata=metadata if metadata else None,
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
        metadata = {
            "quest_id": entry.get("quest_id", ""),
            "state": entry.get("state", ""),
        }
        if "action" in entry:
            metadata["action"] = entry["action"]

        key, node = _dialogue_node(node_id, speaker_name, lines, metadata=metadata)
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

        output_quests.append(
            {
                "id": quest_id,
                "title": str(raw.get("title", quest_id)),
                "description": str(raw.get("narrative_unlock", raw.get("title", ""))),
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


def _write_json(path: Path, payload: dict[str, Any]) -> None:
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

    dialogues = build_dialogues(dialogue_payload, speaker_lookup)
    quests = build_quests(quest_payload)
    items = build_items(items_payload)

    _write_json(OUTPUT_DIALOGUE, dialogues)
    _write_json(OUTPUT_QUESTS, quests)
    _write_json(OUTPUT_ITEMS, items)

    print("Generated runtime narrative data:")
    print(f" - {OUTPUT_DIALOGUE.relative_to(ROOT)}")
    print(f" - {OUTPUT_QUESTS.relative_to(ROOT)}")
    print(f" - {OUTPUT_ITEMS.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
