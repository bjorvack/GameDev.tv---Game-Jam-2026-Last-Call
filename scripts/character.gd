## A speaker in the game's dialogue. One Character resource per
## person who can appear in a CallData — Patty, Cole, Doc Wheeler,
## Sheriff Briggs, etc. — plus a few "anonymous" entries like the
## hesitant wrong-number voice ("???").
##
## Centralises everything the rest of the project needs to know about
## a speaker:
##   - Display data (name, portrait) used by the caller card UI.
##   - Casting context (gender, age, speaking_tone, description) kept
##     as authorial reference even though the runtime no longer uses
##     it to drive any voice/audio pipeline.
##
## DialogueLine.speaker matches against Character.name (or aliases),
## so consumers can look up the right Character for every line without
## each DialogueLine having to carry an explicit reference.
class_name Character
extends Resource

## Canonical display name. CallerCard reads this; DialogueLine.speaker
## must match this string (or one of `aliases`) for any consumer that
## wants to find the matching Character resource.
@export var name: String = ""

## Alternative names the speaker is referred to in dialogue data.
## Useful when call data was authored before the Character resource
## existed and a few lines use e.g. "Mrs. Patty" instead of "Patty".
@export var aliases: Array[StringName] = []

## Gender description — free-form so we don't lock into a closed set.
## Used as context when sourcing or auditioning a reference clip.
## Example: "female", "male, middle-aged", "non-binary".
@export var gender: String = ""

## Rough age band. String for flexibility ("early 30s", "60+").
@export var age: String = ""

## One-line tone descriptor — the casting director's note.
## Example: "warm, businesslike", "gruff, working-class".
@export var speaking_tone: String = ""

## Longer character backstory, motivations, mood baseline. Authorial
## context — not consumed by any runtime system.
@export_multiline var description: String = ""

## Portrait shown by the CallerCard. Same texture currently used in
## the call data — owning it here keeps the lookup single-source.
@export var portrait: Texture2D

## True when this Character's display name or any alias matches the
## given speaker string from a DialogueLine. The match is exact —
## case-sensitive — because DialogueLine.speaker is authored by hand
## and is expected to use the canonical form.
func matches_speaker(speaker: String) -> bool:
	if speaker == name:
		return true
	for alias in aliases:
		if speaker == String(alias):
			return true
	return false
