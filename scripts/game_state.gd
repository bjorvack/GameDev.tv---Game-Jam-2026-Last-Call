## Global game state. Autoload as "GameState".
##
## Holds runtime state (patience + current call index) plus a persisted
## checkpoint that survives scene changes and full restarts. The
## checkpoint records the *next* call to play after the last successful
## connect, so the player can resume from where they left off after a
## bad ending or quit.
extends Node

signal patience_changed(new_value: int)
signal call_advanced(index: int)
signal game_ended(good_ending: bool)

const MAX_PATIENCE := 3
const _PROGRESS_PATH := "user://progress.cfg"
const _PROGRESS_SECTION := "checkpoint"
const _PROGRESS_KEY_CALL_INDEX := "call_index"

var patience: int = MAX_PATIENCE
var current_call_index: int = 0

func _ready() -> void:
	# Preload the on-disk checkpoint cache so has_checkpoint() can answer
	# synchronously when the title screen builds its menu.
	_load_checkpoint_cache()

func reset() -> void:
	patience = MAX_PATIENCE
	current_call_index = 0
	patience_changed.emit(patience)

func lose_patience() -> void:
	patience -= 1
	patience_changed.emit(patience)
	if patience <= 0:
		end_game(false)

func advance_call() -> void:
	current_call_index += 1
	# Persist progress every time the player gets past a call (correct
	# connect *or* a non-pivotal timer expiry that lets the story move
	# on). On a Continue this is where the run resumes.
	save_checkpoint(current_call_index)
	call_advanced.emit(current_call_index)

func end_game(good: bool) -> void:
	# Good ending = game complete, drop the checkpoint so the title goes
	# back to a single Start Call button. Bad ending keeps the checkpoint
	# so the player can retry from the last completed call.
	if good:
		clear_checkpoint()
	game_ended.emit(good)

## --- Checkpoint persistence -------------------------------------------

var _checkpoint_cache: int = 0

func has_checkpoint() -> bool:
	# Only meaningful checkpoints (i.e. the player completed at least one
	# call) should surface a Continue button on the title screen.
	return _checkpoint_cache > 0

func checkpoint_call_index() -> int:
	return _checkpoint_cache

## Persist that the player has progressed past `index - 1` and the next
## call to play on Continue is `index`. Called by the CallDirector after
## every successful connect via advance_call.
func save_checkpoint(index: int) -> void:
	if index <= 0:
		return
	_checkpoint_cache = index
	var cfg := ConfigFile.new()
	cfg.load(_PROGRESS_PATH)
	cfg.set_value(_PROGRESS_SECTION, _PROGRESS_KEY_CALL_INDEX, index)
	cfg.save(_PROGRESS_PATH)

## Wipe the on-disk checkpoint. Called on a good ending (game complete)
## and when the player chooses New Game from the title.
func clear_checkpoint() -> void:
	_checkpoint_cache = 0
	# Remove the file entirely so the next has_checkpoint() check is fast
	# and the user:// directory stays tidy.
	if FileAccess.file_exists(_PROGRESS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_PROGRESS_PATH))

func _load_checkpoint_cache() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_PROGRESS_PATH) != OK:
		_checkpoint_cache = 0
		return
	_checkpoint_cache = int(cfg.get_value(_PROGRESS_SECTION, _PROGRESS_KEY_CALL_INDEX, 0))
