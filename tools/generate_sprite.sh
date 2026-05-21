#!/usr/bin/env bash
# Generate a Last Call sprite locally using mflux (FLUX on Apple MLX).
#
# Usage:
#   tools/generate_sprite.sh portrait <out_name> "<subject prose>" [seed]
#   tools/generate_sprite.sh bg       <out_name> "<subject prose>" [seed]
#
# Examples:
#   tools/generate_sprite.sh portrait daniel "a tall lean man in a baseball cap"
#   tools/generate_sprite.sh bg switchboard "a 1960 telephone exchange switchboard panel" 42
#
# First run downloads ~15 GB of FLUX.2 klein 9B weights to ~/.cache/huggingface.
# Subsequent runs are ~2 min per image on an M4 24 GB at q4.
#
# Notes:
# - Using FLUX.2 klein 9B (FLUX Non-Commercial License). Better prompt
#   adherence than FLUX.1 Schnell — actually draws described props (caps,
#   glasses, phone cords). For commercial use, swap to flux2-klein-4b
#   (Apache 2.0).
# - FLUX.2 klein is step-distilled, so we let mflux use its default step count.
# - Negative prompts are not used (step-distilled models ignore them).
#   Prohibitions are encoded as positive statements in the preamble.

set -euo pipefail

KIND="${1:-}"
NAME="${2:-}"
SUBJECT="${3:-}"
SEED="${4:-}"

if [[ -z "$KIND" || -z "$NAME" || -z "$SUBJECT" ]]; then
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 1
fi

# Shared style anchors (palette, medium, lighting). Applied to every kind.
# v1 wording — Olly Moss noir poster, no Klassen / no "paper cutout" (those
# pushed results toward children's book illustration).
STYLE_TAIL="\
Hand-illustrated graphic poster in the style of Olly Moss alternate-movie-poster art \
and Eyvind Earle — bold, cinematic, moody. Flat fields of colour, screen-print grain, \
no photorealism, no 3D rendering, no cute cartoon style, no childish illustration, \
no children's book look. Strict palette: deep teal night #0F2A33 background, \
mid teal shadow #173E4A, warm wood brown #5A3A22, amber lamp light #E8B86A, \
bone-paper #F1E4C8 only for any text, aged red #C14B4B reserved for telephone \
cables only, mint #7AAE9A for tiny indicator lamps only. Exactly one warm amber \
light source from the upper right."

case "$KIND" in
    portrait)
        WIDTH=1024
        HEIGHT=1024
        OUT_DIR="art/portraits"
        # Portraits: silhouette character + phone, on a completely plain
        # background. NO lamps, NO scenery, NO props — character only.
        PREAMBLE="\
A pure dark silhouette of a single person rendered as a solid black shape against a \
completely plain, flat, uniform deep teal #0F2A33 background. The background is \
empty — NO lamps, NO lampposts, NO sconces, NO candles, NO windows, NO furniture, \
NO scenery, NO decorations, NO props, NO architectural details, NO sky, NO stars, \
NO moon, NO trees, NO room visible whatsoever. The figure stands centred against \
this single solid colour field, like a portrait against a studio backdrop. \
No facial features visible — no eyes, no nose, no mouth, no skin tone — but the \
silhouette retains a painterly, hand-illustrated edge, not a flat paper cutout. \
The figure is clearly, unmistakably holding an old 1960 corded telephone: a chunky \
black handset receiver pressed against the ear, with a visible coiled cord trailing \
down out of frame. The figure's hand and fingers are clearly visible WRAPPING \
AROUND the handset — thumb on one side, fingers on the other, the arm bent at the \
elbow so the wrist meets the receiver. The act of gripping the phone must be \
unmistakable: this is a person holding a handset, not a handset hovering. \
Medium close-up framing, head-and-shoulders, the figure fills roughly 60% of the \
frame, the handset and cord clearly readable in the lower third. The figure's \
shoulders and torso continue off the bottom edge of the frame so the silhouette \
is anchored to the bottom, not floating in the middle. The cap, hat, hair, or \
other head feature described in the subject prose remains the dominant element \
of the upper half of the silhouette. \
A thin warm amber rim of light catches only the top-right edges of the figure as a \
stylised contour highlight — this is a lighting effect on the silhouette only, not \
a visible light source in the frame. \
${STYLE_TAIL}"
        ;;
    bg|background)
        WIDTH=1792
        HEIGHT=1024
        OUT_DIR="art/backgrounds"
        # Backgrounds: environments only. Explicitly NO people / silhouettes
        # / phone characters — those clauses would otherwise contaminate.
        PREAMBLE="\
An empty environmental scene. NO people anywhere in the frame, NO human figures, NO silhouettes of characters, NO hands holding phones. This is a setting, an architectural illustration, completely unpopulated. \
Wide landscape composition with strong negative space and a single clear focal point. \
${STYLE_TAIL}"
        ;;
    scene)
        WIDTH=1024
        HEIGHT=1024
        OUT_DIR="art/portraits"
        # Square environmental scenes (e.g. Margaret's empty rocking chair).
        # Same no-people clause as bg, but at portrait dimensions so the
        # image can sit inside the same CallerCard frame as the character
        # portraits.
        PREAMBLE="\
An empty environmental scene. NO people anywhere in the frame, NO human figures, NO silhouettes of characters, NO hands holding phones. This is a setting, an architectural illustration, completely unpopulated. \
Centered composition with strong negative space and a single clear focal point. \
${STYLE_TAIL}"
        ;;
    text|logo)
        WIDTH=1024
        HEIGHT=1024
        OUT_DIR="art"
        # Text-only: no character preamble, no environment preamble.
        # Just style tail to keep the painterly look + palette.
        PREAMBLE="\
A hand-lettered text-only illustration. NO figures, NO silhouettes, NO people, NO scenery, NO props, NO lamps — only hand-lettered text floating on a flat background. \
${STYLE_TAIL}"
        ;;
    *)
        echo "Unknown kind: $KIND (expected: portrait | bg | scene | text)" >&2
        exit 1
        ;;
esac

STYLE_PREAMBLE="$PREAMBLE"

PROMPT="${STYLE_PREAMBLE} Subject: ${SUBJECT}"

mkdir -p "$OUT_DIR"
OUT_PATH="${OUT_DIR}/${NAME}.png"

SEED_ARGS=()
if [[ -n "$SEED" ]]; then
    SEED_ARGS=(--seed "$SEED")
fi

# mflux refuses to overwrite an existing file and silently appends _1 to the
# stem (e.g. patty.png -> patty_1.png), which has historically caused us to
# review the wrong image. Always remove the target first so the new output
# lands at the requested name.
rm -f "$OUT_PATH"
rm -f "${OUT_PATH%.png}.metadata.json"

echo ">> Generating ${OUT_PATH} (${WIDTH}x${HEIGHT})"
# Using FLUX.2 klein 9B — significantly better prompt adherence than FLUX.1
# Schnell (renders described props like caps, glasses, phone cords). Non-
# commercial license; fine for game jam, swap to klein-4b for commercial use.
# ~2 min per image at q4 on M4 24GB.
mflux-generate-flux2 \
    --model flux2-klein-9b \
    --quantize 4 \
    --width "$WIDTH" \
    --height "$HEIGHT" \
    --prompt "$PROMPT" \
    --metadata \
    --output "$OUT_PATH" \
    "${SEED_ARGS[@]}"

echo ">> Done: $OUT_PATH"
