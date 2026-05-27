#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Prepare a tight 128x128 reference of v2_310_red oriented as a proper
arrow cursor:

    1. Rotate the source 45 degrees clockwise so the originally-
       horizontal plug now spans the diagonal of the frame: brass tip
       at the upper-left, red shell back at the lower-right.
    2. Find the bounding box of the plug via the existing alpha channel
       (the prop pipeline already ran rembg, so the background is
       transparent).
    3. Crop tightly to that bbox so the brass tip sits at the very
       upper-left corner with no empty space, then square the crop by
       padding the shorter side with transparent pixels (keeping the
       tip anchored at (0, 0)).
    4. Upscale the square crop to 128x128.

The output lands at art/cursors/ideas/v2_ref_128.png and is the
intended --image-path init for the next FLUX2 img2img wash batch.
"""
from pathlib import Path

from PIL import Image

REPO = Path(__file__).resolve().parents[1]
SRC = REPO / "art" / "cursors" / "ideas" / "v2_310_red.png"
OUT = REPO / "art" / "cursors" / "ideas" / "v2_ref_128.png"
TARGET = 128

src = Image.open(SRC).convert("RGBA")
# 45 degrees clockwise (PIL's rotate uses CCW for positive angles, so
# we pass -45). expand=True grows the canvas to fit the rotated content
# without clipping. The plug's axis goes from roughly horizontal in
# the original to roughly upper-left -> lower-right diagonal here.
rotated = src.rotate(-45, expand=True, resample=Image.BICUBIC)

# Bounding box from the alpha channel (background is already transparent).
bbox = rotated.getbbox()
if bbox is None:
    raise SystemExit("source has no non-transparent pixels — cutout never ran?")
cropped = rotated.crop(bbox)

# Square the crop while keeping the plug's brass tip anchored at (0, 0)
# — pad the shorter side with transparent pixels on the bottom/right.
w, h = cropped.size
side = max(w, h)
square = Image.new("RGBA", (side, side), (0, 0, 0, 0))
square.paste(cropped, (0, 0))

square = square.resize((TARGET, TARGET), Image.LANCZOS)
OUT.parent.mkdir(parents=True, exist_ok=True)
square.save(OUT)
print(f"wrote {OUT.relative_to(REPO)} (bbox={bbox}, side={side} -> {TARGET})")
