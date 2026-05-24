#!/usr/bin/env bash
# Capture a series of itch.io screenshots by running each scene in turn.
# The existing scripts/debug_screenshot.gd autoload writes a PNG to
# user:// 1 s after each scene starts; we copy it out + quit Godot.
#
# Output: art/screenshots/01_title.png, 02_switchboard.png, ...
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHOT_DIR="$PROJECT_ROOT/art/screenshots"
SRC="$HOME/Library/Application Support/Godot/app_userdata/Last Call/debug_screenshot.png"

mkdir -p "$SHOT_DIR"

RES="${RES:-1280x720}"
# How long after _ready the debug_screenshot autoload waits before snapping.
SCREENSHOT_DELAY="${SCREENSHOT_DELAY:-3.5}"
# Frames to render before --quit-after kicks in. Godot 4's --quit-after
# counts FRAMES, not seconds. Plain wall-clock sleep + kill is more
# reliable across scene weight.
HOLD_SECONDS="${HOLD_SECONDS:-6}"
export SCREENSHOT_DELAY

PROJECT_GODOT="$PROJECT_ROOT/project.godot"
ORIGINAL_MAIN_SCENE=$(grep '^run/main_scene' "$PROJECT_GODOT" || echo '')
restore_main_scene() {
    if [[ -n "$ORIGINAL_MAIN_SCENE" ]]; then
        sed -i.bak "s|^run/main_scene=.*|${ORIGINAL_MAIN_SCENE}|" "$PROJECT_GODOT"
        rm -f "$PROJECT_GODOT.bak"
    fi
}
trap restore_main_scene EXIT

shoot() {
    local name="$1" scene="$2"
    echo ">> ${name}  (scene=${scene})"
    cd "$PROJECT_ROOT"
    # Godot's CLI doesn't reliably honour a scene path argument when the
    # project has a main_scene set; temporarily rewrite project.godot so
    # the engine boots straight into the target scene.
    sed -i.bak "s|^run/main_scene=.*|run/main_scene=\"${scene}\"|" "$PROJECT_GODOT"
    rm -f "$PROJECT_GODOT.bak"
    # Wipe any stale screenshot so we can detect whether the autoload
    # actually fired this run.
    rm -f "$SRC"
    # Spawn Godot in the background, sleep past the autoload's capture
    # delay, then kill it. Godot's --quit-after counts FRAMES not
    # seconds so we use plain wall-clock instead.
    godot --resolution "$RES" >/dev/null 2>&1 &
    local pid=$!
    sleep "$HOLD_SECONDS"
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    if [[ -f "$SRC" ]]; then
        cp "$SRC" "$SHOT_DIR/${name}.png"
        echo "   saved $SHOT_DIR/${name}.png"
    else
        echo "   WARN: no screenshot produced for ${name}"
    fi
}

shoot 01_title          res://scenes/title.tscn
shoot 02_switchboard    res://scenes/switchboard.tscn
shoot 03_ending_good    res://scenes/ending_good.tscn
shoot 04_ending_bad     res://scenes/ending_bad.tscn

echo ">> done. Screenshots in: $SHOT_DIR"
ls -lh "$SHOT_DIR"
