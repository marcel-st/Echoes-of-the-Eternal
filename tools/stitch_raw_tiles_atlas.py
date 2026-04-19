#!/usr/bin/env python3
"""
Stitch all 16×16 PNGs from `assets/raw_tiles/` into a single grid atlas using Pillow.

Outputs:
  - assets/kenney_custom_atlas.png
  - assets/mapping.txt (one line per file: "name.png is at col,row")

Example:
  python3 tools/stitch_raw_tiles_atlas.py
  python3 tools/stitch_raw_tiles_atlas.py --columns 12 --input assets/raw_tiles
"""

from __future__ import annotations

import argparse
import math
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError as e:
    print("This script requires Pillow: pip install Pillow", file=sys.stderr)
    raise SystemExit(1) from e

TILE = 16
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT = PROJECT_ROOT / "assets" / "raw_tiles"
DEFAULT_ATLAS = PROJECT_ROOT / "assets" / "kenney_custom_atlas.png"
DEFAULT_MAPPING = PROJECT_ROOT / "assets" / "mapping.txt"


def _collect_pngs(folder: Path) -> list[Path]:
    if not folder.is_dir():
        raise FileNotFoundError(f"Input folder does not exist: {folder}")
    files = sorted(folder.glob("*.png"), key=lambda p: p.name.lower())
    return [p for p in files if p.is_file()]


def _load_tile(path: Path) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    if im.size != (TILE, TILE):
        im = im.resize((TILE, TILE), Image.Resampling.NEAREST)
    return im


def main() -> None:
    parser = argparse.ArgumentParser(description="Stitch 16×16 PNGs into a grid atlas.")
    parser.add_argument(
        "--input",
        type=Path,
        default=DEFAULT_INPUT,
        help="Folder containing source PNG tiles (default: assets/raw_tiles)",
    )
    parser.add_argument(
        "--columns",
        type=int,
        default=10,
        help="Number of tiles per row in the atlas (default: 10)",
    )
    parser.add_argument(
        "--atlas-out",
        type=Path,
        default=DEFAULT_ATLAS,
        help=f"Output PNG path (default: {DEFAULT_ATLAS.relative_to(PROJECT_ROOT)})",
    )
    parser.add_argument(
        "--mapping-out",
        type=Path,
        default=DEFAULT_MAPPING,
        help=f"Output mapping file (default: {DEFAULT_MAPPING.relative_to(PROJECT_ROOT)})",
    )
    args = parser.parse_args()

    input_dir = args.input
    if not input_dir.is_absolute():
        input_dir = PROJECT_ROOT / input_dir

    cols = max(1, int(args.columns))
    paths = _collect_pngs(input_dir)
    if not paths:
        print(f"No PNG files found in {input_dir}", file=sys.stderr)
        raise SystemExit(2)

    rows = math.ceil(len(paths) / cols)
    atlas_w = cols * TILE
    atlas_h = rows * TILE
    atlas = Image.new("RGBA", (atlas_w, atlas_h), (0, 0, 0, 0))

    atlas_out = args.atlas_out
    if not atlas_out.is_absolute():
        atlas_out = PROJECT_ROOT / atlas_out
    mapping_out = args.mapping_out
    if not mapping_out.is_absolute():
        mapping_out = PROJECT_ROOT / mapping_out

    lines: list[str] = [
        f"# Atlas: {atlas_out.name}",
        f"# Grid: {cols} columns × {rows} rows, tile size {TILE}×{TILE} px",
        f"# Total tiles: {len(paths)}",
        "",
    ]

    for i, path in enumerate(paths):
        col = i % cols
        row = i // cols
        x = col * TILE
        y = row * TILE
        tile = _load_tile(path)
        atlas.paste(tile, (x, y), tile)
        name = path.name
        lines.append(f"{name} is at {col},{row}")

    atlas_out.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(atlas_out, format="PNG")
    mapping_out.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Wrote {atlas_out} ({atlas_w}×{atlas_h} px, {len(paths)} tiles, {cols} wide)")
    print(f"Wrote {mapping_out}")


if __name__ == "__main__":
    main()
