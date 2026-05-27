#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Generate art/props/continue_glyph.png — a small amber brass arrow that
sits in front of the manual-advance hint on the caller card. SpecialElite
doesn't carry the U+25B6 triangle so we ship our own themed glyph instead
of relying on font fallbacks.

Run with `uv run tools/generate_continue_glyph.py` from the repo root.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parents[1]
OUT = REPO / "art" / "props" / "continue_glyph.png"

# Render at 4x then downsample for crisp antialiased edges.
SCALE = 4
W, H = 32 * SCALE, 32 * SCALE

# Palette matches menu_theme.tres / socket label colours.
AMBER = (232, 184, 107, 255)      # 0.91, 0.72, 0.42
AMBER_HI = (255, 215, 140, 255)   # subtle inner highlight
TEAL = (15, 41, 51, 255)          # 0.06, 0.16, 0.2 — outline
SHADOW = (0, 0, 0, 120)

img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# Triangle vertices — chunky, sits slightly off-centre so the tip lands
# near the right edge with a little breathing room.
pad = 4 * SCALE
tri = [
    (pad + 2 * SCALE, pad),
    (W - pad, H // 2),
    (pad + 2 * SCALE, H - pad),
]

# Soft drop shadow first — draw a teal triangle below + right, then blur.
shadow_offset = SCALE
shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(shadow).polygon(
    [(x + shadow_offset, y + shadow_offset) for x, y in tri], fill=SHADOW
)
shadow = shadow.filter(ImageFilter.GaussianBlur(radius=SCALE * 1.5))
img = Image.alpha_composite(img, shadow)

draw = ImageDraw.Draw(img)

# Body — amber fill, teal outline. outline width scaled.
draw.polygon(tri, fill=AMBER, outline=TEAL, width=SCALE)

# Inner highlight — slightly smaller, brighter triangle anchored to the
# upper-left edge so the glyph reads as a lit brass key, not a flat fill.
hi_inset = 3 * SCALE
hi_tri = [
    (tri[0][0] + hi_inset, tri[0][1] + hi_inset),
    (tri[1][0] - hi_inset * 2, tri[1][1]),
    (tri[0][0] + hi_inset, tri[0][1] + hi_inset * 2),
]
hi = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ImageDraw.Draw(hi).polygon(hi_tri, fill=AMBER_HI)
hi = hi.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.6))
img = Image.alpha_composite(img, hi)

img = img.resize((W // SCALE, H // SCALE), Image.LANCZOS)
OUT.parent.mkdir(parents=True, exist_ok=True)
img.save(OUT)
print(f"wrote {OUT.relative_to(REPO)}")
