#!/usr/bin/env python3
"""Emit Godot 4 TileSet (.tres) for assets/kenney_custom_atlas.png (16×16 grid)."""

from __future__ import annotations

import pathlib
import re
import sys

try:
    from PIL import Image
except ImportError as e:
    print("This script requires Pillow: pip install Pillow", file=sys.stderr)
    raise SystemExit(1) from e

ROOT = pathlib.Path(__file__).resolve().parents[1]
ATLAS_PATH = ROOT / "assets" / "kenney_custom_atlas.png"
MAPPING_PATH = ROOT / "assets" / "mapping.txt"
OUT = ROOT / "assets" / "tilesets" / "kenney_custom_atlas.tres"
ATLAS_REL = "res://assets/kenney_custom_atlas.png"

TILE = 16
RECT = "PackedVector2Array(0, 0, 16, 0, 16, 16, 0, 16)"
LINE_IS_AT = re.compile(r"^(.+\.png)\s+is\s+at\s+(\d+)\s*,\s*(\d+)\s*$", re.IGNORECASE)
LINE_GRID = re.compile(
    r"^(.+\.png)\s*->\s*Grid\s+Coord:\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)\s*$",
    re.IGNORECASE,
)


def _parse_mapping(path: pathlib.Path) -> dict[str, tuple[int, int]]:
    out: dict[str, tuple[int, int]] = {}
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        m = LINE_IS_AT.match(line) or LINE_GRID.match(line)
        if not m:
            continue
        name = m.group(1).strip()
        out[name.lower()] = (int(m.group(2)), int(m.group(3)))
    return out


def main() -> None:
    if not ATLAS_PATH.is_file():
        raise SystemExit(f"Missing atlas: {ATLAS_PATH}")

    mapping = _parse_mapping(MAPPING_PATH)
    grass = mapping.get("grass.png")
    tree = mapping.get("tree.png")
    if grass is None or tree is None:
        raise SystemExit(
            f"Expected grass.png and tree.png entries in {MAPPING_PATH} "
            '(e.g. `grass.png -> Grid Coord: (0, 0)` or `grass.png is at 0,0`)'
        )

    im = Image.open(ATLAS_PATH)
    w, h = im.size
    if w % TILE or h % TILE:
        raise SystemExit(f"Atlas size {w}x{h} is not a multiple of {TILE}px tiles")
    cols, rows = w // TILE, h // TILE

    lines: list[str] = [
        '[gd_resource type="TileSet" load_steps=3 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{ATLAS_REL}" id="1_atlas"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_custom"]',
        'resource_name = "kenney_custom_atlas"',
        'texture = ExtResource("1_atlas")',
        "texture_region_size = Vector2i(16, 16)",
    ]

    solid = {tree}
    for y in range(rows):
        for x in range(cols):
            key = f"{x}:{y}/0"
            lines.append(f"{key} = 0")
            if (x, y) in solid:
                lines.append(f"{key}/physics_layer_0/polygon_0/points = {RECT}")

    lines.extend(
        [
            "",
            "[resource]",
            "physics_layer_0/collision_layer = 1",
            "physics_layer_0/collision_mask = 0",
            'sources/0 = SubResource("TileSetAtlasSource_custom")',
            "",
        ]
    )

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT} ({cols}×{rows} cells; solid tile at tree {tree})")


if __name__ == "__main__":
    main()
