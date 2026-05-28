## Menu-layer SFX playback. Autoload as "UiAudio".
##
## Plays optional WAV assets bundled under audio/sfx/. Both files are
## treated as optional — if they're missing on disk the playback methods
## no-op silently so the rest of the menu wiring (cursor changes, button
## visuals, toggle behaviour) keeps working until the curated samples
## are dropped in. No code change needed to "turn on" the audio later.
##
## Pitch shifting is done in-code rather than via additional assets:
##   - play_click()  plays ui_click.wav at 1.0x  (forward / confirm)
##   - play_back()   plays ui_click.wav at 0.85x (back / dismiss)
##   - play_toggle(on) plays ui_toggle.wav, pitched up for ON / down for OFF
##
## Kept separate from AudioManager because menu and gameplay audio sit
## in different mental buckets — best practice from the UI sound design
## research (group sounds by intent, not by file format).
extends Node

const CLICK_PATH := "res://audio/sfx/717365__1bob__click.wav"
const TOGGLE_PATH := "res://audio/sfx/ui_toggle.wav"

## Default playback volume — UI sits one tier below gameplay SFX in the
## project's loudness hierarchy (ring -4, plug/hangup -6, UI -12, music
## -14, bed -22). Standard best practice from game audio mixing guides
## (Audiokinetic, SFX Engine) is to keep UI clearly below in-world
## events so they read as confirmation, not as action.
const VOLUME_DB := -12.0

## Pitch ratios for the various sub-events. 0.85 is roughly two semitones
## down, 1.12 is roughly two up — both still recognisable as the same
## sample, but distinct enough to read as forward vs. back / on vs. off.
const PITCH_FORWARD := 1.0
const PITCH_BACK := 0.85
const PITCH_TOGGLE_ON := 1.12
const PITCH_TOGGLE_OFF := 0.88

var _click_stream: AudioStream
var _toggle_stream: AudioStream

func _ready() -> void:
	# Stay audible while the tree is paused — the pause overlay buttons
	# still need to thunk when clicked.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if ResourceLoader.exists(CLICK_PATH):
		_click_stream = load(CLICK_PATH)
	if ResourceLoader.exists(TOGGLE_PATH):
		_toggle_stream = load(TOGGLE_PATH)

func play_click() -> void:
	_play(_click_stream, PITCH_FORWARD)

func play_back() -> void:
	_play(_click_stream, PITCH_BACK)

func play_toggle(on: bool) -> void:
	var pitch := PITCH_TOGGLE_ON if on else PITCH_TOGGLE_OFF
	# Toggle prefers ui_toggle.wav but transparently falls back to the
	# click sample if only one of the two assets has been shipped.
	var stream: AudioStream = _toggle_stream if _toggle_stream else _click_stream
	_play(stream, pitch)

func _play(stream: AudioStream, pitch: float) -> void:
	if stream == null:
		return
	# Spawn a one-shot AudioStreamPlayer per call so overlapping presses
	# (rapid clicks, simultaneous hover-out + click) don't cut each other
	# off. Each player frees itself on `finished`.
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	# Routed through the dedicated "UI" bus so menu clicks have their
	# own slider and don't ride the gameplay SFX channel.
	player.bus = "UI"
	player.volume_db = VOLUME_DB
	player.pitch_scale = pitch
	player.finished.connect(player.queue_free)
	player.play()
