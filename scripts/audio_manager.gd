## Global audio manager. Autoload as "AudioManager".
##
## Owns four AudioStreamPlayers — Music (foreground melody), MusicBed
## (ambient layer), Ring, and SFX — and exposes simple play/stop helpers
## per event. Streams are loaded by path so authoring new sounds is just
## dropping a file in audio/sfx or audio/music and adding a constant below.
##
## Lifecycle logs:
## When AUDIO_LOG is true, every start / loop / stop emits a [Audio] line
## with the player name and the file basename so you can audit the score
## from the console while play-testing.
extends Node

const AUDIO_LOG := true
const LOG_PREFIX := "[Audio]"

const RING_PATH := "res://audio/sfx/275053__cvp1965__old-phone-ringing (1).wav"
const PLUG_PATH := "res://audio/sfx/477641__joao_janz__power-cord-unplug-1_2.wav"
const HANGUP_PATH := "res://audio/sfx/531060__haleyreesecalhoun__sneaky-phone-put-down-hrc.wav"

const MUSIC_PATHS: Dictionary = {
	"contemplative": "res://audio/music/839571__cvltiv8r__contemplative-string-loop-violin-and-cello.wav",
	"noise": "res://audio/music/197795__yuval__soundtrack-noise-1940s.wav",
}
## Default two-layer score: a quiet ambient room-tone bed + a slow melodic
## foreground that loops over it. Both start when play_music_bed() is called
## and persist across scene changes because AudioManager is an autoload.
const MUSIC_FG := "contemplative"
const MUSIC_BG := "noise"

const MUSIC_VOLUME_DB := -14.0
const MUSIC_BED_VOLUME_DB := -22.0
const RING_VOLUME_DB := -4.0
const SFX_VOLUME_DB := -6.0
## Cap on how long a single ringback one-shot may play. The cvp1965 ring
## sample is ~20 s, but for the post-route "recipient picks up" beat we only
## want one short chirp before the connected dialogue starts.
const RING_ONCE_MAX_DURATION := 1.5

@onready var music_player: AudioStreamPlayer = $Music
@onready var music_bed_player: AudioStreamPlayer = $MusicBed
@onready var ring_player: AudioStreamPlayer = $Ring
@onready var sfx_player: AudioStreamPlayer = $SFX

var _ring_stream: AudioStream
var _plug_stream: AudioStream
var _hangup_stream: AudioStream
var _ringing: bool = false

func _ready() -> void:
	_ring_stream = load(RING_PATH)
	_plug_stream = load(PLUG_PATH)
	_hangup_stream = load(HANGUP_PATH)
	music_player.volume_db = MUSIC_VOLUME_DB
	music_bed_player.volume_db = MUSIC_BED_VOLUME_DB
	ring_player.volume_db = RING_VOLUME_DB
	sfx_player.volume_db = SFX_VOLUME_DB
	# Manual loop for music + ring — reliable across WAV/MP3/OGG formats.
	music_player.finished.connect(_replay_music)
	music_bed_player.finished.connect(_replay_music_bed)
	ring_player.finished.connect(_replay_ring)

# -- ring ---------------------------------------------------------------------

## Start the ring sample looping. Repeats `_ring_stream` until `stop_ring()`
## flips `_ringing` back off.
func play_ring() -> void:
	if _ring_stream == null:
		return
	_ringing = true
	ring_player.stream = _ring_stream
	_log("ring", "start (looping)", _ring_stream)
	ring_player.play()

func stop_ring() -> void:
	if _ringing or ring_player.playing:
		_log("ring", "stop", _ring_stream)
	_ringing = false
	ring_player.stop()

## Awaitable single-shot ringback. Plays the ring sample but caps the wait
## at RING_ONCE_MAX_DURATION — the source sample is ~20 s but the post-route
## "recipient picks up" beat only wants one short chirp before the connected
## dialogue starts. If the sample is still playing when the cap expires we
## stop it explicitly.
func play_ring_once() -> void:
	if _ring_stream == null:
		return
	# Make sure the loop flag is off so _replay_ring won't sneak another play
	# in once this sample finishes.
	_ringing = false
	ring_player.stream = _ring_stream
	_log("ring", "one-shot", _ring_stream)
	ring_player.play()
	await get_tree().create_timer(RING_ONCE_MAX_DURATION).timeout
	if ring_player.playing:
		_log("ring", "one-shot cut", _ring_stream)
		ring_player.stop()

func _replay_ring() -> void:
	# Only re-arm while we're still in a RINGING phase.
	if not _ringing or _ring_stream == null:
		return
	_log("ring", "loop", _ring_stream)
	ring_player.play()

# -- sfx ----------------------------------------------------------------------

func play_plug() -> void:
	if _plug_stream == null:
		return
	sfx_player.stream = _plug_stream
	_log("sfx", "plug", _plug_stream)
	sfx_player.play()

func play_hangup() -> void:
	if _hangup_stream == null:
		return
	sfx_player.stream = _hangup_stream
	_log("sfx", "hangup", _hangup_stream)
	sfx_player.play()

# -- music --------------------------------------------------------------------

func play_music(track: StringName = &"contemplative") -> void:
	var key := String(track)
	if not MUSIC_PATHS.has(key):
		return
	var stream := load(MUSIC_PATHS[key]) as AudioStream
	if stream == null:
		return
	music_player.stream = stream
	_log("music", "start", stream)
	music_player.play()

func stop_music() -> void:
	if music_player.playing:
		_log("music", "stop", music_player.stream)
	music_player.stop()

func _replay_music() -> void:
	if music_player.stream != null:
		_log("music", "loop", music_player.stream)
		music_player.play()

## Starts the two-layer score (foreground melody + ambient bed) and loops
## both indefinitely. Idempotent — calling twice from successive scene
## _ready hooks is safe.
func play_music_bed() -> void:
	var fg_stream := load(MUSIC_PATHS[MUSIC_FG]) as AudioStream
	var bg_stream := load(MUSIC_PATHS[MUSIC_BG]) as AudioStream
	if fg_stream and music_player.stream != fg_stream:
		music_player.stream = fg_stream
		_log("music", "start", fg_stream)
		music_player.play()
	elif fg_stream and not music_player.playing:
		_log("music", "resume", fg_stream)
		music_player.play()
	if bg_stream and music_bed_player.stream != bg_stream:
		music_bed_player.stream = bg_stream
		_log("bed", "start", bg_stream)
		music_bed_player.play()
	elif bg_stream and not music_bed_player.playing:
		_log("bed", "resume", bg_stream)
		music_bed_player.play()

func stop_music_bed() -> void:
	if music_player.playing:
		_log("music", "stop", music_player.stream)
	if music_bed_player.playing:
		_log("bed", "stop", music_bed_player.stream)
	music_player.stop()
	music_bed_player.stop()

func _replay_music_bed() -> void:
	if music_bed_player.stream != null:
		_log("bed", "loop", music_bed_player.stream)
		music_bed_player.play()

# -- logging ------------------------------------------------------------------

func _log(channel: String, event: String, stream: AudioStream) -> void:
	if not AUDIO_LOG:
		return
	var basename := _stream_name(stream)
	print("%s %s %s — %s" % [LOG_PREFIX, channel, event, basename])

func _stream_name(stream: AudioStream) -> String:
	if stream == null:
		return "<null>"
	var path := stream.resource_path
	if path == "":
		return "<inline>"
	return path.get_file()
