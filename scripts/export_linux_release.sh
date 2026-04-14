#!/usr/bin/env bash
# Export a Linux x86_64 release build (CachyOS / Arch / most distros).
# Usage:
#   GODOT_BIN=/path/to/Godot_v4.2*-stable_linux.x86_64 ./scripts/export_linux_release.sh
# Or with godot4 on PATH:
#   ./scripts/export_linux_release.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

: "${GODOT_BIN:=}"
if [[ -z "${GODOT_BIN}" ]]; then
	if command -v godot4 >/dev/null 2>&1; then
		GODOT_BIN="$(command -v godot4)"
	elif command -v Godot >/dev/null 2>&1; then
		GODOT_BIN="$(command -v Godot)"
	elif command -v godot >/dev/null 2>&1; then
		GODOT_BIN="$(command -v godot)"
	fi
fi

if [[ -z "${GODOT_BIN}" || ! -x "${GODOT_BIN}" ]]; then
	echo "Set GODOT_BIN to your Godot 4.x linux binary (4.2+), or install godot4 on PATH." >&2
	exit 1
fi

python3 tools/import_narrative.py

OUT_DIR="${ROOT}/builds/linux"
mkdir -p "$OUT_DIR"
EXE="${OUT_DIR}/echoes-of-the-eternal.x86_64"

# Headless export using export_presets.cfg preset "Linux/X11"
GODOT_SILENCE_ROOT_WARNING=1 "${GODOT_BIN}" --headless --path "$ROOT" --export-release "Linux/X11" "$EXE"

echo "Built: $EXE"
ls -la "$OUT_DIR"
