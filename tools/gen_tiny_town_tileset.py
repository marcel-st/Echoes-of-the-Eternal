#!/usr/bin/env python3
"""Emit a Godot 4 TileSet for Kenney Tiny Town packed tiles."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "tilesets" / "tiny_town.tres"
ATLAS_REL = "res://kenney_pack/2D assets/Tiny Town/Tilemap/tilemap_packed.png"
COLS = 12
ROWS = 11


def main() -> None:
    lines: list[str] = [
        '[gd_resource type="TileSet" load_steps=3 format=3]',
        "",
        f'[ext_resource type="Texture2D" path="{ATLAS_REL}" id="1_atlas"]',
        "",
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_tiny_town"]',
        'resource_name = "kenney_tiny_town_packed"',
        'texture = ExtResource("1_atlas")',
        "texture_region_size = Vector2i(16, 16)",
    ]

    for y in range(ROWS):
        for x in range(COLS):
            lines.append(f"{x}:{y}/0 = 0")

    lines.extend(
        [
            "",
            "[resource]",
            'sources/0 = SubResource("TileSetAtlasSource_tiny_town")',
            "",
        ]
    )
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {OUT}")


if __name__ == "__main__":
    main()
