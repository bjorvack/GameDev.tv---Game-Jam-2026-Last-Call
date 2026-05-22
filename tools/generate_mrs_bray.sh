#!/usr/bin/env bash
# One-off Mrs. Bray generation.
#
# Lives outside tools/generate_sprite.sh because the current portrait
# preamble in that script has accumulated constraints ("WRAPPING AROUND",
# "shoulders anchored to bottom", "head feature dominant") that
# collapse the female-elderly latent direction at FLUX.2 klein 9B
# inference time — every attempt with the new preamble produced a young
# male silhouette regardless of subject wording or seed.
#
# This script uses a leaner preamble (closer to the Tier 2 era that
# produced Henley + Patty correctly) plus an explicit "uniform flat
# black, no interior detail" clause so the silhouette stays a solid
# mass like the rest of the cast. Seed 808 + the body subject produces
# the desired profile + soft hair + phone-in-hand.
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_PATH="art/portraits/mrs_bray.png"
rm -f "$OUT_PATH"

STYLE_TAIL="Hand-illustrated graphic poster in the style of Olly Moss alternate-movie-poster art and Eyvind Earle — bold, cinematic, moody. Flat fields of colour, screen-print grain, no photorealism, no 3D rendering. Strict palette: deep teal night #0F2A33 background, mid teal shadow #173E4A, warm wood brown #5A3A22, amber lamp light #E8B86A, bone-paper #F1E4C8 only for any text, aged red #C14B4B reserved for telephone cables only, mint #7AAE9A for tiny indicator lamps only. Exactly one warm amber light source from the upper right."

PREAMBLE="A pure dark silhouette of a single person rendered as a 100% solid pitch-black shape against a completely plain, flat, uniform deep teal #0F2A33 background. THE ENTIRE FIGURE — HEAD, HAIR, ANY HAT OR CAP, BODY, ARMS, CLOTHING — IS RENDERED AS UNIFORM FLAT BLACK with NO interior shading, NO lighter values inside the silhouette, NO visible hair colour, NO visible fabric texture inside the shape, NO grey or beige patches anywhere within the figure. The silhouette is a single flat black mass. The background is empty — NO lamps, NO lampposts, NO sconces, NO candles, NO windows, NO furniture, NO scenery, NO decorations, NO props, NO architectural details, NO sky, NO stars, NO moon, NO trees, NO room visible whatsoever. The figure floats on a single solid colour field, like a portrait against a studio backdrop. No facial features visible — no eyes, no nose, no mouth, no skin tone. The figure holds an old corded telephone handset pressed to her ear, the chunky receiver visible in profile as a small distinct shape against her face, the coiled cord trailing down out of frame. Medium close-up framing, head-and-shoulders, the figure fills roughly 60% of the frame. A thin warm amber rim of light catches only the top-right edges of the figure as a stylised contour highlight — this is a lighting effect on the silhouette only, not a visible light source in the frame. ${STYLE_TAIL}"

SUBJECT="an ELDERLY SOFT-SHOULDERED WOMAN in profile, her grey hair tucked under a SOFT FRILLED HAIRNET visible as a finely textured rounded shape covering the top of her head (the hairnet creates a distinct soft bumpy silhouette across her crown — clearly fabric, not bare hair), a FLORAL HOUSE APRON tied at her thick waist with the silhouetted apron-strings dangling behind her hip. Posture gentle and round. She holds a SINGLE black telephone handset receiver in ONE HAND, pressed firmly to her ear — only ONE phone, ONE coiled cord trailing down. Her free hand holds a small porcelain TEACUP at chest height."

PROMPT="${PREAMBLE} Subject: ${SUBJECT}"

mflux-generate-flux2 --model flux2-klein-9b --quantize 4 --width 1024 --height 1024 --prompt "$PROMPT" --seed 808 --metadata --output "$OUT_PATH"
