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
## for stage directions.
@export_multiline var text: String = ""

## Optional portrait override. If unset, the CallerCard keeps the current
## portrait. Useful when a recipient picks up and the visual should switch
## from the caller's portrait to theirs.
@export var portrait: Texture2D

## Seconds to display this line before auto-advancing.
@export var duration: float = 2.5

## Optional emotional mood annotation, retained as an authorial note
## now that the voice pipeline has been removed. No runtime system
## currently reads it, but values like &"relieved" / &"urgent" /
## &"hesitant" remain useful editorial breadcrumbs for re-recording or
## re-introducing a voice pass later.
@export var mood: StringName = &""
