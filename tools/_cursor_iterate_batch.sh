#!/usr/bin/env bash
# Fourth pass: lock in the v2_310_red direction. Only the brass-tip
# orientation needs fixing — the rest of the silhouette will be cleaned
# up in the procedural trace-and-recolour step downstream, so we focus
# the prompt on locking the tip up-left / shell down-right at ~45deg
# and try a handful of seed/angle variations.
#
# 128x128 — small enough to iterate fast (much faster than 512), and
# 128 is the smallest multiple of 16 that mflux/FLUX2 accepts without
# rounding the dimensions internally.
set -euo pipefail

cd "$(dirname "$0")/.."

SIZE=128
OUT_DIR="art/cursors/ideas"
mkdir -p "$OUT_DIR"

STYLE_TAIL="\
Hand-illustrated graphic poster in the style of Olly Moss alternate-movie-poster art \
and Eyvind Earle — bold, cinematic, moody. Flat fields of colour, screen-print grain, \
no photorealism, no 3D rendering, no cute cartoon style, no childish illustration, \
no children's book look. Strict palette: deep teal night #0F2A33 background, \
mid teal shadow #173E4A, warm wood brown #5A3A22, amber lamp light #E8B86A, \
bone-paper #F1E4C8 only for any text, aged red #C14B4B reserved for telephone \
cables only, mint #7AAE9A for tiny indicator lamps only. Exactly one warm amber \
light source from the upper right."

PROP_PREAMBLE="\
A single isolated object centred in frame, rendered as if for a product cutout. \
The object sits against a completely plain, flat, uniform deep teal #0F2A33 \
background. The background is empty — NO walls, NO floor, NO ceiling, NO room, \
NO scenery, NO other furniture, NO cast shadow on the ground, NO additional \
props. The object is hand-illustrated, lit with the standard warm-amber-from-\
upper-right rim light only on the object itself. ${STYLE_TAIL}"

# Shared anatomy + orientation block. The orientation language is much
# more explicit than previous passes: we describe what's at the TOP-LEFT
# of the image and what's at the BOTTOM-RIGHT separately, so FLUX can't
# satisfy the prompt by flipping the plug horizontally.
PLUG_BLOCK="\
a historically accurate 1960s Bell System 310 plug (1/4 inch TRS phone plug, \
also known as PJ-068), the kind used by telephone switchboard operators of \
the era. The plug has a smooth cylindrical metal shaft, NOT faceted or \
angular. The metal portion shows three distinct polished brass segments \
separated by TWO thin black insulator rings between them: a rounded brass \
tip cone at the front, then an insulator ring, then a brass ring band, then \
a second insulator ring, then a brass sleeve barrel. The metal shaft then \
meets a smooth deep aged-red bakelite shell (the operator's grip) — \
perfectly cylindrical, glossy, no decorations, no stripes, no wraps. The \
shell ends in a flat or slightly rounded blunt back end. NO cord, NO cable, \
NO wire, NO strain relief — the shell ends cleanly.\
\
ORIENTATION: in the TOP-LEFT half of the image is the brass metal head of \
the plug — the brass tip cone is the highest, leftmost element in the \
entire image, pointing at the top-left corner of the canvas. In the \
BOTTOM-RIGHT half of the image is the red bakelite shell — the flat blunt \
back end of the shell is the lowest, rightmost element in the image, \
pointing at the bottom-right corner. The plug therefore runs as a clean \
diagonal from top-left (brass tip) to bottom-right (red shell back). The \
brass tip and the red shell do NOT swap positions. This is the standard \
arrow-cursor orientation."

shoot() {
    local stem="$1" subject="$2" seed="$3"
    local out="${OUT_DIR}/${stem}.png"
    echo
    echo "=== ${stem} (seed ${seed}) ==="
    rm -f "$out" "${out%.png}.metadata.json"
    mflux-generate-flux2 \
        --model flux2-klein-9b \
        --quantize 4 \
        --width "$SIZE" \
        --height "$SIZE" \
        --prompt "${PROP_PREAMBLE} Subject: ${subject}" \
        --metadata \
        --output "$out" \
        --seed "$seed"
    tools/cutout.py "$out"
}

# Six seed variations on the same tightly-anchored prompt. Different
# seeds tend to give FLUX a different "natural orientation" prior even
# when the prompt language is identical, so the best chance of one
# landing correctly is to roll several dice.
shoot v2r1_310_red \
    "${PLUG_BLOCK}" \
    501
shoot v2r2_310_red \
    "${PLUG_BLOCK}" \
    502
shoot v2r3_310_red \
    "${PLUG_BLOCK}" \
    503
shoot v2r4_310_red \
    "${PLUG_BLOCK}" \
    504

# Two with a steeper angle for variety — sometimes a steeper diagonal
# also nudges the model toward keeping the tip in the top-left quadrant.
shoot v2r5_310_red_steep \
    "${PLUG_BLOCK} The diagonal is steeper than 45 degrees — closer to 60 degrees from horizontal — so the plug reads as a tall slim pointer almost vertical, but the brass tip is still at the very top-left." \
    505
shoot v2r6_310_red_shallow \
    "${PLUG_BLOCK} The diagonal is shallower than 45 degrees — closer to 30 degrees from horizontal — so the plug is more sideways across the frame, but the brass tip is still at the top-left." \
    506

echo
echo "=== v2-focused iterations done ==="
ls -lh "${OUT_DIR}"/v2r*.png
