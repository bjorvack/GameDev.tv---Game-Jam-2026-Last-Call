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
## Hardcoded roster slugs. Used as a fallback when DirAccess listing of
## `res://data/characters/` returns nothing (exported PCKs, particularly
## the web build, have historically been flaky here — see the .remap
## branch in _load_character_roster). Keeping the list in code is fine
## since adding a new character already requires touching code anyway.
const KNOWN_CHARACTER_SLUGS: Array[String] = [
	"cole", "daniel", "doc", "henley", "mrs_bray", "nurse",
	"operator", "patty", "reverend", "sheriff", "trucker", "unknown",
]
const VOICE_DIR := "res://audio/dialogue/"
# Mood-enhanced takes from the CosyVoice 2 pass live in parallel under
# audio/dialogue_enhanced/<slug>/<id>.wav. We check the enhanced tree
# first per line; if no enhanced clip exists we fall back to the
# baseline Qwen3 take. Lets us A/B per-line and ship a mix.
const VOICE_DIR_ENHANCED := "res://audio/dialogue_enhanced/"
const VOICE_EXT := ".wav"

# speaker String → [Character, slug:String]
var _by_speaker: Dictionary = {}

func _ready() -> void:
	_load_character_roster()

func _load_character_roster() -> void:
	# Try DirAccess first so any new character.tres dropped into the
	# folder picks up automatically during editor / desktop play.
	var dir := DirAccess.open(CHAR_DIR)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var f := dir.get_next()
			if f == "":
				break
			# In exported PCKs (notably the web build) Godot renames
			# .tres resources to <name>.tres.remap virtual entries.
			# Accept both — load() transparently follows the remap
			# regardless of which name we pass it.
			var tres_name := ""
			if f.ends_with(".tres"):
				tres_name = f
			elif f.ends_with(".tres.remap"):
				tres_name = f.substr(0, f.length() - ".remap".length())
			else:
				continue
			var c: Character = load(CHAR_DIR + tres_name) as Character
			if c == null:
				continue
			var slug := tres_name.get_basename()
			_index_character(c, slug)
		dir.list_dir_end()
	# Then unconditionally walk the hardcoded slug list. _index_character
	# is idempotent (same key → same data), so this is a safe belt-and-
	# braces fallback for whenever DirAccess listing comes back empty
	# inside a PCK — which is what was happening in the web build.
	for slug in KNOWN_CHARACTER_SLUGS:
		var path := CHAR_DIR + slug + ".tres"
		if not ResourceLoader.exists(path):
			continue
		var c: Character = load(path) as Character
		if c == null:
			continue
		_index_character(c, slug)
	print("[VoiceResolver] roster indexed: %d speaker keys" % _by_speaker.size())

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
## When true, log the first miss for each unique speaker/path so we can
## diagnose web-build asset issues from the browser console without
## drowning the editor in print spam. Flipped off automatically once
## every miss has been reported once.
var _diagnostic_seen: Dictionary = {}

func resolve(line: DialogueLine) -> AudioStream:
	if line == null:
		return null
	var entry = _by_speaker.get(line.speaker)
	if entry == null:
		_diag_once("speaker:" + str(line.speaker), "no speaker entry for '%s'" % line.speaker)
		return null
	var slug: String = entry[1]
	var line_id := _line_id(line)
	if line_id == "":
		_diag_once("lineid:" + str(line.resource_path), "no line_id for %s" % line.resource_path)
		return null
	var enhanced := "%s%s/%s%s" % [VOICE_DIR_ENHANCED, slug, line_id, VOICE_EXT]
	if ResourceLoader.exists(enhanced):
		return load(enhanced) as AudioStream
	var path := "%s%s/%s%s" % [VOICE_DIR, slug, line_id, VOICE_EXT]
	if not ResourceLoader.exists(path):
		_diag_once("clip:" + path, "no clip at %s" % path)
		return null
	return load(path) as AudioStream

func _diag_once(key: String, msg: String) -> void:
	if _diagnostic_seen.has(key):
		return
	_diagnostic_seen[key] = true
	print("[VoiceResolver] miss: ", msg)

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
