#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Generate art/cursors/cursor_default.png + cursor_interact.png from a
single shared style spec.

The cursor is a stylised brass patch-cord tip — the same prop the
operator is actively manipulating in-game (see art/props/jack_idle.png
for the in-world reference). Idle vs. interact swaps the brass tone
from a cool unlit reading to a warm amber "ready to plug" reading, and
adds a soft halo around the tip on the interact variant. Both variants
share silhouette, outline, shadow and hotspot so they read as a set.

Run with `uv run tools/generate_cursor_set.py` from the repo root.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parents[1]
OUT_DIR = REPO / "art" / "cursors"

# --- Shared style spec ------------------------------------------------
CURSOR_SIZE = 48           # square canvas, in display pixels
SCALE = 4                  # render at 4x then downsample for AA
W = H = CURSOR_SIZE * SCALE

# Palette — matches menu_theme.tres and the existing brass/red wrap on
# art/props/jack_idle.png so the cursor reads as the same prop family.
TEAL_OUTLINE = (15, 41, 51, 255)            # silhouette outline
HANDLE_DARK = (18, 20, 24, 255)             # black plug body
HANDLE_HI = (60, 60, 66, 255)               # handle highlight band
RED_WRAP = (140, 38, 34, 255)               # cord wrap accent
RED_WRAP_HI = (190, 70, 55, 255)            # wrap highlight stripe
BRASS_DARK = (158, 102, 38, 255)            # shaft shadow side
BRASS_MID = (210, 152, 70, 255)             # shaft midtone
BRASS_LIGHT = (245, 210, 130, 255)          # shaft highlight
BRASS_TIP_HI = (255, 235, 170, 255)         # sharp specular near the point
COOL_TINT = (185, 195, 205, 60)             # subtle blue wash on idle
AMBER_GLOW = (255, 195, 100, 200)           # halo on interact
SHADOW = (0, 0, 0, 140)

