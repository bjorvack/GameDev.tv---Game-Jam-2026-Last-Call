#!/usr/bin/env bash
# Build Last Call for the Web preset, then zip it for itch.io upload.
#
# Usage:
#   tools/build_web.sh           # full clean build + zip
#   tools/build_web.sh --no-zip  # build only, skip the itch zip
#
# Output:
#   build/web/index.html + .js + .pck + .wasm + icons
#   build/last_call_web.zip   (excluded by --no-zip)
#
# Source-only assets and dev tools (itch_header_*.png, tools/*) are kept
# out of the .pck via the Web preset's exclude_filter in
# export_presets.cfg.
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
WEB_DIR="$BUILD_DIR/web"
ZIP_PATH="$BUILD_DIR/last_call_web.zip"
PRESET="Web"
ENTRY="$WEB_DIR/index.html"

MAKE_ZIP=1
for arg in "$@"; do
    case "$arg" in
        --no-zip) MAKE_ZIP=0 ;;
        -h|--help)
            grep '^#' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "build_web: unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

if ! command -v godot >/dev/null 2>&1; then
    echo "build_web: 'godot' not on PATH" >&2
    exit 1
fi

cd "$PROJECT_ROOT"

echo ">> Cleaning $WEB_DIR"
rm -rf "$WEB_DIR"
mkdir -p "$WEB_DIR"

echo ">> Exporting Godot Web preset"
godot --headless --export-release "$PRESET" "$ENTRY" >/dev/null

if [[ ! -f "$ENTRY" ]]; then
    echo "build_web: export did not produce $ENTRY" >&2
    exit 1
fi

# Copy static loading assets (favicon, splash bg/logo) next to
# index.html. The custom HTML shell references them via relative
# `static/...` paths, and we keep them out of the .pck via
# `web/static/*` in the export preset's exclude_filter — so the
# files only live here, not double-packed inside the engine bundle.
if [[ -d "$PROJECT_ROOT/web/static" ]]; then
    echo ">> Copying web/static → $WEB_DIR/static"
    cp -R "$PROJECT_ROOT/web/static" "$WEB_DIR/static"
fi

echo ">> Sizes:"
ls -lh "$WEB_DIR"/index.{html,js,pck,wasm} 2>/dev/null | awk '{print "   ", $5, "\t", $9}'

if [[ "$MAKE_ZIP" -eq 1 ]]; then
    echo ">> Zipping for itch (excluding .import files)"
    rm -f "$ZIP_PATH"
    ( cd "$WEB_DIR" && zip -qr "$ZIP_PATH" . -x "*.import" )
    echo ">> Built $(ls -lh "$ZIP_PATH" | awk '{print $5}') → $ZIP_PATH"
fi
