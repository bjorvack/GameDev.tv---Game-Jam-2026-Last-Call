# Voice reference sourcing TODO

One row per (character, mood) reference clip we need for the AI-voiced
dialogue layer. Each entry lists the call/line context that motivates
the mood, and tracks sourcing status.

Status legend:

- ☐ — needed, not yet sourced
- ✅ — sourced + transcript + wired into `data/characters/<slug>.tres`
- 💤 — deferred (low priority, default fallback covers it for now)

Beyond what F5-TTS-MLX can do (= clone *speech*), we also have a few
**non-verbal sounds** (breath catching, silence-with-emotion). Those
are tracked at the bottom — they ship as ordinary SFX, not through the
voice-cloning pipeline.

## Per-character mood references

### Daniel
Travelling salesman driving home; emotional spine of the run.

- ✅ **default** — composed son's check-in (call 02). Heflin 02:30
  ("I wonder why more people haven't thought of this…"). Voicing is
  clean at `--steps 32`; the reference's cold-narration prosody can
  bleed into casual lines — see Generation Params note below.
- ✅ **anxious** — worried, things turning bad (call 05, 07). Heflin
  13:30. Approved.
- ✅ **frantic** — desperate plea (call 07). Heflin 15:30. Approved.

### Patty
Diner owner; warm, businesslike. Caller in 01, recipient in 06 + 08.

- ☐ **default** — neutral diner answer / friendly request.
  Source target: 1960s mid-aged American woman, matter-of-fact.
- ☐ **worried** — call 06 ("Hasn't been in today, Sheriff." with the
  weight of dawning concern) and call 08 ("Lord, he doesn't know yet.").

### Cole
Garage mechanic; gruff working-class. Recipient in 01, caller in 08.

- ☐ **default** — one-word answer + clipped acknowledgement
  ("Cole's." / "Yep, I'll be over in twenty.").
- ☐ **concerned** — call 08 ("Anyone heard from Daniel?" + relaying
  what he saw at Margaret's house). Quieter, troubled.

### Doc Wheeler
Town doctor; weary professional.

- ☐ **default** — surname answer + brief clinical response ("Wheeler."
  / "On my way, Reverend.").
- ☐ **grave** — call 05 telling Daniel his mother's condition has
  turned. Slow, picks every word.

### Reverend Carter
Pastor with the pivotal late-game routing.

- ☐ **default** — calm pastoral cadence; surname answer + steady
  reassurance ("Carter." / "I'm leaving now, son.").
- ☐ **urgent** — call 04 ("Doc — Mr. Bray's taken a turn") and call 09
  flagging the trucker ("Need your help, quick.").

### Sheriff Briggs
Town sheriff; authoritative, tired.

- ☐ **default** — surname answer + dispatching ("Briggs." / "I know,
  Mrs. Henley. We're on it.").
- ☐ **shocked** — call 06 closing beats ("…" then "Oh god."). Quiet,
  the moment the picture clicks together.

### Mrs. Henley
Anxious neighbour on 8th Street.

- ☐ **default** — her sole register is anxious-but-controlled,
  so the default IS the worried tone. Single ref covers it.

### Nurse
County General reception; final beat of the game.

- ☐ **default** — calm professional answer ("County General." /
  "Mr. Hayes? She's awake. She's been asking for you."). Warmth has
  to land — this line carries the ending.

### Trucker
Anonymous Highway 40 booth pickup.

- ☐ **default** — rough, road-weary, helpful. One short exchange,
  one ref covers it ("Yeah? Hello?" / "On it, Reverend.").

### ??? (wrong-number recipient)
Hesitant stranger answering a misrouted call.

- ☐ **default** — single soft "Hello?" baseline. Appears in many
  calls as the wrong-number stub. One ref covers all instances.

### Mrs. Bray
One line in call 04 only.

- ☐ **default** — startled "Hello?" from her kitchen. Could share
  the ??? reference if we don't want a distinct voice; otherwise one
  bespoke ref.

### Operator
Player character; only speaks in inter-call inner monologues.

- ☐ **default** — contemplative baseline. Hushed, present-tense.
- ☐ **puzzled** — early calls noticing something off
  ("Margaret Hayes. Her line never rings out like that.").
- ☐ **anxious** — mid-story when she can't reach Margaret;
  also the `timer_expired_thought` source on failed calls.
- ☐ **devastated** — bad-ending monologues.
- ☐ **relieved** — call 10 wrap, the board going dark light by light.

## Non-verbal sounds

Tracked here so they're not forgotten — these are **plain SFX clips**
played through the SFX channel at the right moment in `caller_card`,
not voice references for F5-TTS-MLX.

- ☐ **daniel_breath_catch** — call 10 stage direction
  *"(Daniel's breath catches. The line goes warm with quiet.)"*. ~1–3 s
  audible exhale / breath catch, same voice as Daniel's spoken refs
  (Heflin) so the line goes warm with quiet. Stored under
  `audio/sfx/breaths/` once sourced.

## Quick stats

- **Total references needed (speech):** ~22
- **Sourced so far:** 3 (Daniel default re-clipped to 02:30, plus
  anxious + frantic — all three green-light)
- **Distinct voice actors / sources to find:** ~10 (one per
  character, plus a non-verbal breath for Daniel)

## Generation params (lessons learnt)

Notes for the eventual `tools/generate_voices.py` pipeline so we
don't re-derive these on every character:

- **`--steps 32 --method euler`** is the sweet spot. The library
  default (~8 steps) is noticeably hoarse; jumping to 32 cleans
  it up cleanly. `midpoint` at 32 is barely audibly different
  from `euler` at 32 but ~2× slower, so stick with euler.
- **Prosody comes from the reference, not the text.** A clip of
  cold methodical narration will impose cold methodical tempo on
  any line you generate, even cheerful sign-offs. When a line's
  text doesn't fit the reference's energy, the result feels
  off-beat — the fix is a better reference for that mood, not
  prompt engineering.
- **Reference length:** the F5-TTS-MLX README says 5–10 s; in
  practice 8 s clips are working well. Longer probably helps
  for prosody capture but slows generation; revisit if a
  specific clip keeps producing wobbly output.
- **HF auth:** `~/.cache/huggingface/token` set; suppresses the
  rate-limit warnings on cold cache pulls.
