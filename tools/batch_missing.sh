#!/usr/bin/env bash
# Generate missing assets for Last Call.
# Usage: tools/batch_missing.sh

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

# 1) Good ending background — hospital window at dawn
run bg ending_good 801 \
"a small hospital room window seen from outside at the first amber light of dawn, through gauzy curtains two warm silhouettes are visible: a person resting in a hospital bed and a second figure leaning forward holding their hand, soft amber glow from inside spills out into the cold blue of pre-dawn, centered composition with strong negative space, hopeful but quiet and melancholic, no people visible in the foreground, no text"

# 2) Bad ending background — dark switchboard room
run bg ending_bad 802 \
"a 1960 telephone exchange operator's room at the end of a long night, the desk lamp is off, the switchboard panel sits dark and silent, a single cold thin shaft of teal moonlight cuts across the operator's empty chair and an untouched coffee cup gone cold on the desk, everything else falls into deep teal-black shadow, centered composition with strong negative space, mournful, no people, no text"

# 3) Margaret empty chair (Tier 3 stretch goal — optional).
# Uses the `scene` kind (1024x1024 + no-people preamble) so it sits inside
# the CallerCard frame at the same dimensions as a portrait but without
# the portrait preamble injecting a silhouette person holding a phone.
run scene margaret_empty_chair 803 \
"an empty wooden rocking chair in a darkened sitting room, on a small side table beside the chair a 1960 black corded telephone sits in its cradle with the cradle's small indicator lamp glowing a faint amber as if the phone is ringing into the empty room, deep teal shadows around the chair, centered composition with strong negative space, melancholic, no people, no text"

echo
echo ">> Missing assets batch complete."