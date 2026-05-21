## Title screen. Any key/click starts a fresh run by resetting GameState
## and loading the switchboard.
extends Control

const SWITCHBOARD := "res://scenes/switchboard.tscn"

func _ready() -> void:
	# In case we come back here from an ending, scrub the run state.
	if GameState:
		GameState.reset()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_start()
	elif event is InputEventMouseButton and event.pressed:
		_start()

func _start() -> void:
	get_tree().change_scene_to_file(SWITCHBOARD)
