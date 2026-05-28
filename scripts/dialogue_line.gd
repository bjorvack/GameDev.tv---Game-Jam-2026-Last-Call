## One line of spoken dialogue inside a call (opening, post-connect, or wrong-
## routing response). Resources of this type are composed into Arrays inside
## CallData to make a call read like a real conversation.
class_name DialogueLine
extends Resource

## Display name of who's speaking. Empty string = narrator / SFX line shown
## without a speaker label (e.g. "(Ring. Ring. No answer.)").
@export var speaker: String = ""

## What is said — the text shown on the caller card. Keeps every
## authored reading cue: ellipses for breath catches, em-dashes for
## hesitation, repeated punctuation for escalating panic, parentheses
## for stage directions. Read by the player; not always the right
## thing to send straight to the TTS model — see `voice_text` below.
@export_multiline var text: String = ""

## Optional override of what the F5-TTS-MLX pipeline receives when
## generating the voice for this line. Leave empty for the common
## case — the pipeline will derive a TTS-friendly version from
## `text` via the auto-normalisation rules documented in
## audio/voice_refs/TODO.md (ellipses → commas, repeated punctuation
## → single, all-caps → sentence case, fully-parenthetical lines →
## skipped as stage directions, etc.).
##
## Set `voice_text` when the auto-normalisation isn't enough — e.g.
## "Operator… please." reads better at TTS time as "Operator,
## please." than as the auto-stripped "Operator please.". The
## display `text` stays untouched; the override only affects voice
## generation.
@export_multiline var voice_text: String = ""

## Optional portrait override. If unset, the CallerCard keeps the current
## portrait. Useful when a recipient picks up and the visual should switch
## from the caller's portrait to theirs.
@export var portrait: Texture2D

## Seconds to display this line before auto-advancing.
@export var duration: float = 2.5

## Optional emotional mood for the AI voice pipeline. If set, the TTS
## generator (tools/generate_voices.py) looks for a reference clip at
## `audio/voice_refs/<speaker_slug>/<mood>.wav`; otherwise it falls
## back to the speaker's "default" reference. Leaving this empty (or
## "default") is the normal case — only annotate lines whose delivery
## should clearly differ from the speaker's baseline (e.g. relieved,
## urgent, hesitant). See audio/voice_refs/README.md for the layout.
@export var mood: StringName = &""
