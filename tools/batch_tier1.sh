#!/usr/bin/env bash
# Generate all Tier 1 sprites in one run. See docs/SPRITE_SPEC.md.
#
# Per-character seeds so each image gets a different latent — same seed
# across the batch produced déjà-vu compositions last time.
#
# Usage:  tools/batch_tier1.sh

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

# Switchboard background is intentionally NOT regenerated — switchboard_v2
# was hand-picked as the keeper. Re-run manually if you ever want to revisit.

# Daniel is also locked — FLUX.2 klein 9B nailed him on seed 202. Re-run
# manually if you ever want to revisit:
#   tools/generate_sprite.sh portrait daniel "<prose>" 202

# 3) Patty — diner waitress
run portrait patty 303 \
"a middle-aged round-shouldered woman in profile, her hair tied up in a kerchief at the crown of her head with the silhouetted ties of an apron dangling behind her shoulder, holding the 1985 black corded telephone receiver to her ear with one hand. Her free hand holds a small glass coffee pot."

# 4) Reverend — clergy
run portrait reverend 404 \
"a tall older man in profile, the broad brim of a wide hat held in his free hand at chest height (so the hat-brim shape is visible against his torso silhouette), the bright slit of a white clerical collar visible at his throat as a thin lighter notch in the otherwise solid black silhouette. The 1985 black corded telephone receiver is pressed to his ear."

# 5) Doc — physician
run portrait doc 505 \
"a stocky older man in profile, his shape defined by a buttoned waistcoat and a small bow tie silhouette at his throat. Two tiny round wire-frame glasses sit at his profile as small ring shapes. The 1985 black corded telephone receiver is pressed to his ear."

# 6) Title background — empty switchboard room
run bg title 606 \
"a 1985 telephone exchange operator's room at night viewed from across the room, completely empty of people, an unattended switchboard panel of brass and dark walnut glows under a single amber desk lamp from the upper right, the operator's wooden chair is empty and pushed slightly back, a heavy coat hangs on a wall hook to one side, deep teal shadow fills the rest, no people anywhere in the frame, no text, no signage"

# 7) Title logo — hand-lettered text only (writes directly to art/)
run text title_logo 707 \
"The large title 'Last Call' in imperfect weathered 1940s-style serif lettering, warm bone-white #F1E4C8. Below it, in much smaller hand-lettered text, the subtitle 'a story in ten calls'. Centered on a flat deep teal #0F2A33 background, no other elements."

echo
echo ">> Tier 1 batch complete."
