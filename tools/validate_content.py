#!/usr/bin/env python3
"""Validate scene references against generated narrative/runtime data."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]

SCENE_DIALOGUE_RE = re.compile(r'default_dialogue_id\s*=\s*&"([^"]+)"')
SCENE_FLAG_DIALOGUE_RE = re.compile(r'"[^"]+"\s*:\s*&"([^"]+)"')
SCENE_NPC_RE = re.compile(r'npc_id\s*=\s*&"([^"]+)"')
SCENE_SCRIPT_RE = re.compile(r'\[ext_resource type="Script"[^]]*path="([^"]+)"[^]]*id="([^"]+)"')
SCRIPT_ASSIGN_RE = re.compile(r"script\s*=\s*ExtResource\(\"([^\"]+)\"\)")
SPAWN_NODE_RE = re.compile(r'\[node name="(SpawnStart|Spawn_[^"]+)"')
CONST_SCENE_RE = re.compile(r'const\s+([A-Z0-9_]+)\s*:=\s*"([^"]+\.tscn)"')
TRANSITION_RE = re.compile(
    r'"map_scene_path"\s*:\s*([A-Z0-9_]+|"[^"]+\.tscn").*?'
    r'"spawn_id"\s*:\s*"([^"]+)"',
    re.S,
)
EFFECT_RE = re.compile(r"(start_quest|set_quest_state|complete_objective|complete_quest):([^,\"]+)")


def _load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def _scene_scripts() -> dict[str, Path]:
    scripts: dict[str, Path] = {}
    for scene_path in (ROOT / "scenes").rglob("*.tscn"):
        text = scene_path.read_text(encoding="utf-8")
        resources = {match.group(2): match.group(1) for match in SCENE_SCRIPT_RE.finditer(text)}
        script_match = SCRIPT_ASSIGN_RE.search(text)
        if script_match is None:
            continue
        script_res_id = script_match.group(1)
        script_ref = resources.get(script_res_id, "")
        if script_ref.startswith("res://"):
            scripts[str(scene_path.relative_to(ROOT))] = ROOT / script_ref.removeprefix("res://")
    return scripts


def _collect_scene_refs() -> tuple[list[tuple[Path, str]], list[tuple[Path, str]], dict[str, set[str]]]:
    dialogue_refs: list[tuple[Path, str]] = []
    npc_refs: list[tuple[Path, str]] = []
    spawns_by_scene: dict[str, set[str]] = {}

    for scene_path in (ROOT / "scenes").rglob("*.tscn"):
        text = scene_path.read_text(encoding="utf-8")
        rel_scene = str(scene_path.relative_to(ROOT))
        dialogue_refs.extend((scene_path, match.group(1)) for match in SCENE_DIALOGUE_RE.finditer(text))
        dialogue_refs.extend((scene_path, match.group(1)) for match in SCENE_FLAG_DIALOGUE_RE.finditer(text))
        npc_refs.extend((scene_path, match.group(1)) for match in SCENE_NPC_RE.finditer(text))
        spawns: set[str] = set()
        for match in SPAWN_NODE_RE.finditer(text):
            node_name = match.group(1)
            spawns.add("start" if node_name == "SpawnStart" else node_name.removeprefix("Spawn_"))
        spawns_by_scene[rel_scene] = spawns

    return dialogue_refs, npc_refs, spawns_by_scene


def _collect_transition_refs(scripts_by_scene: dict[str, Path]) -> list[tuple[Path, str, str]]:
    refs: list[tuple[Path, str, str]] = []
    for _scene, script_path in scripts_by_scene.items():
        if not script_path.is_file():
            continue
        text = script_path.read_text(encoding="utf-8")
        constants = {match.group(1): match.group(2) for match in CONST_SCENE_RE.finditer(text)}
        for match in TRANSITION_RE.finditer(text):
            raw_scene = match.group(1)
            spawn_id = match.group(2)
            target = raw_scene.strip('"')
            if target in constants:
                target = constants[target]
            if target.startswith("res://"):
                target = target.removeprefix("res://")
            refs.append((script_path, target, spawn_id))
    return refs


def _collect_dialogue_refs(dialogues: dict[str, Any]) -> tuple[set[str], list[tuple[str, str]], list[tuple[str, str]]]:
    dialogue_ids = set(dialogues.keys())
    choice_targets: list[tuple[str, str]] = []
    effects: list[tuple[str, str]] = []

    def visit_value(dialogue_id: str, value: Any) -> None:
        if isinstance(value, dict):
            if isinstance(value.get("next"), str) and value["next"].strip():
                choice_targets.append((dialogue_id, value["next"].strip()))
            for effect_key in ("effect", "effects", "outcomes"):
                if effect_key in value:
                    collect_effects(dialogue_id, value[effect_key])
            for child in value.values():
                visit_value(dialogue_id, child)
        elif isinstance(value, list):
            for child in value:
                visit_value(dialogue_id, child)

    def collect_effects(dialogue_id: str, value: Any) -> None:
        if isinstance(value, str):
            effects.append((dialogue_id, value.strip()))
        elif isinstance(value, list):
            for item in value:
                collect_effects(dialogue_id, item)
        elif isinstance(value, dict):
            for key, item in value.items():
                effects.append((dialogue_id, f"{key}:{item}"))

    for dialogue_id, payload in dialogues.items():
        visit_value(dialogue_id, payload)

    return dialogue_ids, choice_targets, effects


def main() -> int:
    dialogues = _load_json(ROOT / "data" / "dialogue" / "dialogues.json")
    quests_payload = _load_json(ROOT / "data" / "quests" / "quests.json")
    npcs_payload = _load_json(ROOT / "data" / "npcs" / "npc_registry.json")

    quest_ids = {
        str(quest.get("id", "")).strip()
        for quest in quests_payload.get("quests", [])
        if isinstance(quest, dict)
    }
    objectives_by_quest = {
        str(quest.get("id", "")).strip(): {
            str(objective.get("id", "")).strip()
            for objective in quest.get("objectives", [])
            if isinstance(objective, dict)
        }
        for quest in quests_payload.get("quests", [])
        if isinstance(quest, dict)
    }
    npc_ids = set(npcs_payload.get("characters", {}).keys()) | set(npcs_payload.get("npcs", {}).keys())
    dialogue_ids, choice_targets, effects = _collect_dialogue_refs(dialogues)
    scene_dialogue_refs, scene_npc_refs, spawns_by_scene = _collect_scene_refs()
    scripts_by_scene = _scene_scripts()
    transition_refs = _collect_transition_refs(scripts_by_scene)

    errors: list[str] = []

    for scene_path, dialogue_id in scene_dialogue_refs:
        if dialogue_id not in dialogue_ids:
            errors.append(f"{scene_path.relative_to(ROOT)} references missing dialogue '{dialogue_id}'")

    for scene_path, npc_id in scene_npc_refs:
        if npc_id not in npc_ids:
            errors.append(f"{scene_path.relative_to(ROOT)} references missing npc '{npc_id}'")

    for dialogue_id, target in choice_targets:
        if target not in dialogue_ids:
            errors.append(f"dialogue '{dialogue_id}' choice points to missing dialogue '{target}'")

    for dialogue_id, effect in effects:
        match = EFFECT_RE.match(effect)
        if not match:
            continue
        kind = match.group(1)
        parts = match.group(2).split(":")
        quest_id = parts[0].strip()
        if quest_id not in quest_ids:
            errors.append(f"dialogue '{dialogue_id}' effect '{effect}' references missing quest '{quest_id}'")
            continue
        if kind == "complete_objective":
            if len(parts) < 2:
                errors.append(f"dialogue '{dialogue_id}' effect '{effect}' lacks objective id")
                continue
            objective_id = parts[1].strip()
            if objective_id not in objectives_by_quest.get(quest_id, set()):
                errors.append(
                    f"dialogue '{dialogue_id}' effect '{effect}' references missing objective "
                    f"'{objective_id}' for quest '{quest_id}'"
                )

    for script_path, target_scene, spawn_id in transition_refs:
        spawns = spawns_by_scene.get(target_scene)
        if spawns is None:
            errors.append(f"{script_path.relative_to(ROOT)} transitions to missing scene '{target_scene}'")
        elif spawn_id not in spawns:
            errors.append(
                f"{script_path.relative_to(ROOT)} transitions to '{target_scene}' "
                f"with missing spawn '{spawn_id}'"
            )

    if errors:
        print("Content validation failed:")
        for error in errors:
            print(f" - {error}")
        return 1

    print("Content validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
