#!/usr/bin/env bash
# One-off batch: render 10 cursor concepts via FLUX2, cut the background,
# drop them in art/cursors/ideas/ for human pick.
#
# Bypasses tools/generate_sprite.sh so we can render at 512x512 instead of
# the production 1024x1024 — the cursor only needs to display at 32-64px,
# so 512 is more than enough to read the concept and roughly 4x faster
# (~30-45s per image on M4 vs ~2min). Whole batch ≈ 5-8 min.
#
# Style preamble is inlined (deliberately) so the script is self-contained
# and any future tweaks don't accidentally drift from the production
# generate_sprite.sh look. Concept differentiation lives in SUBJECT.
set -euo pipefail

cd "$(dirname "$0")/.."

SIZE=512
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
upper-right rim light only on the object itself. The object fills roughly 70% \
of the frame with clean negative space around it on all four sides so it can \
be cut out cleanly. NO people, NO silhouettes, NO hands, NO characters. \
${STYLE_TAIL}"

shoot() {
    local idx="$1" name="$2" subject="$3" seed="$4"
    local stem="${idx}_${name}"
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
    # Cutout pipeline (rembg via uv) — turns the flat-teal BG into alpha.
    tools/cutout.py "$out"
}

# Concept 02 (gloved finger) inverts the "NO hands" prop clause on purpose,
# because the cursor concept IS a hand. The other 9 stay in-spec.
shoot 01 brass_plug \
    "a single 1960s telephone switchboard patch-cord plug, oriented at a 45 degree angle with the sharp brass tip in the upper-left corner and the dark black handle trailing toward the lower-right, brass collar between shaft and handle, a thin red cord wrap stripe on the handle near the back end, no cable visible" \
    101

shoot 02 gloved_finger \
    "a vintage 1960s telephone operator's right hand wearing a white cotton glove, pointing with the index finger extended toward the upper-left, the thumb tucked, the other fingers curled, the wrist trailing into the lower-right, no body visible, just the hand floating in frame" \
    102

shoot 03 brass_arrow \
    "an art-deco brass arrow icon in the 1960s telegraph aesthetic, geometric shape with chamfered edges, polished brass surface, a thin red enamel inlay running along the spine of the arrow, the sharp tip pointing toward the upper-left of the frame" \
    103

shoot 04 candlestick_handset \
    "a 1960s antique candlestick telephone receiver, the speaking-bell end pointing toward the upper-left of the frame like the tip of a pointer, brass bell mouthpiece, black bakelite ear cup at the lower-right, a short coiled black cord trailing from the ear cup" \
    104

shoot 05 type_arm \
    "a single 1960s typewriter strike-arm caught mid-strike, slender steel arm with a brass type slug holding a single letter at the tip, the slug positioned in the upper-left as if just touching the paper, the arm trailing back to the lower-right where it pivots out of frame" \
    105

shoot 06 plug_with_cord \
    "a 1960s telephone switchboard patch-cord plug oriented at 45 degrees with the brass tip in the upper-left, the dark black handle in the middle of the frame, and a long red coiled telephone cable curling away from the back of the handle toward the lower-right corner of the frame" \
    106

shoot 07 dial_pointer \
    "a polished brass switchboard dial knob viewed from straight above, circular brass face with subtle tick marks around the perimeter, a single slender brass arrow indicator like a clock hand pointing toward the upper-left of the frame, red enamel detail at the centre hub" \
    107

shoot 08 operator_pencil \
    "a 1960s yellow no.2 wooden pencil oriented at a 45 degree angle with the sharpened graphite tip in the upper-left of the frame and a small brass ferrule with red eraser at the lower-right, the body of the pencil bearing a thin painted stripe, no hand holding it" \
    108

shoot 09 telegraph_key \
    "a 1960s brass telegraph key viewed from the side, the rounded black finger knob pressed downward, the brass lever angled so the contact point in the upper-left of the frame meets an implied contact stud, polished brass base trailing toward the lower-right" \
    109

shoot 10 rotary_phone \
    "a miniature 1960s black rotary telephone with the handset lifted off the cradle, the handset positioned in the upper-left of the frame like a pointer, a coiled black cord running from the handset back to the phone body in the lower-right, the rotary dial visible on the body" \
    110

echo
echo "=== batch done ==="
ls -lh "$OUT_DIR"
