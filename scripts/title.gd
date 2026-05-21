## Title screen. Any key/click starts a fresh run by resetting GameState
## and loading the switchboard.
extends Control

const SWITCHBOARD := "res://scenes/switchboard.tscn"

var _starting := false

func _ready() -> void:
	# In case we come back here from an ending, scrub the run state.
	if GameState:
		GameState.reset()
	# We may have been loaded by a SceneTransition fade-out — make sure
	# the overlay fades back in.
	if SceneTransition:
		SceneTransition.fade_in()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_start()
	elif event is InputEventMouseButton and event.pressed:
		_start()

func _start() -> void:
	if _starting:
		return
	_starting = true
	SceneTransition.change_scene(SWITCHBOARD)