OUTLINE_WIDTH = max(1, SCALE // 2)
SHADOW_OFFSET = SCALE
SHADOW_BLUR = SCALE * 1.6

# Cursor silhouette — a stubby plug, tip pointing up-left so the hotspot
# at (3, 3) lands on the brass point. Coordinates are in the upscaled
# canvas. The shape is a slim ~45-deg-rotated jack: pointed brass tip
# → brass collar ring → dark handle → small wrap stripe at the tail.
TIP = (3 * SCALE, 3 * SCALE)
# Direction vector: from tip toward the cord tail.
def along(d: float, perp: float = 0.0) -> tuple[int, int]:
    # 45-deg axis going down-right from TIP.
    import math
    a = math.radians(45)
    dx = math.cos(a) * d - math.sin(a) * perp
    dy = math.sin(a) * d + math.cos(a) * perp
    return (int(TIP[0] + dx * SCALE), int(TIP[1] + dy * SCALE))


# Segments along the cursor axis (distance from tip, in display pixels):
#   0     -> tip
#   13    -> end of brass shaft / start of brass collar
#   17    -> end of collar / start of black handle
#   33    -> end of handle / start of red wrap
#   39    -> end of wrap / blunt cord stub
SHAFT_HALF = 2.2          # half-thickness of the brass shaft
COLLAR_HALF = 3.3         # half-thickness of the brass collar
HANDLE_HALF = 4.0         # half-thickness of the dark plug body
WRAP_HALF = 3.5           # half-thickness of the red wrap stub


@dataclass
class CursorVariant:
    name: str
    interact: bool


VARIANTS = [
    CursorVariant("cursor_default", interact=False),
    CursorVariant("cursor_interact", interact=True),
]


def quad(d0: float, h0: float, d1: float, h1: float) -> list[tuple[int, int]]:
    """Return a 4-point polygon for a tapered band along the cursor axis."""
    return [
        along(d0, -h0),
        along(d1, -h1),
        along(d1, h1),
        along(d0, h0),
    ]


def render_cursor(variant: CursorVariant) -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # 1. Drop shadow — single silhouette of the whole shape, blurred + offset.
    silhouette = quad(0, 0.1, 13, SHAFT_HALF) + list(reversed(quad(0, 0.1, 13, SHAFT_HALF)))
    full_outline = (
        [TIP]
        + [along(13, SHAFT_HALF), along(13, COLLAR_HALF)]
        + [along(17, COLLAR_HALF), along(17, HANDLE_HALF)]
        + [along(33, HANDLE_HALF), along(33, WRAP_HALF)]
        + [along(39, WRAP_HALF), along(39, -WRAP_HALF)]
        + [along(33, -WRAP_HALF), along(33, -HANDLE_HALF)]
        + [along(17, -HANDLE_HALF), along(17, -COLLAR_HALF)]
        + [along(13, -COLLAR_HALF), along(13, -SHAFT_HALF)]
    )
    shadow_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow_layer).polygon(
        [(x + SHADOW_OFFSET, y + SHADOW_OFFSET) for x, y in full_outline],
        fill=SHADOW,
    )
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=SHADOW_BLUR))
    img = Image.alpha_composite(img, shadow_layer)

    # 2. Interact-only halo behind the shape — soft amber glow that
    # reinforces "this is actionable" without changing silhouette.
    if variant.interact:
        glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        gdraw = ImageDraw.Draw(glow)
        # Halo extents — a bit puffier than the shape itself.
        gx, gy = TIP
        rg = 11 * SCALE
        gdraw.ellipse((gx - rg, gy - rg, gx + rg, gy + rg), fill=AMBER_GLOW)
        glow = glow.filter(ImageFilter.GaussianBlur(radius=SCALE * 2.5))
        img = Image.alpha_composite(img, glow)

    draw = ImageDraw.Draw(img)

    # 3. Brass shaft — tapered, with midtone fill. Outlined.
    shaft_poly = [TIP, along(13, SHAFT_HALF), along(13, -SHAFT_HALF)]
    draw.polygon(shaft_poly, fill=BRASS_MID, outline=TEAL_OUTLINE, width=OUTLINE_WIDTH)
    # Specular highlight along the upper edge of the shaft (the lit side).
    spec_poly = [
        along(0.6, -0.2),
        along(12.6, -SHAFT_HALF * 0.55),
        along(12.6, -SHAFT_HALF * 1.0),
        along(0.6, -0.2),
    ]
    spec_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(spec_layer).polygon(spec_poly, fill=BRASS_LIGHT)
    spec_layer = spec_layer.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.4))
    img = Image.alpha_composite(img, spec_layer)
    # Sharp tip specular dot.
    tip_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(tip_layer).ellipse(
        (TIP[0] - SCALE, TIP[1] - SCALE, TIP[0] + SCALE * 1.5, TIP[1] + SCALE * 1.5),
        fill=BRASS_TIP_HI,
    )
    tip_layer = tip_layer.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.3))
    img = Image.alpha_composite(img, tip_layer)

    draw = ImageDraw.Draw(img)

    # 4. Brass collar between shaft and handle.
    draw.polygon(
        quad(13, COLLAR_HALF, 17, COLLAR_HALF),
        fill=BRASS_DARK,
        outline=TEAL_OUTLINE,
        width=OUTLINE_WIDTH,
    )
    # Collar highlight stripe along the top edge.
    collar_hi = quad(13.3, -COLLAR_HALF * 0.4, 16.7, -COLLAR_HALF * 0.4)
    collar_hi[1] = along(16.7, -COLLAR_HALF * 0.95)
    collar_hi[0] = along(13.3, -COLLAR_HALF * 0.95)
    hi_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(hi_layer).polygon(collar_hi, fill=BRASS_LIGHT)
    hi_layer = hi_layer.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.35))
    img = Image.alpha_composite(img, hi_layer)

    draw = ImageDraw.Draw(img)

    # 5. Dark plug handle.
    draw.polygon(
        quad(17, HANDLE_HALF, 33, HANDLE_HALF),
        fill=HANDLE_DARK,
        outline=TEAL_OUTLINE,
        width=OUTLINE_WIDTH,
    )
    # Subtle highlight band along the top edge of the handle.
    handle_hi = [
        along(18, -HANDLE_HALF * 0.85),
        along(32, -HANDLE_HALF * 0.85),
        along(32, -HANDLE_HALF * 0.4),
        along(18, -HANDLE_HALF * 0.4),
    ]
    hi_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(hi_layer).polygon(handle_hi, fill=HANDLE_HI)
    hi_layer = hi_layer.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.55))
    img = Image.alpha_composite(img, hi_layer)

    draw = ImageDraw.Draw(img)

    # 6. Red wrap stub at the tail end.
    draw.polygon(
        quad(33, WRAP_HALF, 39, WRAP_HALF),
        fill=RED_WRAP,
        outline=TEAL_OUTLINE,
        width=OUTLINE_WIDTH,
    )
    wrap_hi = [
        along(33.6, -WRAP_HALF * 0.85),
        along(38.4, -WRAP_HALF * 0.85),
        along(38.4, -WRAP_HALF * 0.4),
        along(33.6, -WRAP_HALF * 0.4),
    ]
    hi_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(hi_layer).polygon(wrap_hi, fill=RED_WRAP_HI)
    hi_layer = hi_layer.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.4))
    img = Image.alpha_composite(img, hi_layer)

    # 7. Idle variant gets a faint cool wash over the whole shape so the
    # interact (warm + halo) reads as a meaningful state change.
    if not variant.interact:
        wash = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        ImageDraw.Draw(wash).polygon(full_outline, fill=COOL_TINT)
        wash = wash.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.3))
        img = Image.alpha_composite(img, wash)

    return img.resize((CURSOR_SIZE, CURSOR_SIZE), Image.LANCZOS)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for variant in VARIANTS:
        path = OUT_DIR / f"{variant.name}.png"
        render_cursor(variant).save(path)
        print(f"wrote {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
