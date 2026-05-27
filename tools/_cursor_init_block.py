#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Render a flat block-colour 128x128 init image for the brass-plug
cursor: brass tip in the extreme upper-left corner, three brass TRS
segments with two thin black insulator rings, red bakelite shell
trailing to the lower-right. Used as the --image-path init for an
img2img FLUX2 pass — the geometry stays locked while FLUX adds the
painterly Olly-Moss treatment.

Run with `uv run tools/_cursor_init_block.py`.
"""
from pathlib import Path

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "art" / "cursors" / "ideas" / "_init_block.png"

CANVAS = 128
SCALE = 4                                  # supersample for AA
W = H = CANVAS * SCALE

# Palette pinned to menu_theme.tres / generate_sprite.sh.
TEAL_BG = (15, 41, 51, 255)                # background
BRASS = (210, 152, 70, 255)                # tip + segments
INSULATOR = (18, 20, 24, 255)              # thin rings between segments
RED_SHELL = (193, 75, 75, 255)             # aged red bakelite

# Plug axis runs from extreme upper-left corner down to ~80% x 80%.
# 45-degree diagonal across the canvas.
TIP = (4 * SCALE, 4 * SCALE)
BACK = (100 * SCALE, 100 * SCALE)


def along(d: float, perp: float = 0.0) -> tuple[int, int]:
    """Point d pixels along the tip->back axis, perp pixels perpendicular."""
    import math
    a = math.radians(45)
    dx = math.cos(a) * d - math.sin(a) * perp
    dy = math.sin(a) * d + math.cos(a) * perp
    return (int(TIP[0] + dx * SCALE), int(TIP[1] + dy * SCALE))


def quad(d0: float, h0: float, d1: float, h1: float) -> list[tuple[int, int]]:
    return [along(d0, -h0), along(d1, -h1), along(d1, h1), along(d0, h0)]


# Segment lengths along the axis (display pixels):
#   tip cone:   0  ->  10   (brass cone narrowing to the point)
#   ring 1:    10  ->  12
#   ring band: 12  ->  20   (brass cylinder)
#   ring 2:    20  ->  22
#   sleeve:    22  ->  32   (brass cylinder, wider)
#   shell:     32  ->  68   (red bakelite cylinder, widest)
HALF_SHAFT = 4.0
HALF_RING = 4.5
HALF_SLEEVE = 5.0
HALF_SHELL = 6.5

img = Image.new("RGBA", (W, H), TEAL_BG)
draw = ImageDraw.Draw(img)

# Tip cone — triangle narrowing to TIP.
draw.polygon([TIP, along(10, HALF_SHAFT), along(10, -HALF_SHAFT)], fill=BRASS)
# Insulator ring 1.
draw.polygon(quad(10, HALF_SHAFT, 12, HALF_RING), fill=INSULATOR)
# Ring band.
draw.polygon(quad(12, HALF_RING, 20, HALF_RING), fill=BRASS)
# Insulator ring 2.
draw.polygon(quad(20, HALF_RING, 22, HALF_SLEEVE), fill=INSULATOR)
# Sleeve.
draw.polygon(quad(22, HALF_SLEEVE, 32, HALF_SLEEVE), fill=BRASS)
# Bakelite shell.
draw.polygon(quad(32, HALF_SLEEVE, 68, HALF_SHELL), fill=RED_SHELL)

img = img.resize((CANVAS, CANVAS), Image.LANCZOS)
OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT)
print(f"wrote {OUT.relative_to(REPO)}")
