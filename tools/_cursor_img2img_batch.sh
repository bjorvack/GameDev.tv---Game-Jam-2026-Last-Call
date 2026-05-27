#!/usr/bin/env bash
# Fifth pass: img2img wash of the procedural block-colour init image, so
# the brass-tip orientation stays locked at top-left and FLUX2 only
# fills in the painterly Olly-Moss treatment. Six seed variations + one
# strength sweep.
#
# 128x128 source — matches _init_block.png. Per-render ~3-4 min on M4.
set -euo pipefail

cd "$(dirname "$0")/.."

INIT="art/cursors/ideas/v2_ref_128.png"
OUT_DIR="art/cursors/ideas"
mkdir -p "$OUT_DIR"

if [[ ! -f "$INIT" ]]; then
    echo "missing $INIT — run tools/_crop_v2.py first to prepare the reference image" >&2
    exit 1
fi

STYLE_TAIL="\
Hand-illustrated graphic poster in the style of Olly Moss alternate-movie-poster art \
and Eyvind Earle — bold, cinematic, moody. Flat fields of colour, screen-print grain, \
no photorealism, no 3D rendering, no cute cartoon style, no childish illustration, \
no children's book look. Strict palette: deep teal night #0F2A33 background, \
mid teal shadow #173E4A, warm wood brown #5A3A22, amber lamp light #E8B86A, \
bone-paper #F1E4C8 only for any text, aged red #C14B4B reserved for telephone \
cables only, mint #7AAE9A for tiny indicator lamps only. Exactly one warm amber \
light source from the upper right."

PROMPT="\
A single isolated 1960s Bell System 310 phone plug (1/4 inch TRS, PJ-068), the \
operator's patch-cord plug. Smooth cylindrical brass shaft showing tip-ring-sleeve \
segments separated by two thin black insulator rings; deep aged-red bakelite shell \
forming the operator's grip. NO cord, NO cable, NO wire trailing from the back of \
the shell — the shell ends cleanly. The plug is rendered with the brass tip in \
the upper-left corner of the frame and the red shell trailing diagonally to the \
lower-right — standard arrow-cursor orientation, do NOT flip or rotate. The object \
sits against a completely plain deep teal #0F2A33 background with no scenery. \
${STYLE_TAIL}"

shoot() {
    local stem="$1" strength="$2" seed="$3"
    local out="${OUT_DIR}/${stem}.png"
    echo
    echo "=== ${stem} (strength ${strength}, seed ${seed}) ==="
    rm -f "$out" "${out%.png}.metadata.json"
    mflux-generate-flux2 \
        --model flux2-klein-9b \
        --quantize 4 \
        --image-path "$INIT" \
        --image-strength "$strength" \
        --width 128 \
        --height 128 \
        --prompt "$PROMPT" \
        --metadata \
        --output "$out" \
        --seed "$seed"
    tools/cutout.py "$out"
}

# Four seed variations at the "wash sweet spot" (strength 0.55–0.65):
# enough adherence to preserve orientation + palette, enough freedom for
# FLUX to add painterly brushwork, rim light, and atmosphere.
shoot w1_red_plug   0.60 601
shoot w2_red_plug   0.60 602
shoot w3_red_plug   0.55 603
shoot w4_red_plug   0.65 604

# Two with stronger init adherence — should track the block init more
# closely, useful if the wash drifts in the first four.
shoot w5_red_plug_strong 0.75 605
shoot w6_red_plug_strong 0.75 606

echo
echo "=== img2img wash done ==="
ls -lh "${OUT_DIR}"/w[1-6]_red_plug*.png
