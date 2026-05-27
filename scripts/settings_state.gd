## Persisted player settings. Autoload as "SettingsState".
##
## Currently exposes a single accessibility toggle:
##   - manual_dialogue: when true, dialogue lines wait for the player to
##     press Space / Enter / click the caller card instead of auto-advancing
##     after the authored `DialogueLine.duration`.
##
## Settings are persisted to `user://settings.cfg` so the toggle survives
## scene changes, full game restarts, and (on web) browser reloads via
## Godot's IndexedDB-backed user:// filesystem.
extends Node

signal manual_dialogue_changed(value: bool)
signal use_system_cursor_changed(value: bool)

const _PATH := "user://settings.cfg"
const _SECTION := "accessibility"
const _KEY_MANUAL_DIALOGUE := "manual_dialogue"
const _KEY_USE_SYSTEM_CURSOR := "use_system_cursor"

var manual_dialogue: bool = false:
	set(value):
		if value == manual_dialogue:
			return
		manual_dialogue = value
		manual_dialogue_changed.emit(value)
		_save()

## When true, the custom themed cursor textures are bypassed in favour of
## the OS cursor. Provided as an accessibility opt-out (cursor scaling,
## high-contrast modes, screen-reader compatibility).
var use_system_cursor: bool = false:
	set(value):
		if value == use_system_cursor:
			return
		use_system_cursor = value
		use_system_cursor_changed.emit(value)
		_save()

func _ready() -> void:
	_load()

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_PATH) != OK:
		return
	# Bypass the setters so loading from disk doesn't trigger save round-trips.
	manual_dialogue = cfg.get_value(_SECTION, _KEY_MANUAL_DIALOGUE, false)
	use_system_cursor = cfg.get_value(_SECTION, _KEY_USE_SYSTEM_CURSOR, false)

func _save() -> void:
	var cfg := ConfigFile.new()
	# Reload first so we don't clobber unrelated keys written by future code.
	cfg.load(_PATH)
	cfg.set_value(_SECTION, _KEY_MANUAL_DIALOGUE, manual_dialogue)
	cfg.set_value(_SECTION, _KEY_USE_SYSTEM_CURSOR, use_system_cursor)
	cfg.save(_PATH)
