## Plays AI-generated voice clips for dialogue lines. Autoload as
## "VoicePlayer". Owns a single AudioStreamPlayer so only one voice
## line plays at a time — starting a new line cancels the previous
## one silently.
##
## Knows nothing about DialogueLines, Characters, moods, or file
## naming conventions. Consumers (CallerCard, CallDirector) hand it
## a resolved AudioStream; resolution lives wherever the consumer
## prefers. This keeps the player narrowly focused on playback.
##
## Two signals so consumers can distinguish natural completion from a
## caller-initiated cancel:
##   - finished : the clip played to its end on its own
##   - stopped  : stop() was called while the clip was still playing
extends Node

## Emitted when a voice clip ends on its own. The auto-dialogue-
## advance path listens to this so the line advances exactly when
## the speech ends, not on a separately-tracked timer.
signal finished

## Emitted when stop() is called while audio was still playing. Lets
## consumers tell their own stop apart from a natural completion if
## that distinction matters (e.g. analytics, animation cleanup).
signal stopped

var _player: AudioStreamPlayer
var _playing: bool = false

func _ready() -> void:
	# Stay audible while the tree is paused — voice should keep going
	# if a pause overlay opens mid-line. (Matches UiAudio.)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	# Default to the existing master bus; if/when a dedicated "Voice"
	# bus is added (for the telephone-band runtime filter), update
	# this once and every clip starts using it.
	_player.bus = "Master"
	add_child(_player)
	_player.finished.connect(_on_natural_finished)

## Play the given stream. Returns its duration in seconds (or 0.0 if
## `stream` is null). Any in-flight clip is cancelled silently — the
## new one takes over without a `stopped` emit, since the caller is
## the one switching tracks.
func play(stream: AudioStream) -> float:
	if _playing:
		_playing = false
		_player.stop()
	if stream == null:
		return 0.0
	_player.stream = stream
	_player.play()
	_playing = true
	return stream.get_length()

## Stop the current voice line, if any. Emits `stopped` only when a
## clip was actually playing — calling stop() on an idle player is
## a no-op (no spurious signals). Does NOT emit `finished` — that's
## reserved for natural completion so consumers can disambiguate.
func stop() -> void:
	if not _playing:
		return
	_playing = false
	_player.stop()
	stopped.emit()

func _on_natural_finished() -> void:
	# Engine fires AudioStreamPlayer.finished both for natural ends
	# and after .stop() — but we already cleared _playing in stop(),
	# so this guard turns the spurious "finished after stop()" call
	# into a no-op.
	if not _playing:
		return
	_playing = false
	finished.emit()
