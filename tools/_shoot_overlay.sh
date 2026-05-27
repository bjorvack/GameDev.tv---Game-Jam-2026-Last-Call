#!/usr/bin/env bash
# Capture a single screenshot with optional pause / settings overlay open.
# Usage:
#   tools/_shoot_overlay.sh <scene> <out_name> [OPEN_PAUSE] [OPEN_SETTINGS]
# Example:
#   tools/_shoot_overlay.sh res://scenes/switchboard.tscn 05_pause_menu 1
set -euo pipefail

SCENE="$1"
NAME="$2"
OPEN_PAUSE_VAL="${3:-}"
OPEN_SETTINGS_VAL="${4:-}"

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHOT_DIR="$PROJECT_ROOT/art/screenshots"
SRC="$HOME/Library/Application Support/Godot/app_userdata/Last Call/debug_screenshot.png"

mkdir -p "$SHOT_DIR"
rm -f "$SRC"

PROJECT_GODOT="$PROJECT_ROOT/project.godot"
ORIGINAL_MAIN_SCENE=$(grep '^run/main_scene' "$PROJECT_GODOT" || echo '')
restore_main_scene() {
    if [[ -n "$ORIGINAL_MAIN_SCENE" ]]; then
        sed -i.bak "s|^run/main_scene=.*|${ORIGINAL_MAIN_SCENE}|" "$PROJECT_GODOT"
        rm -f "$PROJECT_GODOT.bak"
    fi
}
trap restore_main_scene EXIT

cd "$PROJECT_ROOT"
sed -i.bak "s|^run/main_scene=.*|run/main_scene=\"${SCENE}\"|" "$PROJECT_GODOT"
rm -f "$PROJECT_GODOT.bak"

export SCREENSHOT_DELAY="${SCREENSHOT_DELAY:-2.5}"
export OPEN_PAUSE="$OPEN_PAUSE_VAL"
export OPEN_SETTINGS="$OPEN_SETTINGS_VAL"

godot --resolution "${RES:-1280x720}" >/dev/null 2>&1 &
PID=$!
sleep "${HOLD_SECONDS:-5}"
kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true

if [[ -f "$SRC" ]]; then
    cp "$SRC" "$SHOT_DIR/${NAME}.png"
    echo "saved $SHOT_DIR/${NAME}.png"
else
    echo "WARN: no screenshot produced for ${NAME}"
    exit 1
fi
