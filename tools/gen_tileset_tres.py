#!/usr/bin/env python3
"""Emit Godot 4 TileSet (.tres) for Kenney tiny-dungeon tilemap_packed.png (12×11 @ 16px)."""

from __future__ import annotations

import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/tilesets/generic_overworld_terrain.tres"
ATLAS_REL = "res://kenney_pack/2D assets/Tiny Dungeon/Tilemap/tilemap_packed.png"

# --- Overworld atlas roles (Kenney Tiny Dungeon `tilemap_packed.png`) ---
# Never use green “slime” / mob floor tiles (e.g. (0, 9)) for base ground or paths.
BASE_GROUND = (0, 0)  # dark brown dirt — walkable base
PATH_STONE = (5, 2)  # lighter grey path / stone
PLAZA_STONE = (6, 0)  # stone brick plaza
PLAZA_WOOD = (1, 1)  # wooden floor (alternate; overworld uses stone by default)
OBSTACLE_GRAVE = (5, 3)  # gravestone — blocks player
OBSTACLE_CRAG = (0, 4)  # crags — blocks player
# Sparse detail on GroundDetails (neutral grey; not slime).
DETAIL_ROCK = (1, 5)

# All atlas cells referenced by overworld / tileset (union for TileSetAtlasSource).
GROUND = [BASE_GROUND]
PATH = [PATH_STONE]
PLAZA = [PLAZA_STONE, PLAZA_WOOD]
OBSTACLE = [OBSTACLE_GRAVE, OBSTACLE_CRAG]
DETAIL = [DETAIL_ROCK]

# Full-tile AABB collision only where the player should be blocked.
SOLID = [OBSTACLE_GRAVE, OBSTACLE_CRAG]

RECT = "PackedVector2Array(0, 0, 16, 0, 16, 16, 0, 16)"


def main() -> None:
    cells: set[tuple[int, int]] = set()
    for group in (GROUND, PATH, PLAZA, OBSTACLE, DETAIL):
        cells.update(group)

    lines: list[str] = [
        '[gd_resource type="TileSet" load_steps=3 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{ATLAS_REL}" id="1_atlas"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_terrain"]',
        'resource_name = "kenney_tiny_dungeon_packed"',
        'texture = ExtResource("1_atlas")',
        "texture_region_size = Vector2i(16, 16)",
    ]

    for x, y in sorted(cells):
        key = f"{x}:{y}/0"
        lines.append(f"{key} = 0")
        if (x, y) in SOLID:
            lines.append(f"{key}/physics_layer_0/polygon_0/points = {RECT}")

    lines.extend(
        [
            "",
            "[resource]",
            "physics_layer_0/collision_layer = 1",
            "physics_layer_0/collision_mask = 0",
            'sources/0 = SubResource("TileSetAtlasSource_terrain")',
            "",
        ]
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
