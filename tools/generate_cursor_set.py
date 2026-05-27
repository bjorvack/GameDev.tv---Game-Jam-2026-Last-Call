#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["pillow>=10"]
# ///
"""Generate art/cursors/cursor_default.png + cursor_interact.png from a
single shared style spec so the two cursor states are guaranteed to feel
like a set: same silhouette, same outline weight, same drop shadow —
only the fill palette changes between the idle and "this is actionable"
variants. The fill swap mirrors the cream-idle / amber-lit relationship
already established for sockets and toggle text in menu_theme.tres.

Run with `uv run tools/generate_cursor_set.py` from the repo root.
"""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

REPO = Path(__file__).resolve().parents[1]
OUT_DIR = REPO / "art" / "cursors"

# --- Shared style spec ------------------------------------------------
# Everything below is the single source of truth for cursor look-and-feel.
# Both variants are rendered through the same `render_cursor` function;
# only the `fill` colour and the inner-highlight flag differ.

CURSOR_SIZE = 28           # square canvas, in display pixels
SCALE = 4                  # render at 4x then downsample for AA
W = H = CURSOR_SIZE * SCALE

# Palette — these duplicate the menu_theme.tres / continue_glyph.py palette
# so any future shift in brand colour is a one-line edit per script.
CREAM = (244, 235, 209, 255)        # 0.96, 0.92, 0.82 — idle fill
AMBER = (232, 184, 107, 255)        # 0.91, 0.72, 0.42 — interact fill
AMBER_HI = (255, 215, 140, 255)     # inner highlight on interact only
TEAL = (15, 41, 51, 255)            # 0.06, 0.16, 0.2 — outline
SHADOW = (0, 0, 0, 130)             # soft drop shadow

OUTLINE_WIDTH = 2 * SCALE
SHADOW_OFFSET = SCALE
SHADOW_BLUR = SCALE * 1.4

# Cursor silhouette — an angular brass-tipped arrow pointing up-left so the
# hotspot lands cleanly at (0, 0). Coords are in the upscaled canvas.
TIP = (2 * SCALE, 2 * SCALE)
ARROW_BODY = [
    TIP,
    (16 * SCALE, 10 * SCALE),
    (11 * SCALE, 12 * SCALE),
    (14 * SCALE, 19 * SCALE),
    (11 * SCALE, 20 * SCALE),
    (8 * SCALE, 13 * SCALE),
    (4 * SCALE, 17 * SCALE),
]


@dataclass
class CursorVariant:
    name: str
    fill: tuple[int, int, int, int]
    highlight: bool


VARIANTS = [
    CursorVariant("cursor_default", CREAM, highlight=False),
    CursorVariant("cursor_interact", AMBER, highlight=True),
]


def render_cursor(variant: CursorVariant) -> Image.Image:
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    # Drop shadow — same teal-toned shadow under both variants.
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).polygon(
        [(x + SHADOW_OFFSET, y + SHADOW_OFFSET) for x, y in ARROW_BODY],
        fill=SHADOW,
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=SHADOW_BLUR))
    img = Image.alpha_composite(img, shadow)

    # Body — fill + outline. Same outline colour and thickness across variants
    # so the silhouette reads consistent regardless of state.
    draw = ImageDraw.Draw(img)
    draw.polygon(ARROW_BODY, fill=variant.fill, outline=TEAL, width=OUTLINE_WIDTH)

    # Interact variant gets a soft inner highlight near the tip so it reads
    # as "lit", matching the active-socket vocabulary established elsewhere.
    if variant.highlight:
        hi_layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        # Narrow inner-tip triangle, blurred so it looks like a glow not a fill.
        hi_tri = [
            (TIP[0] + 2 * SCALE, TIP[1] + 1 * SCALE),
            (10 * SCALE, 9 * SCALE),
            (7 * SCALE, 13 * SCALE),
        ]
        ImageDraw.Draw(hi_layer).polygon(hi_tri, fill=AMBER_HI)
        hi_layer = hi_layer.filter(ImageFilter.GaussianBlur(radius=SCALE * 0.6))
        img = Image.alpha_composite(img, hi_layer)

    return img.resize((CURSOR_SIZE, CURSOR_SIZE), Image.LANCZOS)


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for variant in VARIANTS:
        path = OUT_DIR / f"{variant.name}.png"
        render_cursor(variant).save(path)
        print(f"wrote {path.relative_to(REPO)}")


if __name__ == "__main__":
    main()
