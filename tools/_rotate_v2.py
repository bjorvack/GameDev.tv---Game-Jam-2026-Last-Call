#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Probe all four rotations of v2_310_red.png so we can pick visually
which puts the brass tip in the upper-left corner. Each rotation is
saved as a 128x128 RGBA into art/cursors/ideas/.
"""
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
SRC = REPO / "art" / "cursors" / "ideas" / "v2_310_red.png"
OUT_DIR = REPO / "art" / "cursors" / "ideas"

src = Image.open(SRC).convert("RGBA")

rotations = {
    "v2_rot_0":   src,
    "v2_rot_90ccw":  src.transpose(Image.ROTATE_90),    # 90 deg CCW
    "v2_rot_180":    src.transpose(Image.ROTATE_180),   # 180
    "v2_rot_270ccw": src.transpose(Image.ROTATE_270),   # 270 CCW == 90 CW
}

for name, img in rotations.items():
    img = img.resize((128, 128), Image.LANCZOS)
    out = OUT_DIR / f"{name}.png"
    img.save(out)
    print(f"wrote {out.relative_to(REPO)}")
