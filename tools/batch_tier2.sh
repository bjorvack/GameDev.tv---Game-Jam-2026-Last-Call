#!/usr/bin/env bash
# Generate Tier 2 sprites — secondary character portraits. See docs/SPRITE_SPEC.md.
# Per-character locked seeds, single-phone emphasis (Daniel's "two phones"
# problem was the lesson), distinctive silhouette feature called out up front.
#
# Usage:  tools/batch_tier2.sh

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
GEN="$HERE/generate_sprite.sh"

run() {
    local kind="$1" name="$2" seed="$3" subject="$4"
    echo
    echo "============================================================"
    echo "  $name  ($kind, seed $seed)"
    echo "============================================================"
    "$GEN" "$kind" "$name" "$subject" "$seed"
}

# 1) Mrs. Henley — elderly woman peering out a window
run portrait henley 808 \
"an ELDERLY THIN-SHOULDERED WOMAN in profile, her hair pulled into a TIGHT BUN at the back of her head (the bun shape is a clear small round bump on the silhouette of her head), a LACE COLLAR at her throat reading as small bright bumps along the neckline of her dress. Shoulders narrow and a little stooped. She holds a SINGLE black telephone handset receiver in ONE HAND, pressed firmly to her ear — only ONE phone, ONE coiled cord trailing down. Her other hand hangs at her side, empty."

# 2) Sheriff Briggs — wide-brim hat, badge glint
run portrait sheriff 909 \
"a STOCKY MAN slightly turned toward the viewer (three-quarter view rather than pure profile), wearing a WIDE FLAT-BRIMMED COWBOY HAT (the wide flat brim is the most defining silhouette feature on his head, jutting out symmetrically on both sides). A TINY BRIGHT AMBER GLINT on his chest marks the silhouetted shape of a SHERIFF'S STAR BADGE on the lapel of a buttoned uniform shirt. He holds a SINGLE black telephone handset receiver in ONE HAND, pressed firmly to his ear — only ONE phone, ONE coiled cord trailing down. His other hand hangs at his side, empty."

# 3) Cole — backwards ball cap, wrench, greasy rag
run portrait cole 110 \
"a WIRY YOUNGER MAN in profile, wearing a BASEBALL CAP TURNED BACKWARDS (the rounded back of the cap with the closure strap visible on the back of his head, the curved brim sticking out the back rather than the front — clearly worn the wrong way around). The silhouette of an OILY RAG drapes over one of his shoulders, and the curved silhouette of a WRENCH HANDLE pokes out of his back pocket. He holds a SINGLE black telephone handset receiver in ONE HAND, pressed firmly to his ear — only ONE phone, ONE coiled cord trailing down. His other hand hangs at his side, empty."

# 4) Nurse — uniform cap with small cross
run portrait nurse 211 \
"a YOUNG WOMAN in profile, wearing a 1980s NURSE'S CAP with a small CROSS SYMBOL visible on its crown (the cap is a small flat shape perched on top of her head, distinct from a hat — clearly medical), her hair pulled back tight against her head. Posture stiff and professional. She holds a SINGLE black telephone handset receiver in ONE HAND, pressed firmly to her ear — only ONE phone, ONE coiled cord trailing down. Her other hand hangs at her side, empty. Beneath her chin the silhouette of a starched uniform collar."

# 5) Unknown — featureless wrong-number recipient
run portrait unknown 312 \
"a GENERIC FEATURELESS PERSON-SHAPE — just the silhouette of a head and one shoulder with absolutely no distinguishing features: no hat, no glasses, no hair detail, no clothing detail. Plain, unadorned, almost absent. They hold a SINGLE black telephone handset receiver in ONE HAND, pressed firmly to where their ear would be — only ONE phone, ONE coiled cord trailing down. Their other hand hangs at their side. Completely anonymous, deliberately characterless."

echo
echo ">> Tier 2 batch complete."
