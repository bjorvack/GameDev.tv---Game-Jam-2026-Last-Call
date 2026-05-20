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
