## One line of spoken dialogue inside a call (opening, post-connect, or wrong-
## routing response). Resources of this type are composed into Arrays inside
## CallData to make a call read like a real conversation.
class_name DialogueLine
extends Resource

## Display name of who's speaking. Empty string = narrator / SFX line shown
## without a speaker label (e.g. "(Ring. Ring. No answer.)").
@export var speaker: String = ""

## What is said. Supports multi-line via newlines.
@export_multiline var text: String = ""

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
