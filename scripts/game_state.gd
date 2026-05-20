## Global game state. Autoload as "GameState".
extends Node

signal patience_changed(new_value: int)
signal call_advanced(index: int)
signal game_ended(good_ending: bool)

const MAX_PATIENCE := 3

var patience: int = MAX_PATIENCE
var current_call_index: int = 0

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
	call_advanced.emit(current_call_index)

func end_game(good: bool) -> void:
	game_ended.emit(good)
