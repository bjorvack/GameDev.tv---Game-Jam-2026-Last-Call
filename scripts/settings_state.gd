## Persisted player settings. Autoload as "SettingsState".
##
## Exposes accessibility toggles and per-bus volume controls:
##   - manual_dialogue: when true, dialogue lines wait for the player to
##     press Space / Enter / click the caller card instead of auto-advancing
##     after the authored `DialogueLine.duration`.
##   - use_system_cursor: bypass the custom themed cursor.
##   - master/music/sfx/voice/ui volume (0.0..1.0): linear-perception
##     gain applied to the matching audio bus via AudioServer. The mapping
##     to dB is volume_to_db() — linear² for a smoother slider feel — with
##     0.0 hard-muting the bus and 1.0 leaving it at its layout baseline.
##
## Settings are persisted to `user://settings.cfg` so the toggle survives
## scene changes, full game restarts, and (on web) browser reloads via
## Godot's IndexedDB-backed user:// filesystem.
extends Node

signal manual_dialogue_changed(value: bool)
signal use_system_cursor_changed(value: bool)
signal volume_changed(bus: StringName, value: float)

const _PATH := "user://settings.cfg"
const _SECTION := "accessibility"
const _SECTION_AUDIO := "audio"
const _KEY_MANUAL_DIALOGUE := "manual_dialogue"
const _KEY_USE_SYSTEM_CURSOR := "use_system_cursor"

## Buses exposed to the settings panel. Order = display order in the UI.
const BUSES: Array[StringName] = [
	&"Master", &"Music", &"SFX", &"Voice", &"UI",
]

## Default starting volume per bus (0..1). Master sits at 100%; music
## defaults a notch below the rest so dialogue and SFX read clearly over
## the score on first launch. Users can rebalance from the settings page.
const _DEFAULTS: Dictionary = {
	&"Master": 0.9,
	&"Music": 0.7,
	&"SFX": 0.9,
	# Default-muted until the player explicitly enables dialogue audio.
	# The AI-generated voice takes are still pre-production; shipping
	# them off-by-default keeps the first-play experience grounded in
	# the on-card text. Players can raise the slider any time from the
	# Audio tab.
	&"Voice": 0.0,
	&"UI": 0.8,
}

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

## Current 0..1 volume per bus name. Mutated via `set_volume()` so the
## AudioServer is kept in sync and persisted in one place.
var _volumes: Dictionary = {}

func _ready() -> void:
	# Seed defaults so a missing user://settings.cfg still produces a
	# coherent mix on first launch.
	for bus_name in BUSES:
		_volumes[bus_name] = _DEFAULTS.get(bus_name, 1.0)
	_load()
	# Push everything to AudioServer once the autoloads are all up; we
	# defer one frame so the bus layout has definitely been parsed.
	call_deferred("_apply_all")

## Returns the current 0..1 volume for the given bus name. Falls back to
## the default if the bus isn't tracked (defensive — keeps the slider UI
## from crashing if buses get renamed without a migration).
func get_volume(bus_name: StringName) -> float:
	return _volumes.get(bus_name, _DEFAULTS.get(bus_name, 1.0))

## Set the 0..1 volume for `bus_name`. Applies immediately to the
## AudioServer (so sliders respond in real time), emits `volume_changed`,
## and persists to disk.
func set_volume(bus_name: StringName, value: float) -> void:
	var clamped := clampf(value, 0.0, 1.0)
	if is_equal_approx(_volumes.get(bus_name, -1.0), clamped):
		return
	_volumes[bus_name] = clamped
	_apply(bus_name, clamped)
	volume_changed.emit(bus_name, clamped)
	_save()

## Restore every audio bus to its baseline volume (see _DEFAULTS). Each
## bus is routed through `set_volume` so the AudioServer, the change
## signal, and the persisted config file all stay in sync — the settings
## panel just needs to re-read the values after this call.
func reset_volumes() -> void:
	for bus_name in BUSES:
		var default_value: float = _DEFAULTS.get(bus_name, 1.0)
		set_volume(bus_name, default_value)

func _apply(bus_name: StringName, value: float) -> void:
	var idx := AudioServer.get_bus_index(String(bus_name))
	if idx == -1:
		return
	# Hard-mute the bus at 0 — feeding -inf dB into volume_db produces a
	# crackle on some platforms, so we use AudioServer.set_bus_mute()
	# instead for the zero case and keep the dB curve smooth otherwise.
	if value <= 0.0:
		AudioServer.set_bus_mute(idx, true)
		return
	AudioServer.set_bus_mute(idx, false)
	# linear_to_db is perceptually linear-ish at the top of the slider
	# (1.0 = 0 dB) and falls quickly at the bottom (0.1 ≈ -20 dB).
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _apply_all() -> void:
	for bus_name in BUSES:
		_apply(bus_name, _volumes[bus_name])

func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_PATH) != OK:
		return
	# Bypass the setters so loading from disk doesn't trigger save round-trips.
	manual_dialogue = cfg.get_value(_SECTION, _KEY_MANUAL_DIALOGUE, false)
	use_system_cursor = cfg.get_value(_SECTION, _KEY_USE_SYSTEM_CURSOR, false)
	for bus_name in BUSES:
		var key := String(bus_name).to_lower() + "_volume"
		var default_value: float = _DEFAULTS.get(bus_name, 1.0)
		_volumes[bus_name] = float(cfg.get_value(_SECTION_AUDIO, key, default_value))

func _save() -> void:
	var cfg := ConfigFile.new()
	# Reload first so we don't clobber unrelated keys written by future code.
	cfg.load(_PATH)
	cfg.set_value(_SECTION, _KEY_MANUAL_DIALOGUE, manual_dialogue)
	cfg.set_value(_SECTION, _KEY_USE_SYSTEM_CURSOR, use_system_cursor)
	for bus_name in BUSES:
		var key := String(bus_name).to_lower() + "_volume"
		cfg.set_value(_SECTION_AUDIO, key, _volumes.get(bus_name, 1.0))
	cfg.save(_PATH)
