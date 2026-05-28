## Maps DialogueLines to their pre-generated AI voice clips, when one
## exists. Autoload as "VoiceResolver".
##
## Single public method: `resolve(line)` returns the AudioStream the
## CallDirector should hand to CallerCard.play_line — or null when no
## voice was generated for that line (e.g. characters whose references
## aren't yet sourced, stage directions, or lines added after the last
## generation pass). Callers don't need to error-check; null just
## means "no voice, fall back to silent display".
##
## File convention
## ===============
## Each generated clip lives at:
##
##     res://audio/dialogue/<slug>/<call_num>_<sub_resource_id>.wav
##
## where:
##   - <slug>             — the Character resource's filename stem
##                          (e.g. "daniel" from "daniel.tres")
##   - <call_num>          — the two-digit prefix of the call's .tres
##                          filename ("02" from "02_daniel_hayes.tres")
##   - <sub_resource_id>   — the DialogueLine's sub_resource id within
##                          its parent .tres ("connected_1")
##
## Both <call_num> and <sub_resource_id> come from DialogueLine
## .resource_path which Godot formats as
## "res://data/calls/<file>.tres::<sub_id>" — no extra authoring
## required to make the mapping work.
##
## The character roster is loaded once at _ready and indexed by
## speaker name + every alias from Character.aliases, so a
## DialogueLine.speaker = "Daniel Hayes" resolves the same as
## "Daniel" and both point at "daniel.tres".
extends Node

const CHAR_DIR := "res://data/characters/"
const VOICE_DIR := "res://audio/dialogue/"
const VOICE_EXT := ".wav"

# speaker String → [Character, slug:String]
var _by_speaker: Dictionary = {}

func _ready() -> void:
	_load_character_roster()

func _load_character_roster() -> void:
	var dir := DirAccess.open(CHAR_DIR)
	if dir == null:
		push_warning("VoiceResolver: %s not found; voice lookups will all miss." % CHAR_DIR)
		return
	dir.list_dir_begin()
	while true:
		var f := dir.get_next()
		if f == "":
			break
		if not f.ends_with(".tres"):
			continue
		var c: Character = load(CHAR_DIR + f) as Character
		if c == null:
			continue
		var slug := f.get_basename()
		_index_character(c, slug)
	dir.list_dir_end()

func _index_character(c: Character, slug: String) -> void:
	if c.name != "":
		_by_speaker[c.name] = [c, slug]
	# Aliases let "Daniel Hayes" / "Reverend" / "Sheriff" map the same
	# way the formal name does — see Character.matches_speaker().
	for alias in c.aliases:
		_by_speaker[String(alias)] = [c, slug]

## Returns the pre-generated voice clip for a given DialogueLine, or
## null when no clip is available. Callers should treat null as
## "play this line silently" and rely on CallerCard's existing
## timer fallback.
func resolve(line: DialogueLine) -> AudioStream:
	if line == null:
		return null
	var entry = _by_speaker.get(line.speaker)
	if entry == null:
		return null
	var slug: String = entry[1]
	var line_id := _line_id(line)
	if line_id == "":
		return null
	var path := "%s%s/%s%s" % [VOICE_DIR, slug, line_id, VOICE_EXT]
	if not ResourceLoader.exists(path):
		return null
	return load(path) as AudioStream

## Derive "<call_num>_<sub_resource_id>" from a DialogueLine's
## resource_path. The path format Godot uses is
## "res://data/calls/<filename>.tres::<sub_id>" — we split on "::"
## for the sub id and pull the leading digits of the filename for
## the call number.
func _line_id(line: DialogueLine) -> String:
	var path: String = line.resource_path
	if path == "":
		return ""
	var parts := path.split("::")
	if parts.size() != 2:
		return ""
	var sub_id: String = parts[1]
	var basename: String = parts[0].get_file().get_basename()
	var first_underscore := basename.find("_")
	if first_underscore <= 0:
		return ""
	var call_num := basename.substr(0, first_underscore)
	return "%s_%s" % [call_num, sub_id]
