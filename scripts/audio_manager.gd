## Global audio manager. Autoload as "AudioManager".
##
## Owns three AudioStreamPlayers — music, ring, sfx — and exposes simple
## play/stop helpers per event. Streams are loaded by path so authoring new
## sounds is just dropping a file in audio/sfx or audio/music and adding a
## constant below.
extends Node

const RING_PATHS: Array[String] = [
	"res://audio/sfx/274289__abernstein__rotary-phone-ring-medium.wav",
	"res://audio/sfx/275053__cvp1965__old-phone-ringing (1).wav",
]
const PLUG_PATH := "res://audio/sfx/477641__joao_janz__power-cord-unplug-1_2.wav"
const HANGUP_PATH := "res://audio/sfx/531060__haleyreesecalhoun__sneaky-phone-put-down-hrc.wav"

const MUSIC_PATHS: Dictionary = {
	"contemplative": "res://audio/music/839571__cvltiv8r__contemplative-string-loop-violin-and-cello.wav",
	"mellow": "res://audio/music/693423__gis_sweden__waiting-for-mellow-cinematic-loop.wav",
	"noise": "res://audio/music/197795__yuval__soundtrack-noise-1940s.wav",
}

const MUSIC_VOLUME_DB := -12.0
const RING_VOLUME_DB := -4.0
const SFX_VOLUME_DB := -6.0

@onready var music_player: AudioStreamPlayer = $Music
@onready var ring_player: AudioStreamPlayer = $Ring
@onready var sfx_player: AudioStreamPlayer = $SFX

var _ring_streams: Array[AudioStream] = []
var _plug_stream: AudioStream
var _hangup_stream: AudioStream
var _ringing: bool = false

func _ready() -> void:
	for path in RING_PATHS:
		var s := load(path) as AudioStream
		if s:
			_ring_streams.append(s)
	_plug_stream = load(PLUG_PATH)
	_hangup_stream = load(HANGUP_PATH)
	music_player.volume_db = MUSIC_VOLUME_DB
	ring_player.volume_db = RING_VOLUME_DB
	sfx_player.volume_db = SFX_VOLUME_DB
	# Manual loop for music + ring — reliable across WAV/MP3/OGG formats.
	music_player.finished.connect(_replay_music)
	ring_player.finished.connect(_replay_ring)

func play_ring() -> void:
	if _ring_streams.is_empty():
		return
	_ringing = true
	ring_player.stream = _ring_streams.pick_random()
	ring_player.play()

func stop_ring() -> void:
	_ringing = false
	ring_player.stop()

## Awaitable single-shot ring. Plays one random ring sample to completion
## without engaging the looping behaviour, then returns. Used after a correct
## route to play the recipient's ringback as a one-shot punctuation between
## the player's plug and the recipient's pickup.
func play_ring_once() -> void:
	if _ring_streams.is_empty():
		return
	# Make sure the loop flag is off so _replay_ring won't sneak another play
	# in once this sample finishes.
	_ringing = false
	ring_player.stream = _ring_streams.pick_random()
	ring_player.play()
	await ring_player.finished

func _replay_ring() -> void:
	# Re-pick a sample on each loop so the call doesn't sound robotic, but
	# only while we're still in a RINGING phase.
	if not _ringing or _ring_streams.is_empty():
		return
	ring_player.stream = _ring_streams.pick_random()
	ring_player.play()

func play_plug() -> void:
	if _plug_stream:
		sfx_player.stream = _plug_stream
		sfx_player.play()

func play_hangup() -> void:
	if _hangup_stream:
		sfx_player.stream = _hangup_stream
		sfx_player.play()

func play_music(track: StringName = &"contemplative") -> void:
	var key := String(track)
	if not MUSIC_PATHS.has(key):
		return
	var stream := load(MUSIC_PATHS[key]) as AudioStream
	if stream == null:
		return
	music_player.stream = stream
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func _replay_music() -> void:
	if music_player.stream != null:
		music_player.play()
