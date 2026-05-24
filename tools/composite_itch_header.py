#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "pillow>=10.0",
# ]
# ///
"""
Composite the existing Last Call title logo onto a left-side extension of
the itch.io header banner.

Strategy:
  1. Create a new canvas wider than the banner by LEFT_PAD_PX, filled with
     the deep teal night colour from the project palette.
  2. Paste the original banner against the right edge of the new canvas.
  3. Paste the trimmed logo into the centre of the new left padding.

Originals (`art/title.png` and the input banner) are untouched; the
result is written to a separate filename.

Usage:
    tools/composite_itch_header.py <banner.png> [output.png]
"""
from __future__ import annotations

import sys
from pathlib import Path

from PIL import Image

LOGO_PATH = Path("art/title.png")
DEFAULT_OUTPUT = Path("art/itch_header_composite.png")
# Pixels of solid teal to add on the left of the original banner.
LEFT_PAD_PX = 700
# How wide the trimmed logo should be relative to the left pad.
LOGO_WIDTH_RATIO = 0.92
# Final output is downscaled to this width to stay under itch.io's 3 MB
# header upload limit. Itch displays the header at <= 960 px so 1920 px
# leaves 2x for retina without bloating the file.
MAX_OUTPUT_WIDTH = 1920


def trim_transparent(im: Image.Image) -> Image.Image:
    """Crop fully-transparent borders so the logo's bounding box is the text."""
    alpha = im.split()[-1]
    bbox = alpha.getbbox()
    if bbox is None:
        return im
    return im.crop(bbox)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 1
    banner_path = Path(sys.argv[1])
    output_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUTPUT
    if not banner_path.exists():
        print(f"composite: banner not found: {banner_path}", file=sys.stderr)
        return 1
    if not LOGO_PATH.exists():
        print(f"composite: logo not found: {LOGO_PATH}", file=sys.stderr)
        return 1

    banner = Image.open(banner_path).convert("RGBA")
    logo = trim_transparent(Image.open(LOGO_PATH).convert("RGBA"))

    new_w = banner.width + LEFT_PAD_PX
    new_h = banner.height
    out = Image.new("RGBA", (new_w, new_h))

    # Build a clean vertical-gradient pad column from the banner. Sampling
    # a single column and stretching it horizontally exposes the per-row
    # grain as visible bands, so instead we average a wider slice of the
    # banner's left edge into one row-noise-free column, then stretch that
    # to the pad width. Result: same vignette / wall colour gradient as
    # the banner, but no horizontal stripes.
    edge_slice = banner.crop((0, 0, 40, banner.height))
    pad_column = edge_slice.resize((1, banner.height), Image.BILINEAR)
    pad = pad_column.resize((LEFT_PAD_PX, banner.height), Image.NEAREST)
    out.alpha_composite(pad, dest=(0, 0))

    # Banner pasted against the right edge so the operator silhouette
    # stays connected to the right-side switchboard.
    out.alpha_composite(banner, dest=(LEFT_PAD_PX, 0))

    # Logo centred inside the new left pad column.
    target_w = int(LEFT_PAD_PX * LOGO_WIDTH_RATIO)
    scale = target_w / logo.width
    target_h = int(logo.height * scale)
    logo_scaled = logo.resize((target_w, target_h), Image.LANCZOS)

    paste_x = (LEFT_PAD_PX - logo_scaled.width) // 2
    paste_y = (new_h - logo_scaled.height) // 2
    out.alpha_composite(logo_scaled, dest=(paste_x, paste_y))

    # Downscale to fit itch's 3 MB upload limit while still leaving 2x
    # retina headroom over the 960-wide display.
    if out.width > MAX_OUTPUT_WIDTH:
        scale = MAX_OUTPUT_WIDTH / out.width
        out = out.resize(
            (MAX_OUTPUT_WIDTH, round(out.height * scale)),
            Image.LANCZOS,
        )
    out.convert("RGB").save(output_path, "PNG", optimize=True)
    size_kb = output_path.stat().st_size // 1024
    print(f"composite: wrote {output_path} ({out.width}x{out.height}, {size_kb} KB)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
